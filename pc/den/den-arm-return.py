#!/usr/bin/env python3
"""Arm return edges only after the master places the cursor safely inside Homie."""
import pathlib,subprocess,time
p=pathlib.Path.home()/".local/state/homie-control"
for _ in range(30):
    subprocess.run([str(p/"bin/lan-mouse"),"cli","arm-return"],check=True,stdout=subprocess.DEVNULL,timeout=1)
    time.sleep(.03)
    try:
        if (p/"input/return-armed").read_text().strip()=="1":break
    except OSError:pass
else:raise SystemExit("Return-edge readiness was not confirmed")
