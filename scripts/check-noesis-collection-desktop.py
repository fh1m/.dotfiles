#!/usr/bin/env python3
"""Synthetic native cross-vault selection, scoped capture, drafts and window modes."""
import importlib.util,json,os,subprocess,tempfile,time,uuid
from pathlib import Path
repo=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('installer',repo/'scripts/install.py');installer=importlib.util.module_from_spec(spec);spec.loader.exec_module(installer)
with tempfile.TemporaryDirectory(prefix='noesis-collection-ui-') as temporary:
 home=Path(temporary);installer.install(home,True)
 env=dict(os.environ,HOME=str(home),XDG_CONFIG_HOME=str(home/'.config'),XDG_CACHE_HOME=str(home/'.cache'),XDG_STATE_HOME=str(home/'.local/state'),NOESIS_WINDOW_MODE='normal')
 cli=home/'.local/bin/noesis';config=home/'.config/quickshell/wrayth';qs=os.environ.get('NOESIS_QS',str(Path.home()/'.local/opt/sensei-quickshell/bin/qs'))
 def command(*args):return json.loads(subprocess.check_output([str(cli),*args],env=env,text=True))
 roots=[];records=[]
 for name in ('CS','Robotics'):
  vault=home/name;(vault/'System').mkdir(parents=True);(vault/'System/System.json').write_text(json.dumps({'directories':[],'types':{}}))
  command('migrate','--vault',str(vault),'--apply');command('vault-register',str(vault))
  records.append(command('record','--vault',str(vault),'task',name+' reasoning','--body','## Problem statement\n\nPredict the truth table.\n\n## Reference\n\nA protected solution.'))
  roots.append(vault)
 subprocess.run([str(cli),'use',str(roots[1])],env=env,check=True,capture_output=True)
 (config/'shell.qml').write_text('import QtQuick\nimport Quickshell\nimport Quickshell.Io\nimport "modules/learning" as LearningUi\nimport qs.services\nShellRoot { id:probe;property var samples:[];property bool measuring:true;LearningUi.NoesisWindow {} LearningUi.NoesisCompanion {} FrameAnimation {running:probe.measuring;onTriggered:if(frameTime>0&&probe.samples.length<1200)probe.samples.push(frameTime*1000)} IpcHandler {target:"performance";function stop():string{probe.measuring=false;return JSON.stringify(probe.samples);}} Component.onCompleted:Oasis.open() }\n')
 log=home/'qml.log'
 with log.open('w') as stream:
  started=time.perf_counter();process=subprocess.Popen([qs,'-p',str(config),'--no-color'],env=env,stdout=stream,stderr=subprocess.STDOUT)
  try:
   def ipc(target,action,*args):return subprocess.check_output([qs,'-p',str(config),'ipc','call',target,action,*args],env=env,text=True,stderr=subprocess.DEVNULL)
   def state():return json.loads(ipc('noesis-window','state'))
   deadline=time.monotonic()+10
   while True:
    try:
     initial=state()
     if initial['worker'] and initial['watch']:break
    except (subprocess.CalledProcessError,ValueError):pass
    if time.monotonic()>deadline:raise AssertionError('Native startup timeout')
    time.sleep(.05)
   print('Native launch to visible worker/watch ms:',round((time.perf_counter()-started)*1000,2))
   time.sleep(.5)
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if c['pid']==process.pid and c['title'].startswith('Noesis'))
   def key(mods,key):
    expression='hl.dsp.send_shortcut({mods='+json.dumps(mods)+',key='+json.dumps(key)+',window='+json.dumps('address:'+client['address'])+'})'
    subprocess.run(['hyprctl','dispatch',expression],check=True,capture_output=True);time.sleep(.15)
   key('CTRL','6');key('CTRL + SHIFT','k');time.sleep(.5);assert state()['collection']
   key('CTRL','k')
   for letter in 'CS reasoning':key('','space' if letter==' ' else letter)
   time.sleep(.5);assert state()['rows']==1
   key('','Down');key('','Return');time.sleep(1)
   assert state()['vault']==str(roots[0]),state();assert state()['selected']==records[0]['path'],state()
   # New capture after cross-vault opening writes only in the selected record's owner.
   key('CTRL + SHIFT','n');key('','x');key('CTRL','Return');time.sleep(.8)
   captures=command('query','--vault',str(roots[0]),'x')['records']
   assert any(row['type']=='capture' for row in captures)
   assert not any(row['type']=='capture' for row in command('query','--vault',str(roots[1]),'x')['records'])
   current=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if c['address']==client['address']);x,y=current['at'];w,h=current['size']
   subprocess.run(['grim','-g',f'{x},{y} {w}x{h}','/tmp/noesis-cross-vault-native.png'],check=True)
   outline=home/'outline.json'
   entries=[{'key':'lecture'+str(n),'kind':'unit','title':'Lecture '+str(n),'fields':{'unit_kind':'lecture'}} for n in range(6)]
   entries += [{'key':'reading'+str(n),'kind':'unit','title':'Reading '+str(n),'fields':{'unit_kind':'reading'}} for n in range(2)]
   entries += [{'key':'assignment'+str(n),'kind':'task','title':'Assignment '+str(n)} for n in range(2)]
   entries += [{'key':'project','kind':'project','title':'Course project'}]
   outline.write_text(json.dumps({'version':1,'title':'Calibration and linear algebra','entries':entries}))
   key('CTRL','2');key('CTRL + SHIFT','o')
   for letter in str(outline):
    if letter=='_':key('SHIFT','minus')
    else:key('',{'/':'slash','-':'minus','.':'period'}.get(letter,letter))
   key('CTRL','Return');time.sleep(.6);key('CTRL','Return');time.sleep(1.5)
   counts=state()['overview_counts'];assert counts['lectures']['total']==6 and counts['assignments']['total']==2 and counts['projects']['total']==1,state()
   assert counts['assignments']['reported_success']==0
   course=next(row for row in command('query','--vault',str(roots[0]),'Calibration')['records'] if row['type']=='resource')
   key('CTRL + SHIFT','r');key('ALT','Down');time.sleep(.8)
   ordering=[event for event in command('timeline','--vault',str(roots[0]),course['id'])['activities'] if event['event']=='outline-order']
   assert len(ordering)==1
   lectures=command('query','--vault',str(roots[0]),'Lecture')['records']
   assert ordering[0]['state']['unit_order'][:2]==[lectures[1]['id'],lectures[0]['id']]
   assert state()['outline_index']==1 and state()['outline_focused'],state()
   key('ALT','Up');time.sleep(.8);assert not state()['error'],state();key('CTRL + SHIFT','r')
   assert len([event for event in command('timeline','--vault',str(roots[0]),course['id'])['activities'] if event['event']=='outline-order'])==2
   print('PASS: native Arrange mode/Alt arrows preserve two immutable ordering events and consumption/assessment state')
   current=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if c['address']==client['address']);x,y=current['at'];w,h=current['size']
   subprocess.run(['grim','-g',f'{x},{y} {w}x{h}','/tmp/noesis-outline-native.png'],check=True)
   print('PASS: native outline review/create; six lectures, two readings, two assignments, project; no competence awarded')
   large=home/'large-outline.json'
   large.write_text(json.dumps({'version':1,'title':'Long outline','entries':[{'key':str(n),'kind':'unit','title':'Extended lecture '+str(n),'fields':{'unit_kind':'lecture'}} for n in range(123)]}))
   command('course-import','--vault',str(roots[0]),str(large),'--apply','--operation-id',str(uuid.uuid4()))
   key('CTRL','k')
   for letter in 'Long outline':key('','space' if letter==' ' else letter)
   time.sleep(.7);key('','Down');key('','Return');time.sleep(.8)
   assert state()['outline_rows']==50,state()
   key('CTRL + SHIFT','Next');time.sleep(.6);assert state()['outline_rows']==100,state()
   key('CTRL + SHIFT','Next');time.sleep(.6);assert state()['outline_rows']==123,state()
   print('PASS: native course outline pages append 50 → 100 → 123 lessons')
   key('CTRL + SHIFT','o')
   for letter in str(large):
    if letter=='_':key('SHIFT','minus')
    else:key('',{'/':'slash','-':'minus','.':'period'}.get(letter,letter))
   key('CTRL','Return');time.sleep(.6);key('CTRL','Return')
   deadline=time.monotonic()+20
   while state()['outline_import_open'] or state()['working']:
    assert time.monotonic()<deadline,state();time.sleep(.1)
   time.sleep(.3)
   assert state()['overview_counts']['lectures']['total']==123,state()
   assert not state()['error'],state()
   print('PASS: native existing-course import retry retains 123 lessons without duplicating the course or units')
   # Actual focused-window shortcut exercises the same product mode control.
   for expected in ('workspace','tiled','normal'):
    key('CTRL + ALT','m');time.sleep(.6);assert state()['presentation']==expected,state()
    current=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if c['address']==client['address'])
    print('Mode:',expected,{'width':state()['width'],'height':state()['height'],'floating':current['floating'],'fullscreen':current['fullscreen']})
    assert (current['fullscreen']==1)==(expected=='workspace'),current
    assert current['floating']==(expected!='tiled'),current
    assert current['at'][0]>=0 and current['at'][1]>=44,current
    assert current['at'][0]+current['size'][0]<=1920 and current['at'][1]+current['size'][1]<=1080,current
   frames=json.loads(ipc('performance','stop'));frames.sort()
   print('Instrumented Qt animation-frame p95 ms:',round(frames[int(.95*(len(frames)-1))],3),'samples:',len(frames))
   idle_seconds=int(os.environ.get('NOESIS_IDLE_SECONDS','0'))
   if idle_seconds:
    def descendants(pid):
     result=[pid]
     try:
      for child in Path(f'/proc/{pid}/task/{pid}/children').read_text().split():result+=descendants(int(child))
     except FileNotFoundError:pass
     return result
    def cpu_ticks(pid):
     values=Path(f'/proc/{pid}/stat').read_text().rsplit(')',1)[1].split()
     return int(values[11])+int(values[12])
    ids=descendants(process.pid);before={pid:cpu_ticks(pid) for pid in ids};idle_start=time.monotonic()
    while time.monotonic()-idle_start<idle_seconds:time.sleep(min(5,idle_seconds-(time.monotonic()-idle_start)))
    elapsed=time.monotonic()-idle_start
    cpu=100*sum(cpu_ticks(pid)-before[pid] for pid in ids)/os.sysconf('SC_CLK_TCK')/elapsed
    print('Open idle average percent of one CPU core:',round(cpu,4),'seconds:',round(elapsed,1),'processes:',len(ids))
    assert cpu<.1,(cpu,ids)
   memory=[];warm=[]
   def rss():return int(next(line.split()[1] for line in Path('/proc/'+str(process.pid)+'/status').read_text().splitlines() if line.startswith('VmRSS:')))
   for _ in range(12):
    ipc('noesis','close');time.sleep(.1);assert not state()['worker'] and not state()['watch']
    opened=time.perf_counter();ipc('noesis','open')
    deadline=time.monotonic()+5
    while not state()['worker']:
     assert time.monotonic()<deadline;time.sleep(.02)
    warm.append((time.perf_counter()-opened)*1000);time.sleep(.15);memory.append(rss())
   print('Warm-open p95 ms:',round(sorted(warm)[-1],2),'isolated shell RSS KiB over 12 lifecycles:',memory)
   ipc('noesis','close');time.sleep(.4);assert not state()['worker'] and not state()['watch']
   print('PASS: actual keyboard cross-vault search/open/capture; owning vault only; tiled/normal; closed worker/watch')
  finally:
   subprocess.run([qs,'-p',str(config),'kill'],env=env,capture_output=True);process.terminate()
   try:process.wait(timeout=5)
   except subprocess.TimeoutExpired:process.kill();process.wait()
   text=log.read_text();print(text)
  assert 'WARN' not in text and 'ERROR' not in text,text
