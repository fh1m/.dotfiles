#!/usr/bin/env python3
"""Supervised live Den acceptance; importing this module never controls a desktop."""
def main(cycles=3,with_input=False):
    import subprocess,json,time,shlex
    from pathlib import Path
    root=Path.home()/".local/state/homie-control"
    ssh=["ssh","-n","-F",str(root/"client.conf"),"homie"]
    def remote(command):return subprocess.check_output(ssh+[command],timeout=3).decode()
    def hypr(*args):return subprocess.check_output(["hyprctl","-i","0",*args],timeout=2).decode()
    def warp(x,y):hypr("dispatch",f"hl.dsp.cursor.move({{x={x},y={y}}})")
    # Independent systemd timers survive this harness or SSH process failing.
    subprocess.run(["systemd-run","--user","--unit=den-safety-expiry","--on-active=55s","--collect",str(Path.home()/".local/bin/den-control"),"home"],check=True)
    remote("systemd-run --user --unit=den-safety-expiry --on-active=55s --collect /usr/bin/systemctl --user stop den-input.service")
    try:
     remote("systemctl --user start den-input")
     subprocess.run([str(Path.home()/".local/bin/den-control"),"start"],check=True)
     time.sleep(.5)
     for trial,(entry,exit) in enumerate([("top","bottom"),("right","left"),("top","left"),("right","bottom")]*cycles):
      entry_x=[120,960,1800][trial%3];entry_y=[-960,-540,-120][trial%3]
      inst=json.loads(hypr("instances","-j"))[0]
      import os
      env=dict(os.environ,WAYLAND_DISPLAY=inst['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=inst['instance'])
      for n in range(24):
       if entry=="top":warp(entry_x,40);warp(entry_x,0)
       else:warp(-40,entry_y);warp(-1,entry_y)
       # A compositor warp is not device motion. Exercise the real capture stream
       # so a fresh DTLS connection can receive/retry its Enter handshake.
       subprocess.run([str(root/'input-test/test'),'motion',"0" if entry=="top" else "1","-1" if entry=="top" else "0"],env=env,check=True)
       time.sleep(.3)
       ready=remote("cat /home/fh1m/.local/state/homie-control/input/return-armed").strip()
       if ready=="1":break
      assert ready=="1",(entry,"not ready")
      pos=json.loads(remote("hyprctl -i 0 cursorpos -j"))
      assert (pos["y"]>=1060 if entry=="top" else pos["x"]<=20),(entry,pos)
      if with_input:
       clients=json.loads(remote('hyprctl -i 0 clients -j'));own=next(c for c in clients if c.get('title')=='Den input harness')
       assert own['size'][1]>650,'Owned fixture too short for safe pointer motion'
       before=json.loads(remote('cat ~/.local/state/homie-control/input-test/events.json'))
       remote('hyprctl -i 0 dispatch '+shlex.quote('hl.dsp.focus({window="address:'+own['address']+'"})'))
       cx=own['at'][0]+own['size'][0]//2;cy=min(own['at'][1]+own['size'][1]-10,own['at'][1]+own['size'][1]//2+300)
       remote('hyprctl -i 0 dispatch '+shlex.quote(f'hl.dsp.cursor.move({{x={cx},y={cy}}})'))
       active=json.loads(remote('hyprctl -i 0 activewindow -j'));assert active.get('title')=='Den input harness'
       subprocess.run([str(root/'input-test/test')],env=env,check=True);time.sleep(.1)
       after=json.loads(remote('cat ~/.local/state/homie-control/input-test/events.json'))
       assert all(after['keys'].get(k,0)>before['keys'].get(k,0) for k in ['d','e','n','a']),after
       assert after['buttons']>before['buttons'] and after['scrolls']>before['scrolls'],after
       assert not after['held'],after
       print('Owned keyboard/chord/click/scroll check: passed',flush=True)
      dispatch="hl.dsp.cursor.move({x=960,y=1077})" if exit=="bottom" else "hl.dsp.cursor.move({x=2,y=540})"
      remote("hyprctl -i 0 dispatch "+shlex.quote(dispatch))
      subprocess.run([str(root/"input-test/test"),"motion","0" if exit=="bottom" else "-12","12" if exit=="bottom" else "0"],env=env,check=True)
      for n in range(24):
       time.sleep(.05);pos=json.loads(hypr("cursorpos","-j"))
       if (pos["y"]==3 if exit=="bottom" else pos["x"]==-4):break
      assert (pos["y"]==3 if exit=="bottom" else pos["x"]==-4),(entry,exit,pos)
      print(entry,"→ Homie →",exit,"passed",pos,flush=True)
      time.sleep(.1)
     # Verify the real recovery gesture without typing text/clicking any application.
     warp(960,40);warp(960,0);time.sleep(.4)
     inst=json.loads(hypr("instances","-j"))[0]
     import os
     env=dict(os.environ,WAYLAND_DISPLAY=inst['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=inst['instance'])
     subprocess.run([str(root/'input-test/test'),'taps3'],env=env,check=True)
     for n in range(30):
      time.sleep(.05)
      status=subprocess.run(["systemctl","--user","is-active","--quiet","den-input"]).returncode
      pos=json.loads(hypr("cursorpos","-j"))
      if status!=0 and pos=={"x":960,"y":540}:break
     assert status!=0 and pos=={"x":960,"y":540},("gesture",status,pos)
     print("Triple Ctrl stops sharing and returns to main centre: passed",flush=True)
     time.sleep(.8)
     subprocess.run([str(root/'input-test/test'),'taps3'],env=env,check=True)
     for _ in range(60):
      time.sleep(.1)
      if subprocess.run(["systemctl","--user","is-active","--quiet","den-input"],stdout=subprocess.DEVNULL).returncode==0:break
     else:raise AssertionError("Triple Ctrl failed to resume sharing")
     print("Triple Ctrl resumes sharing outside capture: passed",flush=True)
    finally:
     subprocess.run([str(Path.home()/".local/bin/den-control"),"home"],check=False)
     try:remote("systemctl --user stop den-input")
     except subprocess.SubprocessError:pass
     warp(960,540)
     subprocess.run(["systemctl","--user","stop","den-safety-expiry.timer"],check=False)
     try:remote("systemctl --user stop den-safety-expiry.timer")
     except subprocess.SubprocessError:pass

if __name__ == "__main__":
    import argparse
    from pathlib import Path
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--live",action="store_true",help="confirm supervised cursor movement on both desktops")
    parser.add_argument("--cycles",type=int,default=3,choices=range(1,5))
    parser.add_argument("--with-input",action="store_true",help="requires the separately launched owned GTK receiver")
    args=parser.parse_args()
    if not args.live:parser.error("Refusing live input test without --live")
    if not (Path.home()/".local/state/homie-control/input-test/test").is_file():
        parser.error("Dedicated gesture fixture is missing; do not substitute a general typing tool")
    main(args.cycles,args.with_input)
