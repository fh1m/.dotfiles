#!/usr/bin/env python3
"""Preview/install the one optional Python GPU inspector; OS tools use packages/core.txt."""
import argparse,subprocess
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');a=p.parse_args()
print('OS manifest: atuin, lnav, nmap. Optional on-demand GPU inspector: nvitop 1.7.1 via uv tool. No background service.')
if a.apply:subprocess.run(['uv','tool','install','nvitop==1.7.1'],check=True)
