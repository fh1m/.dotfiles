#!/usr/bin/env python3
"""Explicit live failure tests: owned services only, no text or clicks."""
import argparse,json,os,pathlib,shlex,subprocess,time
ROOT=pathlib.Path.home()/'.local/state/homie-control'
SSH=['ssh','-n','-F',str(ROOT/'client.conf'),'homie']
def run(args,**kw):return subprocess.run(args,check=True,capture_output=True,text=True,timeout=8,**kw)
def remote(cmd):return run([*SSH,cmd]).stdout
def hypr(*a):return run(['hyprctl','-i','0',*a]).stdout
def warp(x,y):hypr('dispatch',f'hl.dsp.cursor.move({{x={x},y={y}}})')
def main():
    i=json.loads(hypr('instances','-j'))[0];env=dict(os.environ,WAYLAND_DISPLAY=i['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=i['instance'])
    def motion(dx,dy):run([str(ROOT/'input-test/test'),'motion',str(dx),str(dy)],env=env)
    def start():
        remote('systemctl --user start den-input');run([str(pathlib.Path.home()/'.local/bin/den-control'),'start'])
    def enter():
        for _ in range(12):
            warp(960,40);warp(960,0);motion(0,-1);time.sleep(.1)
            if remote('cat ~/.local/state/homie-control/input/return-armed').strip()=='1':return
        raise AssertionError('Receiver did not arm')
    def capture():return (ROOT/'input/active').read_text().strip()=='1'
    results=[]
    def expiry():
        run(['systemd-run','--user','--unit=den-failure-expiry','--on-active=15s','--collect',str(pathlib.Path.home()/'.local/bin/den-control'),'home'])
    def clear():subprocess.run(['systemctl','--user','stop','den-failure-expiry.timer'],capture_output=True)
    try:
        start();expiry();enter()
        token=(ROOT/'input/active.session').read_text().strip()
        run(['python3',str(ROOT/'den-edge-return.py'),'enter-top'],env=dict(os.environ,DEN_CAPTURE_GENERATION='0:0:1'))
        assert capture(),'Stale helper stopped new capture'
        results.append({'case':'stale entry helper','passed':True});print('Stale helper preserves new capture: PASS',flush=True)
        remote('systemctl --user stop den-input');started=time.monotonic()
        while capture() and time.monotonic()-started<5:time.sleep(.05)
        assert not capture(),'Receiver stop did not release capture within 5 seconds'
        elapsed=time.monotonic()-started;results.append({'case':'receiver stopped','passed':True,'releaseSeconds':round(elapsed,3)});print('Receiver stop releases capture:',round(elapsed,3),'seconds',flush=True)
        clear();start();expiry();enter()
        remote('systemctl --user restart den-cursor');time.sleep(.4)
        remote("hyprctl -i 0 dispatch 'hl.dsp.cursor.move({x=2,y=540})'")
        motion(-12,0)
        started=time.monotonic()
        while capture() and time.monotonic()-started<3:time.sleep(.05)
        assert not capture(),'Receiver cursor service restart broke return'
        results.append({'case':'receiver watcher restart','passed':True});print('Return works after cursor-service restart: PASS',flush=True)
        clear();start();expiry();enter()
        run([str(ROOT/'input-test/test'),'release'],env=env);time.sleep(.2)
        assert not capture(),'Native emergency chord failed'
        results.append({'case':'native release chord','passed':True});print('Native Ctrl+Alt+Esc releases capture: PASS',flush=True)
    finally:
        run([str(pathlib.Path.home()/'.local/bin/den-control'),'home']);clear()
        remote('systemctl --user start den-input')
        (ROOT/'failure-acceptance.json').write_text(json.dumps(results,indent=2))
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--live',action='store_true');a=p.parse_args()
    if not a.live:p.error('Refusing live service/cursor tests without --live')
    main()
