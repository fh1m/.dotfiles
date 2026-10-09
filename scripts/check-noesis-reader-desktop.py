#!/usr/bin/env python3
"""Native lesson → Sioyek page handoff with a disposable profile and authored PDF.

Requires existing Quickshell, Sioyek, Hyprland, grim and reportlab. Does not install
software or touch the user's reader profile. Screenshots are synthetic native
rendering evidence; visible page labels and restored position require inspection.
"""
from pathlib import Path
import importlib.util,json,os,subprocess,tempfile,time,shutil
from reportlab.pdfgen import canvas
repo=Path(__file__).resolve().parents[1]
real_home=Path.home();portable=real_home/'.local/opt/sioyek-2.0.0'
if not (portable/'AppRun').is_file():raise SystemExit('Existing Sioyek portable build required')
reader_exists=any('sioyek' in row['class'].lower() for row in json.loads(subprocess.check_output(['hyprctl','clients','-j'])))
for process in Path('/proc').glob('[0-9]*/exe'):
 try:reader_exists=reader_exists or process.resolve()==(portable/'AppRun').resolve()
 except (FileNotFoundError,PermissionError,OSError):pass
if reader_exists or subprocess.run(['pgrep','-x','sioyek'],capture_output=True).returncode==0:raise SystemExit('Close Sioyek before the isolated reader acceptance; user windows are never reused')
spec=importlib.util.spec_from_file_location('installer',repo/'scripts/install.py');installer=importlib.util.module_from_spec(spec);spec.loader.exec_module(installer)
with tempfile.TemporaryDirectory(prefix='noesis-reader-ui-') as temporary:
 home=Path(temporary);installer.install(home,True)
 (home/'.local/opt').mkdir(parents=True,exist_ok=True);(home/'.local/opt/sioyek-2.0.0').symlink_to(portable)
 root=home/'vault';(root/'System').mkdir(parents=True);(root/'System/System.json').write_text(json.dumps({'directories':[]}))
 pdf=root/'course.pdf';document=canvas.Canvas(str(pdf))
 for page in range(1,7):
  document.setFont('Helvetica',24);document.drawString(60,740,'LINEAR ALGEBRA - LESSON '+str(page))
  document.setFont('Helvetica',18);document.drawString(60,680,'SAVED PLACE: PAGE THREE' if page==3 else 'Distinct page '+str(page))
  document.drawString(60,610,'Predict: when does Ax = b have one solution?')
  document.showPage()
 document.save()
 env=dict(os.environ,HOME=str(home),XDG_CONFIG_HOME=str(home/'.config'),XDG_CACHE_HOME=str(home/'.cache'),XDG_DATA_HOME=str(home/'.local/share'),XDG_STATE_HOME=str(home/'.local/state'),NOESIS_WINDOW_MODE='normal')
 helper=home/'.local/bin/sensei-learn'
 def cli(*args):return json.loads(subprocess.check_output([str(helper),*args,'--vault',str(root)],env=env,text=True))
 cli('migrate','--apply')
 course=cli('record','resource','Linear algebra course','--data',json.dumps({'source_kind':'course','local_file':'course.pdf'}))
 source=home/'outline.json';source.write_text(json.dumps({'version':1,'title':'Linear algebra course','entries':[
  *[{'key':'lecture'+str(n),'kind':'unit','title':'Lecture '+str(n),'fields':{'unit_kind':'lecture'}} for n in range(1,7)],
  *[{'key':'reading'+str(n),'kind':'unit','title':'Reading '+str(n),'fields':{'unit_kind':'reading'}} for n in range(1,3)],
  *[{'key':'assignment'+str(n),'kind':'task','title':'Assignment '+str(n)} for n in range(1,3)],
  {'key':'project','kind':'project','title':'Course project'}]}))
 import uuid
 cli('course-import',str(source),'--course-id',course['id'],'--apply','--operation-id',str(uuid.uuid4()))
 lesson=next(row for row in cli('query','Lecture 3')['records'] if row['type']=='unit')
 cli('event',lesson['path'],'study','--target-id',lesson['id'],'--data',json.dumps({'state':{'locator':{'kind':'page','value':3}}}))
 originals={file.relative_to(root):file.read_bytes() for file in root.rglob('*.md')}
 (home/'.config/sensei-learning').mkdir(exist_ok=True);(home/'.config/sensei-learning/config.json').write_text(json.dumps({'active_vault':str(root)}))
 config=home/'.config/quickshell/wrayth';(config/'shell.qml').write_text('import QtQuick\nimport Quickshell\nimport "modules/learning" as LearningUi\nimport qs.services\nShellRoot {LearningUi.NoesisWindow {} Component.onCompleted:Oasis.open()}\n')
 qs=os.environ.get('NOESIS_QS',str(real_home/'.local/opt/sensei-quickshell/bin/qs'));log=home/'qml.log';reader_pid=None;reader_home=home
 with log.open('w') as stream:
  shell=subprocess.Popen([qs,'-p',str(config),'--no-color'],env=env,stdout=stream,stderr=subprocess.STDOUT)
  try:
   def state():return json.loads(subprocess.check_output([qs,'-p',str(config),'ipc','call','noesis-window','state'],env=env,text=True,stderr=subprocess.DEVNULL))
   time.sleep(3)
   client=next(row for row in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if row['pid']==shell.pid and row['title'].startswith('Noesis'))
   def key(mods,key,address=None):
    expression='hl.dsp.send_shortcut({mods='+json.dumps(mods)+',key='+json.dumps(key)+',window='+json.dumps('address:'+(address or client['address']))+'})'
    subprocess.run(['hyprctl','dispatch',expression],check=True,capture_output=True);time.sleep(.15)
   key('CTRL','2');key('CTRL','k')
   for letter in 'Lecture 3':key('','space' if letter==' ' else letter)
   time.sleep(.5);key('','Down');key('','Return');time.sleep(.7)
   assert state()['selected']==lesson['path'],state()
   key('CTRL + SHIFT','Return')
   deadline=time.monotonic()+15;reader=None
   while time.monotonic()<deadline:
    for row in json.loads(subprocess.check_output(['hyprctl','clients','-j'])):
     if 'sioyek' not in row['class'].lower():continue
     try:environment=Path('/proc/'+str(row['pid'])+'/environ').read_bytes().split(b'\0')
     except FileNotFoundError:continue
     if ('HOME='+str(home)).encode() in environment:reader=row;break
    if reader:break
    time.sleep(.1)
   assert reader is not None,('No isolated reader window',state())
   reader_pid=reader['pid'];time.sleep(2)
   time.sleep(.5)
   active=json.loads(subprocess.check_output(['hyprctl','activewindow','-j']));assert active['address']==reader['address'],active
   assert not state()['error'],state()
   assert not state()['visible'] and not state()['worker'] and not state()['watch'],state()
   x,y=reader['at'];w,h=reader['size'];subprocess.run(['grim','-g',f'{x},{y} {w}x{h}','/tmp/noesis-sioyek-page-native.png'],check=True)
   key('','b',reader['address'])
   for letter in 'resume calculation':key('','space' if letter==' ' else letter,reader['address'])
   key('','Return',reader['address']);time.sleep(.3)
   key('','q',reader['address']);time.sleep(.8)
   databases=list(home.rglob('*.db'));print('Isolated reader data:',[str(path.relative_to(home)) for path in databases])
   assert databases,'Reader did not create its isolated data directory'
   import sqlite3
   for database in databases:
    with sqlite3.connect('file:'+str(database)+'?mode=ro',uri=True) as connection:assert connection.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
   print('PASS: Sioyek data lives in the disposable profile; SQLite integrity checks pass')
   import importlib.machinery
   from unittest.mock import patch
   loader=importlib.machinery.SourceFileLoader('reader_backup',str(home/'.local/bin/sensei-learning-backup'))
   backup_spec=importlib.util.spec_from_loader(loader.name,loader);backup=importlib.util.module_from_spec(backup_spec);loader.exec_module(backup)
   backup.HOME=home;backup.STATE=home/'snapshots'
   with patch.dict(os.environ,env):reports=backup.backup_readers()
   owning=next(report for report in reports if report['source']==str(databases[0].parent))
   restored_home=home/'reader-restored';destination=restored_home/'.config/.local/share/Sioyek'
   restored=backup.restore_reader(Path(owning['snapshot']),destination)
   assert any(info['tables'].get('bookmarks',0)>0 for info in restored['databases'].values()),restored
   restored_env=dict(env,HOME=str(restored_home),XDG_CONFIG_HOME=str(restored_home/'.config'),XDG_DATA_HOME=str(restored_home/'.local/share'))
   reopened=subprocess.Popen([str(home/'.local/bin/sioyek'),str(pdf)],env=restored_env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
   time.sleep(3)
   restored_reader=next(row for row in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if 'sioyek' in row['class'].lower() and ('HOME='+str(restored_home)).encode() in Path('/proc/'+str(row['pid'])+'/environ').read_bytes().split(b'\0'))
   reader_pid=restored_reader['pid'];reader_home=restored_home
   x,y=restored_reader['at'];w,h=restored_reader['size'];subprocess.run(['grim','-g',f'{x},{y} {w}x{h}','/tmp/noesis-sioyek-restored-native.png'],check=True)
   key('','q',restored_reader['address']);time.sleep(.8)
   print('PASS: reader snapshot discovered at its actual portable location; bookmark table restored; native profile reopened without a page argument')

   subprocess.run([qs,'-p',str(config),'ipc','call','noesis','close'],env=env,capture_output=True,check=True)
   shell.terminate();shell.wait(timeout=5);shutil.rmtree(home/'.cache/noesis')
   shell=subprocess.Popen([qs,'-p',str(config),'--no-color'],env=env,stdout=stream,stderr=subprocess.STDOUT);time.sleep(3)
   assert state()['selected']==lesson['path'],state()
   activities=cli('timeline',lesson['id'])['activities'];assert activities[-1]['state']['locator']=={'kind':'page','value':3}
   assert all((root/relative).read_bytes()==content for relative,content in originals.items())
   print('PASS: native course lesson source shortcut opens an isolated Sioyek window; page-3 locator, selected lesson and original notes survive restart/cache loss')
   print('Reader screenshot: /tmp/noesis-sioyek-page-native.png; inspect the actual visible page before claiming page navigation acceptance')
  finally:
   shell.terminate();shell.wait(timeout=5)
   if reader_pid:
    try:
     if ('HOME='+str(reader_home)).encode() in Path('/proc/'+str(reader_pid)+'/environ').read_bytes().split(b'\0'):os.kill(reader_pid,15)
    except (FileNotFoundError,ProcessLookupError):pass
 print(log.read_text()[-3000:]);assert 'WARN' not in log.read_text() and 'ERROR' not in log.read_text()
