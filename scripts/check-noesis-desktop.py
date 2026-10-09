#!/usr/bin/env python3
"""Native Hyprland acceptance with a disposable HOME and synthetic records.

Requires the running desktop, qs, hyprctl and grim. NOESIS_QS overrides qs.
Focuses only the fixture window for injected input; stops its own processes.
Screenshots contain synthetic records and are supplementary visual evidence.
"""
from pathlib import Path
import importlib.util,tempfile,subprocess,os,json,time,shutil
repo=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('installer',repo/'scripts/install.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
with tempfile.TemporaryDirectory(prefix='noesis-ui-') as temporary:
 home=Path(temporary);module.install(home,True);assert not module.install(home,False)['changed']
 vault=home/'vault';(vault/'System').mkdir(parents=True);(vault/'System/System.json').write_text(json.dumps({'directories':[],'home':'test.md','frontier':'test.md','types':{},'noesis_schema':2,'vault_id':'22222222-2222-4222-8222-222222222222'}));(vault/'test.md').write_text('---\nid: 11111111-1111-4111-8111-111111111111\nnoesis_schema: 2\ntype: task\n---\nSynthetic prediction for UI verification.')
 for number in range(122):
  (vault/f'concept-{number:03}.md').write_text(f'---\nid: 33333333-3333-4333-8333-{number:012}\nnoesis_schema: 2\ntype: concept\ntitle: Connected concept {number:03}\n---\nA synthetic technical explanation.')
 (home/'.config/sensei-learning').mkdir(exist_ok=True);(home/'.config/sensei-learning/config.json').write_text(json.dumps({'active_vault':str(vault)}))
 config=home/'.config/quickshell/wrayth';(config/'shell.qml').write_text('import QtQuick\nimport Quickshell\nimport "modules/learning" as LearningUi\nimport qs.services\nShellRoot { LearningUi.NoesisWindow {} LearningUi.NoesisCompanion {} Component.onCompleted:Oasis.open() }\n')
 if os.environ.get('NOESIS_TEST_HOST')=='standalone':
  config=home/'.config/quickshell/noesis'
  p=config/'shell.qml';p.write_text(p.read_text().replace('org.fh1m.Noesis','org.fh1m.Noesis.Acceptance'))
 env=dict(os.environ,NOESIS_WINDOW_MODE="normal",HOME=str(home),XDG_CONFIG_HOME=str(home/'.config'),XDG_CACHE_HOME=str(home/'.cache'),XDG_STATE_HOME=str(home/'.local/state'))
 binary=os.environ.get('NOESIS_QS',str(Path.home()/'.local/opt/sensei-quickshell/bin/qs'))
 log=home/'qml.log'
 with log.open('w') as stream:
  process=subprocess.Popen([binary,'-p',str(config),'--no-color'],env=env,stdout=stream,stderr=subprocess.STDOUT)
  try:
   time.sleep(4)
   state=subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','state'],env=env,text=True,capture_output=True,timeout=5)
   print('Window:',state.stdout.strip(),state.stderr.strip())
   subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','section','Library'],env=env,capture_output=True,timeout=5)
   time.sleep(.7)
   subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','select','test.md'],env=env,capture_output=True,timeout=5)
   time.sleep(.7)
   selected=subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','state'],env=env,text=True,capture_output=True,timeout=5)
   print('Selected:',selected.stdout.strip());data=json.loads(selected.stdout);assert data['rows']==50
   subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','more'],env=env,capture_output=True,timeout=5);time.sleep(.5)
   state=subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','state'],env=env,text=True,capture_output=True,timeout=5);assert json.loads(state.stdout)['rows']==100
   subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','more'],env=env,capture_output=True,timeout=5);time.sleep(.5)
   state=subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','state'],env=env,text=True,capture_output=True,timeout=5);assert json.loads(state.stdout)['rows']==123
   subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','select','test.md'],env=env,capture_output=True,timeout=5);time.sleep(.5)
   clients=json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True));client=next(c for c in clients if c['pid']==process.pid and c['title'].startswith('Noesis'))
   subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+json.dumps('address:'+client['address'])+'})'],capture_output=True)
   time.sleep(.3)
   keyboard_events=[]
   def shortcut(keys,key):
    keyboard_events.append((keys,key))
    result=subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods='+json.dumps(keys.replace(' ',' + '))+',key='+json.dumps(key)+',window='+json.dumps('address:'+client['address'])+'})'],text=True,capture_output=True);assert result.returncode==0,result.stderr;time.sleep(.3)
   def state():
    result=subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','state'],env=env,text=True,capture_output=True,timeout=5);return json.loads(result.stdout)
   shortcut('CTRL','k');assert state()['search_focused']
   shortcut('CTRL SHIFT','n');assert state()['capture_open'] and state()['capture_focused']
   shortcut('','Escape');assert not state()['capture_open']
   shortcut('CTRL','2');assert state()['section']=='Learn'
   shortcut('CTRL','6');assert state()['section']=='Library'
   print('Pagination 50 → 100 → 123; native keyboard search/capture/Escape/workspaces passed')
   # Publish an actual capture using native keyboard input and the UI action.
   shortcut('CTRL SHIFT','n');shortcut('','a');shortcut('CTRL','Return');time.sleep(.8)
   print('Capture result:',state());assert not state()['capture_open']
   assert len(list((vault/'90 Inbox').glob('*.md')))+len(list((vault/'Inbox').glob('*.md')))==1
   subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','select','test.md'],env=env,capture_output=True,timeout=5)
   # The task may lie outside the initial page after refresh; search with the native field.
   if not state()['selected']:
    shortcut('CTRL','k')
    for letter in 'test':shortcut('',letter)
    time.sleep(.4)
    subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','select','test.md'],env=env,capture_output=True,timeout=5)
   time.sleep(.5);assert state()['selected']=='test.md'
   result=subprocess.run([str(home/'.local/bin/noesis'),'event','test.md','attempt-start','--vault',str(vault),'--data',json.dumps({'mode':'derive','scope':'Synthetic task'})],env=env,text=True,capture_output=True,check=True)
   attempt=json.loads(result.stdout)['id'];time.sleep(1);assert state()['attempt']==attempt
   shortcut('CTRL','i');assert state()['inspector']
   scale=client['size'][0]/state()['width']
   def resize(width,height):
    expression='hl.dsp.window.resize({x='+str(round(width*scale))+',y='+str(round(height*scale))+',relative=false,window='+json.dumps('address:'+client['address'])+'})'
    result=subprocess.run(['hyprctl','dispatch',expression],text=True,capture_output=True);assert result.returncode==0,result.stdout;time.sleep(.6)
   resize(1000,650);print('Resized:',state());assert abs(state()['width']-1000)<3 and abs(state()['height']-650)<3 and not state()['inspector']
   resize(1440,880)
   companion=subprocess.run([binary,'-p',str(config),'ipc','call','noesis-companion','state'],env=env,text=True,capture_output=True,timeout=5);print('Companion:',companion.stdout.strip())
   # Record the selected technical context, rather than a screenshot of a blank list.
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==process.pid and c['title'].startswith('Noesis'))
   x,y=client['at'];w,h=client['size'];subprocess.run(['grim','-g',f'{x},{y} {w}x{h}','/tmp/noesis-workspace-check.png'],check=True)
   subprocess.run([binary,'-p',str(config),'ipc','call','noesis','close'],env=env,capture_output=True,timeout=5)
   time.sleep(1)
   closed=subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','state'],env=env,text=True,capture_output=True,timeout=5);data=json.loads(closed.stdout);assert not data['worker'] and not data['watch'];print('Closed worker/watch:',data['worker'],data['watch'])
   process.terminate();process.wait(timeout=5)
   process=subprocess.Popen([binary,'-p',str(config),'--no-color'],env=env,stdout=stream,stderr=subprocess.STDOUT);time.sleep(4)
   restarted=state();print('Restarted context:',restarted['selected'],restarted['attempt']);assert restarted['selected']=='test.md' and restarted['attempt']==attempt and restarted['reference_hidden']
   def cli(*args):
    result=subprocess.run([str(home/'.local/bin/noesis'),*args,'--vault',str(vault)],env=env,text=True,capture_output=True,check=True);return json.loads(result.stdout)
   course=cli('record','resource','Synthetic linear algebra','--data',json.dumps({'source_kind':'course'}),'--body','Six lectures, two independent problem sets and a project.')
   units=[]
   for number in range(6):
    units.append(cli('record','unit',f'Lecture {number+1}','--parent-id',course['id'],'--data',json.dumps({'unit_kind':'lecture'})))
   for number in (0,3):cli('record','task',f'Problem set {number+1}','--parent-id',units[number]['id'],'--relation','assigns')
   cli('record','project','Estimator implementation','--parent-id',course['id'])
   for unit in units[:2]:cli('event',unit['path'],'study','--data',json.dumps({'state':{'status':'read'}}))
   subprocess.run([binary,'-p',str(config),'ipc','call','noesis-window','section','Learn'],env=env,capture_output=True,timeout=5);time.sleep(.5)
   # Select the course using actual search → Down → Enter key delivery.
   clients=json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True));client=next(c for c in clients if c['pid']==process.pid and c['title'].startswith('Noesis'))
   subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+json.dumps('address:'+client['address'])+'})'],capture_output=True)
   shortcut('CTRL','k')
   for letter in 'linear':shortcut('',letter)
   time.sleep(.4);shortcut('','Down');shortcut('','Return');time.sleep(.5)
   current=state();counts=current['overview_counts'];assert current['selected']==course['path'] and current['context_tab']=='Read'
   assert counts['lectures']['total']==6 and counts['lectures']['consumed']==2 and counts['assignments']['reported_success']==0 and counts['projects']['reported_success']==0
   scale=client['size'][0]/current['width'];resize(1000,650)
   current=state();print('Compact course state:',json.dumps(current),flush=True);assert current['read_viewport_height']>100 and current['read_content_height']>current['read_viewport_height']
   print('Course: 2/6 consumed; assignments/projects untouched; compact context scrolls:',current['read_viewport_height'],current['read_content_height'])
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==process.pid and c['title'].startswith('Noesis'))
   x,y=client['at'];w,h=client['size'];subprocess.run(['grim','-g',f'{x},{y} {w}x{h}','/tmp/noesis-course-compact.png'],check=True)
   # Create through the actual dialog keyboard action, then verify its durable receipt.
   shortcut('CTRL','4');shortcut('CTRL','n')
   for letter in 'synthetic problem':shortcut('','space' if letter==' ' else letter)
   shortcut('CTRL','Return');time.sleep(.7)
   records=list((vault/'Records/task').glob('synthetic problem*'))
   assert len(records)==1
   import sys
   sys.path.insert(0,str(repo/'home/.local/share/sensei-learning'))
   from noesis.persistence import parse
   props,_=parse(records[0].read_text());receipt=cli('operation-status',props['operation_id'])
   assert receipt['status']=='committed' and len(receipt['records'])==1
   print('Native problem dialog saved one record with a committed receipt')
   # A complete connected-record route through native dialogs and contextual actions.
   typing_events=[0]
   journey_start=len(keyboard_events)
   def type_text(value):
    typing_events[0]+=len(value)
    for letter in value:
     if letter=='_':shortcut('SHIFT','minus')
     else:shortcut('',{' ':'space','/':'slash','-':'minus','.':'period'}.get(letter,letter))
   implementation=home/'implementation';implementation.mkdir()
   def git(*args):subprocess.run(['git','-C',str(implementation),*args],capture_output=True,check=True)
   git('init','-q');git('config','user.name','Synthetic learner');git('config','user.email','synthetic@example.invalid')
   (implementation/'model.py').write_text('prediction = 0\n');git('add','model.py');git('commit','-qm','Synthetic baseline')
   shortcut('CTRL','3');shortcut('CTRL','n');type_text('synthetic paper');shortcut('CTRL','Return');time.sleep(.5)
   paper_file=next((vault/'Records/resource').glob('synthetic paper*'));paper,_=parse(paper_file.read_text())
   shortcut('CTRL','period');shortcut('','Return');type_text('synthetic question');shortcut('','Tab');type_text('why');shortcut('CTRL','Return');time.sleep(.5)
   question_file=next((vault/'Records/question').glob('synthetic question*'));question,_=parse(question_file.read_text())
   assert question['parent_ref']['record_id']==paper['id']
   shortcut('ALT','Left');time.sleep(.5);assert state()['selected']==str(paper_file.relative_to(vault))
   shortcut('CTRL','period');shortcut('','Down');shortcut('','Return');type_text('synthetic implementation');shortcut('','Tab');type_text(str(implementation));shortcut('CTRL','Return');time.sleep(.5)
   project_file=next((vault/'Records/project').glob('synthetic implementation*'));project,_=parse(project_file.read_text())
   assert project['parent_ref']['record_id']==paper['id'] and project['code_snapshot']['commit']
   shortcut('CTRL','period');shortcut('','Down');shortcut('','Return');type_text('synthetic run');shortcut('','Tab');type_text('prediction zero');shortcut('CTRL','Return');time.sleep(.5)
   run_file=next((vault/'Records/experiment').glob('synthetic run*'));run,_=parse(run_file.read_text())
   assert run['parent_ref']['record_id']==project['id'] and run['code_snapshot']['commit']==project['code_snapshot']['commit']
   shortcut('CTRL','period')
   for _ in range(3):shortcut('','Down')
   shortcut('','Return');type_text('measured one');shortcut('','Tab');shortcut('','Tab');type_text('prediction contradicted');shortcut('CTRL','Return');time.sleep(.6)
   comparisons=[event for event in cli('timeline',run['id'])['activities'] if event['event']=='comparison']
   assert len(comparisons)==1 and comparisons[0]['code_snapshot']['commit']==run['code_snapshot']['commit']
   shortcut('ALT','Left');shortcut('ALT','Left');time.sleep(.5)
   assert state()['selected']==str(paper_file.relative_to(vault))
   print('Native paper → question → implementation → run → comparison → paper passed; all targets remain connected')
   print('Connected route:',len(keyboard_events)-journey_start-typing_events[0],'keyboard actions plus',typing_events[0],'typed characters; no file hunting or metadata copying')
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==process.pid and c['title'].startswith('Noesis'))
   x,y=client['at'];w,h=client['size'];subprocess.run(['grim','-g',f'{x},{y} {w}x{h}','/tmp/noesis-research-context.png'],check=True)
   # Define a capability through the path UI, then preserve three different attempts.
   path=cli('record','path','synthetic demonstration path')
   shortcut('CTRL','2');shortcut('CTRL','k');type_text('demonstration');shortcut('','Down');shortcut('','Return');time.sleep(.5)
   shortcut('CTRL','period')
   for _ in range(3):shortcut('','Down')
   shortcut('','Return');type_text('scoped capability');shortcut('','Tab');type_text('explain failed assumption');shortcut('CTRL','Return');time.sleep(.5)
   capability_file=next((vault/'Records/capability').glob('scoped capability*'));capability,_=parse(capability_file.read_text())
   assert capability['parent_ref']['relation']=='pursues' and capability['criteria']==['explain failed assumption']
   shortcut('CTRL','4');shortcut('CTRL','k');type_text('synthetic problem');shortcut('','Down');shortcut('','Return');time.sleep(.5)
   problem,_=parse(records[0].read_text())
   def action(index):
    shortcut('CTRL','period')
    for _ in range(index):shortcut('','Down')
    shortcut('','Return');time.sleep(.5)
   def reported(outcome_steps):
    action(state()['context_actions'].index('attempt-settings'));shortcut('','Tab');shortcut('','Home')
    for _ in range(outcome_steps):shortcut('','Down')
    shortcut('','Tab');shortcut('','Home');shortcut('','Down') # explicitly declare no outside assistance
    current=state();assert current['reported_outcome']==('failed' if outcome_steps==2 else 'succeeded') and current['declared_assistance']=='none',current
    shortcut('CTRL','Return')
   action(0);type_text('failed prediction');reported(2);action(0)
   attempts=[event for event in cli('timeline',problem['id'])['activities'] if event['event']=='attempt']
   assert len(attempts)==1 and attempts[0]['outcome']=='failed' and attempts[0]['assistance']==['none']
   action(0);type_text('scoped');shortcut('','Down');shortcut('','Return');time.sleep(.5)
   type_text('failure explains the assumption')
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==process.pid and c['title'].startswith('Noesis'))
   x,y=client['at'];w,h=client['size'];subprocess.run(['grim','-g',f'{x},{y} {w}x{h}','/tmp/noesis-evidence-dialog.png'],check=True)
   shortcut('CTRL','Return');time.sleep(.6)
   decisions=[event for event in cli('timeline',capability['id'])['activities'] if event['event']=='capability-decision']
   assert len(decisions)==1 and decisions[0]['evidence_id']==attempts[0]['id'] and decisions[0]['actor']=='learner'
   action(2);type_text('corrected model');action(1);assert not state()['reference_hidden']
   reported(4);action(1)
   action(2);type_text('independent reasoning');reported(4);action(0)
   attempts=[event for event in cli('timeline',problem['id'])['activities'] if event['event']=='attempt']
   assert [(event['outcome'],event['assistance']) for event in attempts]==[('failed',['none']),('succeeded',['reference']),('succeeded',['none'])]
   assert len({event['attempt_id'] for event in attempts})==3
   print('Native practice: independent failure → reference-assisted success → independent retry; explicit scoped learner decision preserved')
   action(4);type_text('changed problem');shortcut('','Tab');shortcut('','Tab');type_text('changed constraints');shortcut('CTRL','Return');time.sleep(.7)
   transfer_file=next((vault/'Records/task').glob('changed problem*'));transfer,_=parse(transfer_file.read_text())
   assert transfer['parent_ref']['record_id']==problem['id'] and transfer['parent_ref']['relation']=='references' and transfer['practice_mode']=='transfer'
   assert state()['reference_hidden'],state()
   action(0);type_text('independent changed solution');reported(4);action(0)
   transferred=[event for event in cli('timeline',transfer['id'])['activities'] if event['event']=='attempt']
   assert len(transferred)==1 and transferred[0]['mode']=='transfer' and transferred[0]['assistance']==['none']
   action(3);type_text('reconstruct with new constraints');shortcut('CTRL + SHIFT','Tab');shortcut('SHIFT','Tab');shortcut('','Home');shortcut('','Down');shortcut('CTRL','Return');time.sleep(.6)
   plans=[event for event in cli('timeline',transfer['id'])['activities'] if event['event']=='review-plan']
   assert len(plans)==1 and plans[0]['stage']=='later' and plans[0]['action']=='schedule',plans
   print('Native changed-task transfer: separate identity, independent transfer attempt and learner-selected later reconstruction plan')
   action(5);assert state()['attempt'] and state()['reference_hidden'],state()
   type_text('reconstructed changed solution without notes');reported(4);action(0)
   reviewed=[event for event in cli('timeline',transfer['id'])['activities'] if event['event']=='attempt' and event.get('review_plan_id')==plans[0]['id']]
   assert len(reviewed)==1 and reviewed[0]['assistance']==['none'] and reviewed[0]['outcome']=='succeeded'
   print('Native selected check performed explicitly: protected reconstruction and outcome link retained; no automatic capability award')
   shortcut('CTRL','2');shortcut('CTRL','k');type_text('scoped');shortcut('','Down');shortcut('','Return');time.sleep(.5)
   assert state()['selected']==str(capability_file.relative_to(vault))
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==process.pid and c['title'].startswith('Noesis'))
   x,y=client['at'];w,h=client['size'];subprocess.run(['grim','-g',f'{x},{y} {w}x{h}','/tmp/noesis-capability-context.png'],check=True)
   subprocess.run([binary,'-p',str(config),'ipc','call','noesis','close'],env=env,capture_output=True,timeout=5);time.sleep(.5)
   assert not state()['worker'] and not state()['watch']
   process.terminate();process.wait(timeout=5);shutil.rmtree(home/'.cache/noesis')
   process=subprocess.Popen([binary,'-p',str(config),'--no-color'],env=env,stdout=stream,stderr=subprocess.STDOUT);time.sleep(4)
   assert state()['selected']==str(capability_file.relative_to(vault))
   recovered=[event for event in cli('timeline',problem['id'])['activities'] if event['event']=='attempt']
   assert [(event['outcome'],event['assistance']) for event in recovered]==[('failed',['none']),('succeeded',['reference']),('succeeded',['none'])]
   assert len([event for event in cli('timeline',capability['id'])['activities'] if event['event']=='capability-decision'])==1
   restored_transfer=cli('timeline',transfer['id'])['activities']
   assert len([event for event in restored_transfer if event['event']=='attempt'])==2
   assert len([event for event in restored_transfer if event.get('review_plan_id')==plans[0]['id'] and event['event']=='attempt'])==1
   assert any(event['id']==plans[0]['id'] for event in restored_transfer)
   print('Original attempts, scoped decision, transfer and performed check recovered after cache deletion and application restart')






  finally:process.terminate();process.wait(timeout=5);print(log.read_text()[-5000:])
 print(log.read_text()[-5000:])
 assert not any(('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line for line in log.read_text().splitlines()), 'Native QML emitted warnings or errors'
