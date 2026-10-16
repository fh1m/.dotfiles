#!/usr/bin/env python3
"""One bounded receiver-side placement/arming transaction; no input capture."""
import json,os,pathlib,re,subprocess,sys,time
sys.path.insert(0,str(pathlib.Path.home()/'.local/share/sensei'))
from den_layout import roles
ROOT=pathlib.Path.home()/'.local/state/homie-control'

def newer(token,previous):
    if not re.fullmatch(r'\d+:\d+:\d+',token):raise ValueError('Invalid entry token')
    if not previous:return True
    if not re.fullmatch(r'\d+:\d+:\d+',previous):return False
    return int(token.rsplit(':',1)[1])>int(previous.rsplit(':',1)[1])

def main():
    mode,ratio,token=sys.argv[1:]
    ratio=float(ratio)
    if mode not in ('enter-top','enter-right') or not 0<=ratio<=1:raise ValueError('Invalid entry')
    marker=ROOT/'input/placed-generation'
    old=marker.read_text().strip() if marker.exists() else ''
    if not newer(token,old):return
    marker.write_text(token)
    def current():return marker.read_text().strip()==token
    monitors=json.loads(subprocess.check_output(['hyprctl','-i','0','monitors','-j'],timeout=1))
    m=roles(monitors,host='homie')['main'];w,h=m['width']/m['scale'],m['height']/m['scale']
    clamp=lambda v,limit:max(10,min(limit-11,v))
    x=m['x']+(clamp(ratio*w,w) if mode=='enter-top' else 10)
    y=m['y']+(h-11 if mode=='enter-top' else clamp(ratio*h,h))
    if not current():return
    subprocess.run(['hyprctl','-i','0','dispatch',f'hl.dsp.cursor.move({{x={round(x)},y={round(y)}}})'],check=True,stdout=subprocess.DEVNULL,timeout=1)
    # No repeated warp after the initial placement: subsequent motion is the user's.
    for _ in range(20):
        if not current():return
        subprocess.run([str(ROOT/'bin/lan-mouse'),'cli','arm-return'],check=True,stdout=subprocess.DEVNULL,timeout=.5)
        if (ROOT/'input/return-armed').read_text().strip()=='1':
            return
        time.sleep(.025)
    raise RuntimeError('Receiver return path did not arm')

if __name__=='__main__':main()
