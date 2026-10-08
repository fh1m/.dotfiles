#!/usr/bin/env python3
"""Native Hyprland acceptance with a disposable HOME and synthetic records.

Requires the running desktop, qs, hyprctl and grim. NOESIS_QS overrides qs.
Focuses only the fixture window for injected input; stops its own processes.
Screenshots contain synthetic records and are supplementary visual evidence.
"""
from pathlib import Path
import importlib.util,tempfile,subprocess,os,json,time
repo=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('installer',repo/'scripts/install.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
with tempfile.TemporaryDirectory(prefix='noesis-ui-') as temporary:
 home=Path(temporary);module.install(home,True);assert not module.install(home,False)['changed']
 vault=home/'vault';(vault/'System').mkdir(parents=True);(vault/'System/System.json').write_text(json.dumps({'directories':[],'home':'test.md','frontier':'test.md','types':{},'noesis_schema':2,'vault_id':'22222222-2222-4222-8222-222222222222'}));(vault/'test.md').write_text('---\nid: 11111111-1111-4111-8111-111111111111\nnoesis_schema: 2\ntype: task\n---\nSynthetic prediction for UI verification.')
 for number in range(122):
  (vault/f'concept-{number:03}.md').write_text(f'---\nid: 33333333-3333-4333-8333-{number:012}\nnoesis_schema: 2\ntype: concept\ntitle: Connected concept {number:03}\n---\nA synthetic technical explanation.')
 (home/'.config/sensei-learning').mkdir(exist_ok=True);(home/'.config/sensei-learning/config.json').write_text(json.dumps({'active_vault':str(vault)}))
 config=home/'.config/quickshell/wrayth';(config/'shell.qml').write_text('import QtQuick\nimport Quickshell\nimport "modules/learning" as LearningUi\nimport qs.services\nShellRoot { LearningUi.NoesisWindow {} LearningUi.NoesisCompanion {} Component.onCompleted:Oasis.open() }\n')
 env=dict(os.environ,HOME=str(home),XDG_CONFIG_HOME=str(home/'.config'),XDG_CACHE_HOME=str(home/'.cache'),XDG_STATE_HOME=str(home/'.local/state'))
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
   def shortcut(keys,key):
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
   current=state();assert current['read_viewport_height']>100 and current['read_content_height']>current['read_viewport_height']
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


  finally:process.terminate();process.wait(timeout=5);print(log.read_text()[-5000:])
 print(log.read_text()[-5000:])
