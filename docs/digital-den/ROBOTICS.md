# Two machines, one lab

Run active builds and editor sessions locally. Hand off exact Git revisions and environment versions; keep recordings and large artifacts on managed storage. A network share is not an environment or a backup.

## Finite ROS fixture

`scripts/den/ros-fixture.py` publishes or verifies one exact nonce payload, for at most 60 seconds, on its own topic. It cannot send arbitrary commands or actuator messages. Choose an unused ROS domain, preserve normal project environments and stop all fixture containers afterwards.

Arete's existing `robotics_essentials_ros2:latest` contains ROS Humble/Python 3.10.12. Its tested image ID was `sha256:5c1733f48006a69fac33fb7f68379e323e467b0d4943dc3d86ffba5edfa82b38`; tags are mutable, so read the current ID before reuse. A network-isolated container with two nodes passed: the subscriber received the exact payload and its checksum matched the publisher. This proves the fixture locally, **not** inter-machine DDS discovery.

Inside a sourced ROS environment:

```sh
export ROS_DOMAIN_ID=77
python3 ros-fixture.py receive --nonce den_peer_trial --seconds 30
# On the other host, with the same domain and compatible ROS environment:
python3 ros-fixture.py publish --nonce den_peer_trial --seconds 20
```

For the cross-host trial, ROS_LOCALHOST_ONLY must be unset/0, both hosts need suitable DDS/network discovery and host/container networking must be chosen deliberately. Each local owner reviews its firewall; do not open broad port ranges or route fixtures onto the robot's production domain. Record image IDs, ROS distribution, RMW implementation, source revision and the receiver's matched checksum. Test both directions. A publisher's successful exit means it ran its finite loop, not that a peer received it.

## Later compute

First compare a small fixed-seed numerical fixture on each GPU, then record package/CUDA/driver compatibility and benchmark a representative single-node workload. Only then evaluate distributed training. Arete's actual 100 Mb/s link can make synchronization slower than a single GPU. Each GPU has 6 GiB; there is no automatic pooled VRAM. No distributed training or speedup has been measured yet.

Homie's Windows boot is a separate QA/gaming environment. Linux ROS/storage/input services do not remain available through a Windows boot. Protect disconnected Windows/data drives; do not repurpose them for shared storage without identity and data-preservation checks.
