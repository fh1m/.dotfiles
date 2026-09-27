# Operate, maintain and recover

[← Workstation](../README.md)

## Quick diagnosis

```sh
hyprctl configerrors
hyprctl monitors -j
qs -c wrayth ipc show
qs -c wrayth ipc call dropdown open system
systemctl --user --failed
systemctl --failed
journalctl -b -p warning
```

Quickshell logs are under `/run/user/$UID/quickshell/by-pid/<PID>/log.log`. Find the current `qs` process; an old log’s warning does not necessarily describe the active instance. Configuration parse errors, binding loops and process exits matter more than a stale screenshot. `~/.local/state/wrayth/shell.log` records wrapper output.

On multi-instance diagnostic sessions, choose the correct `hyprctl -i` instance. Do not reuse a stale HYPRLAND_INSTANCE_SIGNATURE when interrogating a restarted session.

## If the shell dies

Keep the TTY fallback and existing desktop session. The Wrayth wrapper supervises lockscreen recovery; do not replace it with an unauthenticated unlock script. Read the last parse error, restore only the affected source backup, then start `~/.config/quickshell/wrayth/external/wrayth-shell` in the graphical environment. Avoid starting competing notification daemons or multiple shell instances.

A normal shell restart does not require killing Chrome, Spotify, training jobs or the compositor. A compositor restart is a separate disruptive action.

## If selection does not switch

Confirm a real focus dispatch outside the overlay and inspect its address/workspace. The switcher now stores the chosen address, closes its input surface, then dispatches after unmapping. A foreign toplevel activation while an exclusive overlay remains mapped can lose the focus race. Keep the handoff in one place rather than issuing duplicate early/late activation calls.

Workspace-background click areas sit behind tile content but above the panel fill; window drag handlers remain on window tiles. Keyboard Enter and keypad Enter commit. If a target was closed meanwhile, refresh live toplevels and try a current selection.

## If a panel flashes or starts shaky

Check for two animation owners, live height reconfiguration, asynchronous content whose first layout differs from its final one, or duplicate child fades. The outer surface is fixed during the reveal, its layout is checked across consecutive frames, and System/Monitor do not run an independent startup fade. Blur and alpha threshold changes can expose apparent flashes; do not compensate by adding another shadow rectangle.

## Updates

Use Pacman/paru through the Packages section or terminal. Prefer a complete Arch upgrade. After kernel/NVIDIA changes, reboot into the aligned stack and check drivers, ScreenPad DKMS, render nodes and GPU containers. Regenerate CDI when toolkit packaged refresh is unavailable. Validate Chrome again after kernel/driver changes; new-machine defaults remain Intel until tested.

Rebuild the private Spotify source deliberately when upgrading it. Keep its lockfile/source patches and bridge protocol together; swapping only the executable can break the widget. Never commit token/cache files to “make the setup reproducible.”

## Known boundaries

- No firmware logo replacement or custom BIOS flashing was performed.
- Internal panel wiring is not changed by the GPU selector.
- RTX 2060/UHD 630 do not hardware-decode AV1.
- High Intel compositor load on dual high-resolution panels was not eliminated.
- Bluetooth/Spotify network continuity cannot be guaranteed by local code.
- Other Spotify clients can deliberately transfer account-wide playback.
- Android radio/Doze transitions can cause reconnect gaps; ADB needs authorization.
- QEMU support here is user-mode ARM containers, not a complete VM manager.
- Hardware-only controls may be unavailable on other laptops.
- Destructive container operations were not tested against the owner’s existing workloads.

## Backups and privacy

User installer backups live under `~/.local/state/dotfiles-backups`. Historic workstation backups are separate. Chrome, keyrings, `.clipboard`, phone certificates, SSH keys, Syncthing identities and Spotify tokens must be backed up through private means, not this public repository.

When restoring a browser preference, do not replace its newer Cookies/Sessions/History databases with a stale whole-profile backup. When restoring a driver or boot setting, keep a matching kernel/modules path and a recovery entry.

The repository’s gallery uses real surfaces with the shell’s privacy showcase mode: personal notifications and private window previews are hidden for capture, then restored. Robotics code is shown instead of the development conversation. It does not fabricate performance readings or overwrite personal planner/clipboard records.
