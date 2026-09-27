#!/usr/bin/env python3
"""Opt in to a hybrid path after a manual renderer/video validation."""
import argparse, json, platform, subprocess
from pathlib import Path
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--confirm-tested', action='store_true', help='Acknowledge you checked real video playback, renderer, decoder and driver errors')
p.add_argument('--intel-pci', default='0000:00:02.0')
p.add_argument('--nvidia-pci', default='0000:01:00.0')
a = p.parse_args()
if not a.confirm_tested: p.error('Read docs/gpu-and-chrome.md and validate first. This command is not a hardware test.')
for pci in [a.intel_pci, a.nvidia_pci]:
    if not (Path('/dev/dri/by-path')/f'pci-{pci}-render').exists(): p.error('Missing PCI render node: '+pci)
r = subprocess.run(['nvidia-smi','--query-gpu=driver_version','--format=csv,noheader'],capture_output=True,text=True,check=True)
data = {'mode':'nvidia', 'validatedHybrid':True, 'validatedKernel':platform.release(),
        'validatedDriver':r.stdout.strip().splitlines()[0], 'intelPCI':a.intel_pci, 'nvidiaPCI':a.nvidia_pci}
path = Path.home()/'.config/hypr/chrome-gpu.json';path.parent.mkdir(parents=True,exist_ok=True)
if path.exists(): path.with_suffix('.json.pre-hybrid').write_bytes(path.read_bytes())
path.write_text(json.dumps(data,indent=2)+'\n')
print('Hybrid choice saved. Close/relaunch Chrome normally; no browser was killed or profile edited by this command.')
