#!/usr/bin/env python3
"""Empty-vault native self-service acceptance. Records are created by real controls."""
import json,os,time,subprocess,signal,uuid,sys
from pathlib import Path
from noesis_native_fixture import Fixture,REPO
f=Fixture(expected_practice_rows=0)
(f.vault/'problem.md').unlink()
f.env['NOESIS_STUDY_DESK_FIXTURE']='1'
# Wrap the actual Qt window including popup overlay for complete native images.
p=f.home/'.local/share/sensei-learning/ui/NoesisWindow.qml';s=p.read_text().replace(' readonly property var applicationSurface:applicationContent',' readonly property var applicationSurface:applicationContent\n readonly property var reviewSurface:reviewCapture').replace(' ColumnLayout {id:applicationContent;',' Item {id:reviewCapture;anchors.fill:parent\n ColumnLayout {id:applicationContent;').replace(' IpcHandler {target:"noesis-window"',' }\n IpcHandler {target:"noesis-window"');p.write_text(s)
p=f.home/'.local/share/sensei-learning/ui/NoesisWorkspace.qml';p.write_text(p.read_text().replace(' id:root',' id:root\n readonly property var reviewOverlay:Overlay.overlay',1))
p=f.config/'shell.qml';s=p.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:window}').replace('import QtQuick','import QtQuick\nimport QtTest',1)
s=s.replace('ShellRoot {',r'''ShellRoot {
 property bool measuring:false
 property var frames:[]
 FrameAnimation {running:measuring;onTriggered:if(frameTime>0)frames.push(frameTime*1000)}
 TestCase {id:input;parent:window.reviewSurface;visible:false;name:"LearningThreadNative";when:false}
 TestCase {id:deskInput;parent:window.studyDesk.applicationSurface;visible:false;name:"LearningThreadDesk";when:false}
 function find(item,predicate){if(predicate(item))return item;for(let child of item.children||[]){let found=find(child,predicate);if(found)return found;}return null;}
 function named(name){return find(window.contentItem,item=>item.objectName===name);}
 function expose(item){let parent=item.parent;while(parent){if(typeof parent.contentY==="number"&&typeof parent.contentHeight==="number"){for(let n=0;n<70;n++){let point=item.mapToItem(parent,0,0);if(point.y>=0&&point.y+Math.min(item.height,typeof item.getText==="function"?60:item.height)<=parent.height)return true;input.mouseWheel(parent,Math.min(100,parent.width/2),Math.min(100,parent.height/2),0,point.y<0?240:-240);input.wait(25);}return false;}parent=parent.parent;}return true;}
 IpcHandler {target:"journey-fixture";
  function open(value:string):void{window.workspacePage.openWork(JSON.parse(value));}
  function init():void{window.workspacePage.reviewOverlay.parent=window.reviewSurface;}
  function click(label:string):string{let predicate=i=>i.visible&&i.enabled&&(i.text===label||i.title===label)&&typeof i.clicked==="function";let item=find(window.contentItem,predicate);if(!item)return "missing:"+label;if(!expose(item))return "unreachable:"+label;input.waitForPolish(item.parent,2000);input.wait(200);item=find(window.contentItem,predicate);if(!item)return "pending:"+label;input.mouseClick(item,item.width/2,item.height/2);input.wait(100);return "clicked";}
  function type(name:string,value:string):string{let item=named(name);if(!item||!item.enabled)return "missing:"+name;if(!expose(item))return "unreachable:"+name;input.mouseClick(item,Math.min(50,item.width/2),Math.min(20,item.height/2));item.forceActiveFocus();input.keyClick(Qt.Key_A,Qt.ControlModifier);for(let c of value){let key=c===" "?Qt.Key_Space:c==="/"?Qt.Key_Slash:c===","?Qt.Key_Comma:c==="."?Qt.Key_Period:c==="-"?Qt.Key_Minus:/[0-9]/.test(c)?Qt.Key_0+Number(c):Qt.Key_A+c.toUpperCase().charCodeAt(0)-65;input.keyClick(key,/[A-Z]/.test(c)?Qt.ShiftModifier:Qt.NoModifier);}return item.text;}
  function focusField(name:string):string{let item=named(name);if(!item||!expose(item))return "missing";input.mouseClick(item,Math.min(50,item.width/2),Math.min(20,item.height/2));item.forceActiveFocus();input.keyClick(Qt.Key_A,Qt.ControlModifier);return "focused";}
  function pasteField():void{input.keyClick(Qt.Key_V,Qt.ControlModifier);input.wait(100);}
  function field(name:string):string{let item=named(name);return item?item.text:"missing";}
  function choose(name:string,index:int):string{let item=named(name);if(!item)return "missing:"+name;if(!expose(item))return "unreachable:"+name;input.mouseClick(item,item.width/2,item.height/2);input.wait(80);let list=item.popup.contentItem;list.forceLayout();list.positionViewAtIndex(index,ListView.Contain);input.wait(60);let choice=list.itemAtIndex(index);if(!choice)return "missing choice";input.mouseClick(choice,choice.width/2,choice.height/2);input.wait(80);return item.currentText;}
  function state():string{return JSON.stringify({selected:window.workspacePage.selected,history:window.workspacePage.history,frontier:window.workspacePage.frontier,relations:window.workspacePage.relations,attempt:window.workspacePage.activeAttempt,protected:window.workspacePage.referenceHidden,notes:window.workspacePage.evidence.text,actions:window.workspacePage.contextActions(),error:LearningUi.NoesisController.error,operation_error:LearningUi.NoesisController.operationError,modal:window.workspacePage.modalOpen});}
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

clipboard=subprocess.run(["wl-paste","--no-newline"],capture_output=True)
obsidian_process=None;terminal_pid=None;source_library=None
socket=f.home/'editor.sock';nvim=f.home/'.config/noesis-pilot';nvim.mkdir(parents=True);(nvim/'init.lua').write_text('vim.fn.serverstart('+json.dumps(str(socket))+')\n');f.env['NVIM_APPNAME']='noesis-pilot'
directory=f.home/'duplicate-code';directory.mkdir();(directory/'duplicate.py').write_text('def first_duplicate(values):\n    raise NotImplementedError("Reconstruct your approach")\n');(directory/'attention.py').write_text('def scaled_attention(query, key, value):\n    raise NotImplementedError("Derive the scaling convention first")\n');subprocess.run(['git','init','-q',str(directory)],check=True);subprocess.run(['git','-C',str(directory),'add','.'],check=True);subprocess.run(['git','-C',str(directory),'-c','user.name=Noesis agent validation','-c','user.email=validation@invalid.example','commit','-qm','Example skeleton'],check=True)
assets=REPO/'docs/learning-system/assets/self-service';assets.mkdir(parents=True,exist_ok=True)
def click(text):
 result=f.ipc('journey-fixture','click',text)
 assert result=='clicked',(text,result)
def type(name,value):
 if name!='learning-origin':value=value.lower()
 f.client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid and c['title'].startswith('Noesis'))
 subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True)
 assert f.ipc('journey-fixture','focusField',name)=='focused',name
 subprocess.run(['wl-copy'],input=value,text=True,check=True)
 time.sleep(.1);f.ipc('journey-fixture','pasteField');time.sleep(.15)
 result=f.ipc('journey-fixture','field',name)
 assert result==value,(name,result,value)
def capture(name):
 path=assets/(name+'.png');path.unlink(missing_ok=True);f.ipc('journey-fixture','capture',str(path))
 deadline=time.monotonic()+5
 while not path.exists() and time.monotonic()<deadline:time.sleep(.1)
 assert path.exists()
try:
 from noesis_self_service_zotero import SourceLibrary
 source_library=SourceLibrary(f.home,port=23129)
 # Test-owned endpoint only: never reuse the owner's running Zotero on 23119.
 adapter=f.home/'.local/share/sensei-learning/noesis/zotero.py';adapter.write_text(adapter.read_text().replace('127.0.0.1:23119','127.0.0.1:23129'))
 f.start(resume=True);f.ipc('journey-fixture','init');time.sleep(1)
 if '--zotero-only' not in sys.argv:
  capture('empty-today');click('Help');time.sleep(.4);capture('user-guide');click('Close guide')
  click('Start learning');capture('start-learning')
  type('learning-origin','https://www.youtube.com/watch?v=J7DzL2_Na80')
  type('learning-title','Example lecture - agent validation')
  click('Continue');capture('confirm-source');click('Save')
  f.wait(lambda s:bool(s['selected']));time.sleep(1);capture('video-workspace')
  click('Set a reading place');type('reading-place','12 minutes');click('Save reading place');time.sleep(.5)
  type('reading-reasoning','Agent validation note - not owner achievement');click('Save study note');time.sleep(.5)
  registry=f.home/'.config/obsidian';registry.mkdir(parents=True,exist_ok=True);registry_id=uuid.uuid4().hex[:16];(registry/'obsidian.json').write_text(json.dumps({'cli':True,'vaults':{registry_id:{'path':str(f.vault),'ts':int(time.time()*1000),'open':True}}}));(f.vault/'.obsidian').mkdir(exist_ok=True);(f.vault/'.obsidian/app.json').write_text(json.dumps({'showInlineTitle':False}));(f.vault/'.obsidian/core-plugins.json').write_text('[]');(registry/'user-flags.conf').write_text('--user-data-dir='+str(registry)+'\n');obslog=(f.home/'obsidian.log').open('w');obsidian_process=subprocess.Popen(['obsidian'],env=f.env,stdout=obslog,stderr=obslog,start_new_session=True);time.sleep(4)
  video=json.loads(f.ipc('journey-fixture','state'))['selected'];click('Edit complete note in Obsidian ↗');f.wait(lambda s:not s['working'],seconds=25);assert not f.state()['error'];probe=subprocess.run(['obsidian','vault='+registry_id,'file','info=path'],env=f.env,capture_output=True,text=True,timeout=12);assert probe.returncode==0 and video['path'] in probe.stdout,(probe.stdout,probe.stderr);subprocess.run([str(f.home/'.local/bin/noesis'),'window'],env=f.env,check=True,capture_output=True);f.wait(lambda s:s['visible'] and s['worker']);time.sleep(.6)
  f.key('n','CTRL');time.sleep(.3)
  type('learning-origin','https://docs.python.org/3/library/heapq.html')
  type('learning-title','Priority queues - agent example')
  assert f.ipc('journey-fixture','choose','learning-format','6')=='Documentation'
  click('Continue');click('Save');time.sleep(1);capture('documentation-workspace')
  click('Ask a source-linked question');type('record-title','Why are heap operations logarithmic - agent question');click('Save');time.sleep(1);capture('linked-question')
  f.key('n','CTRL');time.sleep(.3);type('learning-title','Binary heap mechanism - agent example');assert f.ipc('journey-fixture','choose','learning-format','8')=='Concept or topic';click('Continue');click('Save');time.sleep(1)
  click('Previous activity');time.sleep(.6);question=json.loads(f.ipc('journey-fixture','state'))['selected'];assert question['type']=='question';click('Connect a deeper mechanism');type('prerequisite-search','binary heap');time.sleep(.8);click('binary heap mechanism - agent example');type('prerequisite-reason','Explain logarithmic work without blocking exploration');assert f.ipc('journey-fixture','choose','prerequisite-role','2')=='Optional deeper study';click('Connect prerequisite');time.sleep(.7);capture('prerequisite-question')
  click('binary heap mechanism - agent example');time.sleep(.6);click('Previous activity');time.sleep(.6);capture('return-to-question');assert json.loads(f.ipc('journey-fixture','state'))['selected']['id']==question['id']
  f.key('n','CTRL');time.sleep(.3);type('learning-origin','https://www.youtube.com/watch?v=J7DzL2_Na80');type('learning-title','Lecture sequence - agent example');assert f.ipc('journey-fixture','choose','learning-format','1')=='Playlist';click('Continue');click('Save');time.sleep(1)
  click('Course options ▾');click('Add lesson or chapter');type('record-title','First lecture - agent example');click('Save');time.sleep(.7);click('← Course outline');time.sleep(.7)
  click('Course options ▾');click('Add lesson or chapter');type('record-title','Second lecture - agent example');click('Save');time.sleep(.7);click('← Course outline');time.sleep(.7);click('Arrange');click('second lecture - agent example');click('↑');time.sleep(.6);click('Done');capture('ordered-playlist')
  f.key('n','CTRL');time.sleep(.4);type('learning-origin','');type('learning-title','First repeated value - agent problem');assert f.ipc('journey-fixture','choose','learning-format','9')=='Practice problem';click('Continue');type('record-purpose','Agent validation example. Return the first value encountered twice in an ordered integer list. Return no value when every item is unique. Predict empty and zero cases without a reference.');click('Save');time.sleep(.8)
  problem=json.loads(f.ipc('journey-fixture','state'))['selected'];click('Start independent attempt');time.sleep(.5);assert f.state()['reference_hidden'];type('practice-reasoning','agent validation prediction. a set can track earlier values. zero must not be mistaken for no result');click('Outcome & assistance');time.sleep(.4);assert f.ipc('journey-fixture','choose','attempt-outcome','3')=='partial';assert f.ipc('journey-fixture','choose','attempt-assistance','5')=='agent';click('Done');time.sleep(.3);click('Record attempt outcome');time.sleep(.7);capture('practice-outcome')
  click('History & next steps');click('Connect implementation');type('record-title','Repeated value implementation - agent example');type('record-repository',str(directory));type('record-code-file','duplicate.py');click('Save');time.sleep(.8);click('Open code ↗');f.wait(lambda s:not s['working'],seconds=20)
  deadline=time.monotonic()+10
  while not socket.exists() and time.monotonic()<deadline:time.sleep(.1)
  assert socket.exists()
  code='def first_duplicate(values):\n    seen = set()\n    for value in values:\n        if value in seen:\n            return value\n        seen.add(value)\n    return None\n';authored=f.home/'authored.py';authored.write_text(code);subprocess.run(['nvim','--server',str(socket),'--remote-send','<Esc>:lua vim.api.nvim_buf_set_lines(0,0,-1,false,vim.fn.readfile('+json.dumps(str(authored))+'))<CR>:write<CR>'],env=f.env,check=True,capture_output=True);time.sleep(.4)
  checker=directory/'check.py';checker.write_text('from duplicate import first_duplicate\nimport json\ncases=[([],None),([0,0],0),([1,2,1,2],1),([1,2,3],None),([-1,2,-1],-1)]\nresults=[dict(values=v,expected=e,observed=first_duplicate(v)) for v,e in cases]\nassert all(r["expected"]==r["observed"] for r in results)\nopen("observed.json","w").write(json.dumps(results))\n');subprocess.run(['nvim','--server',str(socket),'--remote-send','<Esc>:cd '+str(directory)+'<CR>:!python check.py<CR>'],env=f.env,check=True,capture_output=True)
  deadline=time.monotonic()+10
  while not (directory/'observed.json').exists() and time.monotonic()<deadline:time.sleep(.1)
  assert (directory/'observed.json').exists();(assets/'executed-outputs.json').write_text((directory/'observed.json').read_text());subprocess.run(['git','-C',str(directory),'add','duplicate.py','check.py'],check=True);subprocess.run(['git','-C',str(directory),'-c','user.name=Noesis agent validation','-c','user.email=validation@invalid.example','commit','-qm','Agent validation implementation and checked cases'],check=True);code_revision=subprocess.check_output(['git','-C',str(directory),'rev-parse','HEAD'],text=True).strip()
  subprocess.run([str(f.home/'.local/bin/noesis'),'window'],env=f.env,check=True,capture_output=True);f.wait(lambda s:s['visible'] and s['worker']);time.sleep(.6);click('Begin a run');time.sleep(.5);capture('create-experiment');type('record-title','Repeated value cases - agent execution');type('record-purpose','Expect empty unique and zero cases to match explicit expected values');click('Save');time.sleep(.8);click('Record comparison');type('comparison-predicted','Five expected cases match');type('comparison-observed','Five actual cases match. empty unique zero negative repeated values');type('comparison-conditions','Agent authored execution. Python local. Revision '+code_revision);type('comparison-conclusion','This verifies these examples. It is not owner understanding or a proof');click('Save comparison');time.sleep(.7);click('Connect artifact');type('record-title','Actual duplicate test outputs - agent validation');type('record-source',str(directory/'observed.json'));type('record-revision',code_revision);click('Save');time.sleep(.7);capture('executed-artifact')
 f.key('n','CTRL');time.sleep(.4);click('Choose from Zotero');time.sleep(1);click('Attention Is All You Need - agent source fixture');
 deadline=time.monotonic()+20
 while json.loads(f.ipc('journey-fixture','state'))['selected'].get('zotero_server_id')!=source_library.server and time.monotonic()<deadline:time.sleep(.1)
 capture('zotero-paper');assert json.loads(f.ipc('journey-fixture','state'))['selected'].get('zotero_server_id')==source_library.server,json.loads(f.ipc('journey-fixture','state'))
 type('source-reading-place','section 2');click('Save place');time.sleep(.5);click('Research actions');click('Ask a question');type('record-title','Why does scaled attention use a square root - agent question');click('Save');time.sleep(.7);click('Learning options');click('Connect implementation');type('record-title','Attention reconstruction skeleton - agent example');type('record-repository',str(directory));type('record-code-file','attention.py');click('Save');time.sleep(.7);capture('paper-linked-implementation')
 subprocess.run([str(f.home/'.local/bin/noesis'),'window','--start'],env=f.env,check=True,capture_output=True);time.sleep(.5);capture('launcher-start-route');click('Cancel')
 f.key('n','CTRL');time.sleep(.3);type('learning-origin',str(f.home/'unavailable.pdf'));type('learning-title','Unavailable PDF - agent recovery example');click('Continue');click('Save');time.sleep(.7);capture('unavailable-source')
 f.exit();f.start(resume=True);f.ipc('journey-fixture','init');time.sleep(1);capture('restart')
 result={'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip(),'dirty':True,'empty_vault':True,'record_creation':'native mouse and key interactions only','fixture':str(f.home),'passed':['Today start','URL manual title','video resource','Ctrl N start','documentation resource','saved reading place','saved study note','linked source question','concept creation','optional prerequisite','descent and exact question return','playlist units created and reordered','isolated Obsidian exact note handoff','protected practice attempt and agent assistance','editor exact code handoff','five actual code cases','comparison and original output artifact','native Zotero source selection and import','owned paper reading place and question','paper implementation connection','launcher Start IPC route','unavailable local source preserved','restart'],'limitations':['PDF attachment/annotation handoff not tested in this source-only fixture','owner usability not tested'],'learner_achievement':False}
 if '--zotero-only' in sys.argv:result['passed']=result['passed'][17:];result['scope']='Zotero source-only debug'
 (assets/('zotero-source-only.json' if '--zotero-only' in sys.argv else 'acceptance.json')).write_text(json.dumps(result,indent=2)+'\n')
 print(json.dumps(result))
finally:
 f.stop()
 if source_library:source_library.stop()
 if clipboard.returncode==0:subprocess.run(["wl-copy"],input=clipboard.stdout,check=True)
 else:subprocess.run(["wl-copy","--clear"],check=True)
 if obsidian_process and obsidian_process.poll() is None:os.killpg(obsidian_process.pid,signal.SIGTERM);obsidian_process.wait(timeout=10)
 if socket.exists():subprocess.run(['nvim','--server',str(socket),'--remote-send','<Esc>:qa!<CR>'],env=f.env,capture_output=True)
