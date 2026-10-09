#!/usr/bin/env python3
"""Bounded native restart controls. Uses only new profiles and test-owned groups."""
from pathlib import Path
import importlib.util,json,os,signal,socket,sqlite3,subprocess,tempfile,time,shutil
from urllib.request import build_opener,ProxyHandler
from urllib.error import URLError
repo=Path(__file__).resolve().parents[1]
with socket.socket() as sock:
 if sock.connect_ex(('127.0.0.1',23119))==0:raise SystemExit('Existing Zotero API is active; leaving personal sessions untouched.')
root=Path(tempfile.mkdtemp(prefix='noesis-zotero-controls-'));root.chmod(0o700)
profile=root/'profile';profile.mkdir();data=root/'data';data.mkdir()
opener=build_opener(ProxyHandler({}));results=[]
def prefs(location):
 values={'extensions.zotero.useDataDir':True,'extensions.zotero.dataDir':str(location),'extensions.zotero.httpServer.enabled':True,'extensions.zotero.httpServer.localAPI.enabled':True,'extensions.zotero.firstRun.skipFirefoxProfileAccessCheck':True}
 # Native shutdown may rewrite prefs.js. user.js applies the exact test location every startup.
 (profile/'user.js').write_text('\n'.join('user_pref('+json.dumps(k)+', '+json.dumps(v)+');' for k,v in values.items()))
def run(name,location):
 prefs(location);log=root/(name+'.log');start=time.monotonic()
 with log.open('w') as output:
  process=subprocess.Popen([str(Path.home()/'.local/bin/zotero'),'--no-remote','--new-instance','--profile',str(profile)],env=dict(os.environ,MOZ_NO_REMOTE='1'),stdout=output,stderr=output,start_new_session=True)
  result={'control':name,'location':str(location),'pid':process.pid,'ready':False}
  try:
   deadline=start+30
   while time.monotonic()<deadline:
    try:
     with opener.open('http://127.0.0.1:23119/api/',timeout=1) as response:
      result.update(ready=True,server_id=response.headers.get('Zotero-Server-ID'));break
    except (OSError,URLError):
     if process.poll() is not None:result['exit_code']=process.returncode;break
     time.sleep(.1)
   result['seconds']=round(time.monotonic()-start,3)
   result['processes']=subprocess.check_output(['ps','-eo','pid,ppid,pgid,args'],text=True).splitlines()
   result['processes']=[line for line in result['processes'] if str(profile) in line or ('zotero' in line and str(process.pid) in line.split()[:3])]
  finally:
   # Request a native close only for clients belonging to this test process group.
   clients=json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True))
   for client in clients:
    try:owned=os.getpgid(client['pid'])==process.pid
    except ProcessLookupError:owned=False
    if owned:
     subprocess.run(['hyprctl','dispatch','hl.dsp.window.close({window='+json.dumps('address:'+client['address'])+'})'],capture_output=True,check=True)
   try:process.wait(timeout=5);result['shutdown']='native-close'
   except subprocess.TimeoutExpired:result['shutdown']='signal-fallback'
   try:os.killpg(process.pid,signal.SIGTERM)
   except ProcessLookupError:pass
   try:process.wait(timeout=10)
   except subprocess.TimeoutExpired:
    os.killpg(process.pid,signal.SIGKILL);process.wait(timeout=5)
   # Verify group members have stopped before a consistent copy/restart.
   deadline=time.monotonic()+10
   while time.monotonic()<deadline:
    members=[]
    for entry in Path('/proc').iterdir():
     if not entry.name.isdigit():continue
     try:
      fields=(entry/'stat').read_text().rsplit(')',1)[1].split()
      if int(fields[2])==process.pid and fields[0]!='Z':members.append(int(entry.name))
     except (OSError,ValueError,IndexError):pass
    if not members:break
    time.sleep(.1)
   if members:raise RuntimeError('Test process group still alive; refusing copy/restart')
 db=location/'zotero.sqlite'
 if db.exists():
  try:
   with sqlite3.connect(db.as_uri()+'?mode=ro',uri=True) as connection:
    result['integrity']=connection.execute('PRAGMA integrity_check').fetchone()[0]
    result['user_version']=connection.execute('PRAGMA user_version').fetchone()[0]
    result['versions']=connection.execute('SELECT * FROM version').fetchall()
  except sqlite3.Error as error:result['database_error']=str(error)
 results.append(result);(root/'results.json').write_text(json.dumps(results,indent=2));print(name,result['ready'],result['seconds'],flush=True)
 return result['ready']
print('Diagnostics:',root,flush=True)
if run('initial',data):
 run('unchanged',data)
 direct=root/'direct-copy';shutil.copytree(data,direct)
 run('direct-copy',direct)
 spec=importlib.util.spec_from_loader('reader_backup',__import__('importlib.machinery',fromlist=['SourceFileLoader']).SourceFileLoader('reader_backup',str(repo/'home/.local/bin/sensei-learning-backup')))
 backup=importlib.util.module_from_spec(spec);spec.loader.exec_module(backup)
 from unittest.mock import patch
 with patch.object(backup,'STATE',root/'snapshots'):snapshot=backup.backup_readers([data])[0]
 restored=root/'restored';backup.restore_reader(Path(snapshot['snapshot']),restored)
 run('restored-copy',restored)
print('Bounded restart controls complete. Empty database controls do not establish annotation/PDF recovery.',flush=True)
