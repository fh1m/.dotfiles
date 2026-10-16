#!/usr/bin/env python3
"""Single-node or torchrun benchmark. Reports observations, never assumed speedup."""
import argparse
import datetime
import json
import os
from pathlib import Path
import socket
import time
import torch
import torch.distributed as dist
p=argparse.ArgumentParser();p.add_argument('--steps',type=int,default=100);p.add_argument('--output',default='benchmark.json');a=p.parse_args()
if a.steps<1 or a.steps>10000:p.error('steps must be 1..10000')
world=int(os.environ.get('WORLD_SIZE','1'));rank=int(os.environ.get('RANK','0'));local=int(os.environ.get('LOCAL_RANK','0'))
if not torch.cuda.is_available():raise SystemExit('CUDA is unavailable; no GPU result recorded')
torch.cuda.set_device(local);device=torch.device('cuda',local)
if world>1:dist.init_process_group('nccl',timeout=datetime.timedelta(seconds=90))
torch.manual_seed(23);model=torch.nn.Sequential(torch.nn.Linear(256,512),torch.nn.Tanh(),torch.nn.Linear(512,64)).to(device)
if world>1:model=torch.nn.parallel.DistributedDataParallel(model,device_ids=[local])
x=torch.randn(128,256,device=device);target=torch.randn(128,64,device=device);opt=torch.optim.SGD(model.parameters(),lr=.01)
for i in range(10):opt.zero_grad();loss=(model(x)-target).square().mean();loss.backward();opt.step()
if world>1:dist.barrier()
torch.cuda.synchronize();start=time.perf_counter()
for i in range(a.steps):opt.zero_grad();loss=(model(x)-target).square().mean();loss.backward();opt.step()
torch.cuda.synchronize();elapsed=time.perf_counter()-start
record={'host':socket.gethostname(),'rank':rank,'world':world,'gpu':torch.cuda.get_device_name(local),'torch':torch.__version__,'steps':a.steps,'seconds':elapsed,'samples_per_second':a.steps*128/elapsed,'loss':loss.item(),'finite_gradients':all(p.grad is None or torch.isfinite(p.grad).all().item() for p in model.parameters()),'peak_vram_bytes':torch.cuda.max_memory_allocated(),'synthetic':True}
out=Path(a.output)
if world>1:out=out.with_name(out.stem+f'-rank{rank}'+out.suffix)
out.write_text(json.dumps(record,indent=2));print(json.dumps(record))
if world>1:dist.destroy_process_group()
