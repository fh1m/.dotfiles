"""Live regression: reopen Noesis on an invoking display, then verify focus.
Opens the existing app; run explicitly in a logged-in Hyprland session.
"""
import os,json,subprocess
from pathlib import Path
env=dict(os.environ,XDG_RUNTIME_DIR='/run/user/1000',DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1000/bus',WAYLAND_DISPLAY='wayland-1')
for p in Path('/proc').iterdir():
 try:
  if not p.name.isdigit() or (p/'comm').read_text().strip() not in ('Hyprland','quickshell','qs'):continue
  for v in (p/'environ').read_bytes().split(b'\0'):
   k,_,val=v.partition(b'=')
   if k.decode(errors='ignore') in ('HYPRLAND_INSTANCE_SIGNATURE','WAYLAND_DISPLAY'):env[k.decode()]=val.decode()
  if env.get('HYPRLAND_INSTANCE_SIGNATURE'):break
 except OSError:pass
def call(args):
 r=subprocess.run(args,env=env,text=True,capture_output=True,timeout=20)
 try:return json.loads(r.stdout)
 except ValueError:return {'code':r.returncode,'out':r.stdout[-1000:],'error':r.stderr[-1000:]}
qs=str(Path.home()/'.local/opt/sensei-quickshell/bin/qs')

import time
monitors=call(['hyprctl','monitors','-j'])
target=next((m for m in monitors if m['name']=='HDMI-A-1'),next(m for m in monitors if m.get('focused')))
subprocess.run([str(Path.home()/'.local/bin/noesis'),'window','--monitor','eDP-1'],env=env,capture_output=True,check=True)
time.sleep(.6)
workspace=103 if target['name']=='HDMI-A-1' else 3
call(['hyprctl','dispatch','hl.dsp.focus({workspace="'+str(workspace)+'"})'])
result=call([qs,'-p',str(Path.home()/'.config/quickshell/sensei'),'ipc','call','oasis','open'])
for _ in range(40):
 active=call(['hyprctl','activewindow','-j'])
 if active.get('class')=='org.fh1m.Noesis' and active.get('monitor')==target['id'] and active.get('workspace',{}).get('id')==workspace:break
 time.sleep(.1)
verified=active.get('class')=='org.fh1m.Noesis' and active.get('monitor')==target['id'] and active.get('workspace',{}).get('id')==workspace
print(json.dumps({'reopen_ack':result.get('status'),'expected_monitor':target['name'],'expected_workspace':workspace,'actual_class':active.get('class'),'actual_monitor':active.get('monitor'),'actual_workspace':active.get('workspace',{}).get('id'),'focused_after_routing':verified}))
assert verified,'Reopen left focus on a different/empty workspace'

bridge=[qs,'-p',str(Path.home()/'.config/quickshell/sensei'),'ipc','call','noesis-bridge','state']
def indicated(expected):
 for _ in range(30):
  if call(bridge).get('focused') is expected:return True
  time.sleep(.1)
 return False
assert indicated(True),'Underline should indicate focused Noesis'
other=next(c for c in call(['hyprctl','clients','-j']) if c.get('class')!='org.fh1m.Noesis' and not c.get('hidden'))
call(['hyprctl','dispatch','hl.dsp.focus({window="address:'+other['address']+'"})'])
assert indicated(False),'Underline should clear when another application is focused'
call([qs,'-p',str(Path.home()/'.config/quickshell/sensei'),'ipc','call','oasis','open'])
assert indicated(True),'Reopen should restore focus indication'
print(json.dumps({'underline_follows_actual_focus':True}))
