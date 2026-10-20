# Controllers, network and desktop repair — 21 October 2026

Scope: universal controller tester/control panel, integrated network diagnostics,
tray menus, shared workspace indicators and microphone verification.

Discovery: Arete has python-evdev 2.0 and SDL3. No gamepads or Vesktop process /
capture streams are present on Arete. YC1006 USB MIC is the configured default.
Owner confirms controllers are on Homie's hub and requests deferring Homie/USB
work during Windows setup. Do not disrupt or claim to verify that call.

Milestones:
1. Repair tray parent-window coordinates and logical-workspace occupancy. Verify
   all seven workspace transactions and restore the initial subject/output.
2. Add capability-based evdev controller discovery and on-demand live tester,
   calibration profiles and bounded force feedback, plus a bar entry. Never grab
   an input device. Viewer calibration is labelled separately from game settings.
3. Extend existing NetworkWorkbench with structured routes/link/DNS/socket data
   and bounded in-widget diagnostics, optional public-egress/ASN lookup. No scans
   on refresh and no network disconnections during a call.
4. Reuse MeetingCheck in Sound; show actual default mic and capture stream routes.
   Whisper is optional local transcription, not noise reduction or a voice codec.
5. Unit tests, simulated controller stream, live QML/source checks, desktop tests,
   install on Arete, document capabilities/limitations and commit/push.

Done requires actual working controls and honest unavailable states. Physical
controller/calibration/rumble, Homie USB and Vesktop remote listening tests remain
explicitly deferred until Homie returns to Linux. Preserve current audio routing.

## Verified status — 21 October

- Audio first, per owner. See AUDIO-RESEARCH-2026-10-21.md. Corrected misleading DC-inflated metering and added explicit, reversible processing; whisper.cpp sample passes. Listener reports low call volume, and owner cannot reopen Vesktop now. Remote intelligibility/volume acceptance remains pending; no claim of a complete call fix.
- Tray: reproduced native-menu failure in the real shell log. Added UseQApplication at the root and restarted only the supervised shell. Verified the EasyEffects native menu visually beside its Lower bar icon. Correct parent-window coordinates are used instead of a shared arbitrary bottom-bar window.
- Workspaces: live per-output occupancy/counts agree with compositor clients across four outputs and seven subjects. Backend seven-subject switching was exercised earlier and original subject restored. No workspace changes were forced during the owner's current work.
- Network: read-only link counters, system DNS, gateway and public-IP reachability exercised successfully. LAN/port probes remain explicit and confirmation-gated. Public egress lookup is explicit and discloses its external provider.
- Controllers: software WIP preserved. Physical device testing, calibration and rumble are deferred by the owner; do not claim universal game compatibility. Homie is excluded during Windows setup.

## Controller completion — 21 October

Owner subsequently connected three controllers to Arete and confirmed the first
 two work. Fixed numeric evdev capability discovery; added Live/Tune/Device/Robotics
views, hotplug count, independent profiles and bounded rumble. Kernel UInput test
verified simultaneous stick/button events without grabbing physical input.
All three real pads published ROS Joy in auv-ros2 using exported profiles. Direct
SDL probing fixes mapped-name versus raw-joystick-name differences. See
CONTROLLERS.md for tested scope and remaining physical checks. Homie stays excluded.
