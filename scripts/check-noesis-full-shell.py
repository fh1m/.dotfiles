#!/usr/bin/env python3
"""Full rendered Wrayth integration in disposable processes; leaves live shell alone."""
import json,os,signal,subprocess,time,uuid
from noesis_native_fixture import Fixture,QS
f=Fixture();shell=None
try:
 f.start();token=f.hello()['instance']['token'];config=f.home/'.config/quickshell/wrayth'
 entry=config/'shell.qml';entry.write_text('//@ pragma AppId org.fh1m.Wrayth.Acceptance'+uuid.uuid4().hex+'\n//@ pragma ShellId wrayth-acceptance'+uuid.uuid4().hex+'\n'+entry.read_text())
 log=(f.home/'full-shell.log').open('a')
 def start():return subprocess.Popen([QS,'-p',str(config),'--no-color'],env=f.env,stdout=log,stderr=log,start_new_session=True)
 def bridge():
  r=subprocess.run([QS,'-p',str(config),'ipc','call','noesis-bridge','state'],env=f.env,capture_output=True,text=True)
  try:return json.loads(r.stdout)
  except ValueError:return None
 def wait():
  deadline=time.monotonic()+12
  while time.monotonic()<deadline:
   state=bridge()
   if state and state.get('live'):return state
   if shell.poll() is not None:break
   time.sleep(.1)
  raise AssertionError((f.home/'full-shell.log').read_text()[-5000:])
 shell=start();wait();assert f.hello()['instance']['token']==token
 os.killpg(shell.pid,signal.SIGTERM);shell.wait(timeout=5)
 assert f.hello()['instance']['token']==token
 shell=start();wait();f.exit();time.sleep(6)
 assert shell.poll() is None and not bridge()['live']
 f.start();wait();assert shell.poll() is None
 print('PASS: full Wrayth bridge loads; shell restart preserves Noesis; Noesis restart preserves shell')
 print('Diagnostics:',f.home/'full-shell.log')
finally:
 if shell and shell.poll() is None:os.killpg(shell.pid,signal.SIGTERM);shell.wait(timeout=5)
 f.stop()
