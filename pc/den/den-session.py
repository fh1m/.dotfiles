#!/usr/bin/env python3
"""Dedicated Den services; discover the actual graphical session at each start."""
import json, os, pathlib, subprocess, sys, time, tomllib
sys.path.insert(0,str(pathlib.Path.home()/'.local/share/sensei'))
from den_layout import roles as display_roles
from den_geometry import load as geometry,ranges as edge_ranges
state=pathlib.Path.home()/".local/state/homie-control"
if sys.argv[1]=="reset":
    for name in ("active","return-armed"):
        (state/"input"/name).write_text("0")
    raise SystemExit(0)
while True:
    try:
        instances=json.loads(subprocess.check_output(["hyprctl","instances","-j"],stderr=subprocess.DEVNULL))
        if instances:
            instance=instances[0];break
    except (OSError,ValueError,subprocess.SubprocessError):pass
    time.sleep(3)
os.environ.update(HYPRLAND_INSTANCE_SIGNATURE=instance["instance"],WAYLAND_DISPLAY=instance["wl_socket"],XDG_RUNTIME_DIR=f"/run/user/{os.getuid()}")
if sys.argv[1]=="cursor":
    os.execv(sys.executable,[sys.executable,str(state/"den-cursor.py"),"daemon"])
if sys.argv[1]=="clipboard":
    os.execv(sys.executable,[sys.executable,str(state/"den-clipboard.py"),"hub"])
os.environ["DEN_CURSOR_SOCKET"]=str(state/"cursor.sock")
binary=state/"bin/lan-mouse"
if not binary.exists():binary=pathlib.Path("/usr/bin/lan-mouse")
(state/"input/active").write_text("0")
config=tomllib.loads((state/"input/config.toml").read_text())
if config.get("clients"):
    outputs=display_roles(json.loads(subprocess.check_output(["hyprctl","monitors","-j"])))
    edges=[]
    if "main" in outputs:edges.append("top="+outputs["main"]["name"])
    if "upper" in outputs:edges.append("right="+outputs["upper"]["name"])
    main=outputs.get('main',{})
    span=edge_ranges(geometry(),(main.get('x',0),main.get('y',0),main.get('width',1920)/main.get('scale',1),main.get('height',1080)/main.get('scale',1)))
    if not span:edges=[edge for edge in edges if not edge.startswith('top=')]
    os.environ['DEN_CAPTURE_RANGES']='top='+':'.join(str(v) for v in span['top']) if span else ''
    os.environ["DEN_CAPTURE_OUTPUTS"]=",".join(edges)
    os.environ["DEN_CTRL_COMMAND"]=str(state/"den-cursor.py")
    os.environ["DEN_CAPTURE_STATE"]=str(state/"input/active")
    os.environ["DEN_RETURN_COMMAND"]=str(state/"den-edge-return.py")
else:
    outputs=display_roles(json.loads(subprocess.check_output(["hyprctl","monitors","-j"])))
    primary=outputs.get("main",{}).get("name","")
    os.environ["DEN_CAPTURE_OUTPUTS"]="left="+primary+",bottom="+primary
    span=edge_ranges(geometry(),(0,0,1920,1080))
    if not span:os.environ['DEN_CAPTURE_OUTPUTS']='left='+primary
    os.environ['DEN_CAPTURE_RANGES']='bottom='+':'.join(str(v) for v in span['bottom']) if span else ''
    os.environ["DEN_RETURN_EDGES"]="bottom,left"
    os.environ["DEN_RETURN_WATCH"]="1"
    (state/"input/return-armed").write_text("0")
    os.environ["DEN_RETURN_ARMED"]=str(state/"input/return-armed")
os.execv(str(binary),[str(binary),"-c",str(state/"input/config.toml"),"--cert-path",str(state/"input/cert.pem"),"--capture-backend","layer-shell","--emulation-backend","wlroots","daemon"])
