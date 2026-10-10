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
f=Fixture(expected_practice_rows=4);fontconfig=f.home/'fontconfig-review.conf';fontconfig.write_text('<fontconfig><include ignore_missing="yes">/etc/fonts/fonts.conf</include><dir>'+str(Path.home()/'.local/share/fonts')+'</dir></fontconfig>');f.env['FONTCONFIG_FILE']=str(fontconfig)
phase='before' if '--before' in sys.argv else 'after'
sizes=[(1920,1080),(1440,880),(1000,650),(500,650)] if '--matrix' in sys.argv else [(1920,1080)]
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
 syllabus=[('Systems of linear equations',['A geometric view','Elimination and changed cases','Independent assessment: inconsistent systems']),('Vector spaces and linear maps',['Linear independence and bases','The matrix of a transformation','Independent assessment: a changed basis']),('Orthogonality and least squares',['Projection onto a subspace','Least squares and residuals','Independent assessment: noisy measurements'])]
 for module_title,lesson_titles in syllabus:
  m=create(f.vault,'unit',module_title,parent_id=course['id'],fields={'unit_kind':'module'});modules.append(m)
  for name in lesson_titles:
   assessment=name.startswith('Independent assessment')
   lesson=create(f.vault,'task' if assessment else 'unit',name,parent_id=m['id'],body='## Objective\nConnect elimination to the geometry of intersecting planes. Explain the changed case before computing it.\n\n## Source\nUse the course lecture and compare your derivation with the reading. This is a disposable review fixture.',fields={} if assessment else {'unit_kind':'lecture','source':'https://ocw.mit.edu/'})
   lessons.append(lesson)
 paper=create(f.vault,'resource','You Only Look Once: Unified, Real-Time Object Detection',body='## Reading objective\nReconstruct how a single prediction grid connects localization to class confidence.\n\n## Questions and mathematical gaps\nWhich assumptions fail when objects are small or overlap?\n\n## Reconstruction\nWrite an independent explanation before opening the implementation.',fields={'source_kind':'paper','source':'https://arxiv.org/abs/1506.02640'})
 lab=create(f.vault,'experiment','Angular-rate calibration · expected versus observed',body='## Setup\nDisposable engineering fixture; no learner achievement is recorded.\n\n## Interpretation\nA plot or successful process alone cannot verify the hypothesis.',fields={'hypothesis':'A stationary sensor should report zero angular rate after calibration.'})
 if '--dual' in sys.argv:
  import matplotlib;matplotlib.use('Agg')
  import matplotlib.pyplot as plt
  figure=f.vault/'illustrative-calibration.png';plot,axis=plt.subplots(figsize=(8,3));axis.plot([0,1,2,3],[.12,.125,.118,.121],label='Synthetic illustration');axis.axhline(0,color='gray',linestyle='--',label='Zero-rate hypothesis');axis.set(xlabel='Time (s)',ylabel='Angular rate (rad/s)',title='Disposable illustration · not instrument data');axis.legend();plot.tight_layout();plot.savefig(figure,dpi=140);plt.close(plot)
  create(f.vault,'artifact','Illustrative rate curve · synthetic fixture',parent_id=lab['id'],fields={'location':str(figure)})
  create(f.vault,'artifact','Unavailable calibration output',parent_id=lab['id'],fields={'location':str(f.vault/'not-produced.csv')})

shell=f.config/'shell.qml';q=shell.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:fixtureWindow}')
q=q.replace('import QtQuick','import QtQuick\nimport QtTest',1)
q=q.replace('ShellRoot {',r'''ShellRoot {
 property bool measureFrames:false
 property var frameSamples:[]
 FrameAnimation {running:measureFrames;onTriggered:if(frameTime>0)frameSamples.push(frameTime*1000)}
 TestCase {id:deskInput;parent:fixtureWindow.studyDesk.applicationSurface;visible:false;name:"NoesisDeskReview";when:false}
 function findNamed(item,name){if(item.objectName===name)return item;for(let child of item.children||[]){let found=findNamed(child,name);if(found)return found;}return null;}
 TestCase {id:nativeInput;parent:fixtureWindow.applicationSurface;visible:false;name:"NoesisStudioReview";when:false}
 function findItem(item,label){if(item.visible&&item.enabled&&(item.text===label||item.title===label||item.placeholderText===label)&&typeof item.clicked==="function")return item;for(let child of item.children||[]){let found=findItem(child,label);if(found)return found;}return null;}
 function findSurface(item){if(item.visible&&["Problem statement","Your reasoning"].includes(item.currentText))return item;for(let child of item.children||[]){let found=findSurface(child);if(found)return found;}return null;}
 function findEditor(item){if(item.visible&&item.enabled&&item.placeholderText&&item.placeholderText.indexOf("Explain the idea")===0)return item;for(let child of item.children||[]){let found=findEditor(child);if(found)return found;}return null;}
 IpcHandler {target:"studio-fixture";
  function framesStart():void{frameSamples=[];measureFrames=true;}
  function framesStop():string{measureFrames=false;return JSON.stringify(frameSamples);}
  function chooseDesk(side:string,index:int):string{let item=findNamed(fixtureWindow.studyDesk.applicationSurface,"studySurface-"+side);if(!item)return "missing selector";if(!item.popup.visible)deskInput.mouseClick(item,item.width/2,item.height/2);deskInput.wait(60);let list=item.popup.contentItem;list.forceLayout();list.positionViewAtIndex(index,ListView.Contain);deskInput.wait(60);let choice=list.itemAtIndex(index);if(!choice)return "missing popup choice visible="+item.popup.visible+" count="+list.count+" y="+list.contentY;deskInput.mouseClick(choice,choice.width/2,choice.height/2);deskInput.wait(60);return item.currentText;}
  function notesDesk():string{let item=findNamed(fixtureWindow.studyDesk.applicationSurface,"studyNotes-left");if(!item)return "missing notes";deskInput.mouseClick(item,40,40);deskInput.keyClick(Qt.Key_X);deskInput.keyClick(Qt.Key_Y);return item.text;}

  function clickDesk(label:string):string{let item=findItem(fixtureWindow.studyDesk.applicationSurface,label);if(!item)return "missing:"+label;deskInput.mouseClick(item,item.width/2,item.height/2);return "clicked";}
  function capture(path:string):void{fixtureWindow.applicationSurface.grabToImage(result=>result.saveToFile(path));}
  function click(label:string):string{let item=findItem(fixtureWindow.applicationSurface,label);if(!item)return "missing:"+label;nativeInput.mouseClick(item,item.width/2,item.height/2);return "clicked";}
  function lessonNote():string{let item=findEditor(fixtureWindow.applicationSurface);if(!item)return "missing editor";nativeInput.mouseClick(item,30,30);nativeInput.keyClick(Qt.Key_A);nativeInput.keyClick(Qt.Key_B);return item.text;}
  function surface(statement:bool):string{let item=findSurface(fixtureWindow.applicationSurface);if(!item)return "missing";nativeInput.mouseClick(item,item.width/2,item.height/2);nativeInput.keyClick(statement?Qt.Key_Home:Qt.Key_End);nativeInput.keyClick(Qt.Key_Return);return item.currentText;}
  function scrollThinking():void{nativeInput.keyClick(Qt.Key_PageDown,Qt.ControlModifier);}
  function geometry(width:int,height:int):void{LearningUi.NoesisController.windowWidth=width;LearningUi.NoesisController.windowHeight=height;fixtureWindow.applyPresentation();}
  function scale(value:real):void{LearningUi.NoesisStyle.interfaceScale=value;LearningUi.NoesisStyle.readingScale=value;LearningUi.NoesisController.savePreferences();}
  function mode(value:string):void{LearningUi.NoesisController.presentationMode=value;LearningUi.NoesisController.savePreferences();}
 }
''')
shell.write_text(q)
reports=[]
if "--dual" in sys.argv:f.env["NOESIS_STUDY_DESK_FIXTURE"]="1"
def capture(name):
 target=evidence/(name+'.png')
 if target.exists():target.unlink()
 f.ipc('studio-fixture','capture',str(target));deadline=time.monotonic()+5
 while not target.exists() and time.monotonic()<deadline:time.sleep(.05)
 assert target.exists();time.sleep(.3)
 state=f.state();reports.append({'image':name+'.png','state':{key:state[key] for key in ['width','height','qt_device_pixel_ratio','interface_scale','reading_scale','presentation','section'] if key in state}})
def desk_capture(name):
 if "--dual" not in sys.argv:return
 state=json.loads(f.ipc('noesis-study-desk','state'));labels={'source':'Problem statement' if f.state()['section']=='Practice' else 'Source','context':'Context','notes':'Notes & reasoning','figures':'Figures & artifacts','reference':'Reference (protected)' if f.state()['reference_hidden'] else 'Reference preview'};assert state['left_label']==labels[state['view']] and state['right_label']==labels[state['right_view']],state;assert state['visible'] and state['width']==1920 and state['height']==550,state
 frame=int(f.ipc('noesis-study-desk','repaintNow'))
 try:f.wait(lambda s:json.loads(f.ipc('noesis-study-desk','state'))['frame_serial']>frame)
 except AssertionError:
  layers=json.loads(subprocess.check_output(['hyprctl','layers','-j']))['DP-2']['levels']['3']
  if len(layers)==1 and layers[0]['pid']==f.process.pid and layers[0]['namespace']=='noesis-study-desk':
   subprocess.run(['grim','-o','DP-2',str(evidence/(name+'-frame-failure.png'))],check=True,capture_output=True)
  print('ScreenPad frame diagnostics:',f.ipc('noesis-study-desk','state'),layers,flush=True)
  raise
 time.sleep(.1)
 target=evidence/(name+'.png')
 if target.exists():target.unlink()
 # Capture exactly what the ScreenPad displays. Refuse any other overlay so
 # private Wrayth popups or desktop content cannot enter retained evidence.
 deadline=time.monotonic()+10
 while True:
  layers=json.loads(subprocess.check_output(['hyprctl','layers','-j']))['DP-2']['levels']['3']
  if len(layers)==1 or time.monotonic()>=deadline:break
  time.sleep(.2)
 assert len(layers)==1 and layers[0]['namespace']=='noesis-study-desk' and layers[0]['pid']==f.process.pid and layers[0]['w']==1920 and layers[0]['h']==550,layers
 subprocess.run(['grim','-o','DP-2',str(target)],check=True,capture_output=True)
 assert target.exists()
 reports.append({'image':name+'.png','state':{k:state[k] for k in ['width','height','view','screen','source_blocks']}})
def click(label):assert f.ipc('studio-fixture','click',label)=='clicked',label
def resize(width,height,scale):
 f.ipc('studio-fixture','scale',str(scale))
 if width!=1920:f.ipc('studio-fixture','geometry',str(width),str(height))
 f.ipc('studio-fixture','mode','fullscreen' if width==1920 else 'normal')
 try:f.wait(lambda s:not s['mode_pending'] and abs(s['width']-width)<5 and abs(s['height']-height)<5)
 except AssertionError:
  print('MODE FAILURE',width,height,scale,{k:f.state().get(k) for k in ['width','height','error','presentation','mode_pending']},flush=True);raise
 time.sleep(.3)
 time.sleep(.5)
 state=f.state()
 assert abs(state['width']-width)<5 and abs(state['height']-height)<5,state
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
   for width,height in sizes:
    for scale in [1,1.25,1.5,2]:
     resize(width,height,scale);capture(f'{activity}-{width}-{scale}')
     if width==1920 and scale==1:
      capture(activity+'-study');desk_capture(activity+'-second-display')
   resize(1440,880,1)
  print('PASS: native pointer module/lesson navigation; keyboard notes; outline return; Hide/reopen; durable draft after Close',flush=True)
 f.ipc('noesis-window','section','Practice');f.wait(lambda s:s['rows']>0);f.ipc('noesis-window','select','problem.md');f.wait(lambda s:s['preview_length']>0)
 click('Start independent attempt' if phase=='after' else 'Start attempt');f.wait(lambda s:bool(s['attempt']))
 time.sleep(.4);capture('practice-'+phase)
 if phase=='after':
  for width,height in sizes:
   for scale in [1,1.25,1.5,2]:
    f.ipc('studio-fixture','scale',str(scale));f.ipc('studio-fixture','mode','fullscreen' if width==1920 else 'normal');f.wait(lambda s:not s['mode_pending']);time.sleep(.3)
    time.sleep(.5);capture(f'practice-{width}-{scale}')
    if width==1920 and scale in [1,2]:
     capture('practice-study' if scale==1 else 'practice-study-200');desk_capture('practice-second-display' if scale==1 else 'practice-second-display-200')
     if '--dual' in sys.argv:
      choice=f.ipc('studio-fixture','chooseDesk','left','1');assert choice=='Context',choice;time.sleep(.2);desk_capture('practice-second-context' if scale==1 else 'practice-second-context-200');choice=f.ipc('studio-fixture','chooseDesk','left','0');assert choice=='Problem statement',choice
  if '--dual' in sys.argv:
   resize(1920,1080,1)
   choice=f.ipc('studio-fixture','chooseDesk','left','2');assert choice=='Notes & reasoning',choice
   note=f.ipc('studio-fixture','notesDesk');assert note=='xy',note
   f.wait(lambda s:s['draft_length']==2);time.sleep(.7);desk_capture('practice-second-notes')
   f.wait(lambda s:f.preferences().get('drafts',{}).get(str(f.vault)+':'+f.record_id)=='xy')
   attempt=f.state()['attempt'];f.ipc('noesis','hide');f.wait(lambda s:not s['worker']);f.ipc('noesis','open');f.wait(lambda s:s['worker'] and s['draft_length']==2 and s['attempt']==attempt)
   assert f.ipc('studio-fixture','chooseDesk','left','3')=='Figures & artifacts';desk_capture('practice-second-artifacts-empty')
   choice=f.ipc('studio-fixture','chooseDesk','left','4');assert choice=='Reference (protected)',choice
   assert json.loads(f.ipc('noesis-study-desk','state'))['source_blocks']==0 and f.state()['reference_hidden'];desk_capture('practice-second-reference-protected')
   choice=f.ipc('studio-fixture','chooseDesk','left','0');assert choice=='Problem statement',choice
   assert f.ipc('studio-fixture','clickDesk','Use ScreenPad for tools')=='clicked';assert not json.loads(f.ipc('noesis-study-desk','state'))['visible']
   click('Show Study desk');assert json.loads(f.ipc('noesis-study-desk','state'))['visible']
  resize(500,650,2)
  assert f.ipc('studio-fixture','surface','true')=='Problem statement';f.wait(lambda s:not s['practice_thinking']);time.sleep(.3);capture('practice-compact-statement')
  assert f.ipc('studio-fixture','surface','false')=='Your reasoning';f.wait(lambda s:s['practice_thinking']);time.sleep(.3);capture('practice-compact-reasoning');f.ipc('studio-fixture','scrollThinking');time.sleep(.3);capture('practice-compact-actions')
  f.ipc('studio-fixture','scale','1');f.ipc('studio-fixture','mode','normal');time.sleep(.7);subprocess.run(['hyprctl','dispatch','hl.dsp.window.resize({x=1440,y=880,relative=false,window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True);time.sleep(.5)
  for section,record,name in [('Research',paper,'research-current'),('Lab',lab,'lab-current')]:
   f.ipc('noesis-window','section',section);f.wait(lambda s:s['rows']>0);f.ipc('noesis-window','select',record['path']);f.wait(lambda s:s['preview_length']>0);time.sleep(.5);capture(name);resize(1920,1080,1);capture(name.replace('-current','-study'))
   if '--dual' in sys.argv and section=='Lab':
    f.wait(lambda s:s['loaded_figures']==1)
    assert f.ipc('studio-fixture','chooseDesk','left','3')=='Figures & artifacts'
    assert f.ipc('studio-fixture','chooseDesk','right','2')=='Notes & reasoning'
    time.sleep(.5);desk_capture('lab-second-figures-notes')

  f.ipc('noesis-window','section','Today');f.wait(lambda s:not s['selected'] and not s['working']);time.sleep(.5);capture('today-current');resize(1920,1080,1);capture('today-study')
 f.ipc('studio-fixture','framesStart');time.sleep(3)
 frames=sorted(json.loads(f.ipc('studio-fixture','framesStop')))
 memory={}
 for line in Path(f'/proc/{f.process.pid}/smaps_rollup').read_text().splitlines():
  if line.startswith(('Rss:','Pss:')):memory[line.split(':')[0]+'_KiB']=int(line.split()[1])
 (evidence/'render-performance.json').write_text(json.dumps({'instrumented_animation_frame_p95_ms':round(frames[int(.95*(len(frames)-1))],2),'samples':len(frames),'memory':memory,'note':'Three-second fixture instrumentation; not physical input latency or sustained-session proof.'},indent=2)+'\n')
 warnings=[line for line in (f.home/'qml.log').read_text().splitlines() if ('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line];assert not warnings,warnings
 (evidence/('capture-'+phase+'.json')).write_text(json.dumps({'capture':'Native Qt Quick main-window render; second-display compositor capture requires the sole full-display overlay to be the disposable fixture','fixture_only':True,'baseline':'feee017' if phase=='before' else None,'captures':reports},indent=2))
 print('PASS: native renders retained:',evidence,flush=True)
finally:f.stop()
