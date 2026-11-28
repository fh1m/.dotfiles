#!/usr/bin/env python3
"""Dedicated Den services; discover the actual graphical session at each start."""
import json, os, pathlib, subprocess, sys, tomllib
sys.path.insert(0,str(pathlib.Path.home()/'.local/share/sensei'))
from den_layout import roles as display_roles
from den_geometry import load as geometry,ranges as edge_ranges
from desktop_session import wait_for_session
state=pathlib.Path.home()/".local/state/homie-control"

def main(mode):
    if mode not in ('reset','ready','input-ready','cursor','clipboard','input'):raise ValueError('Choose reset, ready, input-ready, cursor, clipboard or input')
    if mode=="reset":
        for name in ("active","return-armed","running"):
            (state/"input"/name).write_text("0")
        return
    instance,runtime=wait_for_session()
    os.environ.update(HYPRLAND_INSTANCE_SIGNATURE=instance["instance"],WAYLAND_DISPLAY=instance["wl_socket"],XDG_RUNTIME_DIR=str(runtime))
    if mode=="ready":return
    if mode=="input-ready":
        from den_input_config import refresh as refresh_input_config
        refresh_input_config(state/"input/config.toml",require_policy=True)
        return
    if mode=="cursor":
        os.execv(sys.executable,[sys.executable,str(state/"den-cursor.py"),"daemon"])
    if mode=="clipboard":
        os.execv(sys.executable,[sys.executable,str(state/"den-clipboard.py"),"hub"])
    os.environ["DEN_CURSOR_SOCKET"]=str(state/"cursor.sock")
    binary=state/"bin/lan-mouse"
    if not binary.exists():binary=pathlib.Path("/usr/bin/lan-mouse")
    (state/"input/active").write_text("0")
    (state/"input/running").write_text("0")
    config=tomllib.loads((state/"input/config.toml").read_text())
    if config.get("clients"):
        # Resolve and pin-check before creating any capture surface. Keep logical
        # hostnames and user pairings; only derived address hints may change.
        from den_input_config import refresh as refresh_input_config
        refresh_input_config(state/"input/config.toml",require_policy=True)
        outputs=display_roles(json.loads(subprocess.check_output(["hyprctl","monitors","-j"])))
        edges=[]
        if "main" in outputs:edges.append("top="+outputs["main"]["name"])
        if "upper" in outputs:edges.append("right="+outputs["upper"]["name"])
        main_output=outputs.get('main',{})
        span=edge_ranges(geometry(),(main_output.get('x',0),main_output.get('y',0),main_output.get('width',1920)/main_output.get('scale',1),main_output.get('height',1080)/main_output.get('scale',1)))
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
    (state/"input/running").write_text("1")
    try:
        os.execv(str(binary),[str(binary),"-c",str(state/"input/config.toml"),"--cert-path",str(state/"input/cert.pem"),"--capture-backend","layer-shell","--emulation-backend","wlroots","daemon"])
    except OSError:
        (state/"input/running").write_text("0")
        raise

if __name__=="__main__":
    try:
        if len(sys.argv)!=2:raise ValueError('Supply one Den service mode')
        main(sys.argv[1])
    except (OSError,RuntimeError,ValueError) as error:raise SystemExit(str(error))
    raise SystemExit(0)
