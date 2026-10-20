# Desktop Commander: leave the terminal closed

Both Den hosts run the official Desktop Commander remote agent under a user
systemd service. User lingering starts it at boot, before desktop login. Saved
pairing stays private on its original machine. Desktop notifications wait until
the notification server exists; GUI tools still require a logged-in desktop.

## Reproduce

Install Node.js and npm through the normal package workflow, then:

```sh
python3 scripts/setup-desktop-commander.py --apply
python3 scripts/install.py --hardware zenbook --apply # pc on Homie
systemctl --user daemon-reload
systemctl --user enable --now sensei-desktop-commander.service
sudo loginctl enable-linger "$USER"
```

Pair a new machine explicitly with the official remote command first. Stop an
old manually launched remote agent before enabling the service. Never copy
another machine's device credentials. Version 0.3.0 is installed locally under
`~/.local/opt/sensei-desktop-commander`; startup does not run npx or download code.
Upgrades are deliberate: change the installer pin and validate before deploying.

## Behavior

The official transport owns heartbeats and network reconnection. The small
supervisor handles process crashes with bounded exponential backoff and cleans
up its own child process group, including an orphaned local MCP process. A
private lock prevents duplicate supervisors. Run the service rather than a
second manual agent.

Connection notices use the existing Den notification system: “Mission Control
linked” and “A small disturbance in the force,” with a little variety. A brief
connection interruption stays quiet; sustained loss gets one notice, followed
by a recovery notice. DND remains controlled by the desktop. No bar buttons or
extra network polling were added.

A genuinely expired/revoked pairing needs human renewal. The service stops with
exit 78 and a notice instead of repeatedly spawning browser pairing. After
renewal, restart it. Internet absence alone is not an authentication failure.

## Inspect and recover

```sh
systemctl --user status sensei-desktop-commander
journalctl --user -u sensei-desktop-commander -n 30
cat ~/.local/state/sensei-den/desktop-commander.json
loginctl show-user "$USER" -p Linger
systemctl --user restart sensei-desktop-commander
```

The supervisor journal/state contain generic lifecycle information, never raw
agent output, auth URLs, account names or tool arguments. Native private logs
and `~/.desktop-commander-device/device.json` remain outside Git. Credentials
are mode 0600 in a 0700 directory.

Undo: `systemctl --user disable --now sensei-desktop-commander`. Keep pairing
files unless deliberately deauthorizing the device. Do not disable user
lingering blindly: other Den services may depend on it.

## Verification boundaries

Six tests cover readiness classification, delayed/deduplicated notifications,
authentication distinction, desktop availability, actual child crash/restart,
orphan cleanup and output privacy. A network-isolated native-agent probe
confirmed startup fails normally without internet; no live NIC was disconnected.
Physical cold boot is not performed automatically because it closes user work.

Official lifecycle reference:
[Desktop Commander remote-device documentation](https://github.com/wonderwhy-er/DesktopCommanderMCP/blob/main/src/remote-device/README.md).

### Deployed check — 2026-10-20

Arete and Homie: enabled + active, user lingering enabled, original paired device
IDs online in the official device list. Six lifecycle tests passed on each host.
A deliberate native-agent crash on each machine recovered to connected attempt
2 without re-pairing. Arete's connection notification reached the existing Den
notification receipts. Shared input/cursor/presence services remained running.
Boot configuration is verified; a physical reboot remains untested.
