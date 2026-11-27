"""Exercise outages without real clipboard, network, accounts or user data."""
import importlib.machinery,importlib.util,json,os,subprocess,sys
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]

def load(name,path):
 loader=importlib.machinery.SourceFileLoader(name,str(ROOT/path));spec=importlib.util.spec_from_loader(name,loader);m=importlib.util.module_from_spec(spec);loader.exec_module(m);return m

def test_clipboard_watcher_death_ends_worker_instead_of_hanging(tmp_path):
 executable=tmp_path/'wl-paste';executable.write_text('#!/bin/sh\nexit 1\n');executable.chmod(0o755)
 process=subprocess.Popen([sys.executable,str(ROOT/'pc/den/den-clipboard.py'),'worker'],env=dict(os.environ,PATH=str(tmp_path)+':'+os.environ['PATH']),stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
 try:
  process.wait(timeout=3)
  assert process.returncode!=0
  assert b'offer watcher stopped' in process.stderr.read()
 finally:
  if process.poll() is None:process.kill();process.wait()
  process.stdin.close();process.stdout.close();process.stderr.close()

def test_sensitive_clipboard_is_not_read_or_emitted():
 bridge=load('clipboard_sensitive','pc/den/den-clipboard.py')
 with patch.dict(os.environ,CLIPBOARD_STATE='sensitive'),patch.object(bridge.subprocess,'check_output') as probe,patch.object(bridge.sys,'stdin') as source,patch.object(bridge.sys,'stdout') as output:
  bridge.event();probe.assert_not_called();source.buffer.read.assert_not_called();output.write.assert_not_called()

def test_quota_outage_is_unknown_with_bounded_retry_and_recovery(tmp_path):
 q=load('quota_recovery','home/.local/bin/sensei-quota-observe')
 with patch.object(q.time,'time',return_value=10000):
  first=q.observe(tmp_path,runner=lambda *a,**kw:subprocess.CompletedProcess([],1,'','private diagnostic'))
 assert first['state']=='unknown' and first['nextRetry']==10300
 path=tmp_path/'.local/state/sensei-quota/observer.json';assert 'private diagnostic' not in path.read_text()
 with patch.object(q.time,'time',return_value=10100):
  def unexpected(*a,**kw):raise AssertionError('Backoff did not apply')
  assert q.observe(tmp_path,runner=unexpected)['attempted'] is False
 with patch.object(q.time,'time',return_value=10301):
  result=q.observe(tmp_path,runner=lambda *a,**kw:subprocess.CompletedProcess([],0,'{"remaining":0.1}',''))
 assert result['state']=='observed' and result['lastSuccess']==10301 and result['failures']==0
 assert path.stat().st_mode&0o777==0o600

def test_clipboard_archive_fails_closed_and_stops_plaintext_snapshots(tmp_path):
 import sqlite3
 binary=tmp_path/'wl-paste';binary.write_text('#!/bin/sh\nexit 1\n');binary.chmod(0o755)
 env=dict(os.environ,HOME=str(tmp_path),PATH=str(tmp_path)+':'+os.environ['PATH'])
 command=[sys.executable,str(ROOT/'home/.local/bin/clipboard-vault'),'store','text']
 subprocess.run(command,input=b'fixture-secret',env=env,check=True)
 database=tmp_path/'.clipboard/history.sqlite'
 with sqlite3.connect(database) as db:assert db.execute('select count(*) from items').fetchone()[0]==0
 binary.write_text('#!/bin/sh\nprintf "%s\\n" text/plain\n')
 subprocess.run(command,input=b'ordinary-fixture',env=env,check=True)
 with sqlite3.connect(database) as db:assert db.execute('select content from items').fetchall()==[('ordinary-fixture',)]
 assert [p for p in database.parent.rglob('*.sqlite') if p!=database]==[]

def test_phone_unknown_portal_state_cannot_claim_disabled(tmp_path):
 import types
 sys.path.insert(0,str(ROOT/'home/.local/share/sensei'))
 with patch.dict(sys.modules,dbus=types.SimpleNamespace()),patch.object(Path,'home',return_value=tmp_path):
  phone=load('phone_portal_safety','home/.local/bin/sensei-phone')
 gate=tmp_path/'permission';gate.write_text('keep')
 with patch.object(phone,'INPUT_GATE',gate),patch.object(phone,'run',side_effect=[{'ok':True,'output':''},{'ok':False,'output':'bus unavailable'}]):
  result=phone.action('remote-input',args=['off'])
 assert not result['ok'] and not gate.exists()
 with patch.object(phone,'run',return_value={'ok':False,'output':'inactive'}):assert phone.portal_state() is False

def test_completed_package_command_does_not_wait_for_inherited_pty(tmp_path):
 import signal,time
 child=tmp_path/'child.pid'
 program='import os,time,pathlib;pid=os.fork();pathlib.Path('+repr(str(child))+').write_text(str(pid)) if pid else time.sleep(60)'
 runner=tmp_path/'runner.py'
 runner.write_text('import importlib.machinery,pathlib,sys\nm=importlib.machinery.SourceFileLoader("package_fixture",'+repr(str(ROOT/'home/.local/bin/sensei-package-job'))+').load_module()\nm.STATE=pathlib.Path('+repr(str(tmp_path/'state'))+')\nm.command=lambda *args:[sys.executable,"-c",'+repr(program)+']\nm.shutil.which=lambda *args:None\nm.run("firmware","")\n')
 started=__import__('time').monotonic()
 try:
  subprocess.run([sys.executable,str(runner)],capture_output=True,text=True,timeout=5,check=True)
  result=json.loads((tmp_path/'state/job.json').read_text())
  assert result['status']=='done' and result['exitCode']==0
  assert __import__('time').monotonic()-started<4
 finally:
  if child.exists():
   try:os.kill(int(child.read_text()),signal.SIGTERM)
   except ProcessLookupError:pass
