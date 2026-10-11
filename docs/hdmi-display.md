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

## First physical login: rendering and session repairs (12 October)

The new login detected all three physical outputs, but HDMI remained blank. The compositor repeatedly logged `EGL (verifyDestinationDMABUF): FAIL, format is external-only`, followed by `destination dmabuf unsupported`. This is a different failure from excluding NVIDIA in the previous session.

Aquamarine 0.15.1 compares `fmt.modifier` with `DRM_FORMAT_INVALID` (a **format**, value zero) rather than `DRM_FORMAT_MOD_INVALID` (the **implicit modifier** sentinel). With this laptop's required `AQ_NO_MODIFIERS=1`, the implicit destination is therefore rejected. The same comparison is still present upstream. The local patch changes that constant; it does not bypass the entire format check. See the [upstream diagnosis and original attribution](https://github.com/hyprwm/aquamarine/issues/220) in issue #220 (the discussion includes the constant diagnosis).

A private Aquamarine 0.15.1 build lives in `~/.local/opt/sensei-aquamarine`. It passed all four upstream CTest tests. Hyprland's version command loaded it, and `ldd -r` found no unresolved symbols. Those checks establish build/load compatibility, **not physical presentation**. The current compositor cannot swap its already-loaded rendering library; a fresh login is required to validate HDMI with this correction.

The session wrapper selects the private library only while recorded `aquamarine` and `hyprutils` package versions still match. On an upgrade it falls back to the system library; rebuild/reassess the patch rather than loading a stale ABI. `SENSEI_SYSTEM_AQUAMARINE=1` explicitly selects the packaged library. `--intel-only` remains available for internal-panel recovery. No system library was overwritten.

To reproduce the private build:

```sh
scripts/build-aquamarine-fix.sh
```

The script pins upstream tag v0.15.1 and commit `f31c47a1b9d300847d8fc3108ad959448103dfc1`, applies the maintained patch idempotently, builds with two workers, runs CTest, installs into the private prefix, and records package versions. It needs the existing C++/CMake/Ninja and Aquamarine build dependencies. It refuses a different installed Aquamarine version.

A second failure was independent of GPU rendering: the old `sensei-shell` supervisor survived logout and restarted Quickshell with the **old** Hyprland instance signature but the reused Wayland socket. That shell could draw bars while its Hyprland IPC was disconnected. Brightness also failed because the old supervisor belonged to an inactive logind session. Starting the shell from the current compositor fixed both. The supervisor now exits when its own compositor disappears, and startup briefly waits for the previous supervisor's lock to be released. A regression fixture verifies it does not relaunch into a subsequent session.

Both main and ScreenPad brightness were tested through the widget's `DisplayControls` path at 99%, confirmed in sysfs and widget state, and restored to their original 100%. No sudoers change or new privileged brightness rule was necessary. Brightness failures are retained in service state instead of being silently discarded.

HDMI was temporarily disabled in the running session to stop repeated failed frame transfers. Its persistent startup rule remains enabled. With the broken output disabled and the shell connected correctly, a three-second idle sample measured Hyprland at 0.0% CPU, Quickshell at 0.7%, and no compositor log growth. This is a short idle measurement, not a general performance benchmark.

The next physical acceptance check remains: new login → three outputs → HDMI pixels at its supported mode → brightness → repeated unplug/replug and monitor replacement → shared workspaces and popup placement → normal interactive load. The current cable remains detected by the kernel and DDC brightness remains available even while its compositor output is temporarily disabled.

The defect is suitable for human upstream review, but [hyprwm's AI policy](https://github.com/hyprwm/.github/blob/main/policies/AI_USAGE.md) forbids agents from submitting or writing developer-facing PR/issue communications. No upstream submission was made. Human submission also requires the organization's vouch process.
