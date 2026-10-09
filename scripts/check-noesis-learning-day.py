#!/usr/bin/env python3
"""Native disposable course journey. Injected actions are not human usability results."""
import importlib.util,json,os,subprocess,tempfile,time,shutil,uuid
from pathlib import Path
repo=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('installer',repo/'scripts/install.py');installer=importlib.util.module_from_spec(spec);spec.loader.exec_module(installer)
with tempfile.TemporaryDirectory(prefix='noesis-learning-day-') as temporary:
 home=Path(temporary);installer.install(home,True)
 env=dict(os.environ,HOME=str(home),XDG_CONFIG_HOME=str(home/'.config'),XDG_CACHE_HOME=str(home/'.cache'),XDG_STATE_HOME=str(home/'.local/state'),NOESIS_WINDOW_MODE='normal')
 cli=home/'.local/bin/noesis';config=home/'.config/quickshell/wrayth';qs=os.environ.get('NOESIS_QS',str(Path.home()/'.local/opt/sensei-quickshell/bin/qs'))
 def command(*args):return json.loads(subprocess.check_output([str(cli),*args],env=env,text=True))
 roots=[]
 for name in ('CS','Mathematics'):
  root=home/name;(root/'System').mkdir(parents=True);(root/'System/System.json').write_text('{}')
  command('migrate','--vault',str(root),'--apply');command('vault-register',str(root));roots.append(root)
 def record(root,kind,title,body='',**fields):return command('record','--vault',str(root),kind,title,'--body',body,'--data',json.dumps(fields))
 cs=record(roots[0],'task','Truth table reconstruction','## Problem statement\n\nPredict NAND for 00, 01, 10 and 11. Explain how negated conjunction gives each output.\n\n## Reference\n\n1, 1, 1, 0.')
 command('event','--vault',str(roots[0]),cs['path'],'attempt-start','--data',json.dumps({'mode':'derive','scope':'NAND reconstruction'}))
 outline=home/'linear-algebra.json'
 entries=[{'key':'module','kind':'unit','title':'Vector spaces','fields':{'unit_kind':'module'}}]
 entries += [{'key':'lecture'+str(n),'kind':'unit','title':'Lecture '+str(n),'parent':'module','body':'Reconstruct the definitions before watching.','fields':{'unit_kind':'lecture'}} for n in range(1,7)]
 entries += [{'key':'reading'+str(n),'kind':'unit','title':'Reading '+str(n),'parent':'lecture3','fields':{'unit_kind':'reading'}} for n in range(1,3)]
 entries += [{'key':'assignment'+str(n),'kind':'task','title':'Basis exercise '+str(n),'parent':'lecture3','body':'## Problem statement\n\nExplain why the columns (1, 0) and (2, 0) cannot span the plane.'} for n in range(1,3)]
 entries += [{'key':'project','kind':'project','title':'Matrix experiment'}]
 outline.write_text(json.dumps({'version':1,'title':'Linear algebra learning day','entries':entries}))
 imported=command('course-import','--vault',str(roots[1]),str(outline),'--apply','--operation-id',str(uuid.uuid4()))
 course=imported['course'];lesson=next(row for row in command('query','--vault',str(roots[1]),'Lecture 3')['records'] if row['type']=='unit')
 assignment=next(row for row in command('query','--vault',str(roots[1]),'Basis exercise 1')['records'] if row['type']=='task')
 for number in (1,2):
  row=next(r for r in command('query','--vault',str(roots[1]),'Lecture '+str(number))['records'] if r['type']=='unit')
  command('event','--vault',str(roots[1]),row['path'],'study','--data',json.dumps({'state':{'status':'read'}}))
 command('event','--vault',str(roots[1]),lesson['path'],'study','--data',json.dumps({'state':{'locator':{'kind':'timestamp','value':'12:34'}}}))
 gap=record(roots[1],'task','Span reconstruction','## Problem statement\n\nDescribe the span of two dependent vectors without a reference.')
 subprocess.run([str(cli),'use',str(roots[1])],env=env,check=True,capture_output=True)
 # Afternoon: a real source equation, with explicitly agent-authored fixture analysis.
 import sys,hashlib,math,csv
 from noesis_attention_fixture import run as attention_fixture
 paper=record(roots[1],'resource','Attention Is All You Need','Source Eq. 1. Fixture analysis is agent-authored, not learner competence.',source_kind='paper',source='https://arxiv.org/html/1706.03762v7',arxiv='1706.03762')
 from unittest.mock import patch
 with patch('pathlib.Path.home',return_value=home):
  attention=attention_fixture(roots[1],paper['id'],{'authority':'source-section reference; native Zotero annotations accepted separately','section':'3.2.1'},home)
 # Evening: execute only this explicitly authored software experiment, never fetched code.
 implementation=home/'calibration';implementation.mkdir()
 code=implementation/'measure.py';code.write_text('import json,math\nfrom statistics import mean\nsamples=[0.12+0.004*math.sin(n*0.1) for n in range(1000)]\nbias=mean(samples[:500])\nprint(json.dumps({"mean":mean(samples),"bias":bias,"held_out_residual":mean([v-bias for v in samples[500:]])}))\n')
 subprocess.run(['git','init','-q',str(implementation)],check=True)
 subprocess.run(['git','-C',str(implementation),'add','measure.py'],check=True)
 subprocess.run(['git','-C',str(implementation),'-c','user.name=Noesis fixture','-c','user.email=fixture@example.invalid','commit','-qm','Authored calibration'],check=True)
 executed=subprocess.run([sys.executable,str(code)],env=env,capture_output=True,text=True,check=True,timeout=10)
 measured=json.loads(executed.stdout);assert abs(measured['mean'])>.005 and abs(measured['held_out_residual'])<.005
 project=record(roots[1],'project','Gyroscope implementation',repository=str(implementation))
 experiment=command('record','--vault',str(roots[1]),'experiment','Zero bias experiment','--parent-id',project['id'],'--data',json.dumps({'hypothesis':'Stationary mean is within 0.005 rad/s of zero','configuration':{'samples':1000,'rate_hz':100,'units':'rad/s'}}))
 data=home/'measurements.csv'
 with data.open('w',newline='') as file:
  writer=csv.writer(file);writer.writerow(['time_s','angular_velocity_rad_s']);writer.writerows((n/100,0.12+0.004*math.sin(n*0.1)) for n in range(1000))
 os.environ['MPLCONFIGDIR']=str(home/'matplotlib')
 import matplotlib;matplotlib.use('Agg')
 import matplotlib.pyplot as plt
 figure,axis=plt.subplots(figsize=(7,3));axis.plot([n/100 for n in range(1000)],[0.12+0.004*math.sin(n*0.1) for n in range(1000)]);axis.axhline(0,color='black',linestyle='--');axis.set(xlabel='Time (s)',ylabel='Angular velocity (rad/s)',title='Generated measurements contradict zero bias');figure.tight_layout();plot=home/'measurement.png';figure.savefig(plot);plt.close(figure)
 for title,file in [('Generated sensor measurements',data),('Prediction and measurement figure',plot)]:
  command('record','--vault',str(roots[1]),'artifact',title,'--parent-id',experiment['id'],'--data',json.dumps({'location':str(file),'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'ownership':'generated acceptance fixture; no hardware claim'}))
 command('event','--vault',str(roots[1]),experiment['path'],'comparison','--evidence','Actual execution contradicts the original generated-data prediction.','--data',json.dumps({'predicted':'0 +/- 0.005','observed':format(measured['mean'],'.6f'),'units':'rad/s','uncertainty':'Synthetic sinusoidal variation; no instrument uncertainty claim','conclusion':'Zero-bias assumption contradicted in generated data','next_experiment':'Test estimated bias on held-out samples','execution':{'returncode':executed.returncode,'command':[sys.executable,str(code)]}}))
 originals={p:p.read_bytes() for root in roots for p in root.rglob('*.md')}
 (config/'shell.qml').write_text('import QtQuick\nimport Quickshell\nimport "modules/learning" as LearningUi\nimport qs.services\nShellRoot { LearningUi.NoesisWindow {} Component.onCompleted:Oasis.open() }\n')
 log=home/'qml.log';actions=[];typing=0;client=None
 with log.open('w') as stream:
  process=subprocess.Popen([qs,'-p',str(config),'--no-color'],env=env,stdout=stream,stderr=subprocess.STDOUT)
  try:
   def ipc(target,action,*args):return subprocess.check_output([qs,'-p',str(config),'ipc','call',target,action,*args],env=env,text=True,stderr=subprocess.DEVNULL)
   def state():return json.loads(ipc('noesis-window','state'))
   def wait(predicate,seconds=10):
    start=time.monotonic()
    while True:
     try:
      value=state()
      if predicate(value):return value,time.monotonic()-start
     except (subprocess.CalledProcessError,ValueError):pass
     assert time.monotonic()-start<seconds,log.read_text();time.sleep(.05)
   wait(lambda value:value['worker'] and value['watch']);time.sleep(.5)
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if c['pid']==process.pid and c['title'].startswith('Noesis'))
   def key(mods,key,typed=False):
    if not typed:actions.append((mods,key))
    subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods='+json.dumps(mods)+',key='+json.dumps(key)+',window='+json.dumps('address:'+client['address'])+'})'],check=True,capture_output=True);time.sleep(.12)
   def text(value):
    global typing
    typing+=len(value)
    for letter in value:key('',{' ':'space','.':'period','-':'minus'}.get(letter,letter),True)
   def find(title):
    key('CTRL','k');key('CTRL','a');text(title);time.sleep(.5);key('','Down');key('','Return');time.sleep(.7)
   def screenshot(name):
    current=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if c['address']==client['address']);x,y=current['at'];w,h=current['size']
    subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',name],check=True)
   def choose_action(number):
    key('CTRL','period')
    for _ in range(number):key('','Down')
    key('','Return');time.sleep(.4)
   def outcome(steps):
    key('CTRL','Tab');key('','Tab');key('','Home')
    for _ in range(steps):key('','Down')
    key('','Tab');key('','Home');key('','Down')
    assert state()['declared_assistance']=='none',state()
   # Morning: another registered owner can recover its durable unfinished attempt.
   key('CTRL','6');key('CTRL + SHIFT','k');find('Truth table reconstruction')
   assert state()['vault']==str(roots[0]) and state()['attempt']
   text('Negating conjunction gives true true true false')
   outcome(4);key('CTRL','Return');time.sleep(.4)
   morning=command('timeline','--vault',str(roots[0]),cs['id'])['activities']
   assert morning[-1]['outcome']=='succeeded' and morning[-1]['assistance']==['none']
   # Midday: find a lesson across owners, connect a prerequisite through the UI.
   find('Lecture 3');assert state()['vault']==str(roots[1])
   key('CTRL + SHIFT','p');text('Span reconstruction');time.sleep(.4);key('','Down');key('','Return');text('Needed to understand the lecture');key('CTRL','Return')
   wait(lambda value:len(value['learning_context'].get('prerequisites',[]))==1)
   links=command('query','--vault',str(roots[1]),'','--kind','relationship')['records']
   assert len(links)==1
   import sys
   sys.path.insert(0,str(repo/'home/.local/share/sensei-learning'))
   from noesis.persistence import parse
   link_props,_=parse((roots[1]/links[0]['path']).read_text())
   assert command('operation-status','--vault',str(roots[1]),link_props['operation_id'])['status']=='committed'
   screenshot('/tmp/noesis-lesson-context-native.png')
   start=len(actions);key('CTRL + ALT','Down');wait(lambda value:value['selected']==gap['path'])
   key('CTRL','Return');time.sleep(.4);text('Dependent vectors span a line through the origin');outcome(4);key('CTRL','Return');time.sleep(.4)
   key('ALT','Left');wait(lambda value:value['selected']==lesson['path'])
   assert state()['learning_context']['prerequisites'][0]['assessment']['outcome']=='succeeded'
   print('Prerequisite assessment and return:',len(actions)-start,'non-text keyboard actions')
   key('CTRL + ALT','r');text('The span explanation is usable here');key('CTRL','Tab');key('','Home');key('CTRL','Return')
   wait(lambda value:value['learning_context']['prerequisites'][0].get('readiness')=='passed')
   # Lesson completion uses the existing contextual action; assignments stay pending.
   time.sleep(.4)
   actions_now=state()['context_actions'];print('Lesson completion actions:',actions_now)
   choose_action(actions_now.index('consumed'));time.sleep(.5)
   assert command('timeline','--vault',str(roots[1]),lesson['id'])['activities'][-1]['state']['status']=='read',state()
   assert not state()['error'],state()
   key('CTRL + ALT','Right');wait(lambda value:value['selected']==assignment['path'])
   key('CTRL','Return');time.sleep(.4);text('Both vectors have zero second coordinate so the span is a line');outcome(4);key('CTRL','Return');time.sleep(.4)
   key('ALT','Left');wait(lambda value:value['selected']==lesson['path'])
   assert state()['learning_context']['assignments'][0]['assessment']['assistance']==['none']
   # Return to module then course without searching files. No capability is awarded.
   key('CTRL + ALT','Left');time.sleep(.4);key('CTRL + ALT','Left');time.sleep(.4)
   assert state()['selected']==course['path'],state()
   counts=state()['overview_counts'];assert counts['lectures']['consumed']==3 and counts['assignments']['reported_success']==1 and counts['other_units']['total']==0,counts
   assert counts['assignments']['independent_reported_success']==1 and counts['projects']['reported_success']==0
   screenshot('/tmp/noesis-course-day-native.png')
   # Afternoon and evening native inspection; specialist reader/API gates stay distinct.
   key('CTRL','3');find('Attention Is All You Need');assert state()['selected']==paper['path']
   screenshot('/tmp/noesis-paper-day-native.png')
   key('CTRL','6');find('Attention forward verification');assert state()['selected']==attention['project']['path']
   key('CTRL','5');find('Zero bias experiment')
   lab,_=wait(lambda value:value['loaded_figures']==1 and value['experiment'])
   assert lab['experiment']['hypothesis']=='Stationary mean is within 0.005 rad/s of zero'
   assert lab['experiment']['latest_comparison']['execution']['returncode']==0
   assert lab['experiment']['artifacts'][0]['availability']=='available'
   screenshot('/tmp/noesis-lab-day-native.png')
   key('CTRL','Next');assert state()['read_scroll_fraction']>0,state()
   screenshot('/tmp/noesis-lab-figure-native.png')
   print('PASS: native paper/source and committed implementation contexts; actual software measurement, original prediction, configuration, local PNG and next experiment visible')
   key('CTRL','6');find('Lecture 3')
   ipc('noesis','close');wait(lambda value:not value['worker'] and not value['watch'])
   subprocess.run([qs,'-p',str(config),'kill'],env=env,capture_output=True);process.wait(timeout=5)
   shutil.rmtree(home/'.cache/noesis')
   process=subprocess.Popen([qs,'-p',str(config),'--no-color'],env=env,stdout=stream,stderr=subprocess.STDOUT)
   recovered,elapsed=wait(lambda value:value['selected']==lesson['path'] and len(value['learning_context'].get('assignments',[]))==2)
   assert recovered['learning_context']['assignments'][0]['assessment']['outcome']=='succeeded'
   timeline=command('timeline','--vault',str(roots[1]),lesson['id'])['activities']
   assert timeline[0]['state']['locator']['value']=='12:34' and timeline[-1]['state']['status']=='read'
   assert all(path.read_bytes()==original for path,original in originals.items())
   print('PASS: cross-vault CS reconstruction; native lesson prerequisite connection/attempt/return; assignment assessment; module/course counts; cache-loss restart')
   print('Automated context recovery seconds:',round(elapsed,3),'non-text keyboard actions:',len(actions),'typed characters:',typing)
   print('This is automated synthetic evidence, not a human usability or competence finding. The native Zotero API/annotation and specialist PDF handoff are separate acceptance scripts.')
  finally:
   subprocess.run([qs,'-p',str(config),'kill'],env=env,capture_output=True);process.terminate()
   try:process.wait(timeout=5)
   except subprocess.TimeoutExpired:process.kill();process.wait()
   output=log.read_text();print(output)
  assert 'WARN' not in output and 'ERROR' not in output,output
