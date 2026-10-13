# Digital Den

Arete travels; Homie stays home. Each machine owns its display, GPU, disks and local deployment. Changes cross machines as reviewed exact Git revisions, not whole-branch installations.

## Daily use

- `den status` — authenticated peer reachability, input process state, storage configuration.
- `den storage open` — open Homie's dedicated share in the file manager. Credentials live in the desktop keyring; the mount belongs to the user session and cannot block boot.
- `den storage check` — encrypted SMB3, temporary 64 KiB upload/download/delete, checksum verification.
- `den input start|stop|status` — explicit input client control. **Running is not proof of working input.** No login autostart until events and recovery are verified.
- `den inbox` / `den read ID` — locally received coordination records.
- `den peer-list` / `den peer-get ID` — fetch published peer records.
- `den send FILE` — explicit delivery with an exact-byte receipt. Message contents never execute.

System → Quick has matching storage and input actions. Status refresh runs while this panel is visible; there is no continuous polling daemon.

## Private setup

`~/.config/sensei-den/config.json` owns peer alias/name, input unit and storage host/share/user. Endpoints, SSH/TLS keys and mailbox messages stay outside public Git. The client uses `~/.local/state/den/ssh/client.conf`, strict pinned host checking and a dedicated forced-command key. Server `authorized_keys` must retain `restrict` and `den-mailbox --serve`; do not reuse this key for a shell or storage access.

The mailbox helper is reviewed from PC `pc/tools/den-mailbox.py` at `6add979`; its identical laptop copy installs through the existing `scripts/install.py` renderer. Keep changes synchronized explicitly. Each message has a stable ID, timezone-aware timestamp, sender/recipient, exact revisions, proposed changes, observations, tests and requested response. Changed bytes under an existing ID are rejected.

Storage uses a separate random account password. Provision via authenticated encrypted transport and store with `secret-tool` under attributes `service=sensei-den host=homie account=fh1m`; never put the password in configuration, command arguments or Git. The current credential lookup is Arete-specific; a future reverse storage share needs its own account/namespace. GVfs remembers its native credential in the keyring.

## Input backend repair

Deskflow v1.26.0 checks `XDG_SESSION_TYPE` to select the Wayland backend. A genuine `app-org.deskflow.deskflow@denclient.service` unit establishes portal application identity; its instance must be alphanumeric. The example under `home/.config/systemd/user/` intentionally is not auto-installed or enabled. Settings require **numeric** `log/level=4` for INFO, not the string INFO.

The existing KDE Connect portal bridge has a Phone consent gate. `phone-den-consent.patch` against upstream `gfhdhytghd/hypr-kdeconnect-fix` revision `362b904235c1b1d679eef73cbd5ad08d313d8954` retains that gate and adds separate per-login Den consent. Only the genuine Deskflow application and verified executable may use it. On this machine, unprivileged filesystem sandboxing makes sibling `/proc/PID/exe` checks fail with EACCES: isolated `systemd-run` comparisons verified this for ProtectHome, ProtectSystem and PrivateTmp. The accompanying scoped drop-in disables those namespace restrictions while keeping NoNewPrivileges, address-family/syscall hardening, caller validation and explicit consent. Apply it only to this bridge; do not weaken SSH or other services. No Phone access is enabled by starting Den. This is a local downstream patch, not an upstream release claim.

To reproduce: obtain that exact source in a separate directory, `git apply --check` then apply the patch; configure/build with CMake; run CTest. Back up the installed binary and any existing source modifications before replacing it. Restart only the bridge with input clients stopped. `den input stop` removes Den's runtime consent; the Phone switch remains independent. Never replace the existing checkout or its uncommitted patch blindly.

## Limits and recovery

The current laptop Ethernet adapter supports 100 Mb/s; Homie supports gigabit. This limits transfers and future distributed training. Each GPU has its own 6 GiB VRAM; two machines do not create a shared 12 GiB allocation.

Only Homie's 256 GB Linux disk is currently connected. The share uses a verified directory on that filesystem. Planned 4 TB storage is not available yet; reconnecting disks requires fresh identity/mount/data-preservation checks. Linux storage and input services are unavailable while Homie is booted into Windows. Windows sharing requires separate installation and acceptance.

Storage is **not a backup**. Keep source in Git, active builds local and large recordings in deliberately managed artifact storage. Add an independent off-device backup before treating Homie as archival protection. Never synchronize credentials or live vault/editor session files.

Undo: stop Den input, disable the mailbox user service if desired, unmount the GVfs share, remove only Den-owned units/configuration/keys and erase its dedicated keyring credential. Keep data and any unrelated SSH/Phone configuration. The portal binary/source backup is in private Den state. Nothing requires editing sudoers or formatting a drive.
