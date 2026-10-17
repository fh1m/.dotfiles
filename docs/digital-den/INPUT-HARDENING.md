# Input handoff and bar cleanup — 2026-10-16

The proposed role-specific bar buttons were withdrawn at the operator’s request.
The prior controls remain. Workspace rails now show local window counts, a muted
marker when the logical workspace is visible on another local panel, attention,
and a thin focus outline. Arete’s outline clears while Homie owns input.
No additional bar destinations or background status poller were added.

## Observed failures and repairs

- An asynchronous entry hook could finish after release or after another entry.
  Each native capture now issues a generation token. Placement checks that token
  before acting; older/duplicate receiver placements and stale recovery are rejected.
- A live test reproduced immediate recapture of the adjacent laptop edge before
  return placement finished. A token-bound return guard releases any new capture
  until placement completes, with a four-second upper bound if the helper dies.
- Receiver loss closed the transport but left a stationary source captured until
  motion occurred. Disconnect now explicitly notifies every edge using that peer;
  send failure also returns an error instead of reporting success.
- Concurrent visual ownership updates could arrive out of order. One coalescing
  worker now serializes them. Pointer placement uses one bounded SSH transaction,
  not repeated warps while the operator moves.
- Companion margin animation previously applied to automatic relocation too.
  Only an intentional, unobstructed horizontal walk of at most 200 logical pixels
  animates now. A display change hides/repositions it without a travel animation.

The private runtime is copied from `pc/den`; it is not installed by the ordinary
home-profile installer. Both machines need the same patched native binary, and
Homie additionally needs `den-entry-place.py`. Keep certificates, SSH profiles,
private screenshots and test recordings outside Git. No general shell input log
was enabled. Only the owned GTK fixture records its limited test keys.

## Reproduction and measured acceptance

`test_edges_desktop.py --live --cycles 2 --with-input` exercises all four routes
twice, varied crossing coordinates, then native triple-Ctrl pause/resume. It
requires the separately launched `input_fixture.py --owned-fixture` on Homie and
Arete’s dedicated native virtual-input fixture. The receiver window is checked
before keys, Ctrl+A, click or scroll are generated. Both sides have independent
expiry timers; cleanup pauses sharing and centres Arete. Resume explicitly with
`den-control start`. The fixture must use monotonic event times and real press/
release intervals: an earlier zero-duration synthetic sequence lost a test key;
that failed run is not counted as passing.

`test_failure_desktop.py --live` separately exercises stale entry, receiver stop
while the cursor is stationary, cursor-service restart, and Ctrl+Alt+Esc. Its
independent expiry returns control even if Python or SSH fails. The final native
build released stationary capture **3.479 seconds** after receiver stop. This
includes upstream keepalive detection, and is not an instantaneous failover claim.
Physical unplug, suspend/resume and cold boot remain separate hardware tests.

The companion was rendered in an isolated preview: placement, text, walk,
reduced-motion and quiet behavior were checked without changing live preferences.
Cross-display preview also confirmed travel animation stays disabled. Policy tests
reject vertical and long-distance walking. Final acceptance: all eight route/input
checks and triple-Ctrl pause/resume passed; 236 Python tests, four native Rust
regressions, cursor-safety tests and installer idempotence passed.

## Why these boundaries

[Lan Mouse source](https://github.com/feschber/lan-mouse/tree/v0.11.0) is the
transport/capture authority; our pinned patch remains narrow and local.
[PanelWindow documentation](https://quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/)
and the [layer-shell protocol](https://wayland.app/protocols/wlr-layer-shell-unstable-v1)
explain why margin changes move compositor surfaces. Automatic repositioning
therefore should not share the explicit-walk animation. Upstream issues about KDE
portal hotplug or DNS retries use different failure paths and were not treated as
proof of our defects. Community preferences for minimal bars are design input,
not reliability evidence.

To roll back, pause with `den-control home` first. Restore the previous private
binary/helper backup as a matching set; restore only intended UI paths from the
installer backup. Do not reset the repository or touch pairing credentials.

### 2026-10-17: shared-corner handoff storm

Live integration caught overlapping enter hooks and sharply rising CPU pressure. The source capture state now refuses a second outgoing handle while a route is active, until explicit release; a 250 ms re-entry guard prevents immediate recapture. Entry helpers check their generation before locking and use a nonblocking placement lock, so stale hooks cannot queue behind SSH. A busy return recovers local input rather than waiting indefinitely.

The headless upstream-pinned build completed. A first cold fixture attempt did not arm the receiver within its short startup budget; the harness now permits a bounded longer initial handshake. A subsequent live run passed all four routes (top→bottom, right→left, top→left, right→bottom), triple-Ctrl release to the main centre, and triple-Ctrl resume. No user application received typed text. The owned watchdog always survived the test process. Old binaries/helpers are retained privately for recovery. This is evidence for those tested routes, not a claim that every physical device or network failure has been exhausted.
