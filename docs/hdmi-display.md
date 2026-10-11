# HDMI on the ZenBook

The internal `eDP-1` and `DP-2` connectors belong to Intel. The HDMI connector belongs to NVIDIA. On 11 October, Linux detected an **LG FULL HD** monitor on `card1-HDMI-A-1` with 1920×1080 modes, but the running Hyprland process allowed only `/dev/dri/card2`. Consequently Hyprland listed only the two internal displays. The connected monitor's gray screen was not an empty Hyprland workspace: its GPU was excluded from the compositor.

The display-manager entry **Hyprland (Intel repair)** invokes `~/.local/bin/hyprland-repair-session`. That wrapper now resolves stable PCI paths and allows both GPUs, with Intel first:

```sh
hyprland-repair-session --print-devices
# Current laptop: /dev/dri/card2:/dev/dri/card1
```

Intel remains the primary renderer. NVIDIA is available for its physically wired HDMI output, including later hotplugging. The existing preferred-mode monitor fallback will configure the external screen. Card numbering is resolved at launch, not hard-coded. The existing ScreenPad modifier workaround remains.

**A logout/login is required.** `AQ_DRM_DEVICES` is consumed when Aquamarine initializes. Reloading QML or the Hyprland config does not add an excluded GPU to this running backend. Do not terminate the desktop while work is open. After logging in through the same session entry with HDMI connected, check:

```sh
hyprctl monitors all -j
hyprctl configerrors
```

Expected: the two internal panels plus `HDMI-A-1`, enabled, at a supported mode. Actual HDMI presentation still needs validation after that login; the current session was deliberately left running.

The previous wrapper is backed up under `~/.local/state/dotfiles-backups/hdmi-session-*`. For Intel-only recovery from a TTY after closing the desktop, use `hyprland-repair-session --intel-only`; `SENSEI_INTEL_ONLY=1` also selects that fallback. Do not start a competing DRM compositor in the current desktop session.

The kernel also logged an HDMI maximum-pixel-clock warning. That is a separate observation, not proof of this failure's cause. Investigate mode/EDID issues only if output still fails with NVIDIA included.

[Hyprland multi-GPU documentation](https://wiki.hypr.land/configuring/extra/multi-gpu/) requires including the GPU owning an external connector, even when it is not the primary renderer. This fix does not claim that the new multi-GPU presentation path has passed long-term stability testing.
## Everyday HDMI behavior

An HDMI display extends to the **left** of the laptop. The helper chooses the highest reported resolution, then its fastest supported refresh rate; 4K-class displays use 2× scaling, lower resolutions use 1×. It uses compositor-reported modes, without custom timings or overclocking. This LG advertises 1920×1080 at approximately **75 Hz** (and 60 Hz). Physical 75 Hz scanout still needs checking after the required login.

The external screen gets a third, bottom-mounted Sensei bar. It shares the main wallpaper, including later wallpaper changes, and the Terminal/Web/Code/Study/Sim/Work workspace pool. There are no duplicate workspace IDs: choosing a workspace visible on the other main/external screen swaps their visible workspaces. Misc remains on the ScreenPad. Popup panels open upward on the bar that opened them; keyboard IPC openings do not inherit a previous HDMI hover.

- **Super+1…7:** select a workspace, respecting the focused display.
- **Super+Ctrl+Left/Right:** focus the adjacent monitor.
- **Super+Ctrl+Shift+Left/Right:** move the current window to the adjacent monitor.
- **HDMI brightness icon:** open hardware brightness controls; scroll changes brightness by 5 percentage points.

Brightness uses `ddcutil` and the monitor's actual VCP 0x10 value and reported maximum. This laptop already has working I2C permissions; no privileged policy was added. Unsupported displays show “Monitor controls” instead of a false brightness percentage. The System panel also includes connected external brightness controls. A changed monitor's EDID invalidates the cached DDC bus before writes.

Connect/disconnect events trigger debounced layout discovery and notifications. No permanent brightness polling is added. Workspace navigation does not wait for the brightness lock. Hyprland evacuates removed-output workspaces; the shell removes its bar and stale popup surface. The HDMI monitor rule is present at startup, and the Quickshell service applies the supported mode and exact placement when the connector becomes available.

Useful diagnostics:

```sh
sensei-displays sync
sensei-displays sync --no-layout --no-notify
hyprctl monitors -j
```

Private hardware/cache state stays in `~/.cache/sensei-displays/`, outside Git. Managed code is `home/.local/bin/sensei-displays`, the `ExternalDisplays` service and `ExternalDisplayDropdown`, plus the existing bar/workspace/wallpaper components. The ordinary dotfiles installer deploys them; `ddcutil` is in the package manifest. Desktop changes were backed up under `~/.local/state/dotfiles-backups/hdmi-desktop-*`.

## Validation and remaining physical check

A disposable headless output verified the third bar, wallpaper inheritance, negative-coordinate placement, workspace swaps, inactive-workspace moves, preservation of ScreenPad Misc, brightness-popup placement and compact/expanded layouts at 1920 and 1280 logical pixels. It was removed afterward. Actual DDC brightness passed a write/readback at the unchanged 90% setting. Installer dry-run, backup, generic rendering and idempotence checks passed. Nine focused display tests cover mode selection, DDC parsing, identity changes, workspace behavior, notification deduplication navigation independence from I2C locking and recovery from initial DDC discovery failure.

The running compositor still excludes NVIDIA, so the headless test is **not** a physical HDMI presentation test. After logging out and back in through **Hyprland (Intel repair)**, confirm `HDMI-A-1` at `x=-1920`, 1920×1080 and approximately 75 Hz, with a 44-pixel bottom bar. Test cable unplug/replug, notifications, brightness, window movement and playback under normal load. If 75 Hz is unavailable in the driver's reported modes, the selector uses the best mode actually offered.

Mode and placement behavior follow [Hyprland monitor positioning](https://wiki.hypr.land/configuring/core/monitors/positioning/). Hardware brightness follows [ddcutil getvcp](https://www.ddcutil.com/command_getvcp/) and [setvcp](https://www.ddcutil.com/command_setvcp/).
