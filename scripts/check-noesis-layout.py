#!/usr/bin/env python3
"""Native Practice scale/layout capture; visual inspection remains required."""
import json,subprocess,time
from pathlib import Path
from noesis_native_fixture import Fixture
f=Fixture();evidence=Path('/tmp/noesis-layout-evidence');evidence.mkdir(exist_ok=True)
shell=f.config/'shell.qml';s=shell.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:fixtureWindow}')
s=s.replace('ShellRoot {','ShellRoot {\n IpcHandler {target:"layout-fixture";function scale(value:real):void{fixtureWindow.openSettings();LearningUi.NoesisStyle.interfaceScale=value;LearningUi.NoesisStyle.readingScale=value;LearningUi.NoesisController.savePreferences();}function settings():void{fixtureWindow.openSettings();}}')
shell.write_text(s)
try:
 f.start();f.key('Return','CTRL');f.wait(lambda v:bool(v['attempt']))
 for width,height in [(1440,880),(1000,650),(500,650)]:
  for scale in [1,1.25,1.5,2]:
   f.ipc('layout-fixture','scale',str(scale));time.sleep(.2);f.key('Escape');subprocess.run(['hyprctl','dispatch','hl.dsp.window.resize({x='+str(width)+',y='+str(height)+',relative=false,window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True);time.sleep(1)
   state=f.state()
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid)
   x,y=client['at'];w,h=client['size'];name=f'practice-{width}-{scale}'
   subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(evidence/(name+'.png'))],check=True,timeout=10)
   (evidence/(name+'.json')).write_text(json.dumps(state,indent=2))
   assert state['statement_height']>40 and state['reasoning_viewport_height']>40,state
 f.key('Next','CTRL');f.wait(lambda state:state['practice_scroll_fraction']>0);time.sleep(.3)
 client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid);x,y=client['at'];w,h=client['size']
 subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(evidence/'practice-500-2-scrolled.png')],check=True,timeout=10)
 before=f.state()['practice_viewport_height'];f.key('f','CTRL + SHIFT');time.sleep(.5);assert f.state()['practice_viewport_height']>before;f.key('Escape');time.sleep(.2)
 f.ipc('layout-fixture','settings');time.sleep(.3);client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid);x,y=client['at'];w,h=client['size']
 subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(evidence/'settings-200.png')],check=True,timeout=10)
 warnings=[line for line in (f.home/'qml.log').read_text().splitlines() if ('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line]
 assert not warnings,warnings
 print('PASS: twelve native Practice size/scale states, including narrow tiled width, loaded with scrollable statement/reasoning viewport; inspect images:',evidence)
finally:f.stop()
