# Lean where idle, responsive where interactive

[← Workstation](../README.md)

The target is a smooth useful machine, not an empty task manager screenshot. A browser workload, GPU driver allocation and page cache are not automatically leaks. The investigation kept account data and working features rather than deleting them to obtain a smaller number.

## Where work is avoided

| Component | Behaviour |
|---|---|
| Docker | Event stream/inventory only while open; task refresh only while jobs run; details only for relevant running selection |
| Phone | KDE Connect pushes; cheap telemetry; lazy tabs; virtualized notifications; bounded/coalesced action queue |
| USB | udev events maintain presence/history; detailed inspection on demand |
| Clipboard | Archive revision events; waiting children use pidfd/backoff rather than a hot process loop |
| Calendar | inotify edits and realtime timer deadlines, instead of a two-second database polling loop |
| Spotify | Native events and local transport; catalogue workers separate; bounded cache/next-track preload |
| Audio visualization | Follows actual active audio; unused processing stops; compact output has a lower frame rate |
| Wallpapers / theme picker | Expensive picker constructed on demand |
| Wallpaper startup | A small cached JPEG of each chosen display image loads first; the full-resolution image follows after settings load. The bundled preset never flashes over a custom choice. |
| Monitor | Live graph samples while visible; process scans only on Processes, hardware inventory only on detail tabs |
| Switcher | Captures only while open; selected previews faster; optional preview pause |

On this laptop, a complete 417-process monitor sample took about 125 ms and a hardware-inventory sample about 375 ms. The graph-only path measured about 63–76 ms after separating those jobs. These are local wall-clock samples, not a guarantee under load.

## Memory: measure the right thing

Inspect `MemAvailable`, reclaimable cache, swap and PSI memory pressure. PSS is more meaningful than summing every process’s RSS when libraries/graphics buffers are shared. Compare the same application set and tab workload over time. A compositor recovery that closes applications is not an honest RAM-savings comparison.

The reference snapshots varied with workload. An ~11 GiB available observation with a smaller running app set was not equivalent to the earlier many-tab desktop. No memory leak was proven from those snapshots alone. Long-session retained graphics memory and repeated popup lifecycles still merit observation.

```sh
free -h
cat /proc/pressure/memory
ps -eo pid,comm,%cpu,rss --sort=-rss | head
systemd-cgtop
# Read-only setup summary, omitting account tokens and personal data:
python3 scripts/doctor.py
```

## Rendering is not free

Two high-resolution 60 Hz panels plus blur and live content keep the Intel compositor busy. On 2026-09-28, `intel_gpu_top` showed 92–100% Render/3D use during the user's normal Kitty/music desktop: roughly 74–77% Hyprland and 17–20% Kitty in samples. CPU and memory had headroom (about 8 GiB MemAvailable, near-zero memory pressure), and NVIDIA was idle. On an empty main workspace the render engine still used about 52–55%; disabling blur temporarily reduced it to about 40–41%. Blur alone was not the whole cause.

The bar once had several independent, perpetual 60 Hz animations. A shared 30 Hz clock was an intermediate improvement; the current shell uses native animations only while each indicator is active, and the ticker no longer renders through two mask textures. An earlier sample of the Kitty desktop showed render use around 46–60%, with Hyprland around 26–42% and Kitty around 16–22%. That workload changed between samples, so these numbers are historical evidence, not a measured saving from the latest change. Blur remains enabled. New render scheduling and eligible direct scanout were retained, but the tested NVIDIA XWayland window did not qualify for scanout.

### October 2026: the compositor budget

A longer trace found Intel Render/3D at 96–99% in a normal Kitty workspace, even though CPU pressure was near zero, 5.8 GiB memory remained available, and Quickshell itself used under 1% of the GPU. The process split was roughly Hyprland 78%, Kitty 16–20%, Quickshell <1%. Disabling all blur for a short A/B run reduced total render use to 68% (Hyprland 47.5%). Reducing blur radius/passes alone did not recover enough headroom. Freezing Quickshell for five seconds also lowered compositor use, implicating constantly changing bar content rather than a hidden CPU daemon.

The useful split was excluding the **large, frequently changing bar and Kitty surfaces** from compositor blur while retaining blur for popups and switchers. In comparable short samples, bar+Kitty excluded averaged about 65% Render/3D; a later live sample averaged 72%. These samples had changing foreground work, so they are evidence of headroom, not a fixed FPS guarantee. The tinted bar and terminal remain; their background no longer frosts the windows behind them. If Intel render use again stays above 90%, inspect the foreground window and use `sudo intel_gpu_top` before removing other effects.

The larger idle cost was **continuous motion on the bars**, not their transparency. On an empty workspace with both displays at 60 Hz, freezing Quickshell dropped Intel Render/3D from roughly 51% to 11–18%. The shell now keeps telemetry and music state live but runs the ticker and decorative music/status animations only while the bar is hovered or an overlay is open. With Quickshell running normally and no interaction, the same empty-workspace sample averaged **11.8% Render/3D** (Hyprland 9.7%, Quickshell near zero). This is a controlled idle comparison; typing into Kitty or scrolling Chrome still costs render time. Global blur, popup glass, bar tint and both 60 Hz outputs remain enabled. A brief all-blur-off test after isolating the bar and terminal had little further effect on the empty workspace, so dropping all visual effects would have sacrificed appearance for little idle gain.

Both internal connectors, `eDP-1` and `DP-2`, resolve to PCI `0000:00:02.0` (Intel UHD 630). The NVIDIA RTX 2060 exposes the external HDMI connector. PRIME can render selected applications on NVIDIA, but their frames still have to cross to Intel for these internal panels; it cannot move the built-in screens' final composition to NVIDIA. A firmware MUX mode would be required for that, and none is established on this machine.

Popup QML trees are now kept after closing for fast repeat opens. A shorter surface-settle gate starts the reveal sooner, and the clipboard vault no longer reloads an unchanged list on every open. The first cold open of large panels still has a construction cost; the cache removes that cost from repeat use without keeping every panel alive all session.

Cold panels now map a lightweight themed placeholder while their asynchronous QML tree builds, then fade content in. Under the measured session, cold System/Spotify/Calendar mapping changed from 548/965/1231 ms to 171/195/157 ms; full content can still take longer. This improves click feedback without eagerly retaining every heavy widget. Benchmark both *map time* and *content ready time* when investigating a regression.

The packaged Noctalia Quickshell fork was built before the installed Qt 6.11.2 packages. Quickshell's own build guide states that its private Qt API use requires rebuilding after each Qt release. Previous QSGRenderThread crashes landed in Mesa EGL `dri2_query_image` during `QWaylandGLContext::swapBuffers`; that trace does **not** by itself prove an ABI mismatch or a permanent Mesa fix. A locally built binary against the installed Qt is selected only while its version stamp matches; the distro binary remains intact. The supervisor still recovers a crash. Stability needs a long-running check after the rebuild.

Do not claim “GPU offload fixes all desktop lag.” NVIDIA application rendering still reaches Intel composition and Intel-wired panels. Hardware decode reduces decode CPU, while JavaScript and many tab allocations remain CPU/RAM work.

## Avoid apparent flicker caused by control flow

Nested fades on System/Monitor were removed so the outer widget reveal is the sole entrance. A surface’s content/layout must stabilize before reveal; a reconfigured Wayland surface mid-animation can look like a transition reset. Modifier release does not commit a switcher selection prematurely; final focus dispatch waits for the overlay to release its surface.

Input masks pass closing-widget clicks through. Late requests use context guards so yesterday’s playlist response cannot overwrite today’s selection. These ordering decisions contribute to smoothness as much as easing curves do.

## Services and boot

Unused reCamera bridge/dashboard units were removed after backups. NoMachine is on demand. Unsupported Dynamic Boost was disabled on this hardware. NVIDIA persistence remained for CUDA readiness with negligible observed CPU use. Network dependencies and essential firmware were not removed just to shorten a boot chart.

There is no perpetual audit timer in this repository. The Monitor's **Capture 15s stall** action runs `sensei-health` once and saves pressure, RAM, process and service context under `~/.local/state/sensei-health/`. Use short comparable samples, then stop tracing. Debug logs, GPU probes and HCI captures can themselves affect the thing being measured.
