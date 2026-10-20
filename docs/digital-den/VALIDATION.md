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

## 20 October — audio, pen, media and popup repair

Arete: 444 repository tests passed after the backend/gateway fixes. Actual YouTube A/V playback passed all four local outputs, with matching audio/video progression, advancing frames, pause/resume and measured instantaneous A/V difference below 0.02 ms in that fixture. This is a short playback test, not a guarantee about all videos or networks.

Homie: the user confirmed PC music through laptop headphones is **clear and responsive**, and confirmed pen strokes draw after the rear USB-port recovery and Pen-tool selection. Direct observations recorded tip-contact transitions and pressure up to 65535. RTL capture measured 19.59 real FFT frames/s (512 bins); terminating the scope left no receiver child. The original hub path had USB protocol failures and is not certified by the direct-port result.

Shared sound controls now include route diagnostics and playback-monitor signal checks; see AUDIO-AND-MEDIA.md. Final deployed UI, popup and Homie media acceptance follows in the deployment receipt below.

### Deployment and desktop acceptance

Both hosts deployed shared main `321d06f`. Native input and cursor services remain active; Arete’s clipboard bridge and Homie storage mount are active. Homie passed all eleven read-only desktop checks and 444 repository tests (one optional test skipped); Arete passed all 444.

Real pointer clicks verified sound buttons both folded and expanded on each host, plus the ScreenPad, Upper, Lower and Homie bottom display controls: all eight cases used the clicked output/edge/centre and stayed within the output. Cursor/fold preferences were restored. Short displays now scroll oversized ordinary panels instead of clipping unreachable actions.

YouTube played the Karpathy micrograd lecture on Homie DP-3 and all four Arete outputs. Live Twitch discovery and a real public stream passed on each host, with advancing rendered frames and pause/resume. Live-stream clocks may restart on reconnect, so the harness requires resume-position continuity only for seekable recordings; live tests still require advancing A/V, rendered frames and bounded sync error. These do not certify every channel, account permission or future network condition.

The fullscreen focus view was visually inspected with artwork, track metadata and large sans-serif timed lyrics. Its diagnostic reported `controlsShown:false` after idle, including paused playback. Movement exposes the controls; Escape/F11 recovery remains available. No always-visible corner buttons remain in this mode.

The RTL panel displayed 512 live bins and 56 waterfall observations without QML errors. Stop released the receiver child. After USB recovery, the tablet and receiver enumerated directly on rear motherboard ports; no further descriptor/TT protocol errors appeared during the observed ten-minute window. The exact VIA model now has a device-scoped no-autosuspend rule; physical hub operation remains unverified.

## 20 October — cursor ownership and docked rails

The previous Arete boot contains 77,849 `compositor released mouse` messages,
peaking at 3,506 in a one-second sliding window. This is a verified input capture
storm. It does not establish the sole cause of the reported whole-machine freeze;
the available kernel journal did not provide a corresponding GPU reset or panic.

Source-level repairs in the pinned Lan Mouse patch:

- Compositor lock loss now emits a capture End through the transport state
  machine. The remote owner and local pointer lock no longer disagree.
- Re-entry inhibition runs before creating/hiding a pointer lock, rather than
  repeatedly grabbing a barrier that the upper layer immediately rejects.
- Stale surface-leave events cannot destroy another barrier's lock. Output
  rebuilds release ownership before destroying/replacing surfaces.
- The optional standard cursor-shape protocol restores the default cursor on
  release and on refused re-entry; hiding it is limited to actual capture.
- A late receiver Leave clears return arming only if no newer incoming owner
  remains. The desktop harness waits for the matching placement generation,
  rather than mistaking a previous entry's armed flag for the current one.
- A five-loss/one-second fail-open guard remains defense in depth. Its independent
  daemon pauses input and centres locally; it never silently resumes capture.

The first guarded build passed two crossings but failed the next exact-position
check. After ownership repairs and generation-aware verification, eight crossings
passed (all top/right entry × bottom/left return combinations, twice), along with
triple-Ctrl pause and resume. Receiver-stop, watcher-restart and native emergency
release checks also passed; receiver-stop released capture in 3.268 seconds.
This is bounded acceptance, not proof that future driver/network faults cannot occur.

Docked layout now uses the full top bar on Upper and the full utility bar on
Lower. Both laptop panels have no bar layers. Three real button-click cases
passed: Upper Sound collapsed/expanded, Lower Display. Popups stayed inside the
clicked output and used its correct edge and anchor. The shared QML expressions
also passed disconnected, partially docked and PC-only routing fixtures.

The XP-Pen is present behind Homie's VIA hub, with its existing writing profile,
threshold 7, pressure, tilt and eraser retained. The targeted hub power rule is
active (`power/control=on`). A watcher bug skipped reapplying an identical profile
after reconnect; disconnect now invalidates its signature. The virtual pen's
identity is also included so a driver restart triggers remapping. A mock
connect/disconnect/reconnect regression verifies reapplication without disturbing
the user's tablet. This pass does not claim a new physical stroke measurement.

Zondo now translates one decoded sprite atlas instead of recropping/reloading its
source each frame. Upper's live capture was visually checked. Dance has a slower
frame cadence and small eased sway; reduced motion still disables movement.
Occasional short sing-along receipts reuse already-loaded timed lyrics, expire
in 30 seconds and never fetch new lyrics. Only eight words plus timestamp/play
state may follow his existing cross-host lease; account data and media URLs do
not. DND, quiet, chatter preferences and non-repetition remain enforced.

Software cursor mode is explicit on both hosts. Its meaning is documented in the
[Hyprland options reference](https://wiki.hypr.land/configuring/core/config-options/).
The native binary, original session scripts and cursor daemon were backed up
privately under `~/.local/state/homie-control/backups/input-guard-*` before deployment.

Final deployment verification: Arete passed 453 Python tests; Homie passed 453
with one optional dependency skip. Five Den Python tests and two native Rust
capture tests passed. The final native binary SHA256 matched on both hosts:
`f4159ff1d41077152bac7dbadb30f1fb0dc40b2e5634e51ff4b7825f42d7acad`.
After cursor-shape restoration was included, all eight crossings and both
triple-Ctrl operations passed again. At 13:22:40 a real isolated compositor
release was followed immediately by `sending Leave event to client 0`, without
a release storm: the repaired backend-to-transport End path was exercised live.

Actual cursor-locator/focus checks passed on eDP-1, DP-1, DP-2 and HDMI-A-1.
Homie's three real popup-click cases also passed; its isolated `uv --with evdev`
test environment supplied the missing harness dependency without changing system
packages. Bar reservations are zero on both laptop panels, 44 px top on Upper,
and 44 px bottom on Lower. Both input/cursor services and Homie's drawing watcher
were active at handoff; no private vault/account data was committed.

Real lyric receipts and live dance frames were observed. A two-minute random
speech observation did not happen to include a sing-along; this is recorded
separately from the passing lyric freshness, privacy, non-repetition and lease
projection tests. The sing-along clock now survives roaming transitions, so short
visits do not restart its entire waiting interval.

## 20 October — lyrics, Zondo and further cursor acceptance

Twelve more normal Den crossings passed, covering all four route combinations
three times, with triple-Ctrl pause/resume. Stale helper, receiver-stop (3.471 s),
watcher-restart and native release-chord tests passed. A fullscreen-music crossing
then failed to enter: the listening room's compositor focus grab was modal and
blocked the native capture barrier. The room is now non-modal. All four crossings
and pause/resume passed with it open after that change. The initial failure is
kept here; it was not labelled passed or hidden behind another watchdog.

Actual focus-room layout checks passed on eDP-1, DP-1, DP-2 and HDMI-A-1: artwork
left, lyric pane right, at least 40 px separation and both sections within output
bounds. The full layout and generated asset ownership are documented in
[Zondo and lyrics](ZONDO-AND-LYRICS.md). The existing reference GIF was inspected;
our fill is line-timed, not a false claim of provider word/syllable timing.

A native D-Bus fixture labelled `KDE Connect` verified phone classification,
retained plain summary/body and DND suppression of speech. It was explicitly a
local test message, not a claim that a physical phone sent it. DND was restored
after the check. New projection tests reject malformed/stale/foreign-host IDs and
strip notification actions/unknown fields. Existing lyric tests now preserve a
complete current line, including its expiry, rather than truncating eight words.

The same entry failure was reproduced with the System dropdown open. During an
active native input session, shared dropdowns now avoid compositor modal grabs
and dismiss passively when another application/monitor gains focus. A watched
`input/running` marker is set by session startup and cleared in ExecStopPost;
normal grabs remain available when the input service is stopped. All four routes
and pause/resume passed with System open after this repair. The new teardown
regression checks that active, return-armed and running markers all clear.

Final polish acceptance: Arete passed 461 Python tests; Homie passed 461 with one
optional skip. Six Den Python checks passed. The generated phone pose and its
real desktop notification bubble were captured and visually inspected: one
character, distinct phone styling, actual owned fixture body and pending badge.
A separate playback observation verified the visible sing-along message exactly
matched the current media lyric line and used the `sing` pose; the song's prior
paused/playing state was restored afterward. Three real popup-click cases passed
on each host after non-modal Den handling. Both input/cursor/presence services,
and Homie's tablet watcher, were active at verification. These are bounded tests,
not a guarantee against every future GPU/network fault.


## Typography and sing-along sizing — 2026-10-20

Arete: 462 tests passed, including enlarged-card collision/bounds cases for
1920×1080, 1920×550 and 1280×720. All six Den tests passed. Live top-bar Sound
(collapsed/expanded) and lower-bar Display placement passed; fullscreen focus
layout and System typography were inspected through local screenshots. Zed Mono
and Iosevka resolve to their actual installed fonts on both hosts. Playback was
left paused after inspection; screenshots and private media state stay local.
The singing geometry tests exercise 300/420 px cards and 96/160/200 px character
sizes, and refuse overlap with the pet footprint or output edges. These are
geometry tests, not a claim of a live lyric-provider test.


During the final app-harness verification, an independent 17:31 system upgrade
had replaced NVIDIA 615.71 userspace with 615.78 while the loaded kernel module
remained 615.71; it also replaced LLVM 22 with 23, leaving the custom Mesa EGL
library unable to resolve `libLLVM.so.22.1`. New Qt windows could not create EGL
contexts. Cached libraries were extracted privately (no package downgrade), and
Intel Wayland EGL initialization passed with that private library path. The
running shell supervisor and a session-only den-cursor systemd override use it.
This is a session recovery, not a permanent graphics-stack upgrade fix. A normal
reboot aligns NVIDIA; the custom Mesa build still needs rebuilding against the
installed LLVM or a properly maintained compatibility package. No reboot,
compositor restart or application shutdown was performed.

After recovery, actual bars, wallpaper and Zondo rendered again, and the full
lyrics-plus-queue view was visually checked with the queue entirely on-screen.
A repeated live popup harness passed the top-bar cases but failed the lower-bar
Display click after the rolling update; another run failed the initial click.
Do not treat the earlier three-case pass as current post-update proof. Homie's
three-case acceptance passed before its final typography-only sync. Graphics/
input acceptance after this host's Qt/NVIDIA/LLVM upgrade remains a separate
follow-up; the typography and geometry unit checks are passing.


## Permanent graphics repair — 2026-10-20

Supersedes the session-only recovery above. See `GRAPHICS-RECOVERY.md`.
Removed the Mesa/lib32-Mesa package hold and completed the signed pending full
upgrade, installing both Mesa variants 26.2.4 against LLVM 23. Unmodified package
files verified; EGL and GLX resolve every dependency. Fresh Wayland EGL reports
Intel UHD 630 / Mesa 26.2.4 without LD_LIBRARY_PATH or LD_PRELOAD overrides.
The shell and companion were relaunched without the old recovery directory;
the session-only systemd override was removed. Input sharing remained active.

Fresh physical bar-click acceptance passed all three cases: Sound collapsed,
Sound expanded on Upper, and Display on Lower. The earlier post-upgrade failures
are no longer reproduced by that complete run. All four laptop outputs are
reported at their native configured modes (main 4K60, ScreenPad 3840×1100 at
60 Hz, both external 1080p100). Six Den regression tests passed; the new read-only
graphics doctor compiled and its live exit-code contract was checked.

The only remaining driver activation gate is reboot: running NVIDIA 615.71.09
versus installed userspace and new CachyOS kernel module 615.78.08. The doctor
correctly exits 2 with no unresolved libraries or held-package warnings. No
reboot has been performed, so post-boot NVIDIA/HDMI acceptance is pending.
