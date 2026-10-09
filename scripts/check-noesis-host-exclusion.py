#!/usr/bin/env python3
"""Rollback host exclusion in one disposable home; never restarts live Wrayth."""
import json,subprocess,time,uuid
from noesis_native_fixture import Fixture,QS
f=Fixture();other=None
try:
 f.start();first=f.hello()['instance']['token']
 embedded=f.home/'.config/quickshell/wrayth'
 (embedded/'shell.qml').write_text('//@ pragma AppId org.fh1m.Noesis.Rollback'+uuid.uuid4().hex+'\n//@ pragma ShellId rollback'+uuid.uuid4().hex+'\nimport QtQuick\nimport Quickshell\nimport "noesis-ui" as UI\nShellRoot { UI.NoesisWindow {} Component.onCompleted:UI.NoesisController.open() }\n')
 def start_embedded():return subprocess.Popen([QS,'-p',str(embedded),'--no-color'],env=f.env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 def hello():
  r=subprocess.run([QS,'-p',str(embedded),'ipc','call','noesis','hello'],env=f.env,capture_output=True,text=True)
  try:return json.loads(r.stdout)
  except ValueError:return None
 def wait(predicate):
  end=time.monotonic()+8
  while time.monotonic()<end:
   value=hello()
   if value and predicate(value):return value
   time.sleep(.1)
  raise AssertionError('Rollback host state timed out')
 other=start_embedded();wait(lambda s:not s['host_ready']);time.sleep(.5)
 assert not hello()['visible'] and f.hello()['instance']['token']==first
 other.terminate();other.wait(timeout=5);other=None
 f.exit();other=start_embedded();wait(lambda s:s['host_ready'] and s['visible'])
 token=hello()['instance']['token']
 routed=subprocess.run([str(f.home/'.local/bin/sensei-learn'),'window'],env=f.env,capture_output=True,text=True,timeout=15)
 assert routed.returncode==0,(routed.stdout,routed.stderr)
 assert hello()['instance']['token']==token and hello()['visible']
 duplicate=subprocess.run([QS,'-p',str(f.config),'--no-color'],env=f.env,capture_output=True,text=True,timeout=8)
 assert duplicate.returncode==0 and hello()['host_ready'] and hello()['visible']
 print('PASS: standalone excludes rollback; graceful exit releases lease; default launcher routes active rollback; rollback excludes standalone')
finally:
 if other:other.terminate();other.wait(timeout=5)
 f.stop()
