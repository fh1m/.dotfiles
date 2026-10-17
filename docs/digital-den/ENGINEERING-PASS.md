# Engineering Den / execution ledger

Approved 2026-10-17. Preserve input sharing, source ownership, private state and host hardware policy.

| Phase | Acceptance | State |
|---|---|---|
| P0 | Homie fresh zsh login; camera controls fit ScreenPad | Validated |
| P1 | Validated shared actions, explicit projects and durable bounded receipts | Validated |
| P2 | Hardware passports; re-enumeration and event-driven RobotBench | Shipped; synthetic identities tested |
| P3 | Named simulation preflight and scoped ROS instruments | Shipped; live container preflight tested |
| P4 | Structured lab results; durable two-host queue and explicit launch | Validated; explicit CPU/RAM limits |
| P5 | Run-linked evidence and explicit bounded MCAP | Shipped; nonempty MCAP fixture verified |
| P6 | Source-owned agenda plus Noesis deployment doctor | Validated source-owned projection |
| P7 | Suggested/pinned instruments and recoverable integrated display editor | Shipped; rollback and independent pin tested |
| P8 | Receipt-driven Zondo; expanded original activities and interactions | Validated renderer and receipt contracts |
| P9 | Both-host desktop, offline, safety, resource and recovery acceptance | Validated on both hosts; boundaries below |

Decisions: reviewed project tasks only in GUI; user chooses host; lively Zondo respecting DND/fullscreen/reduced motion; ScreenPad suggests then pins; scheduled learning reviews included in agenda. No online chatbot or automatic flashing/vehicle control. Actions validate in backend on each host. Same-UID applications remain within the user's OS trust boundary.

Research basis: Docker Compose readiness and daemon security; systemd resource control/udev; ROS topic statistics and MCAP; GNOME timed display rollback; Qt bounded ScrollView; RFC5545 source-qualified calendar identity; Microsoft Human–AI interaction guidelines. Sources and rationale are maintained in [ENGINEERING-RESEARCH.md](ENGINEERING-RESEARCH.md); usage and recovery are in [ENGINEERING.md](ENGINEERING.md).

## Evidence so far

- Homie's login shell changed through authenticated sudo to `/bin/zsh`; fresh SSH passwd readback confirms it. Existing sessions preserved.
- Camera popup is now bounded/scrollable and was visually inspected on the real ScreenPad at 480 logical pixels high. Found and repaired a second issue: bar hover must not relocate an already-open popup. Per-output camera state prevents invisible old instances from keeping preview active.
- Registry contract suite: 10 passed. Rejects unknown actions, extra arguments, changed task trust, expired and reused confirmations. No generic shell execution endpoint.
- Real two-job queue on Arete: both succeeded with hashed artifacts, the second started only after the first finished, and list retained succeeded independently of unit liveness. CPU and memory limits were set on the owned units.
- Synthetic experiment/baseline test passed with explicit m/s units and a measured zero delta; a passed process never implies hypothesis acceptance.
- Existing Mongla checkout registered privately. Real auv-ros2 environment preflight passed; bounded ROS discovery observed zero application nodes and the two standard topics. No vehicle commands were sent.
- Real four-output same-geometry transaction armed an independent rollback worker; automatic rollback completed, original configuration was unchanged, and the native input process PID did not change.
- Full suite passed 335 tests before the latest incremental additions; rerun required before release. Earlier broad run caught one overstrict status-wording regression in a new joke; wording was repaired, not the test weakened.
- MCAP compatibility testing caught Humble's positional-topic CLI and a Docker-root ownership mismatch. The helper now inspects actual recorder help; subsequent fixture tests run as the host UID. Nonempty-message acceptance is still being verified; an empty MCAP file is not counted as success.

## New interfaces

`sensei-actions list|inspect|prepare|run|overview|projects|register|trust|trust-environment|doctor|receipts` returns bounded JSON. `--host homie` selects the host explicitly; no fallback execution or replay after an uncertain launch. Private catalog: `~/.config/sensei-engineering/projects.json`. Definitions and their trust hashes are separate. Read queries use no confirmation; session/execution/write actions require a prepared single-use token.

`sensei-hardware list|watch|register` stores private passports, uses udev discovery without opening serial ports, and distinguishes ambiguous identity matches. Diagnostics refer to reviewed project tasks, not embedded arbitrary commands.

`sensei-lab run --parameters FILE --metrics PROJECT_RELATIVE_JSON --baseline RUN_JSON -- COMMAND…` records structured measurements. `sensei-den job run` accepts optional `--memory-mib` and `--cpu-percent`; one owned worker runs per host, waiting workers block in flock rather than poll.

`sensei-display-layout list|apply|confirm|rollback` owns transactions. A systemd worker performs rollback independently of QML. Confirmed Lua is conditional on the actual EDID bytes; the routing helper ignores stale profiles when connected hardware changes. `nwg-displays` remains recovery tooling.

`System → Digital Den → Engineering` offers projects, explicit-host jobs, hardware and Zondo activities. Launcher entries come from the registry. ScreenPad instruments are opt-in, temporary independent surfaces; they do not replace main-display dropdowns. Camera recording remains off; audio return is explicit and time-limited.

## Assets

Six original transparent 4×4 imagegen sheets: workshop, play, quiet, music, curiosity, rest. Each row has four poses for one of 24 activities. Returned dimensions are 1254×1254, not the requested 1024. `activity-atlases.json` records inspected gutter boundaries; Python/Pillow was used only to inspect alpha boundaries, never edit the artwork. The renderer loads the selected sheet only, disables persistent image caching for these sheets and pauses after a short cycle. 108 authored lines extend the curated pool to 160 without invented biography or simulated test results.

Prompts used the existing `zondo-life-v2.png` as reference: black-haired chibi engineer, black hoodie, raspberry headphones/sneakers, full-body transparent padded 4×4 grid, four successive frames per row, consistent scale, no text/borders. Activities: solder/IMU calibration/robot repair/sensor inspection; paper plane/gear balance/high five/confetti; rain/hammock/geometry/stones; drums/bass/headphones/conducting; telescope/paper boat/gyroscope/geometric model; yoga/tea/aquarium robot/welcome flag. Actual sprite variants were visually inspected before integration.

## Additional acceptance evidence

A real five-second MCAP capture in auv-ros2, UID 1000, domain 101, localhost-only Fast DDS recorded and verified the unique synthetic String topic: one 5090-byte MCAP. Original Cyclone DDS loopback fixtures produced empty recordings and are not counted as passed; the installed middleware preference was not changed. The publisher and all disposable recordings were removed after bounded tests.

Confirmed-profile generated Lua byte-compiles successfully without executing monitor calls. A real same-geometry four-output transaction automatically rolled back after its independent watchdog; source configuration and input PID remained unchanged. Camera panel was visually inspected on ScreenPad with preview off; all selectors and actions are reachable in its bounded scroll view.

Source milestones: d04e549 backend/actions/evidence; 669a241 desktop instruments, linked agenda and display editor. Homie deployment, final resource sample and desktop journey checks remain the release gate. No reboot, physical board disconnect, vehicle control or microphone listening was performed.

## Release acceptance / 17 October

- Shared registry contracts and exact-task confirmations passed. Homie→Arete now uses the existing restricted gateway; catalog/trust editing is excluded. Host changes discard stale UI responses rather than attach their data or deferred action to another machine.
- A real confirmed Arete→Homie `check-contracts` job (`20261017T125826-ea7c99`) completed: 13 tests, exit 0; its log and terminal state remained readable through the shared action API. Queue admission is locked and bounded to 16 pending/running jobs; no GPU scheduler or implicit host selection is claimed.
- Full release suite: **354 tests passed on each host** (Arete 40.2 s; Homie 37.2 s). Focused source-ownership, identity, confirmation, unit and input-generation checks were repeated after the final edits. Python syntax and `git diff --check` passed.
- Noesis review fixtures verified stable source-qualified identity, completion, retirement, conflicting heads and duplicate-vault suppression. Registered hardware identity fixtures verified re-enumeration, duplicate ambiguity and vendor mismatch. No real board was unplugged or opened.
- All **24** new atlas activities were selected in the actual renderer: **24 matched**, **24 Ready**. Original preference keys were restored afterward. Arete's separate renderer sampled **0.0% of one CPU core over three seconds**, RSS **114104 KiB**. This is a short idle observation, not a battery-life benchmark or Homie resource measurement.
- Real ScreenPad instrument remained available while a main-display System popup opened. Observed instrument geometry: 752×480 logical pixels within the 1920×550 panel; main popup retained eDP-1 origin even when another display gained focus. Camera panel controls were separately inspected earlier; no microphone listening was performed.
- Visual review shortened clipped tabs/buttons and removed unrelated project controls from the off-duty page. Gallery images are actual UI crops, inspected before publication, with no camera preview or private research contents.
- Existing encrypted Restic scopes on **both** hosts gained engineering config/state, job history and lab receipts. A real fixture snapshot restored to another temporary location with matching SHA256. This is not a full disaster-recovery rehearsal or off-site backup claim.
- Live input testing found a real overlapping-edge helper storm. The source fix, backed-up matching headless binaries and nonblocking helper were deployed. All four routes and triple-Ctrl release/resume passed. Native input was deliberately stopped only for this safety repair/test; the later main-shell refresh preserved its PID. Independent safety expiry remained armed during cursor tests. See INPUT-HARDENING.md for the failed initial cold attempt and bounded readiness improvement.

### Explicit test boundaries

No physical firmware/vehicle operations, reboot, real serial-board unplug, microphone listening, changed orientation/main-display acceptance, or physical cable removal was performed. MCAP passed with explicit Fast DDS only; original Cyclone loopback fixture failures remain documented. Evidence selection is user-directed and was not used to manufacture learning content in a private vault. Multi-profile chooser, remote display editing, automatic GPU admission and a permanent engineering dashboard are deliberately outside this small first implementation. Neither a passed process nor a Zondo message certifies scientific correctness.

Final Homie suite initially exposed missing Restic (two genuine recovery errors). Installed the repository package `restic 0.19.1-1.1`, declared it in `packages/core.txt`, repaired stale installation guidance and added the dependency to doctor. Both final suites then passed all 354 tests. No tests were disabled to obtain the result.

Immediate encrypted engineering checkpoints captured 17 small files on Arete and 20 on Homie. Each checkpoint's actual project catalog was restored to a separate temporary directory and matched its original SHA256; restored copies were removed. Existing scheduled scopes include the same durable directories. Final shared input/cursor/watch services are active on both hosts; no failed user units and no outstanding crossing helpers were observed. Both installers report `changed: []`. Main-shell refresh on both hosts preserved native input PIDs. Homie's actual engineering panel was visually inspected while querying Arete through the restricted reverse route.
