#!/usr/bin/env python3
"""Tests the Wrayth bridge/companion in an isolated shell, not a live Wrayth restart."""
from pathlib import Path
import json,subprocess,time,uuid,shutil
from noesis_native_fixture import Fixture,QS
f=Fixture();bridge=None;log=None
try:
 f.start();f.wait(lambda s:bool(f.preferences()['context'].get('vault_id')))
 config=f.home/'.config/quickshell/bridge-fixture';(config/'services').mkdir(parents=True);(config/'modules/learning').mkdir(parents=True)
 source=f.home/'.config/quickshell/wrayth'
 for name in ['services/NoesisBridge.qml','modules/learning/NoesisCompanion.qml']:shutil.copy2(source/name,config/name)
 (config/'services/ShellState.qml').write_text('pragma Singleton\nimport QtQuick\nimport Quickshell\nSingleton {property string dropdown:""}\n')
 (config/'noesis-ui').symlink_to('../../../.local/share/sensei-learning/ui',target_is_directory=True)
 (config/'shell.qml').write_text('//@ pragma AppId org.fh1m.Noesis.BridgeFixture\n//@ pragma ShellId noesis-bridge-fixture-'+uuid.uuid4().hex+'\nimport QtQuick\nimport Quickshell\nimport "modules/learning" as Ui\nShellRoot {Ui.NoesisCompanion {}}\n')
 def start_bridge():
  global bridge,log
  log=(f.home/'bridge.log').open('a');bridge=subprocess.Popen([QS,'-p',str(config),'--no-color'],env=f.env,stdout=log,stderr=log)
 def state():
  result=subprocess.run([QS,'-p',str(config),'ipc','call','noesis-bridge','state'],env=f.env,text=True,capture_output=True,timeout=5)
  return json.loads(result.stdout)
 def wait(predicate):
  deadline=time.monotonic()+8
  while time.monotonic()<deadline:
   try:
    value=state()
    if predicate(value):return value
   except ValueError:pass
   time.sleep(.1)
  raise AssertionError((f.home/'bridge.log').read_text()[-3000:])
 start_bridge();wait(lambda s:s['live'] and s['context']['id']==f.record_id)
 token=f.hello()['instance']['token'];bridge.terminate();bridge.wait(timeout=5);log.close();assert f.hello()['instance']['token']==token
 start_bridge();wait(lambda s:s['live']);f.stop();wait(lambda s:not s['live']);assert bridge.poll() is None
 f.start();wait(lambda s:s['live']);assert f.hello()['instance']['token']!=token
 projection=f.home/'.local/state/sensei-learning/companion.json';value=json.loads(projection.read_text());value['version']=999;projection.write_text(json.dumps(value));wait(lambda s:not s['live'])
 value['version']=1;value['context']['body']='PRIVATE BODY';value['context']['drafts']={'private':'DRAFT'};projection.write_text(json.dumps(value))
 clean=wait(lambda s:s['live']);assert 'body' not in clean['context'] and 'drafts' not in clean['context']
 value['instance']['start_ticks']='invalid';projection.write_text(json.dumps(value));wait(lambda s:not s['live'])
 print('PASS: bridge restart leaves application alive; application restart leaves bridge alive; stale/unsupported projections clear context',flush=True)
 print('This checks the actual bridge/companion source in a minimal disposable shell; full/live Wrayth restart remains a separate gate.',flush=True)
finally:
 if bridge and bridge.poll() is None:bridge.terminate();bridge.wait(timeout=5)
 if log:log.close()
 f.stop()
