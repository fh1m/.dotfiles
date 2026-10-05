<div align="center">

<img src="docs/assets/banner.svg" alt="fh1m // Sensei Robotics Workstation" width="100%">

**Two screens. Two GPUs. One opinionated workbench.**

[![Hyprland](https://img.shields.io/badge/Hyprland-0.56%2B-f23d70?style=flat-square)](docs/installation.md) [![Quickshell](https://img.shields.io/badge/Quickshell-0.3-f23d70?style=flat-square)](home/.config/quickshell/wrayth) [![Displays](https://img.shields.io/badge/displays-2-17131a?style=flat-square)](docs/hardware-and-boot.md) [![RTX](https://img.shields.io/badge/RTX-2060-f23d70?style=flat-square)](docs/gpu-and-chrome.md) [![Lab](https://img.shields.io/badge/lab-ARM_%2B_CUDA-17131a?style=flat-square)](docs/robotics.md) [![License](https://img.shields.io/badge/license-GPL--3.0-f23d70?style=flat-square)](LICENSE)

[Install](docs/installation.md) · [Gallery](docs/gallery.md) · [Keybinds](docs/keybindings.md) · [Robotics lab](docs/robotics.md) · [Performance](docs/performance.md) · [Recovery](docs/operations.md)

<img src="docs/assets/flight-deck.gif" alt="The real dual-GPU workstation opening its System and Music panels" width="100%">

<sub>Real desktop. Real windows. Real controls. [Watch in MP4](docs/assets/flight-deck.mp4).</sub>

</div>

## Two displays, one desk

<p align="center"><img src="docs/assets/desktop-empty-main.png" alt="The empty 4K main display and its top instrument rail" width="100%"><br><sub>MAIN DISPLAY // CODE, BROWSER, SIMULATION</sub><br><img src="docs/assets/desktop-empty-screenpad.png" alt="Tiled ScreenPad wallpaper and its bottom instrument rail" width="100%"><br><sub>SCREENPAD // WORKSPACES, DIAGNOSTICS, PHONE, USB</sub></p>

*The ScreenPad earns its pixels. The RTX earns its watts.* [Hardware map](docs/hardware-and-boot.md) · [GPU paths](docs/gpu-and-chrome.md)

## Code in the foreground, lab one click away

![Real floating terminal windows with Mongla calibration code and a CUDA Compose recipe](docs/assets/floating-workstation.png)

<sub>[Mongla’s held-out optical-flow calibration](https://github.com/fh1m/mongla_ws/blob/main/tools/flow_derot_calibrate.py) · [CUDA/ARM Compose recipe](examples/compose.robotics.yaml). Actual files, not terminal wallpaper.</sub>

![The robotics panel moving through Launch, tmux, ARM/GPU and Tasks](docs/assets/robotics-lab.gif)

<sub>Docker · Compose · serial devices · NVIDIA CDI · ARM through QEMU · tmux · experiment tasks. [MP4](docs/assets/robotics-lab.mp4) · [Lab guide](docs/robotics.md)</sub>

## The terminal remembers

![A real Alacritty and isolated tmux lab session switching between calibration and GPU/container facts](docs/assets/tmux-field-lab.gif)

<sub>Alacritty + Iosevka + persistent tmux. Sessions survive the window; the status line tells you where you landed. [Full-size still](docs/assets/tmux-field-lab.png) · [MP4](docs/assets/tmux-field-lab.mp4) · [Terminal guide](docs/terminal.md)</sub>

## The lower deck is working

![ScreenPad moving from the system monitor to the USB inspector](docs/assets/screenpad-tools.gif)

<sub>Monitor catches a 15-second stall trace; USB shows ports, permissions and processes. [MP4](docs/assets/screenpad-tools.mp4) · [All panels](docs/gallery.md)</sub>

## Small windows, useful jobs

![Spotify panel with large album art, queue and transport](docs/assets/music-panel.png)

<sub>Music // album art, queue, library, devices, lyrics. [Audio notes](docs/audio-and-spotify.md)</sub>

<p align="center"><img src="docs/assets/system-panel.png" alt="System panel with connection controls, volume, brightness and power" width="70%"></p>

<sub>System // controls, hardware, robotics, network, packages.</sub>

![Inset native tabs for Alacritty and Obsidian](docs/assets/signal-ledger/tabs-v2.webp)

<sub>Alacritty ⇄ Obsidian. Native Hyprland tabs, inside the window silhouette. [Keybinds](docs/keybindings.md)</sub>

<details><summary>More panels, code, and a very serious comic</summary>

[Every widget, full-size](docs/gallery.md) · [Mongla code close-up](docs/assets/mongla-code.png) · [XKCD intermission](docs/assets/comic.png) · [Phone bridge](docs/phone.md) · [Audio route](docs/audio-and-spotify.md)

</details>

## Numbers before adjectives

| Measured on this machine | Why it matters |
|---|---|
| **22.6% → 6.6%** Intel render share | Alacritty replaced Kitty for the same animated terminal test. |
| **286/s → 0/s** unused ScreenPad I²C interrupts | Disabled touch-controller noise; display and brightness still work. |
| **0.225%** NVMe busy in an apparent “I/O stall” | The bottleneck was Intel display fences, not the SSD. |

*Workload samples, not universal benchmarks.* [Methods and limits](docs/performance.md). Built for an [ASUS ZenBook Pro Duo UX581GV](docs/hardware-and-boot.md); the starting spark was [Wrayth by bowenbride](https://github.com/bowenbride/wrayth). [Credits](THIRD_PARTY.md).

## Bring your own workbench

```sh
git clone https://github.com/fh1m/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
python3 scripts/install.py                 # preview
python3 scripts/install.py --apply         # backs up user files
bash scripts/build-native.sh
python3 scripts/doctor.py
```

[Read the install guide](docs/installation.md) before applying the UX581GV display preset. Credentials, browser profiles, device pairings, and clipboard history stay out of this repo.
