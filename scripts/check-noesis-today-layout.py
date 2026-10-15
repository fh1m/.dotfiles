#!/usr/bin/env python3
"""Native Today continuation, quiet controls and adaptive composition in owned fixtures."""
import json,subprocess,time,sys
from pathlib import Path
from unittest.mock import patch
from noesis_native_fixture import Fixture,REPO
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.models import create
f=Fixture();evidence=Path('/tmp/noesis-today-layout-evidence');evidence.mkdir(exist_ok=True)
with patch('pathlib.Path.home',return_value=f.home):
 path=create(f.vault,'path','First principles: prediction, changed cases and independent reconstruction')
 course=create(f.vault,'resource','A university course with a source, prerequisites and independent assessment',fields={'source_kind':'course'})
 for number in range(5):create(f.vault,'unit',f'Lecture {number+1}: Representation and careful reasoning',parent_id=course['id'],fields={'unit_kind':'lecture'})
 create(f.vault,'experiment','Bias calibration with a preserved prediction',fields={'hypothesis':'Zero mean rate'})
shell=f.config/'shell.qml';s=shell.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:fixtureWindow}')
s=s.replace('ShellRoot {','ShellRoot {\n IpcHandler {target:"today-fixture";function quiet():void{fixtureWindow.focusTodayQuiet();}function presentation(value:string):void{LearningUi.NoesisController.presentationMode=value;LearningUi.NoesisController.savePreferences();}function scale(value:real):void{fixtureWindow.openSettings();LearningUi.NoesisStyle.interfaceScale=value;LearningUi.NoesisStyle.readingScale=value;LearningUi.NoesisController.savePreferences();}}')
shell.write_text(s)
try:
 f.start();f.key('Return','CTRL');f.wait(lambda state:bool(state['attempt']));f.ipc('noesis-window','section','Today');f.wait(lambda state:state['today'].get('continue',{}).get('id')==f.record_id and bool(state['today'].get('records')))
 f.ipc('today-fixture','quiet');f.key('space');f.wait(lambda state:not state['today'].get('records'));assert f.state()['today']['continue']['id']==f.record_id
 f.ipc('today-fixture','quiet');f.key('space');f.wait(lambda state:bool(state['today'].get('records')))
 for width,height in [(1920,1080),(1440,880),(1000,650),(500,650)]:
  for scale in [1,2]:
   f.ipc('today-fixture','scale',str(scale));time.sleep(.2);f.key('Escape');f.ipc('today-fixture','presentation','workspace' if width==1920 else 'normal');time.sleep(.5)
   if width!=1920:subprocess.run(['hyprctl','dispatch','hl.dsp.window.resize({x='+str(width)+',y='+str(height)+',relative=false,window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True)
   time.sleep(1)
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid);x,y=client['at'];w,h=client['size'];name=f'today-{width}-{scale}'
   subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(evidence/(name+'.png'))],check=True,timeout=10);(evidence/(name+'.json')).write_text(json.dumps(f.state(),indent=2))
 warnings=[line for line in (f.home/'qml.log').read_text().splitlines() if ('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line];assert not warnings,warnings
 print('PASS: useful continuation and native Quiet controls preserve context across eight Today layouts. Inspect:',evidence)
finally:f.stop()
