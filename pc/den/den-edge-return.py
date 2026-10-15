#!/usr/bin/env python3
"""Align a Den edge crossing to the physical laptop/upper-left/PC arrangement."""
import json, pathlib, shlex, subprocess, sys
mode=sys.argv[1]
if mode not in ('1','2','enter-top','enter-right'):raise SystemExit('Unknown edge')
sys.path.insert(0,str(pathlib.Path.home()/'.local/share/sensei'))
from den_layout import roles as display_roles
state=pathlib.Path.home()/'.local/state/homie-control'
ssh=['ssh','-F',str(state/'client.conf'),'homie']
def query(args):return json.loads(subprocess.check_output(['hyprctl','-i','0',*args],timeout=2))
remote_query="python3 -c 'import subprocess,json; print(json.dumps({\"monitors\":json.loads(subprocess.check_output([\"hyprctl\",\"-i\",\"0\",\"monitors\",\"-j\"])),\"cursor\":json.loads(subprocess.check_output([\"hyprctl\",\"-i\",\"0\",\"cursorpos\",\"-j\"]))}))'"
try:
    monitors=query(['monitors','-j'])
    target=display_roles(monitors)['main' if mode in ('1','enter-top') else 'upper']
    peer=json.loads(subprocess.check_output(ssh+[remote_query],timeout=4))
    pc=display_roles(peer['monitors'],host='homie')['main']
    def size(m):return m['width']/m['scale'],m['height']/m['scale']
    tw,th=size(target);pw,ph=size(pc)
    def clamp(value,maximum):return max(3,min(maximum-4,value))
    if mode=='1':
        x=target['x']+clamp((peer['cursor']['x']-pc['x'])/pw*tw,tw);y=target['y']+3
    elif mode=='2':
        x=target['x']+tw-4;y=target['y']+clamp((peer['cursor']['y']-pc['y'])/ph*th,th)
    else:
        cur=query(['cursorpos','-j'])
        if mode=='enter-top':x=pc['x']+clamp((cur['x']-target['x'])/tw*pw,pw);y=pc['y']+ph-4
        else:x=pc['x']+3;y=pc['y']+clamp((cur['y']-target['y'])/th*ph,ph)
    dispatch=f'hl.dsp.cursor.move({{x={round(x)},y={round(y)}}})'
    if mode.startswith('enter-'):
        subprocess.run(ssh+['hyprctl -i 0 dispatch '+shlex.quote(dispatch)],stdout=subprocess.DEVNULL,check=True,timeout=4)
        subprocess.run(ssh+['python3 /home/fh1m/.local/state/homie-control/den-arm-return.py'],stdout=subprocess.DEVNULL,check=True,timeout=4)
        subprocess.run(ssh+['python3 /home/fh1m/.local/state/homie-control/den-cursor.py show-local'],stdout=subprocess.DEVNULL,timeout=4)
    else:
        subprocess.run(['hyprctl','-i','0','dispatch',dispatch],stdout=subprocess.DEVNULL,check=True,timeout=2)
        subprocess.run(['python3',str(state/'den-cursor.py'),'show-local'],stdout=subprocess.DEVNULL,timeout=2)
except (StopIteration,ValueError,KeyError,subprocess.SubprocessError):
    # Fail open locally if placement/readiness fails. Never leave capture latched.
    if mode.startswith('enter-'):
        subprocess.run(['python3',str(state/'den-cursor.py'),'recover'],timeout=2)
