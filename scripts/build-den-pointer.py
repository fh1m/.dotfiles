#!/usr/bin/env python3
"""Build the bounded keyboard-handoff pointer helper; never starts input capture."""
from pathlib import Path
import subprocess,tempfile,shutil
root=Path(__file__).resolve().parents[1];dest=Path.home()/'.local/state/homie-control/bin/den-edge-nudge';dest.parent.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='den-pointer-build-') as d:
 p=Path(d);xml=root/'pc/den/protocols/wlr-virtual-pointer-unstable-v1.xml'
 for mode,name in [('client-header','pointer.h'),('private-code','pointer.c')]:subprocess.run(['wayland-scanner',mode,str(xml),str(p/name)],check=True)
 args=['cc','-O2','-I',d,str(root/'pc/den/edge-nudge.c'),str(p/'pointer.c'),'-o',str(p/'den-edge-nudge'),*subprocess.check_output(['pkg-config','--cflags','--libs','wayland-client'],text=True).split()]
 subprocess.run(args,check=True);shutil.copy2(p/'den-edge-nudge',dest);dest.chmod(0o700)
print(dest)
