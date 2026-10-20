# Sensei · Windows setup

Windows-only setup for the Sensei look: tiling, status bar, terminal, prompt, gaming and robotics.
Colours come from `windows/palette/sensei.json`.

## Tiling: GlazeWM + YASB

- **GlazeWM** (v3.10.1, `standalone-glazewm-v3.10.1-x64.msi`, 5,124,096 bytes,
  SHA-256 `ad4122dd4420690e502e7df3ce8d1e4772bf1246cc815db0dd2aaac0e4dc583f`).
  Source: https://github.com/glzr-io/glazewm/releases/tag/v3.10.1. Install the MSI from that page and approve the UAC prompt yourself.
  Config: `%USERPROFILE%\.glzr\glazewm\config.yaml`, from `windows/home/.glzr/glazewm/config.yaml`.
- **YASB** (status bar). It has native GlazeWM widgets:
  `glazewm.workspaces.GlazewmWorkspacesWidget`, `glazewm.tiling_direction.GlazewmTilingDirectionWidget`,
  `glazewm.binding_mode.GlazewmBindingModeWidget`.
  Source: https://github.com/amnweb/yasb/wiki (widgets pages). GlazeWM starts YASB via `startup_commands`.
- **Why GlazeWM and not komorebi:** komorebi's control socket refused connections on this Windows build
  (10.0.26300). Two `komorebic` restarts failed the same way, and I found no matching komorebi issue.
  komorebi and whkd are removed from the repo; their folders are still on disk.
- **Keybindings** use `alt`. `alt+space` stays with Flow Launcher. Full list in the GlazeWM config.

## Terminal and prompt

- PowerShell 7 with Starship (`windows/home/.config/starship.toml`).
- Alacritty and Windows Terminal, both using the Sensei palette (`windows/home/AppData`).
- Font: Iosevka Nerd Font Mono (per-user install). Fallback in the stylesheet: JetBrains Mono Nerd Font.

## Gaming (GTX 1660 SUPER, 6 GB VRAM)

Sources read: NavThemes (1660 Super on Windows 11, 2026), Switchblade Gaming (GTX 1660 Super settings),
BetterFPS per-game guides, FPS Calculator (Windows 11 gaming settings), The Frame Coach (Control),
windowsforum.com (Windows gaming tweaks), XDA Developers (gaming on Windows).

- **VRAM is the limit.** Textures: High, not Ultra. Dropping Ultra to High usually frees 500–800 MB
  (Switchblade). Ray tracing off. FSR Quality or Balanced for extra frames.
- **Power:** High Performance plan. Game Mode on. Game Bar and background recording off.
- **NVIDIA Control Panel:** Power management Prefer maximum performance, Vertical sync off, Low Latency on.
  Reflex On + Boost where a game supports it.
- **HAGS:** test on and off with the same scene, restarting Windows between runs. Results are mixed:
  sources report anywhere from a ~1–4% gain to a low-single-digit loss. HAGS can take up to 1 GB of VRAM,
  which matters on 6 GB.
- **Not applied:** disabling Memory Integrity (VBS). One guide claims up to 15% FPS; I could not verify
  that, and it is a security trade-off.

## Robotics (ROS 2)

- **Path that works here:** WSL2 with Ubuntu 24.04 and ROS 2 Jazzy (`ros-jazzy-desktop`).
  The Jazzy Debian install steps are on docs.ros.org. Third-party walkthrough:
  https://techoverflow.net/2024/12/08/how-to-install-ros2-jazzy-desktop-on-ubuntu-24-04/
- **WSL is not installed on this PC yet.** Installing it needs admin: `wsl --install -d Ubuntu-24.04`,
  with a UAC prompt for you to approve. ROS 2 itself does not need CUDA.
- **Networking:** WSL2 mirrored mode is the first thing to try (`networkingMode=mirrored` in `.wslconfig`).
  Multicast results conflict across reports: microsoft/WSL discussion #10614, issue #10960 (roscore hangs
  under mirrored mode), ros2cli issue #934 (daemon check fails under mirrored mode on Humble).
  If discovery still fails, use a Fast DDS discovery server, which avoids multicast
  (https://github.com/eProsima/Fast-DDS-docs).
- **Isaac Sim:** NVIDIA marks WSL as deprecated for ROS 2 and recommends a native Pixi install on
  Windows 11 for Jazzy: https://docs.isaacsim.omniverse.nvidia.com/6.0.0/installation/install_ros_other_platforms.html
- **Hardware:** community consensus is that WSL is fine for learning and simulation but limited for
  hardware access. Dual boot is the cleaner choice for serious hardware work.

## Install order

1. `windows/tools/install.ps1` (dry run), then `-Apply`. No admin.
2. Install GlazeWM from its MSI (UAC).
3. Re-run `install.ps1 -Apply`. It then writes the GlazeWM autostart entry (`Sensei-Tiling`).
4. Robotics only: `wsl --install -d Ubuntu-24.04` (UAC), then the ROS 2 steps above.

Passwords, PINs and UAC prompts are entered by the user, not by any script.
