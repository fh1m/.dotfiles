#!/usr/bin/env python3
"""One native learning journey, disposable/agent-authored examples, real Qt input."""
import json, os, signal, subprocess, sys, time, uuid
from pathlib import Path
from unittest.mock import patch
from noesis_native_fixture import Fixture, REPO, installer, QS
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.models import create,relationship
from noesis.index import Index
from noesis.convolution import TEMPLATE

f=Fixture();baseline='--before' in sys.argv;f.env['NOESIS_STUDY_DESK_FIXTURE']='1';f.env['NVIM_APPNAME']='noesis-pilot'
evidence=REPO/'docs/learning-system/assets/convolution';evidence.mkdir(parents=True,exist_ok=True)
fonts=f.home/'fonts.conf';fonts.write_text('<fontconfig><include ignore_missing="yes">/etc/fonts/fonts.conf</include><dir>'+str(Path.home()/'.local/share/fonts')+'</dir></fontconfig>');f.env['FONTCONFIG_FILE']=str(fonts)
with patch('pathlib.Path.home',return_value=f.home):
 concept=create(f.vault,'concept','Convolution · discover the mechanism',
  '## Example investigation · agent-authored validation\nHow can the same local rule smooth a signal or respond to an edge?\n\n## Original question\nWhy does reversing an asymmetric kernel change the result?\n\n## Rich derivation\n$$y[n] = \\sum_j x[n+j-r] k[2r-j]$$\n\nExamples are not owner learning evidence.',fields={'learning_demo':'convolution-1d'})
 prerequisite=create(f.vault,'concept','Finite sums and linear combinations','## Mechanism\nEach output adds weighted samples. Predict what happens when you scale every sample.\n\nAgent-authored example, not demonstrated learner understanding.')
 relationship(f.vault,concept['id'],prerequisite['id'],'prerequisite',role='deep-descent',reason='Explain weighted addition without blocking experimentation.',context=concept['id'])
 source=create(f.vault,'resource','Convolution conventions · example reference','## Centered stencil\nCompare zero padding with repeated edge samples.\n\n## Convention\nConvolution reverses kernel weights. Cross-correlation uses them as written.\n\n## Boundaries\nExplicit radius padding, valid computation, then stride. This example is agent-authored.',fields={'source_kind':'docs','source':'https://numpy.org/doc/stable/reference/generated/numpy.convolve.html'})
 relationship(f.vault,concept['id'],source['id'],'references',reason='Explicit convention reference; learner derivation remains separate.')
 upward=create(f.vault,'resource','Original YOLO · paper v1, June 2015','## Version boundary\nOriginal YOLO (2015) is distinct from YOLO11. Understanding this stencil does not establish detector understanding.\n\nAgent-authored source-link example.',fields={'source_kind':'paper','source':'https://arxiv.org/abs/1506.02640v1','source_revision':'arXiv:1506.02640v1'})
 relationship(f.vault,concept['id'],upward['id'],'references',reason='Optional application; no detector competence claim.')
if baseline:
 for name in subprocess.check_output(['git','ls-tree','--name-only','bf0d8f2:home/.local/share/sensei-learning/ui'],cwd=REPO,text=True).splitlines():
  data=subprocess.check_output(['git','show','bf0d8f2:home/.local/share/sensei-learning/ui/'+name],cwd=REPO)
  (f.home/'.local/share/sensei-learning/ui'/name).write_bytes(installer.render(data,f.home,'zenbook'))
# Wrap the actual Qt window including popup overlay for complete native images.
p=f.home/'.local/share/sensei-learning/ui/NoesisWindow.qml';s=p.read_text().replace(' readonly property var applicationSurface:applicationContent',' readonly property var applicationSurface:applicationContent\n readonly property var reviewSurface:reviewCapture').replace(' ColumnLayout {id:applicationContent;',' Item {id:reviewCapture;anchors.fill:parent\n ColumnLayout {id:applicationContent;').replace(' IpcHandler {target:"noesis-window"',' }\n IpcHandler {target:"noesis-window"');p.write_text(s)
p=f.home/'.local/share/sensei-learning/ui/NoesisWorkspace.qml';p.write_text(p.read_text().replace(' id:root',' id:root\n readonly property var reviewOverlay:Overlay.overlay',1))
p=f.config/'shell.qml';s=p.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:window}').replace('import QtQuick','import QtQuick\nimport QtTest',1)
s=s.replace('ShellRoot {',r'''ShellRoot {
 property bool measuring:false
 property var frames:[]
 FrameAnimation {running:measuring;onTriggered:if(frameTime>0)frames.push(frameTime*1000)}
 TestCase {id:input;parent:window.reviewSurface;visible:false;name:"ConvolutionNative";when:false}
 TestCase {id:deskInput;parent:window.studyDesk.applicationSurface;visible:false;name:"ConvolutionDesk";when:false}
 function find(item,predicate){if(predicate(item))return item;for(let child of item.children||[]){let found=find(child,predicate);if(found)return found;}return null;}
 function named(name){return find(window.contentItem,item=>item.objectName===name);}
 function expose(item){let parent=item.parent;while(parent){if(typeof parent.contentY==="number"&&typeof parent.contentHeight==="number"){for(let n=0;n<70;n++){let point=item.mapToItem(parent,0,0);if(point.y>=0&&point.y+Math.min(item.height,typeof item.getText==="function"?60:item.height)<=parent.height)return true;input.mouseWheel(parent,Math.min(100,parent.width/2),Math.min(100,parent.height/2),0,point.y<0?240:-240);input.wait(25);}return false;}parent=parent.parent;}return true;}
 IpcHandler {target:"convolution-fixture";
  function open(value:string):void{window.workspacePage.openWork(JSON.parse(value));}
  function init():void{window.workspacePage.reviewOverlay.parent=window.reviewSurface;}
  function click(label:string):string{let item=find(window.contentItem,i=>i.visible&&i.enabled&&(i.text===label||i.title===label)&&typeof i.clicked==="function");if(!item)return "missing:"+label;if(!expose(item))return "unreachable:"+label;input.wait(100);input.mouseClick(item,item.width/2,item.height/2);return "clicked";}
  function type(name:string,value:string):string{let item=named(name);if(!item||!item.enabled)return "missing:"+name;if(!expose(item))return "unreachable:"+name;input.mouseClick(item,Math.min(50,item.width/2),Math.min(20,item.height/2));item.forceActiveFocus();input.keyClick(Qt.Key_A,Qt.ControlModifier);for(let c of value){let key=c===" "?Qt.Key_Space:c===","?Qt.Key_Comma:c==="."?Qt.Key_Period:c==="-"?Qt.Key_Minus:/[0-9]/.test(c)?Qt.Key_0+Number(c):Qt.Key_A+c.toUpperCase().charCodeAt(0)-65;input.keyClick(key);}return item.text;}
  function choose(name:string,index:int):string{let item=named(name);if(!item)return "missing:"+name;if(!expose(item))return "unreachable:"+name;input.mouseClick(item,item.width/2,item.height/2);input.wait(80);let list=item.popup.contentItem;list.forceLayout();list.positionViewAtIndex(index,ListView.Contain);input.wait(60);let choice=list.itemAtIndex(index);if(!choice)return "missing choice";input.mouseClick(choice,choice.width/2,choice.height/2);input.wait(80);return item.currentText;}
  function state():string{let p=named("convolution-page");return JSON.stringify({config:p?.configuration(),result:p?.result,implementation:p?.implementation,buildResult:p?.buildResult,stage:p?.stage,protected:p?.protectedReference,prediction:named("convolution-prediction")?.text,notes:p?.notes,selected:window.workspacePage.selected,history:window.workspacePage.history,context:window.workspacePage.learningContext,scroll:named("convolution-play-scroll")?.contentItem.contentY});}
  function back():void{window.workspacePage.back();}
  function capture(path:string):void{window.reviewSurface.grabToImage(r=>r.saveToFile(path));}
  function mode(value:string):void{LearningUi.NoesisController.presentationMode=value;LearningUi.NoesisController.savePreferences();}
  function scale(value:real):void{LearningUi.NoesisStyle.interfaceScale=value;LearningUi.NoesisStyle.readingScale=value;LearningUi.NoesisController.savePreferences();}
  function top():void{let p=named("convolution-play-scroll");if(p)p.contentItem.contentY=0;}
  function chooseDesk(index:int):string{let item=find(window.studyDesk.applicationSurface,i=>i.objectName==="studySurface-left");deskInput.mouseClick(item,item.width/2,item.height/2);deskInput.wait(80);let list=item.popup.contentItem;list.forceLayout();list.positionViewAtIndex(index,ListView.Contain);deskInput.wait(60);let choice=list.itemAtIndex(index);deskInput.mouseClick(choice,choice.width/2,choice.height/2);return item.currentText;}
  function deskClick(label:string):string{let item=find(window.studyDesk.applicationSurface,i=>i.text===label&&i.visible&&i.enabled);if(!item)return "missing";deskInput.mouseClick(item,item.width/2,item.height/2);return "clicked";}
  function keepDesk():string{let item=find(window.studyDesk.applicationSurface,i=>i.text==="Keep here"&&i.visible&&i.enabled);if(!item)return "missing";deskInput.mouseClick(item,item.width/2,item.height/2);return "kept";}
  function framesStart():void{frames=[];measuring=true;}
  function framesStop():string{measuring=false;return JSON.stringify(frames);}
 }
''');p.write_text(s)
reports=[];tools=[];obsidian_process=None;terminal_pid=None

def state():return json.loads(f.ipc('convolution-fixture','state'))
def wait(pred,seconds=12):
 deadline=time.monotonic()+seconds
 while time.monotonic()<deadline:
  if pred(state()) and not f.state()['working']:return state()
  time.sleep(.1)
 raise AssertionError('Journey timeout: '+json.dumps({'state':state(),'application':f.state()})[-4000:]+'\n'+(f.home/'qml.log').read_text()[-1800:])
def click(label):
 deadline=time.monotonic()+6
 while time.monotonic()<deadline:
  result=f.ipc('convolution-fixture','click',label)
  if result=='clicked':time.sleep(.2);return
  time.sleep(.1)
 raise AssertionError(result+' '+json.dumps({'stage':state()['stage'],'protected':state()['protected'],'application':f.state()}))
def type_field(name,value):
 result=f.ipc('convolution-fixture','type',name,value);assert result==value,(name,result)
def open_record(record):
 f.ipc('convolution-fixture','open',json.dumps(dict(record,vault=str(f.vault),vault_id=f.vault_id)));f.wait(lambda s:s['selected']==record['path'] and s['preview_length']>0);time.sleep(.4)
def capture(name):
 time.sleep(.3)
 p=evidence/(name+'.png');p.unlink(missing_ok=True);f.ipc('convolution-fixture','capture',str(p));deadline=time.monotonic()+5
 while not p.exists() and time.monotonic()<deadline:time.sleep(.05)
 if not p.exists():
  f.ipc('convolution-fixture','capture',str(p));deadline=time.monotonic()+5
  while not p.exists() and time.monotonic()<deadline:time.sleep(.05)
 if not p.exists():
  native=f.state();active=json.loads(subprocess.check_output(['hyprctl','activewindow','-j']));assert native['presentation']=='fullscreen' and active['pid']==f.process.pid,(native,active)
  subprocess.run(['grim','-o','eDP-1',str(p)],check=True,capture_output=True)
 assert p.exists(),(name,f.state());reports.append({'image':p.name,'kind':'native Qt window render including popups','conditions':{k:f.state()[k] for k in ('width','height','presentation')},'fixture_only':True})
def desk_capture(name):
 d=json.loads(f.ipc('noesis-study-desk','state'));assert d['visible'] and d['width']==1920 and d['height']==550,d;f.ipc('noesis-study-desk','repaintNow');deadline=time.monotonic()+3
 while time.monotonic()<deadline and json.loads(f.ipc('noesis-study-desk','state'))['frame_serial']<=d['frame_serial']:time.sleep(.05)
 time.sleep(.4)
 layers=json.loads(subprocess.check_output(['hyprctl','layers','-j']))['DP-2']['levels']['3'];assert len(layers)==1 and layers[0]['namespace']=='noesis-study-desk' and layers[0]['pid']==f.process.pid and layers[0]['w']==1920 and layers[0]['h']==550,layers
 p=evidence/(name+'.png');subprocess.run(['grim','-o','DP-2',str(p)],check=True,capture_output=True);reports.append({'image':p.name,'kind':'actual sole fixture ScreenPad compositor pixels','fixture_only':True})
def cli(*args):return subprocess.run([str(f.home/'.local/bin/noesis'),*args,'--vault',str(f.vault)],env=f.env,capture_output=True,text=True,timeout=25)
def reopen():
 f.ipc('noesis','open');f.wait(lambda s:s['visible'] and s['worker']);time.sleep(.5)

try:
 f.start();f.ipc('convolution-fixture','init');
 if not baseline:
  f.ipc('noesis-window','section','Today');f.wait(lambda s:s['section']=='Today' and not s['selected']);click('Explore convolution · example');capture('start-editable-investigation');click('Save');f.wait(lambda s:s['selected'] and s['preview_length']>0);assert state()['selected']['learning_demo']=='convolution-1d'
 open_record(concept);capture('before-normal' if baseline else 'after-normal');f.ipc('convolution-fixture','mode','fullscreen');f.wait(lambda s:s['presentation']=='fullscreen' and s['width']==1920 and not s['mode_pending']);time.sleep(.3);capture('before-study' if baseline else 'after-study')
 if baseline:print('PASS baseline native images',flush=True);sys.exit(0)
 # A deliberately incorrect prediction, saved before any result is shown.
 type_field('convolution-signal','1, 2, 3');type_field('convolution-kernel','2, 1, -1');type_field('convolution-prediction','agent example predicts zero at the left edge')
 assert not state()['result'];f.key('Return','CTRL');wait(lambda s:s['result'].get('observed',{}).get('outputs')==[5,7,1]);capture('prediction-and-calculation')
 observed=state()['result'];assert observed['prediction']=='agent example predicts zero at the left edge' and not observed['learner_achievement']
 # Change the boundary with actual keyboard input; fresh prediction is necessary.
 assert f.ipc('convolution-fixture','choose','convolution-boundary','1')=='Repeat edge sample';type_field('convolution-prediction','agent example predicts repeated samples alter both edges');click('Save prediction & reveal output');wait(lambda s:s['result'].get('observed',{}).get('outputs')==[4,7,7]);capture('repeated-boundary')
 # Build uses ordinary experiment/artifact records and a local Git scaffold.
 click('Build a minimal version');click('Create local implementation & Lab');wait(lambda s:bool(s['implementation'].get('id')));build=state()['implementation'];capture('build-ready')
 click('Run local comparison');wait(lambda s:bool(s['buildResult'].get('observed',{}).get('agrees')));capture('executed-comparison')
 outputs=[state()['buildResult']['observed']]
 directory=Path(build['repository']);assert directory.is_relative_to(f.vault)
 # Genuine terminal/editor handoff. Bare Neovim profile keeps it independent of personal plugins.
 click('Edit convolution.py ↗');f.wait(lambda s:not s['visible'] and not s['working']);deadline=time.monotonic()+10
 while time.monotonic()<deadline:
  clients=json.loads(subprocess.check_output(['hyprctl','clients','-j']));matches=[x for x in clients if x.get('title','').startswith('Noesis · Convolution')]
  if matches:break
  time.sleep(.1)
 assert len(matches)==1,matches;terminal_pid=matches[0]['pid'];children=subprocess.check_output(['pgrep','-P',str(terminal_pid)],text=True).splitlines();assert any('nvim' in Path('/proc/'+pid+'/cmdline').read_bytes().decode(errors='replace') for pid in children);tools.append({'editor':'actual Alacritty/Neovim','repository_verified':True,'fixture_only':True});reopen();wait(lambda s:s['implementation'].get('id')==build['id'])
 # A controlled wrong implementation then a corrected authored revision. Neither is owner achievement.
 (directory/'convolution.py').write_text('# Agent-authored disposable wrong case; not owner work.\ndef convolve(signal,kernel,boundary,stride,convention): return [0 for i in range(0,len(signal),stride)]\n')
 subprocess.run(['git','-C',str(directory),'add','convolution.py'],check=True);subprocess.run(['git','-C',str(directory),'-c','user.name=Noesis agent validation','-c','user.email=validation@invalid.example','commit','-qm','Agent-authored failing validation example'],check=True)
 click('Run local comparison');wait(lambda s:s['buildResult'].get('observed',{}).get('agrees') is False);outputs.append(state()['buildResult']['observed']);capture('failed-implementation')
 (directory/'convolution.py').write_text('# Agent-authored corrected validation; not learner achievement.\n'+TEMPLATE);subprocess.run(['git','-C',str(directory),'add','convolution.py'],check=True);subprocess.run(['git','-C',str(directory),'-c','user.name=Noesis agent validation','-c','user.email=validation@invalid.example','commit','-qm','Agent-authored corrected convolution example'],check=True)
 click('Run local comparison');wait(lambda s:bool(s['buildResult'].get('observed',{}).get('agrees')));outputs.append(state()['buildResult']['observed']);capture('corrected-implementation')
 click('Inspect evidence in Lab');f.wait(lambda s:s['selected']==build['path'] and s['loaded_figures']>0);time.sleep(.5);capture('lab-executed-evidence');assert f.ipc('convolution-fixture','chooseDesk','3')=='Figures & artifacts';assert json.loads(f.ipc('noesis-study-desk','state'))['view']=='figures';desk_capture('screenpad-executed-figure');assert f.ipc('convolution-fixture','keepDesk')=='kept';f.ipc('convolution-fixture','back');f.wait(lambda s:s['selected']==concept['path']);wait(lambda s:s['implementation'].get('id')==build['id']);desk_capture('screenpad-kept-figure');assert f.ipc('convolution-fixture','deskClick','Kept context options')=='clicked';assert f.ipc('convolution-fixture','deskClick','Hide kept context options')=='clicked';capture('return-from-lab')
 # Reference-hidden changed-case attempt, honest failure and an exact evidence-linked question.
 click('Return to the signal');click('Try a changed case without notes');f.wait(lambda s:bool(s['attempt']) and s['reference_hidden']);assert not state()['result'];type_field('convolution-prediction','agent fixture predicts wrong edges before computing');type_field('convolution-reasoning','agent fixture failed to account for kernel reversal');capture('changed-case-protected');desk_capture('screenpad-protected')
 click('Record the changed-case attempt');assert f.ipc('convolution-fixture','choose','attempt-outcome','2')=='failed';assert f.ipc('convolution-fixture','choose','attempt-assistance','1')=='none';capture('honest-failure-dialog');click('Save reconstruction result');f.wait(lambda s:not s['attempt'] and not s['working']);wait(lambda s:any(e.get('event')=='attempt' and e.get('outcome')=='failed' and e.get('assistance')==['none'] for e in s['history']))
 click('Save prediction & reveal output');wait(lambda s:bool(s['result']));capture('changed-case-result')
 click('Investigate the failed attempt');type_field('record-title','agent example why does reversal change the edge');type_field('record-purpose','agent validation question about reversal and boundary assumptions');click('Save');f.wait(lambda s:s['selected']!=concept['path'] and s['section']=='Learn' and s['preview_length']>0);question=state()['selected'];capture('failure-linked-question')
 click('Connect a deeper mechanism');capture('connect-deeper-mechanism');type_field('prerequisite-search','finite sums');time.sleep(.6);click('Finite sums and linear combinations');type_field('prerequisite-reason','agent example explain the weighted sum without blocking');f.ipc('convolution-fixture','choose','prerequisite-role','2');click('Connect prerequisite');f.wait(lambda s:not s['working']);time.sleep(.5);click('Finite sums and linear combinations');f.wait(lambda s:s['selected']==prerequisite['path']);capture('deeper-mechanism');f.ipc('convolution-fixture','back');f.wait(lambda s:s['selected']==question['path']);capture('exact-question-return');f.exit();preferences=f.preferences();draft_key=str(f.vault)+':convolution:'+concept['id'];cached=json.loads(preferences['drafts'][draft_key]);cached['implementation']={};preferences['drafts'][draft_key]=json.dumps(cached);(f.home/'.local/state/sensei-learning/window.json').write_text(json.dumps(preferences));f.env.pop('NOESIS_WINDOW_MODE',None);f.start(resume=True);f.ipc('convolution-fixture','init');f.wait(lambda s:s['selected']==question['path']);capture('question-after-restart');open_record(concept);click('Build a minimal version');click(build['title']);wait(lambda s:s['implementation'].get('id')==build['id']);capture('recovered-investigation')
 # Scaled native states. We inspect 100/150/200%; fullscreen remains the primary product.
 for scale in (1.5,2):
  f.ipc('convolution-fixture','scale',str(scale));time.sleep(.4);f.ipc('convolution-fixture','top');capture('study-'+str(scale));desk_capture('screenpad-'+str(scale))
  if scale==2:click('Show reasoning');capture('study-2-reasoning');click('Show the experiment')
 f.ipc('convolution-fixture','scale','1');time.sleep(.4)
 # Optional isolated real Obsidian run, never using the personal profile or vault.
 registry=f.home/'.config/obsidian';registry.mkdir(parents=True,exist_ok=True);registry_id=uuid.uuid4().hex[:16];(registry/'obsidian.json').write_text(json.dumps({'cli':True,'vaults':{registry_id:{'path':str(f.vault),'ts':int(time.time()*1000),'open':True}}}));(f.vault/'.obsidian').mkdir(exist_ok=True);(f.vault/'.obsidian/app.json').write_text(json.dumps({'showInlineTitle':False}));(f.vault/'.obsidian/core-plugins.json').write_text('[]');(registry/'user-flags.conf').write_text('--user-data-dir='+str(registry)+'\n')
 obslog=(f.home/'obsidian.log').open('w');obsidian_process=subprocess.Popen(['obsidian'],env=f.env,stdout=obslog,stderr=obslog,start_new_session=True);time.sleep(4)
 click('Open rich derivation in Obsidian ↗');f.wait(lambda s:not s['working'],seconds=25)
 if f.state()['error']:raise AssertionError('Real isolated Obsidian handoff: '+f.state()['error'])
 probe=subprocess.run(['obsidian','vault='+registry_id,'file','info=path'],env=f.env,capture_output=True,text=True,timeout=12);assert probe.returncode==0 and concept['path'] in probe.stdout,(probe.stdout,probe.stderr)
 tools.append({'obsidian':'actual isolated native vault','exact_concept_path_verified':True,'fixture_only':True});reopen();wait(lambda s:s['implementation'].get('id')==build['id']);capture('after-obsidian-return')
 f.ipc('convolution-fixture','framesStart');time.sleep(3);frames=sorted(json.loads(f.ipc('convolution-fixture','framesStop')));performance={'frame_p95_ms':round(frames[int(.95*(len(frames)-1))],3),'samples':len(frames),'note':'Three-second instrumented native frame interval; not input latency or sustained learning.'}
 with patch('pathlib.Path.home',return_value=f.home):
  ix=Index(f.vault)
  try:
   ix.reconcile();q=ix.record(question['id'])['props'];assessment=ix.record(q['evidence_refs'][0]['record_id'])['props'];assert q['parent_ref']['record_id']==concept['id'] and assessment['outcome']=='failed' and assessment['assistance']==['none'];assert not any(e.get('event')=='capability-decision' for e in ix.timeline(concept['id']));assert len([e for e in ix.timeline(build['id']) if e['event']=='comparison'])==3
  finally:ix.close()
 warnings=[l for l in (f.home/'qml.log').read_text().splitlines() if ('WARN' in l or 'ERROR' in l) and 'Could not register app ID' not in l];assert not warnings,warnings
 (evidence/'executed-outputs.json').write_text(json.dumps({'authorship':'Agent-authored disposable acceptance; not owner understanding','outputs':outputs},indent=2)+'\n');(evidence/'acceptance.json').write_text(json.dumps({'commit_under_test':'working tree','fixture_only':True,'captures':reports,'tools':tools,'performance':performance,'assertions':['prediction before computed reveal','boundary manipulation','actual implementation match and mismatch','Git revision and checksum','Lab output and actual figure','protected changed case and honest failure','native linked question and deep prerequisite return','restart ownership and draft recovery','real editor and isolated Obsidian return','no automatic mastery']},indent=2)+'\n');print('PASS complete convolution native journey:',evidence,flush=True)
finally:
 f.stop()
 if obsidian_process and obsidian_process.poll() is None:os.killpg(obsidian_process.pid,signal.SIGTERM);obsidian_process.wait(timeout=10)
 if terminal_pid and Path('/proc/'+str(terminal_pid)).exists():
  # Close only the window launched from this fixture, after verifying its process owns the fixture working directory.
  children=subprocess.run(['pgrep','-P',str(terminal_pid)],capture_output=True,text=True).stdout.splitlines()
  if any(Path('/proc/'+pid+'/cwd').resolve().is_relative_to(f.vault) for pid in children):os.kill(terminal_pid,signal.SIGTERM)
