# Engineering Den / execution ledger

Approved 2026-10-17. Preserve input sharing, source ownership, private state and host hardware policy.

| Phase | Acceptance | State |
|---|---|---|
| P0 | Homie fresh zsh login; camera controls fit ScreenPad | In progress |
| P1 | Validated shared actions, explicit projects and durable bounded receipts | Pending |
| P2 | Hardware passports; re-enumeration and event-driven RobotBench | Pending |
| P3 | Named simulation preflight and scoped ROS instruments | Pending |
| P4 | Structured lab results; durable two-host queue and explicit launch | Pending |
| P5 | Run-linked evidence and explicit bounded MCAP | Pending |
| P6 | Source-owned agenda plus Noesis deployment doctor | Pending |
| P7 | Suggested/pinned instruments and recoverable integrated display editor | Pending |
| P8 | Receipt-driven Zondo; expanded original activities and interactions | Pending |
| P9 | Both-host desktop, offline, safety, resource and recovery acceptance | Pending |

Decisions: reviewed project tasks only in GUI; user chooses host; lively Zondo respecting DND/fullscreen/reduced motion; ScreenPad suggests then pins; scheduled learning reviews included in agenda. No online chatbot or automatic flashing/vehicle control. Actions validate in backend on each host. Same-UID applications remain within the user's OS trust boundary.

Research basis: Docker Compose readiness and daemon security; systemd resource control/udev; ROS topic statistics and MCAP; GNOME timed display rollback; Qt bounded ScrollView; RFC5545 source-qualified calendar identity; Microsoft Human–AI interaction guidelines. Sources and rationale are in the approved conversation plan; implementation evidence is appended here.

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
