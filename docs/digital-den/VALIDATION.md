# Continuity acceptance — 2026-10-16

Results below describe performed checks, not a claim of a bug-free system.
Private logs, account information, file inventories and desktop captures remain
under `~/.local/state/homie-control/` and `~/.local/state/sensei-den/`.

| Workflow | Observed result | Boundary |
|---|---|---|
| Shared input | Four main/upper crossing and return combinations; triple-Ctrl pause/resume passed with independent expiry timers | Repeated on final deployment; physical unplug/replug and suspend are separate tests |
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
| Companion | Actual wallpaper capture reviewed; text bubble and poses recorded; no sound or input region | Live quiet suppression passed; fullscreen/click-through still needs final interaction acceptance |

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

## Final deployment checks

- Both profiles applied with no remaining installer changes; main branch shared.
- Both presence services and daily backup timers enabled and active.
- Fresh encrypted backup runs succeeded; both restore checks repeated successfully.
- Manual pause remained paused across presence refresh; away released input and
  returning to auto resumed sharing. Final four cursor routes passed.
- Homie desktop checks all passed; all six designated data mounts readable with
  intended writable/read-only separation. Both agent authentication checks passed.
- Live Spotify catalogue query returned HTTP 429. Cooldown was preserved; this is
  an unresolved provider-facing behavior, not a passed playback acceptance test.

## Aesthetic/companion pass — 2026-10-16

- 32 targeted searches plus direct technical-source checks are recorded in
  [the research ledger](POLISH-RESEARCH.md); no additional pet framework installed.
- 231 Python tests pass. New cases exercise geometry, floating-window/bubble
  avoidance, short displays, non-repetition, contextual messages and motion input.
- Live temporary-renderer preview passed speech, movement, reduced motion and
  quiet controls. Its actual capture was visually inspected; a source-clip bug
  caught during visual review was fixed before replacing the gallery capture.
- Neovim headless checks loaded the theme and opened/closed the explicit DenTip
  float; terminal semantic green matched. Zsh syntax and repeated hook loading
  passed. Installer dry-run/backup/seed-state/idempotence checks passed.
- No automatic message claims a test passed. Only a newly observed backup result
  emits backup status. No assistant/model service, extra persistent renderer,
  clipboard access or source-code inspection was added.

Final polish UI checks also confirmed the System companion state fields and the
Nerd Talk artwork in the live shell. Receiver status now reports that host's own
companion preferences. The original fallback desk line is no longer presented as
an attributed quotation. An eight-second idle sample of the existing combined
cursor/companion renderer observed 0.00% of one CPU core at the sampling resolution
and 200.7 MiB RSS; this is a short whole-renderer sample, not isolated companion
cost or a performance guarantee.


## Connected next-pass release — 2026-10-16

See [the execution record](NEXT-PASS-IMPLEMENTATION.md) for the full P0–P6 coverage
and open gates. Both hosts passed 271 regression tests; live dropdown placement
passed 76 Arete cases and 19 Homie cases. Official Spotify pause/resume and
single-shot Next passed on each host. Cross-host companion ownership, ROS,
checksummed remote jobs, two-node NCCL and bidirectional checkpoint recovery were
observed. This small workload strongly favors independent jobs on the current
link. One exact-coordinate assertion failed during repeat input testing; cleanup
released control and a complete subsequent run passed. Its cause remains unknown.
Physical display transfer, unattended boot/Windows return, off-site operation and
phone-controlled Spotify soak remain unverified. Private evidence stays local.
