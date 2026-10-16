# Den implementation — 2026-10-16

This records observed work, not a claim that every acceptance gate passed.
Baseline: b49e7b0. Preserve the restored bars; workspace additions are indicators only.

## Deployed shared behavior

- Focus follows the pointer (`input.follow_mouse=1`); both profiles have the same live setting.
- Seven subjects route across main/lower/upper; ScreenPad Utility is workspace 90. The old ScreenPad workspace 7 was empty. A private pre-migration monitor/workspace manifest is saved under `~/.local/state/sensei-den/migrations/`.
- The workspace enclosure uses the neutral rule color. A reconnecting compositor event reader and authoritative client/monitor snapshots repair stale rail state. Per-output counts no longer depend on the stale Quickshell toplevel cache.
- Media Play and widget controls now use the same selected backend. Login startup selects the official launcher only when configured; the native service condition prevents an unused daemon starting at the next login. Current passive daemon was not killed during listening.
- Music has an explicit native/official backend selector in Account. Official playback uses MPRIS, independent of the catalogue request budget. Selection is private in `~/.config/sensei-den/music.json`; both hosts currently select official Spotify. Selection does not start playback or transfer a Connect device.
- Single-shot controls never retry a skip. Unsupported official queue operations fail clearly rather than controlling another backend. Existing quota and Retry-After gates remain intact.
- Job receipts include schema, inputs/checksums, code revision/dirty flag, execution outcome and output checksums. `job artifacts` lists outputs; `job fetch` verifies and refuses to overwrite a destination. Small transfers are capped at 8 MiB.
- Companion roaming uses separate expiring leases, never input ownership. Local travel is enabled, with 45–90 second opportunities, a landing animation, manual tour/follow/here controls and the existing quiet/reduced-motion controls. Cross-host sender hides before granting; an uncertain remote lease must expire before returning locally.
- Display topology changes stop capture before rebuilding routes and preserve manual pause.

## Observed validation

- Hyprland config errors: none. Runtime follow_mouse: 1.
- Live Web/Misc strip tests reached the correct carriage position in 0.619/0.454 seconds including animation; original logical subject restored afterward.
- Final full suite: 271 tests passed on Arete (36.014 seconds) and Homie (35.184 seconds). Installer safety, backups, rendering and idempotence passed.
- Pointer-only focus passed for two owned GTK windows using a temporary Wayland virtual pointer; fixtures closed, original subject/pointer restored. Warping alone was not accepted as a focus test.
- Fresh local companion capture reviewed. Exclusive cross-host handoff and return separately verified. Existing artwork retained.
- RTX 2060 / PyTorch 2.11 CUDA synthetic baseline completed: 100 measured steps, 0.0763 seconds, finite gradients, ~20.5 MB peak allocated VRAM. This small workload is a harness check, not representative training throughput or a two-node result.
- Official MPRIS status works, reports capabilities and was observed Playing; a single-shot Next plus pause/resume passed on both hosts through both the helper and the live widget IPC route; phone transfer and a two-hour music soak remain unverified.
- Synthetic stationary IMU calibration ran through a real owned systemd job. Bias error: 0.000005803 rad/s. CSV, SVG and metrics received checksummed receipts; metrics retrieval was independently verified. This is not a physical sensor experiment.

## Open gates

Homie returned online and the shared main was deployed. Live checks now cover
cross-host companion handoff/return, input edges and failure recovery, two-node
training and bidirectional checkpoint recovery. Actual external-monitor cable
transfer, unattended cold boot and Windows return remain physical acceptance gates.
A private Tailscale SSH connection was verified; an actual off-site session was not.

Spotify still needs a real mixed playback/phone-control session and soak. Official MPRIS may not expose every queue operation or remote-device capability; the widget reports unsupported operations rather than implying full parity. Custom-client registration is not required for fallback and has not been changed.

No physical drives, firmware entries, credentials, partitions or private application databases were modified.

## Resource sample and recovery

The cursor-renderer process was sampled for 30 seconds hidden and 30 seconds with
companion enabled: 0.067% and 0.033% of one CPU core respectively, RSS 98,972 and
98,988 KiB. The negative CPU difference is sampling noise, **not a speedup**.
This is an idle/enabled sample, not a worst-case animated or cross-host benchmark.
Private measurement JSON is under `~/.local/state/sensei-den/`.

The installer created per-change backups under `~/.local/state/dotfiles-backups/`.
The cursor shell has a separate pre-change backup there. Revert a specific commit
normally and preview deployment to undo source changes; do not reset unrelated
work. Preserve the migration manifest. Do not blindly move workspace 7 back to
ScreenPad after it has acquired user windows. `sensei-den companion roam off`
disables roaming; `sensei-spotify-control backend native` returns native controls.
Nothing here removes private settings, experiments or credentials.

## Homie and connected-Den acceptance

- Official Spotify: user completed keyring unlock/login. Status reports Playing,
  ready and all six transport capabilities. Only the matching official software
  installation was copied to repair an incomplete launcher download; credentials
  and private application profiles stayed local. After explicit authorization, pause/resume and one Next were tested on each host; exactly one track transition was observed per Next. Prior playing/paused state was restored. No phone transfer was simulated. Native selection explicitly starts its service.
- Owned GTK input receiver: eight entry/return combinations passed key, chord,
  click, scroll and held-state release checks. Triple-Control pause/resume and
  Control-Alt-Escape passed. Receiver-stop recovery released in 3.471 seconds;
  stale-entry and cursor-renderer restart recovery passed. Fixtures and independent
  expiry timers were removed; sharing state restored.
- Companion: Arete hid before Homie DP-3 became visible; return to Arete HDMI-A-1
  left the peer hidden. Full windows may suppress wallpaper placement; a passive
  32-pixel perch uses measured empty bar space instead, with no added button.
  Fullscreen, quiet and reduced-motion policies still apply. Companion refreshes
  do not restart native input. Cache-busting component URLs and in-place root
  deployment repair stale Quickshell component/file watches.
- Remote synthetic IMU receipt `20261016T133416-942e5b` ran clean commit 555c74e.
  Metrics and SVG hashes recorded; verified fetch reproduced the bias error
  5.803e-6 rad/s. This is synthetic, not a physical sensor calibration.
- Two-node NCCL completed 100 measured steps in 6.188/6.190 seconds, finite
  gradients and identical model SHA256
  `2a69ab1cf4fbd27c8688be7bb9d90c9db7cf5548bbb4e6b0bda8722a1f21fecf`.
  Single-device loops were 0.0763/0.0831 seconds. Distributed batch was twice the
  single-device batch; no equivalent-convergence or useful speedup claim.
  Whole-interface counters rose roughly 78 MB each way, including other traffic.
  Temporary peer-scoped firewall rules and expiry timers were removed and checked.
- Checkpoints restored on the opposite GPU in both directions with matching
  model hashes. Independent jobs remain the default; GPUs do not pool VRAM.
- Isolated ROS domain-83 publisher/subscriber and return acknowledgment passed;
  no robot commands were sent. Container and fixtures were cleaned up.
- Logical away/auto restored sharing and preserved an existing manual pause.
  Eleven Homie desktop harness checks passed. Physical unplug/replug still needs
  a real cable operation; software simulation is not a substitute.

Private evidence, account state, desktop screenshots and raw experiment artifacts
remain outside the public repository. The gallery capture contains wallpaper and
the companion only, not private applications or keyring dialogs.

## Final UI and regression sweep

- All 19 existing dropdowns opened with valid dimensions and completed reveal on
  each of Arete's four outputs (76/76) and Homie (19/19). This verifies panel
  construction/placement, not every provider-backed action inside every panel.
- Initial Arete openings all followed one stale monitor. Switching
  `ShellState.focusedScreenName()` to the authoritative Spaces monitor snapshot
  repaired routing; the entire 76-case sweep was repeated successfully.
- Field Guide now reads all live compositor and tmux bindings, all configured
  Alacritty bindings, Neovim active maps and lazy plugin key declarations on open.
  Arete inventory: 129 desktop, 314 tmux, 22 terminal and 248 editor rows, plus 61
  curated explanations. These are searchable entries, not 774 distinct chords.
  Application-native defaults and dynamic buffer-local keys remain in native help
  (`:help index`, `:map`); the guide does not pretend to inspect every running app.
  Source/table expansion gives each current desktop binding an action description.
  Curated introductions use watched JSON to avoid stale imported-JavaScript caches.
- Field Guide visually inspected on main: readable panel, search/list and footer,
  no clipped outer geometry. Native input PID stayed unchanged through companion
  reloads on both hosts.
- Storage harness previously accepted an autofs placeholder as a working drive.
  It now enters each mount read-only, inspects the backing filesystem and checks
  protected-volume policy. All six actual volumes passed; four protected volumes
  are read-only. No disk configuration was changed. Current kernel log has no
  descriptor/-71 failures; the historical hardware fault is not declared cured.
- Retention has a non-destructive `sensei-den backup retain-preview`; the real
  Arete preview succeeded. Reserve checks preserve existing snapshots on failure.
- One repeated input run failed its exact return-coordinate assertion on the final
  crossing after seven passed. Cleanup released input; it did not remain captured.
  No cause was established, so no speculative runtime patch was applied. A fresh
  full eight-crossing run plus pause/resume, stale-helper, stopped receiver,
  renderer-restart and emergency-release tests subsequently passed (3.472-second
  stopped-receiver recovery). This transient remains a monitoring concern, not
  evidence that input can never fail.

## Plan coverage and explicit remaining gates

| Milestone | Implemented / observed | Remaining acceptance |
| --- | --- | --- |
| P0 routing | Seven-subject contract, separate Utility 90, live rail/focus repair, topology/manual-pause recovery, mocked roles and live edges | Actual repeated cable hotplug |
| P1 music | Official fallback on both, local single-shot transport, preserved catalogue gates, real pause/resume/Next | Phone-controlled ownership/position, network interruption and long soak; provider API quota remains external |
| P2 continuity | Both hosts online, private SSH, logical away/return, sharing/modifier/failure checks, existing sync/clipboard tests | Actual away-network and suspend journey |
| P3 display/boot | EDID/profile policy and live widgets retained; native PC desktop checks pass | Physical panel transfer, unattended boot and Windows return; no reboot performed |
| P4 jobs/compute | Checksummed remote robotics receipt, GPU baselines, two-node gradients, both-direction checkpoint restore, reserve guard and retention preview | Real sensor/production training workload is optional future work |
| P5 companion | Exclusive cross-host leases, safe wallpaper placement/perch, independent preferences, real local GIF, resource sample | Worst-case animation profiling and longer daily use |
| P6 release | Shared main, profile deployment, tests, reviewed assets and recovery evidence | Hardware/provider gates above stay visible |

No remote command can physically move a cable or verify a phone's displayed
playback position. Those acceptance rows remain open deliberately. This pass does
not reclassify them as done because software tests succeeded.
