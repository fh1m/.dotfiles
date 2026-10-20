# Port notes: Linux desktop → Windows

## Principle

Same aesthetic and the same way of working, built from Windows-native parts. Nothing
here imports Linux files. Shared values live in `windows/palette/sensei.json` only.

## Mapping

| Linux (Arete / Homie) | Windows-native match | Status |
|---|---|---|
| Alacritty | Alacritty for Windows, launches PowerShell 7 | Ported (`windows/home/AppData/Local/alacritty`) |
| zsh + Starship | PowerShell 7 profile + Starship | Ported (profile, `windows/home/.config/starship.toml`) |
| Palette (sensei colours) | `palette/sensei.json` rendered into each app | Ported |
| tmux sessions | Windows Terminal profile (fragment) | Profile ported; panes and tabs are native WT |
| Neovim config | Neovim for Windows | Not ported yet; audit `main`'s Lua config for Linux-only paths first |
| Hyprland (tiling WM) | komorebi + whkd, or GlazeWM | Planned; needs a hotkey map from `main`'s Hyprland config |
| Quickshell bar (Wrayth) | yasb, themed from the same palette | Planned |
| Den input sharing, Zondo | none | Not available on Windows; Wayland-specific |
| `scripts/install.py` | `windows/tools/install.ps1` | Ported (dry run, backups, idempotent, no root) |
| `scripts/install.py` manifests | not yet | Restore-from-backup script is planned |

## Lag findings (2026-10-20, read-only)

Measured while the machine was near idle, plus event logs for the last 24 hours.

1. **Storage reset.** `storahci` event 129 ("Reset to device, RaidPort0") at 15:10.
   Resets stall every disk. The disk on RaidPort0 is not yet identified.
2. **Unclean reboot.** Kernel-Power 41 at 14:42. Check `C:\Windows\Minidump` for the cause.
3. **Memory pressure.** 16 GB RAM, about 10 GB committed, a pagefile of about 2.9 GB,
   and 19 Chrome, 13 Claude and 12 WebView2 processes.
4. **Refresh rate.** The NVIDIA reports 60 Hz; the LG panel supports about 75 Hz.
5. **Post-boot work.** The uptime was under an hour, so indexing and Defender were active.

No display driver resets (TDR), no WHEA errors, and all disks report Healthy.

Reproduce: `windows/tools/Test-HomieWindows.ps1` (elevated) plus
`Get-WinEvent -LogName System -FilterHashtable @{Level=1,2,3}` for the last day.
