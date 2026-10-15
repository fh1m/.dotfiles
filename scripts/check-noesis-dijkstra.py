#!/usr/bin/env python3
"""Complete shared Dijkstra journey; synthetic agent-authored validation, never owner achievement."""
import hashlib, json, os, signal, subprocess, sys, time, uuid, shutil
from pathlib import Path
from unittest.mock import patch
from noesis_native_fixture import Fixture, REPO
from noesis_authored_examples import DIJKSTRA
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.models import create
from noesis.index import Index
f=Fixture(expected_practice_rows=2);f.env['NOESIS_STUDY_DESK_FIXTURE']='1';f.env['NVIM_APPNAME']='noesis-pilot'
evidence=REPO/'docs/learning-system/assets/dijkstra';evidence.mkdir(parents=True,exist_ok=True)
fonts=f.home/'fonts.conf';fonts.write_text('<fontconfig><include ignore_missing="yes">/etc/fonts/fonts.conf</include><dir>'+str(Path.home()/'.local/share/fonts')+'</dir></fontconfig>');f.env['FONTCONFIG_FILE']=str(fonts)
with patch('pathlib.Path.home',return_value=f.home):
 problem=create(f.vault,'task','Shortest paths - discovery is not finalization',
  '## Problem statement\n\nAgent-authored example - not owner learning evidence. A directed graph has edges A to B costing 10, A to C costing 1, and C to B costing 1.\n\n### Question\nPredict the shortest distances from A. When can a distance become permanent?\n\n### Constraints\nNonnegative integer weights. Allow zero weights and isolated vertices. Explain your first approach before consulting a solution.',fields={'source_kind':'problem-statement'})
 invariant=create(f.vault,'concept','Greedy invariant and nonnegative edges',
  '## Example mechanism - agent-authored reference\nThe smallest unsettled tentative distance can become permanent because every remaining path extension has nonnegative cost. Discovery alone is insufficient.\n\n## Counterexample\nS to A costs 2; S to B costs 5; B to A costs -4. A greedy permanent distance of 2 would be wrong: the path through B costs 1.\n\n## Still to reconstruct\nProve the cut argument. Explain stale heap entries, zero edges and unreachable vertices. Reading this is assistance, not independent evidence.')
 directory=f.vault/'shortest-paths';shutil.copytree(REPO/'home/.local/share/sensei-learning/examples/dijkstra',directory)
 (directory/'.gitignore').write_text('__pycache__/\nobservations*.json\n')
 subprocess.run(['git','init','-q',str(directory)],check=True)
 def commit(message):
  subprocess.run(['git','-C',str(directory),'add','.'],check=True);subprocess.run(['git','-C',str(directory),'-c','user.name=Noesis agent validation','-c','user.email=validation@invalid.example','commit','-qm',message],check=True)
 commit('Example skeleton and independent expected cases')
 socket=f.home/'editor.sock';nvim=f.home/'.config/noesis-pilot';nvim.mkdir(parents=True);(nvim/'init.lua').write_text('vim.fn.serverstart('+json.dumps(str(socket))+')\n')
baseline='--before' in sys.argv
if baseline:
 for name in subprocess.check_output(['git','ls-tree','--name-only','dcfcb01:home/.local/share/sensei-learning/ui'],cwd=REPO,text=True).splitlines():
  from noesis_native_fixture import installer
  data=subprocess.check_output(['git','show','dcfcb01:home/.local/share/sensei-learning/ui/'+name],cwd=REPO)
  (f.home/'.local/share/sensei-learning/ui'/name).write_bytes(installer.render(data,f.home,'zenbook'))
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
  function type(name:string,value:string):string{let item=named(name);if(!item||!item.enabled)return "missing:"+name;if(!expose(item))return "unreachable:"+name;input.mouseClick(item,Math.min(50,item.width/2),Math.min(20,item.height/2));item.forceActiveFocus();input.keyClick(Qt.Key_A,Qt.ControlModifier);for(let c of value){let key=c===" "?Qt.Key_Space:c==="/"?Qt.Key_Slash:c===","?Qt.Key_Comma:c==="."?Qt.Key_Period:c==="-"?Qt.Key_Minus:/[0-9]/.test(c)?Qt.Key_0+Number(c):Qt.Key_A+c.toUpperCase().charCodeAt(0)-65;input.keyClick(key);}return item.text;}
  function choose(name:string,index:int):string{let item=named(name);if(!item)return "missing:"+name;if(!expose(item))return "unreachable:"+name;input.mouseClick(item,item.width/2,item.height/2);input.wait(80);let list=item.popup.contentItem;list.forceLayout();list.positionViewAtIndex(index,ListView.Contain);input.wait(60);let choice=list.itemAtIndex(index);if(!choice)return "missing choice";input.mouseClick(choice,choice.width/2,choice.height/2);input.wait(80);return item.currentText;}
  function state():string{return JSON.stringify({selected:window.workspacePage.selected,history:window.workspacePage.history,frontier:window.workspacePage.frontier,relations:window.workspacePage.relations,attempt:window.workspacePage.activeAttempt,protected:window.workspacePage.referenceHidden,notes:window.workspacePage.evidence.text,actions:window.workspacePage.contextActions(),modal:window.workspacePage.modalOpen});}
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
reports=[];outputs=[];terminal_pid=None;obsidian_process=None
source_revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip()

def state():return json.loads(f.ipc('journey-fixture','state'))
def wait(pred,seconds=15):
 deadline=time.monotonic()+seconds
 while time.monotonic()<deadline:
  s=state()
  if pred(s) and not f.state()['working']:return s
  time.sleep(.1)
 raise AssertionError('Journey timeout '+json.dumps(s)[-2500:]+' '+json.dumps(f.state())+' '+(f.home/'qml.log').read_text()[-1500:])
def click(label):
 deadline=time.monotonic()+6
 while time.monotonic()<deadline:
  result=f.ipc('journey-fixture','click',label)
  if result=='clicked':time.sleep(.25);return
  time.sleep(.1)
 raise AssertionError(result+' '+json.dumps(state())[-1800:])
def type_field(name,value):
 deadline=time.monotonic()+5
 while time.monotonic()<deadline:
  result=f.ipc('journey-fixture','type',name,value)
  if result==value:return
  time.sleep(.15)
 raise AssertionError((name,result,value))
def open_record(record):
 f.ipc('journey-fixture','open',json.dumps(dict(record,vault=str(f.vault),vault_id=f.vault_id)));f.wait(lambda s:s['selected']==record['path'] and s['preview_length']>0);time.sleep(.4)
def actions():
 f.key('period','CTRL');time.sleep(.3)
 if not state()['modal']:
  click('History & next steps' if state()['selected']['type'] in ('task','problem') else 'More')
def capture(name):
 time.sleep(.3);p=evidence/(name+'.png');p.unlink(missing_ok=True);f.ipc('journey-fixture','capture',str(p));deadline=time.monotonic()+5
 while not p.exists() and time.monotonic()<deadline:time.sleep(.05)
 if not p.exists():
  f.ipc('journey-fixture','capture',str(p));deadline=time.monotonic()+5
  while not p.exists() and time.monotonic()<deadline:time.sleep(.05)
 if not p.exists():
  active=json.loads(subprocess.check_output(['hyprctl','activewindow','-j']));assert f.state()['presentation']=='fullscreen' and active['pid']==f.process.pid,(f.state(),active)
  subprocess.run(['grim','-o','eDP-1',str(p)],check=True,capture_output=True)
 assert p.exists(),name
 reports.append({'image':p.name,'kind':'actual native Qt application and popup pixels','width':f.state()['width'],'height':f.state()['height'],'fixture_only':True})
def desk_capture(name):
 d=json.loads(f.ipc('noesis-study-desk','state'));assert d['visible'],d;f.ipc('noesis-study-desk','repaintNow');time.sleep(.6)
 layers=json.loads(subprocess.check_output(['hyprctl','layers','-j']))['DP-2']['levels']['3'];assert len(layers)==1 and layers[0]['pid']==f.process.pid,layers
 subprocess.run(['grim','-o','DP-2',str(evidence/(name+'.png'))],capture_output=True,check=True);reports.append({'image':name+'.png','kind':'actual ScreenPad compositor','fixture_only':True})
def reopen():
 f.ipc('noesis','open');f.wait(lambda s:s['visible'] and s['worker']);time.sleep(.4)
def editor_send(keys):
 subprocess.run(['nvim','--server',str(socket),'--remote-send',keys],env=f.env,check=True,capture_output=True)
def execute(label,extra=''):
 target=directory/('observations-'+label+'.json');target.unlink(missing_ok=True)
 editor_send('<Esc>:cd '+str(directory)+'<CR>:!python check_cases.py --output '+target.name+extra+'<CR>')
 deadline=time.monotonic()+12
 while not target.exists() and time.monotonic()<deadline:time.sleep(.1)
 assert target.exists(),label
 report=json.loads(target.read_text());outputs.append({'stage':label,'report':report});time.sleep(.4);editor_send('<CR>');return report

def record_attempt(outcome,assistance):
 click('Outcome & assistance');assert f.ipc('journey-fixture','choose','attempt-outcome',str(['unknown','incomplete','failed','partial','succeeded'].index(outcome)))==outcome
 assert f.ipc('journey-fixture','choose','attempt-assistance',str(['unknown','none','hint','reference','collaborator','agent'].index(assistance)))==assistance
 click('Done');click('Record attempt outcome');wait(lambda s:not s['attempt'] and any(e['event']=='attempt' for e in s['history']))

try:
 f.start();f.ipc('journey-fixture','init');open_record(problem);capture('before-normal' if baseline else 'after-normal');f.ipc('journey-fixture','mode','fullscreen');f.wait(lambda s:s['presentation']=='fullscreen' and s['width']==1920 and not s['mode_pending'])
 if baseline:
  capture('before-study');print('PASS original native baseline',flush=True);sys.exit(0)
 capture('after-study')
 click('Start independent attempt');wait(lambda s:bool(s['attempt']) and s['protected']);type_field('practice-reasoning','agent example predicts b is 10 because first discovery is final');capture('first-protected-attempt');f.ipc('journey-fixture','scale','2');time.sleep(.4);capture('protected-attempt-200');f.ipc('journey-fixture','scale','1');time.sleep(.3);desk_capture('statement-beside-reasoning');record_attempt('failed','none')
 click('Investigate the missing mechanism');type_field('record-title','why is discovery not finalization');type_field('record-purpose','agent example failure preserved. what makes the minimum tentative distance permanent');capture('failure-to-question');click('Save');wait(lambda s:s['selected'].get('type')=='question' and bool(s['frontier'].get('origin')));question=state()['selected'];type_field('investigation-reasoning','agent example. i need a cut argument and a negative edge counterexample');capture('invariant-question')
 click('Connect a deeper mechanism');type_field('prerequisite-search','greedy invariant');time.sleep(.8);click(invariant['title']);type_field('prerequisite-reason','explain the nonnegative cut argument without blocking exploration');assert f.ipc('journey-fixture','choose','prerequisite-role','2')=='Optional deeper study';click('Connect prerequisite');wait(lambda s:any(r.get('role')=='deep-descent' for r in s['relations']))
 click(invariant['title']);f.wait(lambda s:s['selected']==invariant['path']);capture('optional-invariant-descent');f.ipc('journey-fixture','back');wait(lambda s:s['selected']['id']==question['id'] and 'cut argument' in s['notes'])
 # Ordinary project creation through the existing command/action menu, no lesson backend.
 actions();click('Connect implementation');type_field('record-title','shortest paths reconstruction example');type_field('record-purpose','agent authored validation from a skeleton. not owner understanding');type_field('record-repository',str(directory));type_field('record-code-file','dijkstra.py');click('Save');wait(lambda s:s['selected'].get('type')=='project');project=state()['selected'];capture('implementation-skeleton-context')
 click('Open code ↗');f.wait(lambda s:not s['visible'] and not s['working']);deadline=time.monotonic()+10
 while not socket.exists() and time.monotonic()<deadline:time.sleep(.1)
 assert socket.exists(),(f.home/'qml.log').read_text()[-2000:]
 clients=json.loads(subprocess.check_output(['hyprctl','clients','-j']));matches=[c for c in clients if c.get('title','').startswith('Noesis · shortest paths reconstruction example')];assert len(matches)==1,matches;terminal_pid=matches[0]['pid'];editor_send('<Esc>:edit dijkstra.py<CR>');assert 'NotImplementedError' in (directory/'dijkstra.py').read_text();assert not execute('skeleton')['all_agree']
 wrong="""# Agent-authored discovery-finalization mistake, not owner work.
import math
def shortest_paths(vertices, edges, source):
    if any(w < 0 for _, _, w in edges): raise ValueError("nonnegative required")
    d = dict.fromkeys(vertices, math.inf); d[source] = 0; queue = [source]
    while queue:
        u = queue.pop(0)
        for a, b, w in edges:
            if a == u and d[b] == math.inf:
                d[b] = d[a] + w; queue.append(b)
    return d
"""
 def author_in_editor(code):
  authored=f.home/'authored.py';authored.write_text(code)
  editor_send('<Esc>:lua vim.api.nvim_buf_set_lines(0,0,-1,false,vim.fn.readfile('+json.dumps(str(authored))+'))<CR>:write<CR>');time.sleep(.3)
 author_in_editor(wrong);commit('Agent-authored discovery-finalization mistake');wrong_report=execute('wrong');assert not wrong_report['all_agree'] and wrong_report['cases'][0]['observed']['B']==10
 author_in_editor(DIJKSTRA);commit('Agent-authored corrected nonnegative shortest paths');correct=execute('corrected');assert correct['all_agree'] and len(correct['cases'])==8
 reopen();wait(lambda s:s['selected']['id']==project['id']);click('Begin a run');type_field('record-title','counterexamples and corrected implementation');type_field('record-purpose','agent example predicts the corrected algorithm matches independent expected cases');click('Save');wait(lambda s:s['selected'].get('type')=='experiment');experiment=state()['selected'];assert experiment['code_entrypoint']=='dijkstra.py';assert experiment['code_snapshot']['commit']==correct['code_revision']
 click('Record comparison');type_field('comparison-observed','agent executed 8 cases. all matched after correcting first discovery finalization');type_field('comparison-conditions',correct['code_revision']);type_field('comparison-conclusion','software test only. proof and unfamiliar transfer still need reasoning');capture('reported-execution-comparison');f.ipc('journey-fixture','scale','2');time.sleep(.4);capture('comparison-200');f.ipc('journey-fixture','scale','1');time.sleep(.3);click('Save comparison');wait(lambda s:any(e['event']=='comparison' for e in s['history']));
 click('Connect artifact');type_field('record-title','executed shortest paths output');type_field('record-source',str(directory/'observations-corrected.json'));type_field('record-revision',correct['code_revision']);type_field('record-purpose','agent authored actual software output. not owner achievement');click('Save');wait(lambda s:s['selected'].get('type')=='artifact');artifact=state()['selected'];actions();click('Check checksum');wait(lambda s:any(e['event']=='artifact-check' for e in s['history']));open_record(experiment);capture('lab-executed-evidence')
 # Preserve failed output separately; never replace evidence with a corrected verdict.
 click('Connect artifact');type_field('record-title','first discovery failure output');type_field('record-source',str(directory/'observations-wrong.json'));type_field('record-revision',wrong_report['code_revision']);type_field('record-purpose','actual failed case b was 10 instead of 2. agent validation');click('Save');wait(lambda s:s['selected'].get('type')=='artifact')
 open_record(invariant);type_field('investigation-reasoning','agent example insight. discovery is not finalization. settle minimum tentative cost with nonnegative edges. ignore stale queue entries. a negative edge can invalidate the cut argument');click('Save as a study note');wait(lambda s:any(e['event']=='study' for e in s['history']));capture('reusable-invariant-insight')
 # Real isolated Obsidian ownership and precise concept-file handoff.
 registry=f.home/'.config/obsidian';registry.mkdir(parents=True,exist_ok=True);registry_id=uuid.uuid4().hex[:16];(registry/'obsidian.json').write_text(json.dumps({'cli':True,'vaults':{registry_id:{'path':str(f.vault),'ts':int(time.time()*1000),'open':True}}}));(f.vault/'.obsidian').mkdir(exist_ok=True);(f.vault/'.obsidian/app.json').write_text(json.dumps({'showInlineTitle':False}));(f.vault/'.obsidian/core-plugins.json').write_text('[]');(registry/'user-flags.conf').write_text('--user-data-dir='+str(registry)+'\n')
 obslog=(f.home/'obsidian.log').open('w');obsidian_process=subprocess.Popen(['obsidian'],env=f.env,stdout=obslog,stderr=obslog,start_new_session=True);time.sleep(4)
 click('Open derivation in Obsidian ↗');f.wait(lambda s:not s['working'],seconds=25);assert not f.state()['error'],f.state()['error'];probe=subprocess.run(['obsidian','vault='+registry_id,'file','info=path'],env=f.env,capture_output=True,text=True,timeout=12);assert probe.returncode==0 and invariant['path'] in probe.stdout,(probe.stdout,probe.stderr);reopen()
 open_record(question);click('← Return to '+problem['title']);f.wait(lambda s:s['selected']==problem['path']);click('Question, mechanism & implementation ('+str(len(state()['relations']))+')');capture('shared-thread-navigation');click(question['title']);wait(lambda s:s['selected']['id']==question['id']);f.ipc('journey-fixture','back');wait(lambda s:s['selected']['id']==problem['id'])
 actions();click('Try a changed problem');type_field('record-title','changed graph - shortest paths to a destination');type_field('record-purpose','agent example. directed edges a to t cost 7, b to t cost 2, a to b cost 1, c to a cost 0, c to b cost 8. x is isolated. find every distance to t. predict before opening reference');click('Save');wait(lambda s:s['selected'].get('practice_mode')=='transfer');transfer=state()['selected'];assert transfer['parent_ref']['record_id']==problem['id'];click('Start independent attempt');wait(lambda s:s['attempt'] and s['protected']);type_field('practice-reasoning','agent example predicts reverse edges preserves path cost. x stays unreachable. original direction would answer a different question');capture('independent-changed-problem');assert all(a['action']!='implementation' for a in state()['actions'])
 # Deliberate reference exposure remains assistance even when the later outcome selector says none.
 click('Reveal reference');wait(lambda s:not s['protected']);capture('deliberate-reference-exposure');f.ipc('noesis','hide');f.wait(lambda s:not s['visible'] and not s['worker']);transferred=execute('transfer',' --transfer');assert transferred['all_agree'] and len(transferred['cases'])==9;reopen();wait(lambda s:s['selected']['id']==transfer['id'] and s['attempt'] and not s['protected']);record_attempt('partial','none');assert 'reference' in next(e for e in reversed(state()['history']) if e['event']=='attempt')['assistance']
 click('Start independent attempt');wait(lambda s:s['attempt'] and s['protected']);type_field('practice-reasoning','agent second changed case. unaided retry predicts t 0 b 2 a 3 c 3 and x unreachable');record_attempt('succeeded','none');capture('changed-problem-result')
 open_record(experiment);click('Connect artifact');type_field('record-title','changed destination graph executed output');type_field('record-source',str(directory/'observations-transfer.json'));type_field('record-revision',correct['code_revision']);type_field('record-purpose','agent example changed graph checked only after saved prediction and deliberate reference reveal');click('Save');wait(lambda s:s['selected'].get('type')=='artifact');open_record(question);type_field('investigation-reasoning','agent continuation. cut proof remains unknown. preserved failure code results and transfer are separate');capture('question-before-restart');f.exit();f.env.pop('NOESIS_WINDOW_MODE',None);f.start(resume=True);f.ipc('journey-fixture','init');wait(lambda s:s['selected']['id']==question['id'] and 'cut proof remains unknown' in s['notes']);assert any(row['id']==project['id'] for row in state()['frontier']['items']);capture('exact-question-after-restart');desk_capture('resumed-question-screenpad')
 f.ipc('journey-fixture','framesStart');time.sleep(3);frames=sorted(json.loads(f.ipc('journey-fixture','framesStop')))
 with patch('pathlib.Path.home',return_value=f.home):
  ix=Index(f.vault)
  try:
   ix.reconcile();q=ix.record(question['id'])['props'];assessment=ix.record(q['evidence_refs'][0]['record_id'])['props'];assert assessment['outcome']=='failed' and assessment['assistance']==['none'];assert q['parent_ref']['record_id']==problem['id'];events=ix.timeline(transfer['id']);attempts=[e for e in events if e['event']=='attempt'];assert attempts[-1]['assistance']==['none'] and attempts[-1]['outcome']=='succeeded';assert not any(e['event']=='capability-decision' for e in events);assert ix.record(artifact['id'])['props']['revision']==correct['code_revision'];assert any(e['event']=='artifact-check' and e.get('observed_sha256') for e in ix.timeline(artifact['id']))
  finally:ix.close()
 warnings=[l for l in (f.home/'qml.log').read_text().splitlines() if ('WARN' in l or 'ERROR' in l) and 'Could not register app ID' not in l];assert not warnings,warnings
 subprocess.run(['git','-C',str(directory),'bundle','create',str(evidence/'validation-code.bundle'),'--all'],check=True);(evidence/'corrected-implementation.py').write_text(DIJKSTRA);(evidence/'failed-implementation.py').write_text(wrong)
 (evidence/'executed-outputs.json').write_text(json.dumps({'authorship':'Agent-authored disposable acceptance, not owner understanding','executions':outputs},indent=2)+'\n')
 (evidence/'acceptance.json').write_text(json.dumps({'source_files':{str(path.relative_to(REPO)):hashlib.sha256(path.read_bytes()).hexdigest() for folder in ['ui','noesis','examples'] for path in (REPO/'home/.local/share/sensei-learning'/folder).rglob('*') if path.is_file() and path.suffix in ('.qml','.py','.md') and '__pycache__' not in path.parts},'source_revision':source_revision,'source_was_dirty':bool(subprocess.check_output(['git','status','--porcelain','--','home'],cwd=REPO,text=True).strip()),'fixture_only':True,'captures':reports,'code_revision':correct['code_revision'],'performance':{'frame_p95_ms':round(frames[int(.95*(len(frames)-1))],3),'samples':len(frames),'note':'Three-second animation interval, not physical input latency or a human trial'},'assertions':['failure preserved before question','native nonblocking prerequisite and exact return','empty skeleton and actual editor execution','wrong and corrected code revisions','eight independent expected cases','actual outputs attached to Lab','reusable concept reflection','isolated native Obsidian exact file','protected transfer and irreversible exposure','restart exact question and draft','no automatic mastery']},indent=2)+'\n');print('PASS shared Dijkstra native journey',evidence,flush=True)
finally:
 f.stop()
 if obsidian_process and obsidian_process.poll() is None:os.killpg(obsidian_process.pid,signal.SIGTERM);obsidian_process.wait(timeout=10)
 if terminal_pid and Path('/proc/'+str(terminal_pid)).exists():
  children=subprocess.run(['pgrep','-P',str(terminal_pid)],capture_output=True,text=True).stdout.splitlines()
  if any(Path('/proc/'+pid+'/cwd').resolve().is_relative_to(f.vault) for pid in children):os.kill(terminal_pid,signal.SIGTERM)
 print('Disposable diagnostics retained:',f.home,flush=True)
