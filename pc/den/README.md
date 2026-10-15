> **Current status (2026-10-15): corrected sharing deployed and enabled.**
> Four photo-layout routes and triple-Ctrl recovery passed on the final build.
> Homie uses a non-capturing return watcher; its local input is never grabbed.


# Digital Den — laptop controls Homie

Arete is the input master. Homie is physically above the laptop. Move through the **top edge of eDP-1** or **right edge of upper DP-1** to enter Homie. Leave Homie through its bottom edge to return to the laptop, or through its left edge to return to the upper external monitor. **Ctrl + Alt + Esc** releases capture immediately. Both hosts use the unified main branch; hardware policy remains isolated by profile.

Lan Mouse 0.11.0 uses native layer-shell capture and wlroots input emulation. Its upstream edge selection is insufficient for this two-edge physical arrangement. `capture-output.patch` adds `DEN_CAPTURE_OUTPUTS=top=eDP-1,right=DP-1`, two receiver return edges, and a bounded authenticated return-edge message using the existing Leave payload. Only the active connection accepts a return; duplicate late returns are ignored. If a selected output disappears, its capture is disabled rather than moved unexpectedly. Both machines use the same private headless build from upstream revision `0d2190e787db9e482e17d4c16fb7c00ef4841bcb`:

```sh
git apply capture-output.patch
cargo build --locked --release --no-default-features --features layer_shell_capture,wlroots_emulation -j 4
```

This is a narrow local patch, not an upstream claim. Source, patch and private binary are kept in `~/.local/state/homie-control/`. Upstream source/license: [Lan Mouse](https://github.com/feschber/lan-mouse/tree/v0.11.0).

## Ownership and transport

Mouse/keyboard traffic is encrypted with DTLS. Each peer authorizes the other certificate fingerprint, read directly from its local certificate. Only LAN UDP/4242 is allowed. An unknown peer is not authorized by being on the LAN. Configs, certificates and SSH keys are private, outside this public checkout. Certificates have mode 0600; their directory is 0700.

Lan Mouse does not implement clipboard sharing. `den-clipboard.py` supplies a small event-driven bridge using `wl-paste --watch`, the existing strictly pinned key-only SSH connection, and `wl-copy`. It supports text and PNG up to 8 MiB, keeps payloads in memory, suppresses echoes, and excludes clipboard offers marked sensitive. It never logs or saves clipboard contents. Other MIME types and large file transfers are intentionally outside this bridge. The laptop owns the initial clipboard on reconnect; subsequent copies flow both ways. Clipboard history remains each desktop's existing local responsibility.

`den-session.py` discovers the current Wayland socket on each start, including after logout/login. New dedicated user units are linked from the private connection directory; they restart after failure and wait for a graphical session. These units remain separate from the desktop compositor's lifecycle.

## Reproduce the service wiring

Copy the maintained scripts into `~/.local/state/homie-control/`. Create the private input configuration and certificates there, authorize each independently read fingerprint, and configure the pinned SSH profile on the laptop. No credentials are supplied by this repository. Store the service files alongside the scripts, then:

```sh
systemctl --user link ~/.local/state/homie-control/den-input.service
systemctl --user enable --now den-input.service
# Laptop only:
systemctl --user link ~/.local/state/homie-control/den-clipboard.service
systemctl --user enable --now den-clipboard.service
```

The laptop has two client entries for the same authenticated Homie: `position = "top"` and `position = "right"`, both with `hostname = "homie.local"` and `activate_on_startup = true`. Their fixed local `enter_hook` calls `den-edge-return.py enter-top` or `enter-right`. Homie has no outgoing client. Both use `release_bind = ["KeyLeftCtrl", "KeyLeftAlt", "KeyEsc"]`, the layer-shell capture backend and wlroots emulation. Certificate fingerprints belong under `[authorized_fingerprints]` in each private config, and are never guessed or auto-trusted.

## Controls

On Arete:

```sh
systemctl --user status den-input den-clipboard
systemctl --user restart den-input den-clipboard
systemctl --user stop den-input den-clipboard
```

On Homie, use `den-input` only. To undo sharing, disable these newly added units with `systemctl --user disable --now ...`; remove only their unit links and dedicated Den firewall rules. Preserve unrelated desktop services and authorized keys. Private connection data may then be archived, never published.

The SSH endpoint uses `homie.local` with the independently verified host key pinned. Lan Mouse uses that hostname plus the current LAN address as a fallback. LAN-scoped firewall rules avoid tying input access to a temporary DHCP lease; certificate authorization remains required. For predictable fallback addresses, reserve the computers' leases in the router. No router or network connection settings were changed by this work.

## Verified behavior

A temporary native GTK receiver recorded the expected `d`, `e`, `n` keys, Ctrl+A, pointer motion, a click and wheel scrolling. A fixed-US native virtual-keyboard fixture was used; wtype's custom synthetic keymap is unsuitable as proof of physical scancode forwarding. The emergency release generated a verified capture-release event. Text and generated valid PNG clipboard fixtures passed both directions repeatedly, including after service startup. The test restored the laptop's previous clipboard; no test payload or private desktop screenshot is committed.

Both computers' input services and the laptop clipboard service are enabled. Cold boot, physical suspend/resume and unplugging the network still require hardware acceptance; the implementation does not claim these tests happened. Reboot is not performed while user work is open.

## Physical layout verified from the user’s photograph

```text
DP-1 upper external  ⇄  Homie DP-3
        ⇅                     ⇅
HDMI lower external  ⇄  eDP-1 laptop
                              ⇅
                         DP-2 ScreenPad
```

The red displays remain one Hyprland desktop; the blue display remains Homie’s own desktop. Laptop keyboard/mouse are the master. All four return combinations are tested, including entering from one red display and leaving onto the other. `den-edge-return.py` maps the crossing coordinate to the adjacent screen using actual logical sizes/scales and places the pointer a few pixels inward to prevent immediate recapture. It uses the existing pinned SSH connection only when crossing, not continuous polling; no display positions or unrelated Hyprland files are changed. A fixed local executable handles only validated edge IDs 1/2. The native virtual-keyboard, pointer, click, wheel and emergency-release tests remain available as private receiver fixtures.

`test_edges_desktop.py` is an explicitly invoked desktop acceptance harness, run on the laptop only while the private `Den input harness` receiver is open on Homie. It asserts focus before any test interaction, moves the cursor through the four routes and checks actual return coordinates. It is never run automatically by installation or at login.


## Safety and final acceptance — 2026-10-15

An earlier receiver edge-capture design captured the operator's input and required
a restart. It was disabled immediately. The deployed design replaces Homie's
capture barriers with a non-capturing cursor-position watcher. While remotely
owned and armed, it queries local Unix compositor IPC at 25 Hz, without spawning
per-frame subprocesses. There is no cursor polling while unarmed. The receiver
never locks its local mouse or keyboard for returning to the laptop.

Two native defects were corrected: replies for two edges sharing one peer could
be associated with the wrong client handle; repeated Enter packets could disarm
a return path. The fork also makes deferred capture lifecycle operations
idempotent and prepares emulation before acknowledging entry. The source patch
is pinned to upstream v0.11.0 / 0d2190e787db9e482e17d4c16fb7c00ef4841bcb.

Final live acceptance used independent 15-second systemd stop timers and a
try/finally cleanup; it sent no text or clicks. Both main-top→Homie-bottom and
upper-right→Homie-left entries passed, each returning through either Homie
bottom or left (four combinations), twice with the corrected return design.
The final build also passed real triple-Ctrl stop-and-centre recovery. The native
shared-peer routing regression test passed. This is evidence for these routes,
not a claim of exhaustive hardware/long-duration reliability.

Input, cursor, clipboard and storage services are enabled. Input service failure
restarts on failure only; an explicit stop or recovery never restarts it. Stop
cleanup resets ownership/readiness flags. Entry placement/readiness failures
request local recovery. The cursor UI has a pidfd death watch and its service
restarts independently. Keyboard/mouse authority stays with the laptop.

The independent cursor service remains enabled. Two bare Ctrl taps locate the
cursor; three toggle sharing: pause and return to the laptop main-screen centre,
then resume on the next triple tap. Ctrl chords are excluded from gesture recognition.
Local Homie input remains available with den-input stopped. If needed:
`systemctl --user stop den-input.service` on each machine. After recovery, triple-tap Ctrl again or use System → Digital Den → Sharing. Certificate/key material stays private.

Corner marks are pink on the focused display and muted on others. Inactive
screens also get a 14% black overlay. These surfaces accept no mouse/keyboard
input, reserve no screen area, and use no blur, shaders or idle animation.
A cursor-locator request animates briefly. Temporary lock-recovery outputs are
excluded. `qs -p ~/.local/state/homie-control/cursor-ui ipc call den-cursor state`
reports actual focus/dim state for diagnostics. While sharing, ownership changes
update both machines. The laptop remains the Den focus authority; Homie is marked inactive whenever
the laptop owns input.
The laptop's existing desktop configuration is not modified; Den uses isolated
user services and a runtime-only, removable Ctrl-event subscription.

### Storage and GPU acceptance

Homie has five physical drives. Six data volumes are available under `~/Drives`:
Datasets and Storage are writable; Windows-SATA, Windows-NVMe, Legacy-Linux and
Home-Archive are read-only. Existing ownership is preserved. The writable shared
workspace is `~/Drives/Storage/Den-workspace`. On Arete use `~/Den/Homie` over
host-key-pinned SSHFS. UUID-based nofail automounts avoid making removable/missing
storage a boot dependency. Original fstab is backed up on Homie under
`/etc/fstab.den-backup-20261014-220041`. No partitions were formatted.

Run `python3 pc/tools/check-homie-storage.py` on Homie for non-mutating checks.
Actual write/read/checksum fixtures passed Datasets and Storage/Den-workspace
through the network mount; fixtures were removed. All physical SMART health
checks passed. Four short-test logs completed without errors. Revenger reports
completed status but its stored test-log entry remains stale/in-progress; this
firmware discrepancy is unresolved. Transcend has three historical interface CRC
errors; reallocated/pending/uncorrectable counts checked were zero.

The GTX 1660 SUPER is the native display renderer. CUDA, Docker NVIDIA CDI and
NVENC encoding were exercised successfully. Idle P8 is intentional power saving;
no overclock or permanent high-power setting is imposed. Cold boot, suspend and
off-device backup restoration have not been tested in this session. Network
storage access is not a backup.

### Recovery and uninstall

Stop/disable Den input, cursor, clipboard and storage user services independently.
Stopping den-cursor removes its runtime Ctrl subscription. Unmount SSHFS with
`fusermount3 -u ~/Den/Homie` after closing files. Do not delete the drive content.
Review the backed-up fstab before undoing data-volume automount entries.
Existing desktop rollback backups remain under `~/.local/state/homie-control/backups`.
The cursor assets carry their upstream license and attribution alongside the theme.


### Current reproducible Den components

`den-session.py` discovers the active compositor; user-service templates remain
separate from hardware desktop deployment. Copy the maintained `pc/den` scripts
and `cursor-ui` into the private `~/.local/state/homie-control` runtime, retaining
its private certificates/config/SSH profile. Never copy those private files into
this repository. The PC needs the cursor service before accepting input; its
return watcher only arms after safe cursor placement. The laptop needs
`den-edge-return.py` and the private pinned `client.conf` profile.

Build the pinned native release with the checked-in patch:
`cargo build --locked --release --no-default-features --features layer_shell_capture,wlroots_emulation -j3`.
The receiver uses DEN_RETURN_WATCH=1 and DEN_RETURN_EDGES=bottom,left. Main capture
is scoped to top=eDP-1,right=DP-1; missing outputs disable that crossing. Local
session paths and monitor mappings are today's hardware adapters, not universal
layout detection. Re-run supervised acceptance after changing the physical layout.

Validation: 14 Python tests across clipboard protocol, recovery safety, PC profile
and developer launcher; 11 desktop checks; six volume checks; Python compilation;
installer apply then zero-change dry run; reverse-applicability of the native
patch; shared-peer Rust routing regression; actual four-route and recovery checks;
text and PNG clipboard checks in both directions. No unattended live input tests.


### Capture-native escape

Triple-Ctrl release is handled inside Lan Mouse while it owns input, independently
of the compositor Lua hook. It releases the native pointer lock first, sends the
final Ctrl-up to the receiver, then asks the separate cursor daemon to stop sharing
and centre the pointer. Double-Ctrl requests the locator. Normal Ctrl chords and
long holds do not count; unit tests cover both. Outside capture the non-consuming
runtime Lua hook provides the same gestures. Ctrl+Alt+Esc remains the native
release chord. The operator's desktop is never a target for automated typing.

Focus ownership acceptance: owner-off → no active PC output, owner-on → DP-3, owner-off → inactive again passed against the actual QML IPC state.

The System widget on either machine controls the same laptop-master state via `den-control`. Old Deskflow control is not used by this widget.


### Shared connection regression (2026-10-15)

Two edges aimed at one peer now reuse the existing live DTLS connection, scoped
to the configured address and port. Pong/disconnect state is propagated to both
handles. This avoids replacing an address-keyed socket with a competing second
connection. Three Rust tests cover reply routing, connection selection, and the
Ctrl gesture. A supervised test completed three passes of all four crossings
with typing, Ctrl+A, clicks and scrolling into an owned GTK test window. The
receiver event log confirmed every sequence; user applications were not typed into.
