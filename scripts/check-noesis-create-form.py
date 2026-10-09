#!/usr/bin/env python3
"""Creation form debounce recovery and inline validation in a disposable native app."""
import json,subprocess,time
from pathlib import Path
from noesis_native_fixture import Fixture
f=Fixture();evidence=Path('/tmp/noesis-create-form-evidence');evidence.mkdir(exist_ok=True)
shell=f.config/'shell.qml';s=shell.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:fixtureWindow}')
s=s.replace('ShellRoot {','ShellRoot {\n IpcHandler {target:"form-fixture";function begin(kind:string,medium:string):void{fixtureWindow.beginRecord(kind,medium);}function scale(value:real):void{LearningUi.NoesisStyle.interfaceScale=value;LearningUi.NoesisStyle.readingScale=value;}}')
shell.write_text(s)
key=str(f.vault)+':form:create:project::false:'
def draft():return json.loads(f.preferences()['drafts'][key])
def type_text(value):
 mapping={'/':'slash','-':'minus','.':'period',' ':'space','_':'minus'}
 for char in value:f.key(mapping.get(char,char),'SHIFT' if char=='_' else '')
try:
 f.start();f.ipc('form-fixture','begin','project','');f.key('a');f.exit();assert draft()['name']=='a'
 f.start();f.ipc('form-fixture','begin','project','');f.key('b');f.key('Tab');type_text(str(f.home/'missing-repository'));f.key('Return','CTRL')
 f.wait(lambda state:bool(state['error']) and not state['working']);assert 'repository' in f.state()['error'].lower(),f.state()['error']
 time.sleep(.6);assert len(draft()['name'])==2 and draft()['repository']==str(f.home/'missing-repository')
 assert not list((f.vault/'Records/project').glob('*.md'))
 f.ipc('form-fixture','scale','2');subprocess.run(['hyprctl','dispatch','hl.dsp.window.resize({x=500,y=650,relative=false,window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True);time.sleep(.5)
 client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid);x,y=client['at'];w,h=client['size']
 subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(evidence/'invalid-project-500-200.png')],check=True,timeout=10)
 f.exit();assert len(draft()['name'])==2 and draft()['repository']==str(f.home/'missing-repository')
 warnings=[line for line in (f.home/'qml.log').read_text().splitlines() if ('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line];assert not warnings,warnings
 print('PASS: Close flushes creation debounce; reopening retains fields; invalid repository is reported without creating a record; failed form survives Close. Inspect:',evidence)
finally:f.stop()
