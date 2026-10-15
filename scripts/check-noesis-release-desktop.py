#!/usr/bin/env python3
"""Native release: long histories, storage interruption, Zed, absent ScreenPad and idle."""
import json,os,time,subprocess,signal,sys,uuid
from datetime import datetime,timedelta,timezone
from pathlib import Path
from noesis_native_fixture import REPO
prefix=(REPO/'scripts/check-noesis-self-service.py').read_text().split('clipboard=subprocess.run')[0]
exec(compile(prefix,'release-native-instrumentation','exec'))
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.persistence import render,parse
from noesis.models import create
from noesis.exploration import prepare
assets=REPO/'docs/learning-system/assets/release-hardening';assets.mkdir(parents=True,exist_ok=True)
# Explicit history/availability stress fixtures, not synthetic owner achievements.
props={'noesis_schema':2,'id':f.record_id,'type':'task','title':'Agent validation · returning graph problem'}
(f.vault/'problem.md').write_text(render(props,'## Problem statement\n\nPredict what happens when the graph contains a negative edge. Preserve your uncertainty.\n\n## Reference answer\n\nHidden reference marker: do not expose during the active attempt.\n'))
folder=f.vault/'Activities';folder.mkdir();previous=None;started=None
for n in range(1001):
 identity=str(uuid.uuid4());event='attempt-start' if n%2==0 else 'attempt';row={'noesis_schema':2,'id':identity,'type':'activity','event':event,'timestamp':(datetime(2024,1,1,tzinfo=timezone.utc)+timedelta(seconds=n)).isoformat(),'target':{'vault_id':f.vault_id,'record_id':f.record_id},'previous':previous,'provenance':'agent stress fixture','mode':'derive'}
 if n%2:row.update(attempt_id=started,outcome='failed',assistance=['agent'])
 else:started=identity
 (folder/f'{n:04}.md').write_text(render(row,'Agent validation history. No owner result or competence claim.'));previous=identity
scratch=prepare(f.vault,f.record_id,'Agent validation · editor continuity','scratch',str(uuid.uuid4()))
# Existing owned records are fixture setup; stress data is intentionally prepared.
shell=f.config/'shell.qml';s=shell.read_text().replace('function chooseDesk(index:int)', 'function historyState():string{return JSON.stringify({ids:window.workspacePage.historyDisplay.map(r=>r.id),older:window.workspacePage.historyCursor,newer:window.workspacePage.historyNewerCursor});}\n  function absentDesk(value:bool):void{window.studyDesk.testScreenAbsent=value;}\n  function captureDesk(path:string):void{window.studyDesk.applicationSurface.grabToImage(r=>r.saveToFile(path));}\n  function chooseDesk(index:int)');shell.write_text(s)
p=f.home/'.local/share/sensei-learning/ui/NoesisStudyDesk.qml';s=p.read_text().replace(' readonly property var deskScreen:', ' property bool testScreenAbsent:false\n readonly property var deskScreen:testScreenAbsent?null:');p.write_text(s)
# Use the installed editor with isolated configuration and data, not personal projects.
zed_config=f.home/'.config/zed';zed_config.mkdir();(zed_config/'settings.json').write_text(json.dumps({'telemetry':{'diagnostics':False,'metrics':False},'languages':{'Python':{'language_servers':[]}},'auto_update':False}))
(f.home/'.local/bin/zed').symlink_to(Path.home()/'.local/bin/zed')
f.env['PATH']=str(f.home/'.local/bin')+':'+f.env['PATH']
clipboard=subprocess.run(['wl-paste','--no-newline'],capture_output=True)
def click(label):
 result=f.ipc('journey-fixture','click',label)
 if result!='clicked':
  f.ipc('journey-fixture','capture',str(assets/'failure.png'));time.sleep(.5)
  raise AssertionError((label,result,json.loads(f.ipc('journey-fixture','historyState'))))
def capture(name):
 path=assets/(name+'.png');path.unlink(missing_ok=True);f.ipc('journey-fixture','capture',str(path));time.sleep(.5);assert path.exists()
def memory():
 data=Path(f'/proc/{f.process.pid}/smaps_rollup').read_text();return {key:int(next(line.split()[1] for line in data.splitlines() if line.startswith(key+':'))) for key in ['Rss','Pss']}
def cpu():
 fields=Path(f'/proc/{f.process.pid}/stat').read_text().rsplit(')',1)[1].split();return (int(fields[11])+int(fields[12]))/os.sysconf('SC_CLK_TCK')
zed_pids=[]
try:
 subprocess.run(['hyprctl','dispatch','hl.dsp.focus({workspace="4"})'],check=True,capture_output=True)
 f.start(resume=True);f.ipc('journey-fixture','init');f.ipc('journey-fixture','open',json.dumps(dict(props,path='problem.md',vault=str(f.vault),vault_id=f.vault_id)));f.wait(lambda s:s['attempt']==started);assert f.state()['reference_hidden'];click('History & next steps')
 for _ in range(len(json.loads(f.ipc('journey-fixture','state'))['actions'])-1):f.key('Down')
 f.key('Return');f.wait(lambda s:s['context_tab']=='History');time.sleep(.3)
 seen=set();pages=0
 while True:
  page=json.loads(f.ipc('journey-fixture','historyState'));assert len(page['ids'])<=50;assert not seen.intersection(page['ids']);seen.update(page['ids']);pages+=1
  if not page['older']:break
  click('Older history');time.sleep(.2)
 assert len(seen)==1001 and pages==21,(len(seen),pages);capture('oldest-history');click('Newer history');time.sleep(.2);assert len(json.loads(f.ipc('journey-fixture','historyState'))['ids'])==50;click('Latest history');time.sleep(.3);assert f.state()['reference_hidden'];capture('latest-protected-history')
 click('← Return to thinking');assert f.ipc('journey-fixture','type','practice-reasoning','agent validation uncertainty remains after interruption')=='agent validation uncertainty remains after interruption';time.sleep(.6)
 offline=f.home/'offline-storage';f.vault.rename(offline);click('Refresh');time.sleep(1);assert f.state()['error'];capture('unavailable-storage');assert json.loads(f.ipc('journey-fixture','state'))['notes']=='agent validation uncertainty remains after interruption'
 offline.rename(f.vault);click('Refresh');time.sleep(1);assert f.state()['selected']=='problem.md';assert json.loads(f.ipc('journey-fixture','state'))['notes']=='agent validation uncertainty remains after interruption'
 f.exit();f.start(resume=True);f.ipc('journey-fixture','init');f.wait(lambda s:s['attempt']==started);assert f.state()['reference_hidden'];assert json.loads(f.ipc('journey-fixture','state'))['notes']=='agent validation uncertainty remains after interruption';capture('returning-learner')
 # Change editor through its real Settings control, then open the owned file.
 click('Settings');assert f.ipc('journey-fixture','choose','settings-code-editor','1')=='Zed · native editor';f.wait(lambda s:not s['working']);time.sleep(.5);click('Done');f.ipc('journey-fixture','open',json.dumps(dict(scratch,vault=str(f.vault))));f.wait(lambda s:s['experiment']);click('Edit scratch code');f.wait(lambda s:not s['visible'] and not s['working'],seconds=20)
 deadline=time.monotonic()+20
 while time.monotonic()<deadline:
  rows=[c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c.get('class')=='dev.zed.Zed' and str(f.home) in Path(f'/proc/{c["pid"]}/environ').read_bytes().decode(errors='replace')]
  if rows:break
  time.sleep(.2)
 assert rows,'Native Zed did not open';zed_pids=[c['pid'] for c in rows];assert any('scratch.py' in c['title'] for c in rows),rows
 zed=rows[0];subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+json.dumps('address:'+zed['address'])+'})'],check=True,capture_output=True)
 geometry=zed['at']+zed['size'];subprocess.run(['grim','-g',f'{geometry[0]},{geometry[1]} {geometry[2]}x{geometry[3]}',str(assets/'zed-open.png')],check=True)
 # Respect Zed project trust: remain restricted; editing does not need code execution.
 time.sleep(1.5)
 subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods="CTRL + ALT + SHIFT",key="s",window='+json.dumps('address:'+zed['address'])+'})'],check=True,capture_output=True);time.sleep(.4)
 # Real editor key input alters and saves only the disposable code, proving reachability.
 subprocess.run(['wl-copy'],input='print("agent validation · Zed edit")\n',text=True,check=True);time.sleep(.25)
 for mods,key in [('CTRL','a'),('CTRL','v'),('CTRL','s')]:subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods='+json.dumps(mods)+',key='+json.dumps(key)+',window='+json.dumps('address:'+zed['address'])+'})'],check=True,capture_output=True);time.sleep(.15)
 time.sleep(.7)
 geometry=zed['at']+zed['size'];subprocess.run(['grim','-g',f'{geometry[0]},{geometry[1]} {geometry[2]}x{geometry[3]}',str(assets/'zed-after-input.png')],check=True)
 assert 'Zed edit' in (f.vault/scratch['local_file']).read_text()
 geometry=zed['at']+zed['size'];subprocess.run(['grim','-g',f'{geometry[0]},{geometry[1]} {geometry[2]}x{geometry[3]}',str(assets/'zed-owned-code.png')],check=True)
 f.ipc('noesis','open');f.wait(lambda s:s['visible']);f.ipc('journey-fixture','mode','fullscreen');time.sleep(.5);assert json.loads(f.ipc('noesis-study-desk','state'))['visible'];f.ipc('journey-fixture','absentDesk','true');time.sleep(.2);assert not json.loads(f.ipc('noesis-study-desk','state'))['visible'];assert f.state()['visible'];f.ipc('journey-fixture','absentDesk','false');time.sleep(.3);assert json.loads(f.ipc('noesis-study-desk','state'))['visible'];capture('fullscreen-exploration')
 samples=[memory()]
 for n in range(20):
  f.ipc('noesis','hide');f.wait(lambda s:not s['worker'] and not s['watch']);f.ipc('noesis','open');f.wait(lambda s:s['visible'] and s['worker']);
  if n%5==4:samples.append(memory())
 assert samples[-1]['Pss']-samples[0]['Pss']<50*1024,samples
 # Five-minute observed idle interval. Outer tool remains nonblocking for updates.
 start=time.monotonic();ticks=cpu();print('Native journeys passed; beginning five-minute idle observation',flush=True)
 for minute in range(5):time.sleep(60);print('idle minute',minute+1,memory(),flush=True)
 idle={'seconds':time.monotonic()-start,'cpu_seconds':cpu()-ticks,'before':samples[-1],'after':memory()}
 assert idle['after']['Pss']-idle['before']['Pss']<30*1024,idle
 result={'history_events':len(seen),'history_pages':pages,'protected_after_history_restart':True,'draft_after_storage_return_restart':True,'zed_native_edit_saved':True,'absent_screen_adapter_recovery':True,'open_hide_cycles':20,'process_memory_kib':samples,'idle':idle,'native_state':f.state(),'provenance':'agent validation fixtures; no owner achievement'}
 (assets/'desktop-acceptance.json').write_text(json.dumps(result,indent=2)+'\n');print('PASS: release desktop gates',flush=True)
finally:
 f.stop()
 for pid in set(zed_pids):
  try:os.kill(pid,signal.SIGTERM)
  except ProcessLookupError:pass
 if clipboard.returncode==0:subprocess.run(['wl-copy'],input=clipboard.stdout)
