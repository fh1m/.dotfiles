#!/usr/bin/env python3
"""Long native course and module expansion captures in a disposable owned vault."""
import json,subprocess,time,sys
from pathlib import Path
from unittest.mock import patch
from noesis_native_fixture import Fixture,REPO
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.models import create
f=Fixture();evidence=Path('/tmp/noesis-course-layout-evidence');evidence.mkdir(exist_ok=True)
with patch('pathlib.Path.home',return_value=f.home):
 course=create(f.vault,'resource','Foundations of learning systems: representation, prediction and independent verification',fields={'source_kind':'course'})
 modules=[]
 for number in range(3):
  module=create(f.vault,'unit',f'Module {number+1}: Mathematical models and careful reasoning',parent_id=course['id'],fields={'unit_kind':'module'});modules.append(module)
  for lesson in range(18):create(f.vault,'unit',f'Lesson {lesson+1}: A long source title with a changed case · বাংলা পাঠ',parent_id=module['id'],fields={'unit_kind':'lecture'})
shell=f.config/'shell.qml';s=shell.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:fixtureWindow}')
s=s.replace('ShellRoot {','ShellRoot {\n IpcHandler {target:"layout-fixture";function presentation(value:string):void{LearningUi.NoesisController.presentationMode=value;LearningUi.NoesisController.savePreferences();}function scale(value:real):void{fixtureWindow.openSettings();LearningUi.NoesisStyle.interfaceScale=value;LearningUi.NoesisStyle.readingScale=value;LearningUi.NoesisController.savePreferences();}}')
shell.write_text(s)
try:
 f.start();f.ipc('noesis-window','section','Learn');f.wait(lambda state:state['rows']>0);f.ipc('noesis-window','select',course['path']);f.wait(lambda state:state['outline_rows']==3);f.key('r','CTRL + SHIFT');f.wait(lambda state:state['outline_focused']);f.key('r','CTRL + SHIFT');f.key('Right');f.wait(lambda state:state['expanded_module_rows']==18)
 for width,height in [(1920,1080),(1440,880),(1000,650)]:
  for scale in [1,1.25,1.5,2]:
   f.ipc('layout-fixture','scale',str(scale));time.sleep(.2);f.key('Escape');f.ipc('layout-fixture','presentation','workspace' if width==1920 else 'normal');time.sleep(.5)
   if width!=1920:subprocess.run(['hyprctl','dispatch','hl.dsp.window.resize({x='+str(width)+',y='+str(height)+',relative=false,window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True)
   time.sleep(1)
   state=f.state();assert state['read_viewport_height']>100,state
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid);x,y=client['at'];w,h=client['size'];name=f'course-{width}-{scale}'
   subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(evidence/(name+'.png'))],check=True,timeout=10);(evidence/(name+'.json')).write_text(json.dumps(state,indent=2))
 f.key('Next','CTRL');f.wait(lambda state:state['read_scroll_fraction']>0);time.sleep(.5)
 client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid);x,y=client['at'];w,h=client['size']
 subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(evidence/'course-1000-2-scrolled.png')],check=True,timeout=10)
 warnings=[line for line in (f.home/'qml.log').read_text().splitlines() if ('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line];assert not warnings,warnings
 print('PASS: twelve long-course size/scale states loaded; keyboard module expansion passes; visual inspection and pointer acceptance still required:',evidence)
finally:f.stop()
