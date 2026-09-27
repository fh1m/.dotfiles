# What was verified

The published source was exported from the running UX581GV on 28 September 2026. The live Quickshell configuration loaded, Hyprland returned no config errors, and the selection handoff focused both a Chrome window on workspace 2 and workspace 2 itself from workspace 1. The delayed focus is essential: the chooser's exclusive input layer must finish closing first. A user click is the same `WindowDesk.choose()` path as the IPC test, though physical mouse timing deserves a normal-session check after future edits.

The installation test runs in a temporary home directory. It checks dry-run safety, backup of an existing tmux file, `@HOME@` rendering, removal of UX581-specific monitor positioning in generic mode, recreation of Wrayth helper links and an idempotent second run. CI repeats these checks plus syntax checks. CI does **not** launch a compositor, build the whole Rust Spotify client or probe GPU/Android hardware.

On the reference machine, the native Spotify transport and configurable Bluetooth preload library compiled. Existing running services and prior hands-on tests covered CUDA in Docker, ARM64 through QEMU, Chrome's Intel video decode and NVIDIA rendering under XWayland, and KDE Connect/Tailscale/Termux across the phone link. These are reference-device findings, not promises for a fresh Arch machine.

The screenshot gallery contains actual compositor output. `grim` sometimes stalled while the full-screen navigation overlay used live toplevel previews, so switcher/overview captures are omitted rather than fabricated. The monitor gallery hides private host/network addresses; the privacy pass reviewed every published PNG. The capture script restores the original focus and only closes its own showcase windows.

A fresh Arch install, future kernel/NVIDIA upgrades, phone cellular handoff, actual mouse drag/drop on the current build and long-term Bluetooth jitter are not proven by these checks. Use [installation](installation.md) and [operations](operations.md) for staged validation and rollback.
