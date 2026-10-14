# Digital Den — laptop controls Homie

Arete is the input master. Homie is physically above the laptop. Move through the **top edge of eDP-1** to enter Homie; move down out of Homie to return. **Ctrl + Alt + Esc** releases capture immediately. Existing laptop monitor geometry, bindings, shell and development configuration remain owned by Claude.

Lan Mouse 0.11.0 uses native layer-shell capture and wlroots input emulation. Its upstream top-edge selection chooses the highest output in a multi-monitor group; `capture-output.patch` adds the optional `DEN_CAPTURE_OUTPUT` environment variable so the physical laptop edge can be selected without changing any display position. If that output disappears, capture is disabled rather than moved unexpectedly. The PC uses the stock packaged binary. The laptop uses a private headless build from upstream revision `0d2190e787db9e482e17d4c16fb7c00ef4841bcb`:

```sh
git apply capture-output.patch
cargo build --locked --release --no-default-features --features layer_shell_capture,wlroots_emulation -j 4
```

This is a narrow local patch, not an upstream claim. Source, patch and private binary are kept in `~/.local/state/homie-control/`. Upstream source/license: [Lan Mouse](https://github.com/feschber/lan-mouse/tree/v0.11.0).

## Ownership and transport

Mouse/keyboard traffic is encrypted with DTLS. Each peer authorizes the other certificate fingerprint, read directly from its local certificate. Only LAN UDP/4242 is allowed. An unknown peer is not authorized by being on the LAN. Configs, certificates and SSH keys are private, outside this public checkout. Certificates have mode 0600; their directory is 0700.

Lan Mouse does not implement clipboard sharing. `den-clipboard.py` supplies a small event-driven bridge using `wl-paste --watch`, the existing strictly pinned key-only SSH connection, and `wl-copy`. It supports text and PNG up to 8 MiB, keeps payloads in memory, suppresses echoes, and excludes clipboard offers marked sensitive. It never logs or saves clipboard contents. Other MIME types and large file transfers are intentionally outside this bridge. The laptop owns the initial clipboard on reconnect; subsequent copies flow both ways. Clipboard history remains each desktop's existing local responsibility.

`den-session.py` discovers the current Wayland socket on each start, including after logout/login. New dedicated user units are linked from the private connection directory; they restart after failure and wait for a graphical session. These additions do not rewrite Claude's existing laptop services or desktop configuration.

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
