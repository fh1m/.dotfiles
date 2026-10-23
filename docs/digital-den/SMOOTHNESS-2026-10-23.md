# All-display freeze investigation and music presentation repair

## Verified observations

The learner reports every display freezing visually while input is buffered;
workspace switching restores updates. This is not yet a reproducible automated
failure. No GPU reset, NVIDIA Xid, OOM or blocked-task report appeared in the
checked two-hour kernel window. Absence of those messages does not exclude a
rendering/fence problem.

Arete: Hyprland 0.56.2, Intel UHD630 + NVIDIA RTX2060 Mobile, two internal
60Hz outputs and two external 100Hz outputs. Keep the existing repaired
Aquamarine library and CPU-backed software cursor configuration.

RAM available was 0.5–1GB of 16GB, with 12–14GB swapped. One sample showed
56MB/s swap-in. Memory PSI recorded full stalls (avg10 up to 2.68%). Quickshell
itself had about 380MB swapped out. This is a verified contributor to cold UI
latency; it does not establish the cause of frozen display presentation.
Do not swapoff or terminate applications under this pressure.

## Changes and evidence

* Disable experimental `render:new_render_scheduling` on the existing laptop
  profile, live and persistently. Keep scanout and cursor settings unchanged.
  This is a conservative mitigation under evaluation, **not a proven permanent
  freeze cure**. Hyprland documents the option as experimental/default-off and
  has reports of setup-dependent stuttering.
* IPC median before/after: 4.50 / 4.38ms; maxima 5.02 / 6.69ms. These short
  samples demonstrate responsiveness only; they do not measure presented frames.
* Dropdowns previously mapped a full-sized dark placeholder while the async
  Loader was still compiling. Map only after Loader.Ready and stable geometry.
  Track which output still owns the request so a late ready signal cannot
  reopen a panel on its previous display.
* Live System, Sound and Spotify panels on all four outputs revealed only after
  readiness. Cold System open: 2675ms; other measured opens: 561–910ms. Startup
  latency remains material; do not hide this behind a claim of instant opening.
* Music uses actual lyric content, not provider success, to decide whether a
  lyric pane exists. Missing/instrumental lyrics center art/details. Available
  lyrics keep artwork left, with a responsive gap. Queue remains independent.
* Two real cover hues make a dark gradient, transitioning over 1.6s and drifting
  over 36s, capped at 10 updates/s. No shader, extra render process or full-resolution blur. Drift stops
  hidden/paused/reduced-motion; color transitions also honor reduced motion.
* Visual inspection revealed fullscreen tools behind the desktop bar. Reserve
  each output's actual top/bottom bar insets, including when moving displays.

## Lyrics ownership and availability

Existing local LRC/plain files, LRCLIB and lyrics.ovh remain supported. Optional
Musixmatch uses its official `matcher.lyrics.get` API, preserving restricted and
copyright fields; plain lyrics never receive invented synchronization.

Set `MUSIXMATCH_API_KEY` in a private environment, or store the licensed key at
`~/.config/sensei-spotify/musixmatch.key` (mode 0600). No key is shipped or copied
between hosts. Press Retry after configuration. The integration is unit-tested;
no live licensed key was available for acceptance. Copyright stays visible even
in focus mode.

Spotify has no public lyrics Web API. Lyrics Plus calls an internal Spotify
service from the desktop client. The current go-librespot control API does not
provide that capability. Do not claim official Spotify lyrics integration or
borrow another client's embedded tokens. Retain reliable fallbacks instead.

## Diagnostics and rollback

`sensei-frame-audit --seconds 120` records private, bounded memory PSI, available
RAM, swap and compositor IPC timing under `~/.local/state/den-diagnostics/`.
It records no window titles or conversation content. A responsive IPC sample
is not proof of a displayed frame. Correlate timestamps with future stalls.

Private pre-deployment copies:
`~/.local/state/den-repairs/smoothness-20261023-213706/`.
Restore only the particular file being reverted after comparing current edits.
Live scheduler rollback (no compositor restart):
`hyprctl eval 'hl.config({render={new_render_scheduling=true}})'`.
Persistently restore the previous value only if the comparison supports it.

Homie was initially offline and later became reachable again. Deploy only the
shared UI/lyrics files there; keep the laptop renderer profile on Arete. Record
the separate runtime acceptance below.

## Sources

- https://wiki.hypr.land/Configuring/Basics/Variables/
- https://hypr.land/news/update50/
- https://github.com/hyprwm/Hyprland/issues/10979
- https://github.com/spicetify/cli/blob/main/CustomApps/lyrics-plus/README.md
- https://github.com/musixmatch/musixmatch-sdk
- https://github.com/devgianlu/go-librespot/blob/master/API.md
- https://community.spotify.com/t5/Spotify-for-Developers/Update-endpoint-for-lyrics/td-p/5355493

## Acceptance receipts

78 focused automated tests passed (66 Spotify transport/backend/lyrics plus 12
music presentation/palette tests). Four-output panel-readiness checks passed.
Rapid successive same-panel requests across all four outputs left exactly one
visible panel on the final output. No new QML TypeError, ReferenceError or
configuration-load error appeared in the checked runtime log.

A ten-second diagnostic run returned all compositor IPC calls in 6.53ms or less;
available RAM fell to 473MiB. This short observation does **not** close the
intermittent display-freeze investigation. No reliable reproduction was obtained.

## Homie deployment acceptance

Homie reconnected during this pass and fast-forwarded main to d2e2a81. Shared
music, lyrics and dropdown files were deployed with private backups at
`~/.local/state/den-repairs/smoothness-20261023-214751/`. Its renderer settings
were not changed. All 78 focused tests also passed on Homie.

The reload exposed an older incomplete deployment: ControllerDropdown and its
service/helper were missing from the installed tree, despite existing in Git.
Installed those dependencies and the already-manifested `python-evdev` package.
The System panel then reported Loader.Ready, surface ready and reveal=1 on DP-3.

Also completed deployment of the previous Noesis launch repairs with its scoped
installer. A single controlled restart of **only Homie's main Quickshell shell**
was necessary: hot reload retained the previous Noesis singleton interface.
The new process exposes focused/launching/error fields correctly. Applications,
compositor and the independent cursor/input process were preserved. No account,
private-vault migration or authenticated Notion-sync acceptance is implied.

User feedback after the renderer change: **too soon to tell**. Keep the freeze
investigation open; do not describe it as permanently fixed.
