#!/usr/bin/env python3
"""Dedicated Den services; discover the actual graphical session at each start."""
import json, os, pathlib, subprocess, sys, time
state=pathlib.Path.home()/".local/state/homie-control"
while True:
    try:
        instances=json.loads(subprocess.check_output(["hyprctl","instances","-j"],stderr=subprocess.DEVNULL))
        if instances:
            instance=instances[0];break
    except (OSError,ValueError,subprocess.SubprocessError):pass
    time.sleep(3)
os.environ.update(HYPRLAND_INSTANCE_SIGNATURE=instance["instance"],WAYLAND_DISPLAY=instance["wl_socket"],XDG_RUNTIME_DIR=f"/run/user/{os.getuid()}")
if sys.argv[1]=="clipboard":
    os.execv(sys.executable,[sys.executable,str(state/"den-clipboard.py"),"hub"])
binary=state/"bin/lan-mouse"
if binary.exists():os.environ["DEN_CAPTURE_OUTPUT"]="eDP-1"
else:binary=pathlib.Path("/usr/bin/lan-mouse")
os.execv(str(binary),[str(binary),"-c",str(state/"input/config.toml"),"--cert-path",str(state/"input/cert.pem"),"--capture-backend","layer-shell","--emulation-backend","wlroots","daemon"])
