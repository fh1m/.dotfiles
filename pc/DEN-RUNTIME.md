> **Historical handoff.** Current development uses `main` on both machines. Start with [the current Digital Den guide](../docs/digital-den/README.md) and [PC guide](README.md). Preserve the recovery evidence below; do not repeat old installation steps.

# Den runtime and recovery

Arete coordinates shared architecture and design; Homie implements and verifies local desktop hardware and services. Current observed results and pending gates are in STATE.md. Private endpoint, trust, certificate and account settings remain outside Git.

## Storage

The named Den SMB3 share uses /srv/den/share on verified Dahua Btrfs @srv. Its capacity is shared with the other subvolumes on this same SSD. Authentication, mandatory encryption/signing, local and peer content round trips, guest rejection and Arete's user-session GVfs mount passed. The service is enabled at boot; clients use user mounts, not boot-blocking fstab entries. Sharing is not a backup; root Snapper does not include this separate subvolume. Preserve data before altering the share or its eventual storage backing.

The separate random credential lives in OS keyrings. Exchange only recipient-encrypted envelopes over authenticated SSH, never plaintext credentials or the sudo password. A locked keyring or Windows/offline peer must be reported as unavailable rather than silently falling back to guest or insecure transport. Recheck the actual DHCP endpoint before adjusting the narrow firewall/host ACL.

To stop sharing, stop/disable the local smb service and remove only its dedicated firewall rule. Restore the saved pre-Den Samba configuration if one existed. Keep /srv/den/share contents and do not delete the user's data as part of service rollback. Protected Toshiba/NVMe preservation gates still govern later storage expansion.

## Input

Deskflow uses Homie as keyboard/mouse server, Arete as client. Homie is physically to Arete's right. Private settings and TLS files are under ~/.local/state/den/deskflow. Peer fingerprints must be independently verified before pinning. Clipboard synchronization is disabled during acceptance. Lan Mouse is installed as a reviewed fallback and remains inactive.

Use the genuine installed desktop identity in the service name: app-org.deskflow.deskflow@denserver.service. The tested portal app-unit parser requires an alphanumeric instance; hyphenated suffixes can leave identity empty. Do not edit permission databases to bypass rejection. For Deskflow 1.27, computer declarations belong in general settings, while links/hotkey actions remain in the server configuration.

`sensei-den-input start|stop|status` manages Homie's own server. Ctrl+Alt+F11 selects Arete; Ctrl+Alt+F12 returns to Homie. Ctrl+Alt+Pause independently releases compositor input capture and stops the server. Bindings permit execution while input is captured. Registered/read-back shortcuts and local service control pass; peer TLS/session and actual input/physical release acceptance are still pending. The input service is not enabled automatically at login yet.

Rollback: stop the server, disable any later login activation, remove only its peer firewall rule, and restore the installer manifest for these helper/binding files. Preserve all user applications and private certificates until a deliberate revocation/reconfiguration. No unrestricted shell, sudoers relaxation or router exposure is part of this setup.

## Next checks

Finish paired typing, scrolling, modifiers and immediate local release in disposable windows. Test real reconnection and actual Windows/offline behavior. Continue canonical UI dependencies in small reviewed slices, then one bounded cross-host ROS topic experiment with exact image/environment identities. Benchmark compute placement and network throughput before training distribution or large artifact migration.

References: [Hyprland global shortcuts](https://wiki.hypr.land/configuring/core/binds/globals/), [systemd app naming](https://systemd.io/DESKTOP_ENVIRONMENTS/), [portal host identity](https://blogs.gnome.org/ignapk/2025/06/04/using-portals-with-unsandboxed-apps/), [Samba configuration](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html).
