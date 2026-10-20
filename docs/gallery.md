# Actual desktop gallery

[← Digital Den](../README.md)

## The whole Den

<picture><source media="(prefers-reduced-motion: reduce)" srcset="assets/digital-den/den-layout.png"><img src="assets/digital-den/den-layout.gif" alt="Five real workspaces in their physical orientation, with animated pink input routes and a typing engineer avatar" width="100%"></picture>

Two external displays stacked at left. Homie at upper right. Arete and ScreenPad below. [Full-size still](assets/digital-den/den-layout.png) · [Capture and illustration notes](digital-den/GALLERY.md).

## Code and context / main

![Neovim and tmux beside Mongla on GitHub](assets/digital-den/arete-main.gif)

[Native-size image](assets/digital-den/arete-main.png) · [Actual executed check](../examples/den-calibration-check.py)

## Reasoning and mechanisms / upper

![Obsidian with a real MathJax equation and experiment Canvas](assets/digital-den/arete-upper.png)

[Native-size image](assets/digital-den/arete-upper.png) · [Public study example](../examples/den-study/Calibration%20lab.md)

## Documentation and the day / lower

![ROS documentation, Calendar and Weather in floating panels](assets/digital-den/arete-lower.gif)

[Native-size image](assets/digital-den/arete-lower.png)

## Small jobs / ScreenPad

![Examples folder and the executed calibration sanity-check summary](assets/digital-den/arete-screenpad.gif)

[Native-size image](assets/digital-den/arete-screenpad.png)

## Home base / Homie

![Live PC telemetry and System over Neovim and NVIDIA documentation](assets/digital-den/homie-live.gif)

[System](assets/digital-den/homie-system.png) · [Monitor](assets/digital-den/homie-monitor.png) · [Code](assets/digital-den/homie-code.png) · [Hardware](digital-den/HARDWARE.md)

## Arete, portable

These are real screenshots of fh1m’s desktop. A temporary privacy mode suppresses personal notifications and private window previews. The code window opens [Mongla’s public optical-flow calibration](https://github.com/fh1m/mongla_ws/blob/main/tools/flow_derot_calibrate.py); the other shows this repo’s CUDA Compose recipe. Neither screenshot claims a vehicle or container was running. The system numbers are live samples.

![Main display above ScreenPad, animated as one two-screen desk](assets/duo-hero.gif)

[Full-quality paired tour](assets/duo-hero.mp4) · [Reduced-motion still](assets/duo-hero.png). The two screen tours were recorded separately and edited into one spatial view.

![Robotics work on the main display paired with Monitor and USB inspection on the ScreenPad](assets/duo-lab.gif)

[Lab pair MP4](assets/duo-lab.mp4) · [Reduced-motion still](assets/duo-lab.png). Both panels are real recordings, paired for the gallery.

## Watch the workbench work

![Main display: System and Spotify over real working windows](assets/flight-deck.gif)

[Main display MP4](assets/flight-deck.mp4) · [Full-size floating workstation](assets/floating-workstation.png)

![Robotics panel: launching environments, tmux, ARM/GPU and tasks](assets/robotics-lab.gif)

[Robotics MP4](assets/robotics-lab.mp4) · [Lab guide](robotics.md)

![Alacritty and tmux with public Mongla code, GPU metrics and container inventory](assets/tmux-field-lab.gif)

[Tmux MP4](assets/tmux-field-lab.mp4) · [Full-size still](assets/tmux-field-lab.png) · [Terminal guide](terminal.md)

![ScreenPad switching from Monitor to USB inspection](assets/screenpad-tools.gif)

[ScreenPad MP4](assets/screenpad-tools.mp4)

| Surface | Purpose |
|---|---|
| Empty main + ScreenPad | The actual stacked UX581GV desktop before showcase windows open |
| Main workspace | Comfortable code reading on the main panel |
| ScreenPad | Navigation and practical tools on the second display |
| System | Quick controls, hardware, robotics, networking and packages |
| Monitor | Live resources, processes and hardware views |
| Spotify | Native player, artwork, transport, queue/library/devices |
| Sound | Per-device and per-app routing/volume/profile controls |
| Calendar | Calendar and time-manager entry |
| Docker | ARM and native NVIDIA tooling within the lab |
| Phone | Calls/messages feature entry without publishing personal conversations |
| USB | Current device inventory and diagnostic entry |
| Weather | Forecast view |
| Launcher | Native icons and search |
| Operator | Live CPU, available RAM, CUDA work and lab shortcuts |
| Native tabs | Alacritty and Obsidian with a cut-corner, inset title strip |
| XKCD | Right-click intermission, with keyboard and swipe navigation |

## Main / ScreenPad

*Big canvas above; tiled instrument field below. The repeat is deliberate.*

![Empty main](assets/desktop-empty-main.png)
![Empty ScreenPad](assets/desktop-empty-screenpad.png)

![Main code workspace](assets/desktop-main.png)
![ScreenPad](assets/desktop-screenpad.png)

## System and observability

![Operator deck](assets/operator.png)
![System](assets/system.png)
![Monitor](assets/monitor.png)
![USB](assets/usb.png)

## Music and sound

![Spotify](assets/spotify.png)
![Sound](assets/sound.png)

## Time, weather and phone

![Calendar](assets/calendar.png)
![Weather](assets/weather.png)
![Phone](assets/phone.png)

## Robotics and navigation

*The code is a held-out calibration fit from the public AUV stack; the terminal is set smaller so you can read more than twelve lines at once.*

![Mongla optical-flow fit in the terminal](assets/mongla-code.png)

![Docker](assets/docker.png)
![Launcher](assets/launcher.png)
![Native Alacritty and Obsidian tabs](assets/signal-ledger/tabs-v2.webp)

## Intermission

*An engineer may press Right Click to consult a stick figure. This one is [XKCD #3306](https://xkcd.com/3306/) by Randall Munroe ([CC BY-NC 2.5](https://xkcd.com/license.html)).*

![XKCD in the shell](assets/comic.png)
The [switcher implementation](../home/.config/quickshell/sensei/modules/navigation/NavigationOverlay.qml) combines app/window cards with a six-space drag overview. On the reference hybrid-GPU session, `grim` stalled while the live toplevel previews were active, so these two surfaces are deliberately absent from the gallery. They remain available with Alt+Tab and Super+A in the actual session.

## Engineering, then a small detour

### Choose the host. Keep the receipt.

![Live Engineering workspace showing the confirmed Homie contract job and preserved earlier robotics runs](assets/digital-den/engineering/jobs.png)

[Projects, passports and evidence](digital-den/ENGINEERING.md). Real job results; a process passing does not certify a scientific claim.

### Arrange the screens, with a way back

![Live integrated display editor with the actual four Arete outputs, scale, orientation and timed confirmation controls](assets/digital-den/engineering/displays.png)

The map is this laptop’s attached outputs. Homie keeps its own display settings.

### Zondo is off duty

![Live local play corner: high five, boat, tea, a logic problem and silent rhythm](assets/digital-den/engineering/zondo-play.png)

Original sprites, short animation bursts and no online conversation model. Arete and Homie remain his shared home.

## Re-capture on your machine

`scripts/capture-gallery.py` takes the stills. `scripts/capture-showcase.py` records the main/ScreenPad tours; `scripts/capture-workflows.py` records the robotics/tmux tours. `scripts/build-duo-hero.sh` pairs them into the two-screen scenes. Capture scripts use the live desktop, restore focus and close only their showcase windows. Review frames before publishing; new widgets may need additional privacy treatment.

## The invisible neighbourhood

![Homie's live RTL-SDR spectrum and rolling waterfall in the shared pink-and-black shell](assets/digital-den/radio-lab.png)

Actual receiver data, not a demo waveform. FM, bounded sensor observations, IQ
captures and receipts live behind the tower button. [Radio bench](digital-den/RADIO.md).
