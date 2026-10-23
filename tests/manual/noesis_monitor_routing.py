"""Live acceptance: opens a new Noesis window and verifies compositor monitor ID.
Run explicitly in the logged-in desktop; the new learning view stays open.
"""
import os,subprocess,json,time
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
monitors=json.loads(subprocess.check_output(['hyprctl','monitors','-j'],env=env,text=True));target=next((m for m in monitors if m['name'] not in ('eDP-1','DP-2')),monitors[0])
before={c['address'] for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],env=env,text=True))}
r=subprocess.run([str(Path.home()/'.local/bin/noesis'),'window','--new','--monitor',target['name']],env=env,text=True,capture_output=True,timeout=30);r.check_returncode()
for _ in range(30):
 clients=json.loads(subprocess.check_output(['hyprctl','clients','-j'],env=env,text=True));rows=[c for c in clients if c['address'] not in before and 'noesis' in c.get('class','').lower()]
 if rows and all(c['monitor']==target['id'] for c in rows):break
 time.sleep(.1)
print(json.dumps({'requested_monitor':target['name'],'requested_id':target['id'],'actual':[r['monitor'] for r in rows],'verified':bool(rows) and all(c['monitor']==target['id'] for c in rows)}))
assert rows and all(c['monitor']==target['id'] for c in rows)
