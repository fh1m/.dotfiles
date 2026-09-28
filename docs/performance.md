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
| Monitor | Fast live sampling while visible; stable delegates and retained graph history |
| Switcher | Captures only while open; selected previews faster; optional preview pause |

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

The bar had several independent, perpetual 60 Hz animations: the scrolling ticker, rotating album art, robot badge, sound pulse and Bluetooth pulse. They now use one shared 30 Hz clock. In a later sample of the same Kitty desktop, render use was roughly 46–60%, with Hyprland around 26–42% and Kitty around 16–22%. The workload changed between samples, so these numbers are evidence of a strong improvement, not a fixed percentage saving. Blur stayed enabled at its preferred settings. New render scheduling and eligible direct scanout were retained, but the tested NVIDIA XWayland window did not qualify for scanout.

Popup QML trees are now kept after closing for fast repeat opens. A shorter surface-settle gate starts the reveal sooner, and the clipboard vault no longer reloads an unchanged list on every open. The first cold open of large panels still has a construction cost; the cache removes that cost from repeat use without keeping every panel alive all session.

Do not claim “GPU offload fixes all desktop lag.” NVIDIA application rendering still reaches Intel composition and Intel-wired panels. Hardware decode reduces decode CPU, while JavaScript and many tab allocations remain CPU/RAM work.

## Avoid apparent flicker caused by control flow

Nested fades on System/Monitor were removed so the outer widget reveal is the sole entrance. A surface’s content/layout must stabilize before reveal; a reconfigured Wayland surface mid-animation can look like a transition reset. Modifier release does not commit a switcher selection prematurely; final focus dispatch waits for the overlay to release its surface.

Input masks pass closing-widget clicks through. Late requests use context guards so yesterday’s playlist response cannot overwrite today’s selection. These ordering decisions contribute to smoothness as much as easing curves do.

## Services and boot

Unused reCamera bridge/dashboard units were removed after backups. NoMachine is on demand. Unsupported Dynamic Boost was disabled on this hardware. NVIDIA persistence remained for CUDA readiness with negligible observed CPU use. Network dependencies and essential firmware were not removed just to shorten a boot chart.

There is no perpetual audit timer in this repository. Use short comparable samples, then stop tracing. Debug logs, GPU probes and HCI captures can themselves affect the thing being measured.
