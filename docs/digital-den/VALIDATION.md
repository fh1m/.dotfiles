# Continuity acceptance — 2026-10-16

Results below describe performed checks, not a claim of a bug-free system.
Private logs, account information, file inventories and desktop captures remain
under `~/.local/state/homie-control/` and `~/.local/state/sensei-den/`.

| Workflow | Observed result | Boundary |
|---|---|---|
| Shared input | Four main/upper crossing and return combinations; triple-Ctrl pause/resume passed with independent expiry timers | Physical unplug/replug and suspend are separate tests |
| Personal files | Eleven folders reached idle with no outstanding files/errors; a deliberate conflict retained both versions; payload checksum matched | A mirror propagates deletion; it is not a backup |
| Project history | Seven private Git handoffs passed connectivity checks; staged changes and independent work files preserved in fixture tests | Git metadata is excluded from Syncthing; commit/pull remains explicit |
| Account continuity | Both agent CLIs report authentication; Spotify local login available | No billed agent request made; refresh-token rotation is provider-owned |
| Encrypted recovery | Both hosts restored an owned fixture into a different directory with matching SHA256; Homie snapshots also copied onto Arete | Local copies do not protect against loss of the whole home |
| Remote desktop | Actual private Tailscale stream delivered video and audio packets; Homie HEVC NVENC and Arete hardware decode; desktop visually reviewed | Sunshine is on demand; physical HDMI switching is unrelated |
| GPU work | Identical synthetic CUDA/autograd check passed on RTX 2060 and GTX 1660 SUPER, including finite gradients and recovered weights | Not pooled VRAM, distributed-training validation or a speed comparison |
| Remote containers | Explicit Homie Docker context ran a CUDA container and identified the desktop GPU | Default Docker context unchanged |
| Robotics transport | Isolated ROS domain 83 exchanged a nonce and return acknowledgement between hosts; both processes exited successfully with scoped firewall active | Synthetic String topic, no actuators; not production robot acceptance |
| Spotify transport | Owned UDP fixture verifies one Next/Previous command and bounds stale progress; Rust middleware tests cover request behavior | Provider/device-transfer acceptance remains open |
| Playback observation | 90 minutes: 1,076 samples, 121 playing samples, two track transitions, zero status errors or unexpected resets | About ten minutes observed playing; not 90 minutes of continuous audio |
| Companion | Actual wallpaper capture reviewed; text bubble and poses recorded; no sound or input region | Fullscreen/quiet behavior still needs final desktop acceptance |

## Remaining acceptance gates

- Real Spotify Connect transfer between hosts, repeated skips and external-device
  control during playback. Request budgeting reduces known failure modes; it does
  not prove provider-side playback is fixed.
- Move the two external panels physically to Homie; verify digital 100 Hz, role
  placement, widgets and return to Arete. Software preparation is not this test.
- Unattended Homie cold boot and native Windows return. Earlier firmware-loop
  acceptance failed; see [boot recovery](../../pc/BOOT-EXPERIENCE.md).
- Leave home, disconnect LAN and suspend/resume with local work open. Tailscale
  reachability is verified; the physical travel sequence is not.
- Off-device/off-site recovery, a real two-node training workload and storage
  reallocation are future work, not completed capabilities.

## Repeatable checks

```sh
python3 -m unittest discover -s tests
python3 scripts/test-install.py
python3 scripts/check-den-ros.py --live  # Arete; owned isolated topic
den doctor
den backup check
den backup restore-test
```

The wired laptop link currently negotiates **100 Mb/s**. The measured transfer
was about 11.3 MB/s. Software tuning cannot promise gigabit throughput on that link.
