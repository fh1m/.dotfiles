# Controllers · input lab

Open the gamepad button on the bar. It counts connected pads automatically.

- **Live test:** both sticks, analog triggers when reported, D-pad, every exposed
  button and recent raw input events. Sampling is bounded to 30 Hz while open.
- **Tune:** viewer deadzone, 12-second range calibration and reset. Release sticks
  for the first two seconds, then sweep their full range. No movement preserves
  the old profile. These settings do not alter games, Steam or SDL mappings.
- **Device:** kernel driver, USB identity, input node, physical connection,
  force-feedback support and raw axis ranges. Unsupported battery data is labelled.
- **Robotics:** inspect host or a running Docker environment, save ROS rate,
  deadzone, event coalescing, generic/mapped node and sticky-button settings;
  export an input-only launch profile. Save buttons persist each field separately.

Pause stops the tester, **not the controller**. Games retain input. Rumble is a
bounded 350 ms effect. No exclusive grabs or USB permission changes are used.

## Persistence and debugging

Profiles: `~/.config/sensei/controllers.json` (private, atomic replacement).
Exports: `~/.local/share/sensei-controllers/exports/<id>/<timestamp>/`.
Each export contains joy.yaml, hardware identity and a launch README; old exports
are retained. Serial identity survives port moves; pads without serial numbers
use their physical USB path to distinguish identical models. Moving such a pad
may create a new profile.

CLI: `sensei-controllers list`, `environments`, `watch`,
`ros-probe ID ENVIRONMENT`, `export-ros ID`. Watch is read-only and ends with Ctrl-C.
The UI exposes calibration/reset, rumble and saved settings without editing JSON.
Do not assume evdev codes equal ROS Joy array indices. SDL's mapped controller
name can differ from its raw joystick name: the probe records both and exports
whichever the selected ROS node needs. Probe again after moving environments or
changing mappings. Host/container needs Python 3 and SDL2 for probing, ROS joy for
publishing, and explicit access to the device. No container is reconfigured.

## Robotics suitability

The F310 and Xbox-style layout are practical for simulation and manual input.
The generic PS2-style pad also reports sticks/buttons, but its order and analog
capabilities differ. Choose by measured centering, reliable buttons and physical
comfort rather than brand. Inspect every axis and button before assigning it.
Use a held enable/dead-man button, command timeout, limited speeds and simulation
checks in the robot project. Keep sticky buttons off for held enable controls.
This panel does not launch teleop, arm a vehicle or publish velocity commands.

## Verification, 21 October 2026

- Three real devices discovered independently: F310 046d:c21d, Xbox360 045e:028e,
  generic USB Gamepad 0810:0001. Third hotplug appeared without a shell restart.
- Owner confirmed the first two physically work. Full third-pad movement and
  user-performed calibration remain physical acceptance checks.
- Temporary kernel UInput device exercised opposite stick movement plus a button
  through the actual watch process, then was removed. No input grabbed.
- All three exported generic joy_node profiles produced sensor_msgs/Joy in the
  running auv-ros2 container, isolated domain 191 and test namespace. Nodes stopped
  afterward; no robot control commands launched.
- Unit coverage includes numeric capability detection, axis layouts, bounds,
  independent persistence, export names, invalid settings and environment guards.
- Widget visually inspected; no private screenshots or profiles are tracked.

ROS node/name behavior: https://github.com/ros-drivers/joystick_drivers/tree/ros2/joy
Linux gamepad semantics: https://kernel.org/doc/html/latest/input/gamepad.html
