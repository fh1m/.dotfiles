# Termux integration and widget races — 2026-09-28

## Phone setup
- Confirmed SM-A525F, <termux-user>, aarch64. SSH reachable at private Tailscale <private-device-ip>:8022. Installed dedicated laptop Ed25519 public key; password was used only interactively and is not saved in scripts/config. Existing authorized keys preserved.
- Phone target saved in ~/.config/sensei-phone.json; private key ~/.ssh/sensei_phone. Host keys stored in normal known_hosts.
- Boot script ~/.termux/boot/40-sensei-services starts sshd and Syncthing if absent. User opened Termux:Boot to enable Android boot receiver. Script start tested; reboot not yet tested. No permanent wake lock; Android can still defer background work while sleeping.
- Syncthing phone GUI bound only to 127.0.0.1:8384; API access goes through short-lived private SSH tunnels, not public HTTP. Device IDs paired; only Models and Transfers shared under /storage/emulated/0/Sensei/. Transfers is bidirectional. Models is laptop-send-only and laptop-paused until phone has enough space. Phone folders are available; ignorePerms enabled for Android shared storage, version keep=3 on phone, keep=10 on laptop.
- Phone free storage about 400MB. Both phone database and folder free-space reserves set to absolute 100MB (percentage default was blocking all sync); no phone files deleted to free space. NAT port mapping disabled on the new phone Syncthing setup. Default encrypted discovery/relays retained for internet reachability.
- Tested tiny synchronized file arrival, rsync upload and private-key remote commands. Test payload files removed after verification. Rsync tilde destinations now expand to Termux home correctly despite protected args.
- Phone shared files mounted at ~/Phone/Browse via SSHFS, with reconnect/keepalive. Files tab offers mount/open/unmount. Mount is user-initiated, not a permanent boot poller.
- Sync tab offers remote phone status and pause/resume controls in addition to laptop controls. Remote status fetched only on request.

## Widget fixes
- Playlist browse clears inherited filter, initializes own pagination and survives opening/reopening popup. Late library results cannot overwrite collection pagination; late context-page results must match collection ID. Verified actual ListView count=50, not only backend row count; close/reopen retains 50.
- Phone tabs now instantiate lazily; notifications use a virtualized list with expandable bodies, instead of constructing every card. Stable notification model is independent of battery/other updates. Draft clipboard/reply/filter/command text survives tab changes and popup close in session.
- D-Bus watcher publishes atomic private snapshot; status refresh reuses pushed data. UI telemetry excludes duplicate device snapshot, preventing older polling results overwriting current pushed state. Meaningful phone media changes are pushed; position-only ticks ignored.
- Action queue bounded; helper actions limited to 30 seconds and telemetry 20 seconds. State refresh does not disable unrelated controls.
- File dialog return delays keyboard grab restoration, avoiding premature popup dismissal during native focus transfer. Async popup construction waits for ready content.

## Validation and limits
All nine Phone tabs render at 457 logical pixels. Phone tab response samples ~51–70ms; Spotify IPC samples ~33–36ms. Native playback controls were preserved. Syncthing TLS connection established and tiny test delivered; SSHFS mount and rsync exit=0 verified. Final syntax/runtime checks performed after correcting a temporary QML wrapper error during editing. Current pairing is reachable over LAN; private SSH transport separately verified. Cellular-only authenticated KDE feature test and actual reboot remain untested. ADB/scrcpy still needs Android debugging authorization. No claim of zero downtime during loss of radio/network/Android background availability.

Backups of changed shell sources and helpers are alongside this report. Syncthing was newly initialized on the phone during this task; no prior phone sync configuration was replaced.

Sources:
https://github.com/termux/termux-boot#usage
https://docs.syncthing.net/rest/config.html

Fresh-load validation: restarted wrayth-recover-7084.service (shell only; Spotify/apps unaffected). New qs PID 100888. Actual Spotify view again count=50. Fresh Phone Control rendered at 457px. No duplicate phone watcher. Final telemetry samples 135–143ms, around 2.6KB without redundant notifications/device snapshot. SSHFS shared-root path uses /storage/emulated/0 (mounting the Termux symlink itself failed and was corrected). Sync reserves saved using full config PUT, preserving nested values after subsequent permission changes. No personal phone data deleted; harmless test payload files removed.

Offline safety: mount presence checks read /proc/self/mountinfo rather than statting an SSHFS path, so disconnected phone FUSE requests cannot block telemetry. Fresh closed shell CPU: 9 ticks over 5s (~1.8% of one core); fresh log 0 warnings/errors.
