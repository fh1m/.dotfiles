#!/usr/bin/env python3
"""Independent/embedded parity on disposable homes; no personal writes/restarts."""
from pathlib import Path
import importlib.util,json,os,subprocess,tempfile,time,sys
repo=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('installer',repo/'scripts/install.py');installer=importlib.util.module_from_spec(spec);spec.loader.exec_module(installer)
qs=str(Path.home()/'.local/opt/sensei-quickshell/bin/qs')
evidence=Path('/tmp/noesis-host-evidence');evidence.mkdir(exist_ok=True)
for host in ('embedded','standalone'):
 home=Path(tempfile.mkdtemp(prefix='noesis-parity-'+host+'-'));installer.install(home,True)
 assert not installer.install(home,False)['changed']
 vault=home/'vault';(vault/'System').mkdir(parents=True)
 (vault/'System/System.json').write_text(json.dumps({'directories':['Notes'],'noesis_schema':2,'vault_id':'22222222-2222-4222-8222-222222222222'}))
 (vault/'problem.md').write_text('---\nid: 11111111-1111-4111-8111-111111111111\nnoesis_schema: 2\ntype: task\ntitle: Reconstruct a linear transformation without losing the source context\n---\n## Problem statement\n\nExplain why the columns (1, 0) and (2, 0) cannot span the plane. Predict the effect of replacing the second column with (0, 1).\n\n## Reference\n\nThe first two vectors are dependent. The changed pair is a basis.\n')
 (home/'.config/sensei-learning').mkdir(exist_ok=True)
 (home/'.config/sensei-learning/config.json').write_text(json.dumps({'active_vault':str(vault)}))
 env=dict(os.environ,HOME=str(home),XDG_CONFIG_HOME=str(home/'.config'),XDG_CACHE_HOME=str(home/'.cache'),XDG_STATE_HOME=str(home/'.local/state'),NOESIS_WINDOW_MODE='normal')
 if host=='embedded':
  config=home/'.config/quickshell/wrayth'
  (config/'shell.qml').write_text('//@ pragma AppId org.fh1m.Noesis.ParityEmbedded\n//@ pragma ShellId noesis-parity-embedded\nimport QtQuick\nimport Quickshell\nimport "modules/learning" as LearningUi\nimport "noesis-ui" as Shared\nShellRoot { LearningUi.NoesisWindow {} Component.onCompleted:Shared.NoesisController.open() }\n')
 else:
  config=home/'.config/quickshell/noesis'
  p=config/'shell.qml';p.write_text(p.read_text().replace('org.fh1m.Noesis','org.fh1m.Noesis.ParityStandalone'))
 def ipc(target,method,*args):
  result=subprocess.run([qs,'-p',str(config),'ipc','call',target,method,*args],env=env,text=True,capture_output=True,timeout=5)
  if result.returncode:raise RuntimeError(result.stderr)
  return result.stdout.strip()
 def state():return json.loads(ipc('noesis-window','state'))
 def wait(predicate,timeout=8):
  deadline=time.monotonic()+timeout
  while time.monotonic()<deadline:
   try:
    value=state()
    if predicate(value):return value
   except (ValueError,RuntimeError):pass
   time.sleep(.1)
  raise RuntimeError('State wait timed out: '+(evidence/(host+'.log')).read_text()[-5000:])
 with (evidence/(host+'.log')).open('w') as log:
  process=subprocess.Popen([qs,'-p',str(config),'--no-color'],env=env,stdout=log,stderr=log)
  try:
   wait(lambda s:s['visible'] and s['worker'])
   ipc('noesis-window','section','Practice');wait(lambda s:s['section']=='Practice' and s['rows']==1)
   ipc('noesis-window','select','problem.md');data=wait(lambda s:s['selected']=='problem.md' and s['preview_length']>0 and not s['mode_pending'])
   assert data['reference_hidden'] and data['context_tab']=='Work'
   clients=json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True));client=next(c for c in clients if c['pid']==process.pid and c['title'].startswith('Noesis'))
   subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+json.dumps('address:'+client['address'])+'})'],check=True,capture_output=True)
   def key(mods,key):
    subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods='+json.dumps(mods)+',key='+json.dumps(key)+',window='+json.dumps('address:'+client['address'])+'})'],check=True,capture_output=True);time.sleep(.15)
   key('CTRL','Return');wait(lambda s:bool(s['attempt']))
   key('','a');time.sleep(.7)
   assert state()['draft_length']==1
   key('CTRL','k');assert state()['search_focused']
   key('CTRL + SHIFT','n');assert state()['capture_open'] and state()['capture_focused']
   key('','Escape');assert not state()['capture_open'];time.sleep(.5)
   clients=json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True));client=next(c for c in clients if c['pid']==process.pid and c['title'].startswith('Noesis'))
   (evidence/(host+'-geometry.json')).write_text(json.dumps(client,indent=2))
   monitor=next(m for m in json.loads(subprocess.check_output(['hyprctl','monitors','-j'],text=True)) if m['id']==client['monitor'])
   x,y=client['at'];width,height=client['size']
   subprocess.run(['grim','-g',f'{x},{y} {width}x{height}',str(evidence/(host+'.png'))],check=True)
   ipc('noesis','close');data=wait(lambda s:not s['visible'] and not s['worker'] and not s['watch'])
   ipc('noesis','open');data=wait(lambda s:s['visible'] and s['worker'] and s['selected']=='problem.md' and s['draft_length']==1)
   (evidence/(host+'.json')).write_text(json.dumps(data,indent=2))
   print(host,'PASS: load, protected statement, search/capture/Escape, hide/worker stop, resume; home',home,flush=True)
  finally:
   process.terminate();process.wait(timeout=5)
 text=(evidence/(host+'.log')).read_text()
 failures=[line for line in text.splitlines() if ('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line]
 if failures:raise RuntimeError('\n'.join(failures))
print('Evidence:',evidence)
