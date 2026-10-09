#!/usr/bin/env python3
"""Native recovery-sprint review. Synthetic owned data; Qt pointer/key events.

Retains window-content renders, never captures unrelated personal desktop layers.
Before mode renders the same content with committed feee017 QML.
"""
import sys,json,time,subprocess,os
from pathlib import Path
from unittest.mock import patch
from noesis_native_fixture import Fixture,REPO,installer,QS
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.models import create
f=Fixture();fontconfig=f.home/'fontconfig-review.conf';fontconfig.write_text('<fontconfig><include ignore_missing="yes">/etc/fonts/fonts.conf</include><dir>'+str(Path.home()/'.local/share/fonts')+'</dir></fontconfig>');f.env['FONTCONFIG_FILE']=str(fontconfig)
phase='before' if '--before' in sys.argv else 'after'
evidence=REPO/'docs/learning-system/assets/recovery-sprint';evidence.mkdir(exist_ok=True)
if phase=='before':
 prefix='home/.local/share/sensei-learning/ui/'
 for filename in subprocess.check_output(['git','ls-tree','--name-only','feee017:'+prefix.rstrip('/')],cwd=REPO,text=True).splitlines():
  (f.home/'.local/share/sensei-learning/ui'/filename).write_bytes(installer.render(subprocess.check_output(['git','show','feee017:'+prefix+filename],cwd=REPO),f.home,'zenbook'))
 window=f.home/'.local/share/sensei-learning/ui/NoesisWindow.qml';window.write_text(window.read_text().replace(' id:win',' id:win\n readonly property var applicationSurface:applicationContent',1))
(f.vault/'problem.md').write_text('---\nid: '+f.record_id+'\nnoesis_schema: 2\ntype: task\ntitle: When does a system have one solution?\n---\n## Problem statement\n\nConsider A = [[1, 2], [2, 4]] and b = [3, 6]. Explain geometrically why the system has many solutions.\n\nChanged case: replace b by [3, 7]. Predict what changes before elimination. Derive both cases and state your assumptions.\n\nবাংলা: আপনার যুক্তি লিখুন।\n')
with patch('pathlib.Path.home',return_value=f.home):
 course=create(f.vault,'resource','Linear Algebra · From systems to transformations',body='## Learning objective\nExplain how linear transformations connect equations, geometry and approximation.',fields={'source_kind':'course','source':'https://ocw.mit.edu/'})
 modules=[];lessons=[]
 for module_title in ['Systems of linear equations','Vector spaces and linear maps','Orthogonality and least squares']:
  m=create(f.vault,'unit',module_title,parent_id=course['id'],fields={'unit_kind':'module'});modules.append(m)
  for name in ['A geometric view','Derivation and changed case','Independent assessment']:
   lesson=create(f.vault,'unit',name,parent_id=m['id'],body='## Objective\nConnect elimination to the geometry of intersecting planes. Explain the changed case before computing it.\n\n## Source\nUse the course lecture and compare your derivation with the reading. This is a disposable review fixture.',fields={'unit_kind':'lecture','source':'https://ocw.mit.edu/'})
   lessons.append(lesson)
 paper=create(f.vault,'resource','You Only Look Once: Unified, Real-Time Object Detection',body='## Reading objective\nReconstruct how a single prediction grid connects localization to class confidence.\n\n## Questions and mathematical gaps\nWhich assumptions fail when objects are small or overlap?\n\n## Reconstruction\nWrite an independent explanation before opening the implementation.',fields={'source_kind':'paper','source':'https://arxiv.org/abs/1506.02640'})
 lab=create(f.vault,'experiment','Angular-rate calibration · expected versus observed',body='## Setup\nDisposable engineering fixture; no learner achievement is recorded.\n\n## Interpretation\nA plot or successful process alone cannot verify the hypothesis.',fields={'hypothesis':'A stationary sensor should report zero angular rate after calibration.'})
shell=f.config/'shell.qml';q=shell.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:fixtureWindow}')
q=q.replace('import QtQuick','import QtQuick\nimport QtTest',1)
q=q.replace('ShellRoot {',r'''ShellRoot {
 TestCase {id:nativeInput;parent:fixtureWindow.applicationSurface;visible:false;name:"NoesisStudioReview";when:false}
 function findItem(item,label){if(item.visible&&item.enabled&&(item.text===label||item.title===label||item.placeholderText===label)&&typeof item.clicked==="function")return item;for(let child of item.children||[]){let found=findItem(child,label);if(found)return found;}return null;}
 function findSurface(item){if(item.visible&&["Problem statement","Your reasoning"].includes(item.currentText))return item;for(let child of item.children||[]){let found=findSurface(child);if(found)return found;}return null;}
 function findEditor(item){if(item.visible&&item.enabled&&item.placeholderText&&item.placeholderText.indexOf("Explain the idea")===0)return item;for(let child of item.children||[]){let found=findEditor(child);if(found)return found;}return null;}
 IpcHandler {target:"studio-fixture";
  function capture(path:string):void{fixtureWindow.applicationSurface.grabToImage(result=>result.saveToFile(path));}
  function click(label:string):string{let item=findItem(fixtureWindow.applicationSurface,label);if(!item)return "missing:"+label;nativeInput.mouseClick(item,item.width/2,item.height/2);return "clicked";}
  function lessonNote():string{let item=findEditor(fixtureWindow.applicationSurface);if(!item)return "missing editor";nativeInput.mouseClick(item,30,30);nativeInput.keyClick(Qt.Key_A);nativeInput.keyClick(Qt.Key_B);return item.text;}
  function surface(statement:bool):string{let item=findSurface(fixtureWindow.applicationSurface);if(!item)return "missing";nativeInput.mouseClick(item,item.width/2,item.height/2);nativeInput.keyClick(statement?Qt.Key_Home:Qt.Key_End);nativeInput.keyClick(Qt.Key_Return);return item.currentText;}
  function scrollThinking():void{nativeInput.keyClick(Qt.Key_PageDown,Qt.ControlModifier);}
  function scale(value:real):void{LearningUi.NoesisStyle.interfaceScale=value;LearningUi.NoesisStyle.readingScale=value;LearningUi.NoesisController.savePreferences();}
  function mode(value:string):void{LearningUi.NoesisController.presentationMode=value;LearningUi.NoesisController.savePreferences();}
 }
''')
shell.write_text(q)
reports=[]
def capture(name):
 target=evidence/(name+'.png')
 if target.exists():target.unlink()
 f.ipc('studio-fixture','capture',str(target));deadline=time.monotonic()+5
 while not target.exists() and time.monotonic()<deadline:time.sleep(.05)
 assert target.exists();time.sleep(.3)
 state=f.state();reports.append({'image':name+'.png','state':{key:state[key] for key in ['width','height','qt_device_pixel_ratio','interface_scale','reading_scale','presentation','section'] if key in state}})
def click(label):assert f.ipc('studio-fixture','click',label)=='clicked',label
def resize(width,height,scale):
 f.ipc('studio-fixture','scale',str(scale));f.ipc('studio-fixture','mode','workspace' if width==1920 else 'normal');time.sleep(.6)
 if width!=1920:subprocess.run(['hyprctl','dispatch','hl.dsp.window.resize({x='+str(round(width*f.state()["compositor_scale"]))+',y='+str(round(height*f.state()["compositor_scale"]))+',relative=false,window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True)
 time.sleep(.5)
 state=f.state()
 if width!=1920:assert abs(state['width']-width)<5 and abs(state['height']-height)<5,state
try:
 f.start();f.ipc('noesis-window','section','Learn');f.wait(lambda s:s['rows']>0);f.ipc('noesis-window','select',course['path']);f.wait(lambda s:s['outline_rows']==3);time.sleep(.5)
 capture('course-'+phase)
 if phase=='before':
  click('Expand');f.wait(lambda s:s['expanded_module_rows']==3);click('A geometric view');f.wait(lambda s:s['selected']==lessons[0]['path'] and s['preview_length']>0);time.sleep(.3);capture('lesson-before')
 if phase=='after':
  click('Continue learning');f.wait(lambda s:s['expanded_module_rows']==3)
  click('A geometric view');f.wait(lambda s:s['selected']==lessons[0]['path'] and s['preview_length']>0);time.sleep(.5)
  capture('lesson-after')
  note=f.ipc('studio-fixture','lessonNote');assert note=='ab',note;time.sleep(.7);f.wait(lambda s:s['draft_length']==2)
  click('← Course outline');f.wait(lambda s:s['selected']==course['path'] and s['outline_rows']==3)
  click('A geometric view');f.wait(lambda s:s['selected']==lessons[0]['path'] and s['draft_length']==2)
  f.ipc('noesis','hide');f.wait(lambda s:not s['worker'] and not s['watch']);f.ipc('noesis','open');f.wait(lambda s:s['visible'] and s['selected']==lessons[0]['path'] and s['draft_length']==2)
  f.ipc('noesis','exit');f.process.wait(timeout=8);saved=f.preferences();assert saved['drafts'][str(f.vault)+':'+lessons[0]['id']]=='ab';assert saved['context']['course']['id']==course['id'];f.log=(f.home/'qml.log').open('a');f.process=subprocess.Popen([QS,'-p',str(f.config),'--no-color'],env=f.env,stdout=f.log,stderr=f.log,start_new_session=True);f.wait(lambda s:s['selected']==lessons[0]['path'] and s['draft_length']==2 and s['course_id']==course['id']);f.wait(lambda s:s['expanded_module_rows']==3)
  time.sleep(.5)
  for activity in ['lesson','course']:
   if activity=='course':click('← Course outline');f.wait(lambda s:s['selected']==course['path'])
   for width,height in [(1920,1080),(1440,880),(1000,650),(500,650)]:
    for scale in [1,1.25,1.5,2]:resize(width,height,scale);capture(f'{activity}-{width}-{scale}')
   resize(1440,880,1)
  print('PASS: native pointer module/lesson navigation; keyboard notes; outline return; Hide/reopen; durable draft after Close',flush=True)
 f.ipc('noesis-window','section','Practice');f.wait(lambda s:s['rows']>0);f.ipc('noesis-window','select','problem.md');f.wait(lambda s:s['preview_length']>0)
 click('Start independent attempt' if phase=='after' else 'Start attempt');f.wait(lambda s:bool(s['attempt']))
 time.sleep(.4);capture('practice-'+phase)
 if phase=='after':
  for width,height in [(1920,1080),(1440,880),(1000,650),(500,650)]:
   for scale in [1,1.25,1.5,2]:
    f.ipc('studio-fixture','scale',str(scale));f.ipc('studio-fixture','mode','workspace' if width==1920 else 'normal');time.sleep(.6)
    if width!=1920:subprocess.run(['hyprctl','dispatch','hl.dsp.window.resize({x='+str(round(width*f.state()["compositor_scale"]))+',y='+str(round(height*f.state()["compositor_scale"]))+',relative=false,window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True)
    time.sleep(.5);capture(f'practice-{width}-{scale}')
  assert f.ipc('studio-fixture','surface','true')=='Problem statement';f.wait(lambda s:not s['practice_thinking']);time.sleep(.3);capture('practice-compact-statement')
  assert f.ipc('studio-fixture','surface','false')=='Your reasoning';f.wait(lambda s:s['practice_thinking']);time.sleep(.3);capture('practice-compact-reasoning');f.ipc('studio-fixture','scrollThinking');time.sleep(.3);capture('practice-compact-actions')
  f.ipc('studio-fixture','scale','1');f.ipc('studio-fixture','mode','normal');time.sleep(.7);subprocess.run(['hyprctl','dispatch','hl.dsp.window.resize({x=1440,y=880,relative=false,window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True);time.sleep(.5)
  for section,record,name in [('Research',paper,'research-current'),('Lab',lab,'lab-current')]:
   f.ipc('noesis-window','section',section);f.wait(lambda s:s['rows']>0);f.ipc('noesis-window','select',record['path']);f.wait(lambda s:s['preview_length']>0);time.sleep(.5);capture(name)
  f.ipc('noesis-window','section','Today');f.wait(lambda s:not s['selected'] and not s['working']);time.sleep(.5);capture('today-current')
 warnings=[line for line in (f.home/'qml.log').read_text().splitlines() if ('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line];assert not warnings,warnings
 (evidence/('capture-'+phase+'.json')).write_text(json.dumps({'capture':'Native Qt Quick window-content render; excludes other desktop layers','fixture_only':True,'baseline':'feee017' if phase=='before' else None,'captures':reports},indent=2))
 print('PASS: native renders retained:',evidence,flush=True)
finally:f.stop()
