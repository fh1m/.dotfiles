#!/usr/bin/env python3
"""Read-only Homie desktop acceptance harness. Private results stay local."""
import json, os, subprocess
from pathlib import Path
h=Path.home()
i=json.loads(subprocess.check_output(['hyprctl','-i','0','instances','-j']))[0]
e=dict(os.environ,HYPRLAND_INSTANCE_SIGNATURE=i['instance'],WAYLAND_DISPLAY=i['wl_socket'],XDG_RUNTIME_DIR='/run/user/'+str(os.getuid()),DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/'+str(os.getuid())+'/bus')
def run(a):return subprocess.check_output(a,env=e,text=True,stderr=subprocess.PIPE,timeout=15)
def ipc(t,m,*args):return json.loads(run(['qs','-c','sensei','ipc','call',t,m,*args]))
checks={}
assert not run(['hyprctl','configerrors']).strip();checks['hyprland_config']=True
monitors=json.loads(run(['hyprctl','monitors','-j']));main=next(m for m in monitors if m['focused'])
assert main['scale']==1 and main['width']==1920 and main['refreshRate']>74;checks['native_display']=True
state=ipc('workspaces','state');assert len(state['slots'])==7;checks['seven_workspaces']=True
rail=ipc('workspace-rail-'+main['name'],'state');assert rail['active']>=0;checks['animated_workspace_rail']=True
for target in ['bar-controls-'+main['name'],'bar-controls-bottom-'+main['name']]:assert isinstance(ipc(target,'state'),dict)
checks['separate_bar_controls']=True
assert not ipc('displays','state')['externalScreens'];checks['primary_not_laptop_external']=True
assert (h/'.config/quickshell/sensei/noesis-ui').resolve().is_dir();checks['noesis_dependency']=True
assert run(['systemctl','is-enabled','sshd']).strip()=='enabled';checks['ssh_startup']=True
assert (h/'.config/quickshell/sensei').is_dir() and (h/'.config/hypr/hypr-sensei.lua').exists();checks['canonical_namespace']=True
assert 'NVIDIA' in run(['nvidia-smi','--query-gpu=name','--format=csv,noheader']);checks['nvidia_renderer']=True
assert (h/'.local/bin/sensei-terminal').exists();checks['alacritty_launcher']=True
print(json.dumps({'host':'homie','checks':checks},indent=2))
