#!/usr/bin/env python3
"""Serialize crossings and reject stale entry hooks after a release/new entry."""
import fcntl,json,os,pathlib,shlex,subprocess,sys
sys.path.insert(0,str(pathlib.Path.home()/'.local/share/sensei'))
from den_layout import roles as display_roles
from den_geometry import load as geometry,enter_ratio,return_coordinate
STATE=pathlib.Path.home()/'.local/state/homie-control'

def current_entry(root,token):
    try:return bool(token) and (root/'input/active').read_text().strip()=='1' and (root/'input/active.session').read_text().strip()==token
    except OSError:return False

def current_return(root,token):
    try:return bool(token) and (root/'input/active').read_text().strip()!='1' and (root/'input/active.session').read_text().strip()==token
    except OSError:return False

def clear_return(root,token):
    guard=root/'input/active.returning'
    try:
        if guard.read_text().strip()==token:guard.unlink(missing_ok=True)
    except OSError:pass

def main():
    mode=sys.argv[1]
    if mode not in ('1','2','enter-top','enter-right'):raise ValueError('Unknown edge')
    entering=mode.startswith('enter-');token=os.environ.get('DEN_CAPTURE_GENERATION' if entering else 'DEN_RETURN_GENERATION','')
    ssh=['ssh','-n','-F',str(STATE/'client.conf'),'homie']
    def query(args):return json.loads(subprocess.check_output(['hyprctl','-i','0',*args],timeout=1))
    # Drop stale entries before contending for placement; never queue an old
    # generation behind a slow SSH operation. Native capture holds one route.
    if entering and not current_entry(STATE,token):return
    with (STATE/'input/edge-placement.lock').open('a') as lock:
        try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:
            if not entering:
                clear_return(STATE,token)
                if current_return(STATE,token):subprocess.run(['python3',str(STATE/'den-cursor.py'),'recover'],timeout=8)
            return
        if entering and not current_entry(STATE,token):return
        if not entering and not current_return(STATE,token):clear_return(STATE,token);return
        try:
            monitors=query(['monitors','-j']);roles=display_roles(monitors)
            target=roles['main'] if mode in ('1','enter-top') else roles['upper'] if entering else roles.get('upper',roles['main'])
            tw,th=target['width']/target['scale'],target['height']/target['scale']
            if entering:
                cur=query(['cursorpos','-j'])
                ratio=enter_ratio(geometry(),cur['x'] if mode=='enter-top' else cur['y'],'x' if mode=='enter-top' else 'y')
                args=['python3',str(STATE/'den-entry-place.py'),mode,str(max(0,min(1,ratio))),token]
                if not current_entry(STATE,token):return
                subprocess.run(ssh+[shlex.join(args)],check=True,timeout=2.5,stdout=subprocess.DEVNULL,stdin=subprocess.DEVNULL)
            else:
                code='import json,subprocess;print(json.dumps({"cursor":json.loads(subprocess.check_output(["hyprctl","-i","0","cursorpos","-j"])),"monitors":json.loads(subprocess.check_output(["hyprctl","-i","0","monitors","-j"]))}))'
                peer=json.loads(subprocess.check_output(ssh+[shlex.join(['python3','-c',code])],timeout=2))
                pos=peer['cursor'];pc=display_roles(peer['monitors'],host='homie')['main']
                pw,ph=pc['width']/pc['scale'],pc['height']/pc['scale']
                clamp=lambda v,limit:max(3,min(limit-4,v))
                x=target['x']+(clamp(return_coordinate(geometry(),pos['x']-pc['x'],'x')-target['x'],tw) if mode=='1' else tw-4)
                y=target['y']+(3 if mode=='1' else clamp(return_coordinate(geometry(),pos['y']-pc['y'],'y')-target['y'],th))
                if not current_return(STATE,token):return
                subprocess.run(['hyprctl','-i','0','dispatch',f'hl.dsp.cursor.move({{x={round(x)},y={round(y)}}})'],check=True,stdout=subprocess.DEVNULL,timeout=1)
        except (OSError,StopIteration,ValueError,KeyError,subprocess.SubprocessError):
            # Only this failed, still-current entry may release capture. An old
            # helper must never stop the new session or warp its cursor.
            if (entering and current_entry(STATE,token)) or (not entering and current_return(STATE,token)):
                subprocess.run(['python3',str(STATE/'den-cursor.py'),'recover'],timeout=8)
        finally:
            if not entering:clear_return(STATE,token)

if __name__=='__main__':main()
