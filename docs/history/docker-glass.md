# Docker robotics lab and glass UI — 2026-09-28

Open System → Robotics → Docker robotics lab. Eight pages: containers, images, launch, Compose, storage/network, tmux, ARM/GPU and tasks.

Container lifecycle actions, inspect/health/ports/mounts/users/labels/network details, running stats/processes/file changes/logs, image pull/save/load/remove, container export and file copy, Compose lifecycle/build/logs, volumes/networks and disk accounting are exposed. Advanced accepts Docker arguments without host shell evaluation for less common operations (network create/connect/disconnect, volume create, container update/rename, image tag/push, prune, buildx, etc.). Removal/kill actions use inline two-click confirmation; advanced commands are explicit.

Launch form: native or ARM platform, image, name, command, tmux session, bind-mounted workspace, selected serial device, ROS domain, opt-in host networking/shared IPC and native NVIDIA GPU. Existing containers are never started by inventory; requesting a stopped container shell explicitly starts it. Existing tmux sessions gain a new window; new sessions are created when needed.

Installed qemu-user-static and qemu-user-static-binfmt. ARM64 alpine uname returned aarch64. ARM emulation is CPU-only, not host NVIDIA CUDA passthrough and not full-system VM management.

Fixed stale /etc/cdi/nvidia.yaml referencing missing libnvidia-egl-wayland.so.1.1.21. Refreshed to actual .1.1.22. Original backed up alongside it. Added boot oneshot sensei-nvidia-cdi-refresh.service and post-package-update hook /etc/pacman.d/hooks/95-sensei-nvidia-cdi.hook, following NVIDIA CDI refresh lifecycle guidance: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html

Verified Docker --gpus all sees RTX 2060/driver 615.71.09. Compiled and ran a CUDA sm_75 kernel in disposable CUDA 12.8 container: result 42, cudaSuccess. Verified helper launches a GPU-enabled container in its own tmux session, executes commands and sees RTX 2060; disposable test container/session cleaned up. Ten original containers remain. ARM Alpine image remains available for future checks. Existing lifecycle destructive actions were not exercised on user workloads.

UI: removed two rounded black popup shadow layers, black widget glass alpha .60→.44 with softer inner surfaces. Focus grabs arm after entrance settles and release when close begins; closing surfaces pass clicks through immediately using Quickshell input masks. External file dialogs retain existing focus-return guards. Switcher now uses cut-corner panels/cards/search controls and glass, native icons, live previews, window actions, fuzzy search, workspace movement/dragging, frequent launchers, and optional preview pause. Added 230ms entrance/150ms exit; compositor blur limited to panel alpha. Spotify expanded art popup uses matching chamfer frame.

Docker inventories and event stream only while panel open; task refresh only while jobs run; running-container details only on container page. Independent bounded processes/queue keep long Docker work outside UI. Stable per-list models avoid reset on unrelated data changes. All eight visible tabs inspected via IPC (789 logical pixels panel height); calls ~50–104ms during tab activation. No Docker event process when closed.

Backups of initial Theme, Dropdowns, SystemDropdown, NavigationOverlay and WorkspacePreview are in this directory. New implementation files: ~/.local/bin/sensei-docker, services/DockerLab.qml, modules/dropdowns/DockerDropdown.qml. GPU refresh service enabled but next boot/package upgrade has not yet been observed. Overall animation/focus feel still needs normal daily use feedback; no claim of every possible Docker feature having a dedicated graphical form.
