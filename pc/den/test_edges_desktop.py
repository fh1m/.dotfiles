#!/usr/bin/env python3
"""Supervised live Den acceptance; importing this module never controls a desktop."""
def main():
    import subprocess,json,time,shlex
    from pathlib import Path
    root=Path.home()/".local/state/homie-control"
    ssh=["ssh","-F",str(root/"client.conf"),"homie"]
    def remote(command):return subprocess.check_output(ssh+[command],timeout=3).decode()
    def hypr(*args):return subprocess.check_output(["hyprctl","-i","0",*args],timeout=2).decode()
    def warp(x,y):hypr("dispatch",f"hl.dsp.cursor.move({{x={x},y={y}}})")
    # Independent systemd timers survive this harness or SSH process failing.
    subprocess.run(["systemd-run","--user","--unit=den-safety-expiry","--on-active=30s","--collect","/usr/bin/systemctl","--user","stop","den-input.service"],check=True)
    remote("systemd-run --user --unit=den-safety-expiry --on-active=30s --collect /usr/bin/systemctl --user stop den-input.service")
    try:
     remote("systemctl --user start den-input")
     subprocess.run(["systemctl","--user","start","den-input"],check=True)
     time.sleep(.5)
     for entry,exit in [("top","bottom"),("right","left"),("top","left"),("right","bottom")]:
      for n in range(10):
       if entry=="top":warp(960,40);warp(960,0)
       else:warp(-40,-540);warp(-1,-540)
       time.sleep(.3)
       ready=remote("cat /home/fh1m/.local/state/homie-control/input/return-armed").strip()
       if ready=="1":break
      assert ready=="1",(entry,"not ready")
      pos=json.loads(remote("hyprctl -i 0 cursorpos -j"))
      assert (pos["y"]>=1060 if entry=="top" else pos["x"]<=20),(entry,pos)
      dispatch="hl.dsp.cursor.move({x=960,y=1079})" if exit=="bottom" else "hl.dsp.cursor.move({x=0,y=540})"
      remote("hyprctl -i 0 dispatch "+shlex.quote(dispatch))
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
     subprocess.run(["systemctl","--user","stop","den-input"],check=False)
     try:remote("systemctl --user stop den-input")
     except subprocess.SubprocessError:pass
     warp(960,540)

if __name__ == "__main__":
    import argparse
    from pathlib import Path
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--live",action="store_true",help="confirm supervised cursor movement on both desktops")
    args=parser.parse_args()
    if not args.live:parser.error("Refusing live input test without --live")
    if not (Path.home()/".local/state/homie-control/input-test/test").is_file():
        parser.error("Dedicated gesture fixture is missing; do not substitute a general typing tool")
    main()
