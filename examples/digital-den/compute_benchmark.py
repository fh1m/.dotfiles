#!/usr/bin/env python3
"""Single-node or torchrun benchmark. Reports observations, never assumed speedup."""
import argparse
import datetime
import json
import hashlib
import os
from pathlib import Path
import socket
import time
import torch
import torch.distributed as dist
p=argparse.ArgumentParser();p.add_argument('--steps',type=int,default=100);p.add_argument('--output',default='benchmark.json');p.add_argument('--checkpoint');p.add_argument('--resume');p.add_argument('--verify-checkpoint',action='store_true');a=p.parse_args()
if a.steps<1 or a.steps>10000:p.error('steps must be 1..10000')
world=int(os.environ.get('WORLD_SIZE','1'));rank=int(os.environ.get('RANK','0'));local=int(os.environ.get('LOCAL_RANK','0'))
if not torch.cuda.is_available():raise SystemExit('CUDA is unavailable; no GPU result recorded')
torch.cuda.set_device(local);device=torch.device('cuda',local)
if world>1:dist.init_process_group('nccl',timeout=datetime.timedelta(seconds=90))
torch.manual_seed(23);model=torch.nn.Sequential(torch.nn.Linear(256,512),torch.nn.Tanh(),torch.nn.Linear(512,64)).to(device)
if a.resume:
 saved=torch.load(a.resume,map_location='cpu',weights_only=True);model.load_state_dict(saved['model'])
def checksum(model):return hashlib.sha256(b''.join(v.detach().cpu().contiguous().numpy().tobytes() for k,v in sorted(model.state_dict().items()))).hexdigest()
if a.verify_checkpoint:
 if not a.resume:raise SystemExit('--verify-checkpoint requires --resume')
 print(json.dumps({'host':socket.gethostname(),'checkpoint_recovered':True,'model_sha256':checksum(model),'gpu':torch.cuda.get_device_name(local)}));raise SystemExit(0)
if world>1:model=torch.nn.parallel.DistributedDataParallel(model,device_ids=[local])
x=torch.randn(128,256,device=device);target=torch.randn(128,64,device=device);opt=torch.optim.SGD(model.parameters(),lr=.01)
for i in range(10):opt.zero_grad();loss=(model(x)-target).square().mean();loss.backward();opt.step()
if world>1:dist.barrier()
torch.cuda.synchronize();start=time.perf_counter()
for i in range(a.steps):opt.zero_grad();loss=(model(x)-target).square().mean();loss.backward();opt.step()
torch.cuda.synchronize();elapsed=time.perf_counter()-start
record={'host':socket.gethostname(),'rank':rank,'world':world,'gpu':torch.cuda.get_device_name(local),'torch':torch.__version__,'steps':a.steps,'seconds':elapsed,'samples_per_second':a.steps*128/elapsed,'loss':loss.item(),'finite_gradients':all(p.grad is None or torch.isfinite(p.grad).all().item() for p in model.parameters()),'peak_vram_bytes':torch.cuda.max_memory_allocated(),'synthetic':True}
base=model.module if world>1 else model
record.update(model_sha256=checksum(base),batch_per_rank=128,global_batch=128*world)
if a.checkpoint and rank==0:torch.save({'schema':1,'model':base.state_dict(),'steps':a.steps},a.checkpoint)
out=Path(a.output)
if world>1:out=out.with_name(out.stem+f'-rank{rank}'+out.suffix)
out.write_text(json.dumps(record,indent=2));print(json.dumps(record))
if world>1:dist.destroy_process_group()
