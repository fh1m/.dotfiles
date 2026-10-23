# Noesis launch/focus repair — 2026-10-23

The bar click could focus Noesis on its previous Study workspace before the
asynchronous placement steps moved the window away. The result was an empty
workspace 4 and a misleading selected underline. Reopening an existing host also
omitted the invoking monitor unless it was explicitly supplied.

The launch contract now does the following:

- Current-placement reopen carries the invoking monitor; an explicit bar display
  takes priority. Dedicated placement remains an explicit preference.
- The bar supplies its display. ScreenPad remains a utility launcher for the main
  display; the lower desktop rail opens on its own display when docked.
- Window discovery never focuses prematurely. Focus follows verified workspace,
  floating/fullscreen state and geometry. Moving through the window's display
  control also requests focus after placement.
- The underline follows the compositor's actual focused Noesis window, including
  secondary windows, rather than a background-visible companion projection.
- Launch actions are serialized and failures produce a local notification.

Proof: the original live reopen reproduced an empty active workspace; the same
reproduction passed after repair. A focused Noesis → other application → reopen
cycle verified that the bar indication clears and returns. Explicit display,
current display and dedicated-preference tests pass. The Noesis Python suite has
187 passing tests; native offscreen dialog/window checks also pass.

Run `python tests/manual/noesis_reopen_focus.py` explicitly in the docked laptop
session. It opens the real application and changes focus; it does not alter notes.
The scoped installer backs up changed deployed files under the private
`~/.local/state/noesis-deployments/` directory. No compositor or input-sharing
restart is required.
