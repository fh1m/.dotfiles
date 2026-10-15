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

## Continuity controls

`den mode auto` follows LAN presence. `den mode away` leaves Arete independent;
`den mode homie` is the explicit desktop-only context. Returning to `auto` restores
the normal desk policy. Input sharing stays LAN-only; remote administration and
jobs may use the pinned private Tailscale route. Triple Ctrl's manual pause must
survive automatic presence refreshes.

`den sync status` reports the personal mirror; `scan`, `pause` and `resume` are
explicit controls. Paths and selected vaults are private configuration. Git
histories travel through `scripts/setup-den-projects.py --apply`, never a synced
`.git` directory. Preview first; existing repositories are not reset.

`den job run --host homie --project PATH -- COMMAND` runs an owned persistent job.
Use `den job list`, `status --id ID`, `logs --id ID` or `cancel --id ID` to inspect
it. Remote commands are not retried after an ambiguous connection failure.
`den workbench open` opens the paired Homie desktop privately and releases edge
capture for the session; closing it stops Sunshine and restores prior sharing.

`den backup run`, `check`, `restore-test`, `retain` and `peer-copy` operate on the
private Restic configuration. Daily timers run the backup and peer copy; retention
is explicit (7 daily / 4 weekly / 3 monthly). Missing targets and free-space
reserves fail safely. Downloads, large recordings and generated data are excluded;
review the private scope before trusting it with new work. Keep recovery passwords
outside these two machines as well. Nothing is uploaded publicly.

### The little engineer

The README character now lives in the independent cursor renderer. It follows
the active display, checks for a free corner, speaks in short **text bubbles**,
and occasionally walks using the new 16-frame sheet. It never receives clicks.
If application windows fill the display, it hides; it is below applications even
while geometry refreshes. It does not read window titles, code, clipboard or keys. System → Digital Den provides its controls.

```sh
den companion say "One small baseline. Then the universe."
den companion wave
den companion walk
den companion quiet on
den companion chatter off
den companion motion off
den companion tip
den companion hide
```

`show`, `follow`, `here` and `size 96` restore or adjust it. Preferences are private;
the sprite sheet and QML are shared. Quiet mode, lock and fullscreen suppress it.
There is no speech service, model download or additional companion renderer.

The shared local catalogue mixes context-relevant tips with occasional original
humour; recent lines do not repeat. Automatic chatter is limited to once per six
minutes while visible. A new backup completion can produce a factual message;
startup does not replay old completions. No test or learning success is inferred.
`:DenTip` opens an explicit field note inside Neovim; q/Esc/Enter closes it.
[Research and decisions](POLISH-RESEARCH.md) · [Artwork provenance](ARTWORK.md).

### Machine-local setup

The `setup-den-{apps,sync,backup,projects}.py` scripts preview by default. Their
private state is outside Git. Arete's scoped firewall provisioning is
`sudo python3 scripts/provision-den-firewall.py`; it preserves the existing
firewall table policy and Docker rules. Homie uses its existing UFW policy.
Do not copy one host's firewall backend or hardware profile to the other.

To undo continuity automation, stop/disable `den-watch.service` and
`den-backup.timer`, pause Syncthing's Den folders, and use `den-control home`.
Keep notes, mirrored files, pairing backups and encrypted snapshots until their
recovery is independently confirmed. Installer backups allow targeted UI rollback.

## Input recovery

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

[Input handoff hardening and minimal bars — 2026-10-16](INPUT-HARDENING.md).
