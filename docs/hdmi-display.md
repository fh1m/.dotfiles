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
