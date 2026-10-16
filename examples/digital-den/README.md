# A small, inspectable robotics job

`imu_bias.py` generates a deterministic **synthetic** stationary gyro stream, estimates its bias and writes units, metrics, a CSV and an SVG. No hardware is involved.

```sh
sensei-den job run --project "$HOME/.dotfiles/examples/digital-den" \
  --input imu_bias.py --artifact results/metrics.json \
  --artifact results/calibration.svg --artifact results/imu.csv -- python3 imu_bias.py
sensei-den job artifacts --id JOB_ID
sensei-den job fetch --id JOB_ID --file results/metrics.json --output /tmp/imu-result.json
```

Add `--host homie` to run inside an existing Homie checkout. Inputs must already exist there; this command does not silently copy a working tree. For a clean reproduction, commit first and check out the same revision on both hosts. Dirty runs remain explicitly marked.

`compute_benchmark.py` supports a local CUDA baseline and `torchrun` DDP. Use the same pinned environment, code and workload, compare multiple repetitions, and record network traffic and desktop responsiveness. A completed single-GPU run is **not** a two-node speedup result. On the current 100-Mb/s laptop link, independent jobs may be preferable. It does not pool GPU memory.

```sh
/path/to/cuda-env/bin/python compute_benchmark.py --output /tmp/arete-baseline.json
# Both hosts, only after trusted rendezvous connectivity and matching environments:
/path/to/cuda-env/bin/python -m torch.distributed.run --nnodes=2 --nproc-per-node=1 --node-rank=0 \
  --master-addr=TRUSTED_LAN_IP --master-port=29583 compute_benchmark.py
# Use --node-rank=1 on Homie. Keep the rendezvous port scoped to the peer.
```

Results stay ignored. Fetch refuses changed artifacts and existing destination files. Keep large recordings/datasets outside this repository and transfer them explicitly.

## Measured on this Den · 2026-10-16

Same PyTorch 2.11.0+cu130 and synthetic MLP, 100 measured steps:

| Run | Measured loop | Finite gradients |
| --- | ---: | --- |
| Arete RTX 2060, batch 128 | 0.0763 s | yes |
| Homie GTX 1660 SUPER, batch 128 | 0.0831 s | yes |
| Two-node NCCL, batch 128 per rank | 6.19 s | yes, matching final model hashes |

This tiny workload verifies communication, not useful training speedup. Distributed
global batch is 256, so this is not a comparison of equivalent convergence.
Independent jobs are the practical default on the current 100-Mb/s laptop link.
Checkpoint recovery was checked in both directions. Temporary peer-scoped firewall
allowances were removed afterward; rendezvous alone is not all NCCL traffic.
See [the execution record](../../docs/digital-den/NEXT-PASS-IMPLEMENTATION.md).
