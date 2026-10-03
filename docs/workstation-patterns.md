# Sensei workstation patterns

Twenty-four targeted searches covered performance engineering, developer workstations, Hyprland, Quickshell, Qt Quick, and community desktop builds. The useful pattern is **tight feedback loops, persistent context, and visible evidence**. More resident widgets are not automatically better.

| Source | Idea | This workstation's version |
| --- | --- | --- |
| [Karpathy's autoresearch](https://github.com/karpathy/autoresearch/blob/master/program.md?plain=1) | Bound experiments and keep results comparable. | `sensei-lab run` records the command, project revision, output, exit status, and time. Human review decides which run matters. |
| [tinygrad speed guide](https://docs.tinygrad.org/developer/speed/) from the project George Hotz founded | Separate compute, memory, and transfer bottlenecks. | GPU/CUDA and memory data live beside process and I/O data; future experiment records can add model throughput. |
| [Brendan Gregg's USE method](https://www.brendangregg.com/usemethod.html) | Check utilization, saturation, and errors for each resource. | `sensei-health` captures CPU, memory, and I/O pressure during a stall, not just an idle CPU percentage. |
| [Casey Muratori's performance series](https://www.computerenhance.com/p/table-of-contents) | Measure before rewriting hot paths. | The monitor's process scan was timed, then separated from graph sampling. |
| [Julia Evans on debugging tools](https://jvns.ca/blog/2016/09/17/strange-loop-talk/) | Make the system explain what happened. | On-demand traces save raw samples and a short readable report under `~/.local/state/sensei-health/`. |
| [Mitchell Hashimoto on a Ghostty memory leak](https://mitchellh.com/writing/ghostty-memory-leak-fix) | Long-running desktop programs need long-uptime tests. | Compare shell PSS, crash history, pressure and responsiveness after hours, not only after a restart. |
| [Omarchy navigation](https://github.com/omacom/omarchy/blob/quattro/manual/04-navigation.md) | Keep common work reachable from the keyboard. | A project session can be resumed in tmux; existing Hyprland navigation remains the primary path. |
| [ThePrimeagen's productivity notes](https://theprimeagen.github.io/dev-productivity/) | Reduce repeated setup and context switching. | `sensei-lab open` resumes a named project session in its directory. |
| [John Carmack's long-form development interview](https://www.youtube.com/watch?v=I845O57ZSy4) | Treat the workstation as a tool for the work in front of it; personal editor or hardware choices are context, not a universal recipe. | Keep shortcuts and telemetry tied to this ZenBook's robotics work, and verify changes with real tasks. |
| [Qt Quick performance guide](https://doc.qt.io/qt-6/qtquick-performance.html) | Avoid needless binding work and visual layers; load large views lazily. | Tickers use native animation instead of a JavaScript clock and two mask textures; dropdowns load asynchronously. |
| [Qt Creator QML profiler](https://doc.qt.io/qtcreator/creator-qml-performance-monitor.html) | Attribute time to bindings and scene-graph work. | Use it when the lightweight changes do not explain a remaining stall. |
| [Hyprland performance notes](https://wiki.hypr.land/configuring/extra/performance/) | Test expensive effects with actual GPU load. | Keep the glass aesthetic, measure compositor time, and tune only the effects with evidence. |
| [Quickshell issue 919](https://github.com/quickshell-mirror/quickshell/issues/919) | Qt/Wayland render paths can wedge around output changes. | Keep a crash supervisor and save coredumps; a similar symptom does not establish the same cause. |

The community builds that last as daily drivers tend to make utilities available on demand. This setup's next useful additions are run-to-run throughput comparison, a one-key stall marker, and per-project pinned devices or ROS domain. They should build on recorded runs and actual usage, rather than adding another always-running poller.

Validation targets: widget click feedback under 50 ms, warm panel presentation under 250 ms, no visible wallpaper reset on a shell restart, no Quickshell crash in a 48-hour run, and zero unnecessary background sampling for the experiment tools. The crash and long-uptime targets require observation beyond one session.
