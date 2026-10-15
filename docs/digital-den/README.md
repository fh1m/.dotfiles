# Digital Den

Arete travels. Homie stays at the desk. One checkout and one development branch, with explicit hardware profiles.

## Update either host

```sh
cd ~/.dotfiles
git status --short
git fetch origin
git merge --ff-only origin/main
python3 scripts/install.py --hardware zenbook  # Arete; use pc on Homie
# Review the preview, then repeat with --apply.
```

The installer backs up replaced files under `~/.local/state/dotfiles-backups/` and preserves seeded machine state, palette files and private account configuration. A second preview should report no changes. Do not pull over unrelated edits or run both hosts as simultaneous writers. Commit and push one host before updating the other.

Shared UI, shell, editor, learning tools and helpers live in `home/`. `profiles/pc/home/` overrides desktop hardware policy. `pc/` retains installation, disk preservation, firmware recovery and Den runtime source. Subject vaults and application credentials remain private.

## One keyboard and mouse

Arete is the master. Main panel top → Homie bottom; upper external right → Homie left. Return through Homie's bottom to Arete's main panel, or left to its upper external. The ScreenPad and lower external use the laptop's normal compositor boundaries.

- **Double Ctrl:** locate the cursor.
- **Triple Ctrl:** pause and centre on Arete; repeat to resume.
- **Ctrl+Alt+Esc:** immediate native release.
- **System → Digital Den:** sharing toggle, locator, bring home, storage and connection status. Both hosts control the same source state.

The receiver does not grab local input. A separate cursor service survives sharing being stopped. Inactive panels dim slightly; the focused display retains normal brightness. No blur animation runs continuously for this marker.

```sh
den-control status
den-control toggle
den-control home
systemctl --user status den-input den-cursor
```

Services start with the graphical session. `den-input` discovers the actual compositor. Missing configured outputs disable that edge. Private SSH profiles use key-only authentication, pinned host keys, keepalives and multiplexing; the PC's reverse key is forced to the Den action whitelist. LAN firewall pairing is local administration, not a public key or address list. A changed host fingerprint must be verified locally, never accepted automatically.

## Clipboard and storage

Text and PNG clipboard offers bridge in both directions; sensitive offers are excluded, payloads stay in memory, and 8 MiB is the limit. Other formats stay local. Private service/configuration state lives in `~/.local/state/homie-control/`.

Homie's `~/Drives` exposes the six UUID-based mounts. Arete's `~/Den/Homie` is an encrypted SSHFS view with reconnect. Windows and legacy Linux mounts remain read-only; only Datasets and the designated Storage workspace are writable. Disconnects never justify changing disk ownership or formatting anything.

## Qt context-menu guard

`bash scripts/build-qt-context-guard.sh` builds and tests the small local Qt guard
for the verified null-focus right-click crash. It is also part of `build-native.sh`.
The shell wrapper loads only a matching Qt build. Rebuild after Qt upgrades;
[the source and regression tests](../../src/qt-context-guard/README.md) explain
what is filtered and how to remove it. System libraries remain untouched.

## Recovery

If input behaves unexpectedly, use triple Ctrl or Ctrl+Alt+Esc, then `den-control home`. On either host's own keyboard, `systemctl --user stop den-input` stops that host's service. Restart sharing with `den-control start` only after the peer is available.

Native input source is pinned and patched in [pc/den](../../pc/den/README.md). Runtime scripts and units are maintained there; pairing keys and certificates are intentionally not installed from public Git. Back up private pairing state encrypted, separately from this repository. Git is not a backup for vaults, datasets or disks. Internal PC copies do not protect against whole-PC loss.

Installer rollback: use its timestamped backup and restore only the intended paths. Historical branch tips have annotated `archive/2026-10-15/*` tags. To inspect old source without switching the daily driver, use `git worktree add --detach /tmp/den-history TAG`.

## Validation

```sh
python3 -m unittest discover -s tests
python3 scripts/test-install.py
python3 pc/tools/check-homie-desktop.py       # on Homie
python3 pc/tools/check-homie-storage.py       # on Homie
```

The live edge harness requires explicit `--live`, a dedicated gesture fixture and supervision. It installs independent expiry timers, tests all four crossing/return combinations and the pause/resume gesture, then stops sharing and centres the cursor. Restore normal sharing afterward with `den-control start`. It never types text or clicks user applications.

[Hardware](HARDWARE.md) · [Consolidation record](REPOSITORY-AUDIT.md) · [Boot acceptance still pending](../../pc/BOOT-EXPERIENCE.md)
