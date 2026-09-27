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

Two high-resolution 60 Hz panels plus blur and live content keep the Intel compositor busy. Samples showed substantial render-engine use. Reduced blur, 30 Hz ticker and precision experiments did not sufficiently solve that overall cost and were reverted to preserve the preferred appearance. New render scheduling and eligible direct scanout were retained, but the tested NVIDIA XWayland window did not qualify for scanout.

Do not claim “GPU offload fixes all desktop lag.” NVIDIA application rendering still reaches Intel composition and Intel-wired panels. Hardware decode reduces decode CPU, while JavaScript and many tab allocations remain CPU/RAM work.

## Avoid apparent flicker caused by control flow

Nested fades on System/Monitor were removed so the outer widget reveal is the sole entrance. A surface’s content/layout must stabilize before reveal; a reconfigured Wayland surface mid-animation can look like a transition reset. Modifier release does not commit a switcher selection prematurely; final focus dispatch waits for the overlay to release its surface.

Input masks pass closing-widget clicks through. Late requests use context guards so yesterday’s playlist response cannot overwrite today’s selection. These ordering decisions contribute to smoothness as much as easing curves do.

## Services and boot

Unused reCamera bridge/dashboard units were removed after backups. NoMachine is on demand. Unsupported Dynamic Boost was disabled on this hardware. NVIDIA persistence remained for CUDA readiness with negligible observed CPU use. Network dependencies and essential firmware were not removed just to shorten a boot chart.

There is no perpetual audit timer in this repository. Use short comparable samples, then stop tracing. Debug logs, GPU probes and HCI captures can themselves affect the thing being measured.
