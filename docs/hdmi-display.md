# Displays on the ZenBook

## Current four-display setup — 14 October

The replacement HDMI cable resolved the USB-C monitor's missing signal. All four physical panels are enabled. Current layout (coordinates are logical pixels):

| Display | Output | Mode | Scale | Position | Bar |
|---|---|---|---|---|---|
| Laptop main | eDP-1 | 3840×2160, 60 Hz | 2× | 0, 0 | Top |
| ScreenPad | DP-2 | 3840×1100, 60.02 Hz | 2× | 0, 1080 | Bottom |
| Lower external | HDMI-A-1 | 1920×1080, 100 Hz | 1× | −1920, 0 | Bottom |
| Upper external | DP-1 | 1920×1080, 100 Hz | 1× | −1920, −1080 | Top |

The upper bar-edge shadow follows its top bar rather than leaving a stray horizontal line at the bottom. Both external bars inherit the main wallpaper and show only workspace navigation and their own display control. Upper popups open below its top bar; lower popups open above its bottom bar. External labels are Upper/Lower throughout the display controls. Small display-control text uses native, hinted rendering; external panels retain native pixels and integer scaling. Main-display scaling is 2× as requested. Iosevka terminal font is 11.4 pt; existing line and letter spacing are preserved.

Terminal/Web/Code/Study/Sim/Work are shared logical desktops with separate physical windows on each screen. Main uses 1–6, Lower 101–106, Upper 201–206. Selecting Code updates all three to 3/103/203, including their animated indicators. Misc remains ScreenPad workspace 7. Window lists, attention counts and overview geometry include all three desktop halves. The connector-slot registry reserves stable ranges for additional outputs; it is private cache state, not a published hardware inventory. Custom workspace names survive reconciliation.

Discovery is event-driven and debounced. Reload/startup rules avoid `auto-left` relocating the lower screen beyond the upper screen. The helper then selects the highest advertised resolution and refresh without custom timings. Losing one external recovers its windows to their matching main workspace without disturbing the other external. This behavior is covered by disposable regression tests; a physical unplug/replug was not performed during final acceptance.

**Brightness limitation:** Lower exposes working DDC on this connection. Upper's USB-C adapter path returns `EREMOTEIO` for VCP 0x10, so its bar says **Monitor keys** and its panel explains the limitation. No software dimming is substituted for hardware brightness. Use that monitor's physical controls unless a different adapter exposes DDC.

Validation: all 250 Python tests passed, including 27 focused display tests. Live checks verified synchronized workspace selection from the upper output, all three rail indicators, moving a disposable Alacritty window through Upper → Lower → Main, correctly placed System/display popups, wallpaper inheritance, 100 Hz modes, main scaling and no Hyprland configuration errors. Private screenshots were inspected and excluded from Git. Existing user windows and focus were restored. Backups reside under `~/.local/state/dotfiles-backups/usb-c-display-*`.

The older sections below are the HDMI investigation history, not the current monitor arrangement.


**Resolved on 12 October:** physical HDMI output is confirmed by the owner, with 1920×1080 at 74.973 Hz, Intel as primary renderer and NVIDIA driving HDMI. The sections below retain the investigation history; the final acceptance section records the working state.

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

The external screen gets a third, bottom-mounted Sensei bar. It shares the main wallpaper, including later wallpaper changes, and the Terminal/Web/Code/Study/Sim/Work workspace pool. The six logical workspaces span main and external together: selecting a workspace switches both displays, with separate windows on each half and the same selection on both bars. Misc remains on the ScreenPad. Popup panels open upward on the bar that opened them; keyboard IPC openings do not inherit a previous HDMI hover.

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

### Second physical login: the constant fix was insufficient

The constant fix removed the initial rejection, but NVIDIA then failed with `glCheckFramebufferStatus failed: 1282`. The monitor was correctly detected at 1080p/74.973 Hz and had wallpaper/bar surfaces; this still did **not** mean physical presentation worked. Testing 60 Hz did not repair the framebuffer error. HDMI was disabled again in the running session to prevent the repeated failed-frame loop.

A small isolated GBM/EGL diagnostic reproduced the actual failure without taking DRM master or restarting the desktop. On the NVIDIA render node, allocating XR24 native buffers and supplying their explicit NVIDIA layout modifiers produced a complete framebuffer (`0x8cd5`, no GL error). Importing the same buffers while omitting their modifiers produced an incomplete attachment (`0x8cd6`, GL error `0x502`). Intel's own implicit/native buffers also produced complete framebuffers. This explains why the global modifier-free workaround cannot be applied identically to both vendors.

The private patch now adds an opt-in `SENSEI_AQ_NVIDIA_MODIFIERS=1` exception to the global `AQ_NO_MODIFIERS` setting. Intel retains the ScreenPad workaround; NVIDIA uses its driver-reported explicit modifier capability and native renderable scanout buffers. Its blit destination is not a shared linear swapchain, so NVIDIA can render into a compatible tiled target while sampling the Intel source. The environment exception is enabled only alongside the tested private library. This is a machine workaround, separate from the generic constant correction.

The revised build passed the four upstream tests and load-symbol checks. The build script installs into a new versioned directory and activates a symlink after validation, preserving libraries already mapped by running processes. Old build directories are retained for rollback. Existing single-hunk builds are upgraded without discarding source changes: each maintained patch file is independently applied or verified already applied.

The diagnostic source is `scripts/diagnostics/gbm-probe.cpp`. Build and run it with the **current** render-node path (resolve the stable PCI symlink first):

```sh
c++ scripts/diagnostics/gbm-probe.cpp -o /tmp/gbm-probe $(pkg-config --cflags --libs egl glesv2 gbm libdrm)
/tmp/gbm-probe /dev/dri/by-path/pci-0000:01:00.0-render
/tmp/gbm-probe /dev/dri/by-path/pci-0000:01:00.0-render omit
```

It allocates only small temporary buffers, does not change display modes, and does not request DRM master. The test demonstrates buffer renderability, not screen scanout. Physical presentation with the revised vendor-specific workaround still requires the next compositor login.


## Third physical login: working output and reading polish

The fresh session loaded the revised, versioned Aquamarine library. HDMI frame capture completed immediately; the former destination-DMABUF and framebuffer/blit errors were absent. The owner confirmed the physical picture. The actual mode is 1920×1080 at 74.973 Hz, 1× scale, XRGB8888, positioned left at −1920,0. The two internal panels remain at their original modes and 2× scale.

The external bar now contains only its workspace rail (with an External marker) and hardware brightness. Its workspace labels are 13px with no added tracking. Small brightness labels use native Qt text rendering. The ScreenPad marker identifies External when that output is focused. Both the ScreenPad's main-display rail and HDMI's rail use the same shared-workspace helper; selecting a visible workspace swaps it between the two displays. Misc retains its ScreenPad role.

An event-triggered monitor snapshot avoids incomplete/stale monitor metadata in the running Quickshell service. It refreshes on workspace, focus and topology changes, coalesces bursts, and retains the previous state on failed reads. There is no idle polling. Each rail keeps its own monitor's active workspace visible even while a scratchpad is open; its 220ms moving selection retains the last valid position through refreshes. A live switch from Web to Code measured intermediate x=176.99 then final x=213, proving that the carriage moves rather than jumps. The original workspace was restored.

The external terminal had been hidden in a legacy Scratch workspace. It was moved intact into regular Terminal, preserving its process and tmux session. The four legacy shortcuts for hiding/moving ordinary windows into Scratch were removed. Workspaces 1–6 form one unpinned shared pool; only Misc retains its persistent ScreenPad assignment. Empty regular workspaces are created after focusing the requested output, avoiding accidental creation on another display. Live checks covered empty-workspace creation on each display, visible-workspace swaps, and a configuration reload with the same terminal process still visible.

Preview geometry uses each output’s actual logical dimensions and origin instead of fixed main-display coordinates. The overview includes all ordinary applications. Existing intentionally named special utilities remain discoverable if occupied; no Scratch workspace is created. Overview selection of a regular workspace uses the same shared-pool helper as the rail.

The application switcher previously rendered only on main-bar screens. It now uses the invoking display's overlay screen and includes external-screen applications and their live previews. Keyboard-opened dropdowns use the focused display rather than unconditionally choosing main/ScreenPad. Live checks confirmed the switcher surface on HDMI and the System popup there (596×788, fully revealed), plus Sound and Calendar through their own keyboard IPC routes. Clicking an internal bar still opens its widget on that bar. Noesis's explicitly main-display workspace is preserved.

Terminal rendering keeps Iosevka at 11.8pt, using its installed Medium face for stronger strokes and glyph offsets x=1/y=2 to center ink within the additional cell spacing. Fontconfig full hinting applies only to Iosevka raster sizes at or below 20px; larger HiDPI sizes retain slight hinting. Grayscale antialiasing is retained, avoiding an assumption about the subpixel order of arbitrary plugged-in displays. Existing Alacritty windows reloaded the font/spacing configuration without closing tmux sessions. Fontconfig readback confirmed hintstyle=3 at 16px and hintstyle=1 at 32px.

The monitor's physical pixel density is approximately 102 pixels/inch from its reported 480×270mm dimensions. Native 1080p cannot show the same fine detail as the internal 4K panel. No supersampling, invented HDR profile, custom timing or unmeasured color correction is applied. For monitor-side text issues, use the monitor's native/no-overscan mode and avoid artificial sharpening: [LG's manual](https://gscs-b2c.lge.com/open/downloadFile?fileId=tLpwl3q8THbE4wNVGT59A) says Super Resolution+ is unsuitable for normal text/desktop icons. The exact physical panel model and calibration remain unverified; no factory settings were reset.

Rendering choices follow [Qt text rendering](https://doc.qt.io/qt-6/qml-qtquick-text.html), [Fontconfig properties](https://fontconfig.pages.freedesktop.org/fontconfig/fontconfig-user.html), and [Alacritty font/cell offsets](https://alacritty.org/releases/0.14.0/config-alacritty.html). The existing [native Xwayland scaling](https://wiki.hypr.land/configuring/extra/xwayland/) setting is preserved.

After a compositor configuration reload, the display service reapplies the best supported native mode; the preferred-mode fallback must not silently leave this monitor at 60 Hz. DDC state reports the actual brightness and mode, and scrolling coalesces increments using the latest requested level rather than repeatedly starting from an old readback. Current DDC reads and the actual popup were verified. Main and ScreenPad brightness repairs were already verified through their widget path with sysfs readback. The renderer build's four upstream tests and the dotfiles regression suite (226 tests) pass. Physical cable replacement/unplug/replug and prolonged video playback are still owner acceptance checks; software topology/monitor-identity regressions do not substitute for those checks.

The scoped polish backup is `~/.local/state/dotfiles-backups/external-polish-20261012-004942/`. Only display, rail, popup/switcher routing, font and renderer-build files were deployed. Generated palettes and unrelated live configuration were preserved. Rollback uses the backed-up files; the renderer has retained versioned builds and Intel-only/system-library startup fallbacks described above.


## Shared desktops — final behavior, 13 October

The earlier independent-workspace swapping behavior misunderstood the requested workflow and is superseded. Terminal, Web, Code, Study, Sim and Work now span the main display and HDMI together. Both bars highlight the same logical workspace and count/flag windows across both displays. Misc retains its ScreenPad role. No Scratch workspace is created.

Hyprland owns one physical monitor per workspace. The helper pairs main IDs 1–6 with external IDs 101–106, presenting only the six logical identities in navigation. External physical names have an `· External` suffix to avoid ambiguous client caches; user-facing rail labels remain identical. [Native workspace dispatchers](https://wiki.hypr.land/Configuring/Basics/Dispatchers/) provide the underlying focus, move and rename operations. This is coordinated extended workspaces, not screen mirroring.

- Either rail or **Super+1…6** switches both halves in one compositor transaction and restores focus to the invoking display.
- **Super+Ctrl+Left/Right** focuses the adjacent display; **Super+Ctrl+Shift+Left/Right** transfers the window within the active logical desktop.
- **Super+Shift+1…6**, overview moves and drag/drop preserve the window’s current display while changing its logical workspace.
- Focusing a window on another workspace aligns the other display after an event-driven debounce. No idle reconciliation polling runs.
- Disconnect recovery merges external-half windows into their matching main workspaces, preserving processes. This path has regression coverage; physical cable removal was not performed during this final check.

The overview combines both halves into one card using the extended display geometry. Counts and attention use current per-window IPC metadata, with cached workspace objects only as fallback. Navigation and recovery use a separate short workspace lock, never the potentially slow DDC brightness lock.

Live acceptance covered paired Web/Code/Terminal/Work selection from either display, matching rail highlights, terminal transfer in both directions, retaining its process, and reload persistence. A subsequent user login also retained the linked Terminal layout. The full regression suite passes **234 tests**, including logical/physical identity, duplicate-name migration, stale-client metadata, simulated display recovery and display-preserving window moves. Screenshots and machine-local telemetry were kept outside Git.

Rollback: the preceding implementation is commit `30aa66d`; the scoped pre-change backup is `~/.local/state/dotfiles-backups/joined-workspaces-20261012-013242/`. Restore the helper, rules and QML together rather than mixing workspace identity models.
