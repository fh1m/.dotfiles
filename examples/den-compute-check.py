#!/usr/bin/env python3
"""Small CUDA correctness/learning check, not a performance benchmark."""
import argparse
import json
import socket
import time
from pathlib import Path

import torch

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--device',choices=['cuda','cpu'],default='cuda')
p.add_argument('--output',type=Path)
a=p.parse_args();torch.set_num_threads(2);torch.manual_seed(42)
if a.device=='cuda' and not torch.cuda.is_available():raise SystemExit('CUDA unavailable; no silent CPU fallback')
device=torch.device(a.device);start=time.monotonic()
x=torch.randn(256,8,device=device);truth=torch.arange(1,9,device=device,dtype=torch.float32)/8
y=x@truth[:,None]+.3
model=torch.nn.Linear(8,1).to(device);optimizer=torch.optim.SGD(model.parameters(),lr=.1)
initial=float(torch.nn.functional.mse_loss(model(x),y).detach())
for _ in range(60):
    optimizer.zero_grad();loss=torch.nn.functional.mse_loss(model(x),y);loss.backward();optimizer.step()
final=float(torch.nn.functional.mse_loss(model(x),y).detach())
if device.type=='cuda':torch.cuda.synchronize()
checks={'finite':bool(torch.isfinite(loss)),'loss_reduced':final<initial*.001,
        'recovered_weights':bool(torch.allclose(model.weight.detach().ravel(),truth,atol=.003))}
result={'host':socket.gethostname(),'device':str(device),'gpu':torch.cuda.get_device_name(0) if device.type=='cuda' else None,
        'torch':torch.__version__,'cuda':torch.version.cuda,'seconds':round(time.monotonic()-start,3),
        'initial_loss':initial,'final_loss':final,'checks':checks,'claim':'synthetic regression and autograd correctness only'}
if a.output:
    a.output.parent.mkdir(parents=True,exist_ok=True);tmp=a.output.with_suffix('.tmp');tmp.write_text(json.dumps(result,indent=2));tmp.replace(a.output)
print(json.dumps(result,indent=2))
if not all(checks.values()):raise SystemExit(1)
