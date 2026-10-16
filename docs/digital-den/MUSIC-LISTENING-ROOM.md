# Music listening room · 2026-10-16

The music widget now has a corner maximize button. Fullscreen keeps artwork,
playback, lyrics and queue/playlist browsing together. Escape or F11 restores the
widget; × closes the room. Tab reaches controls; unhandled Space toggles playback.
The room uses the initiating display; a short ScreenPad opens it on the primary
screen instead. A disconnected destination falls back to an available display.

## Audit → repair

| Observed in source/runtime | Change | Verification |
| --- | --- | --- |
| Lyrics replaced the list in the dropdown. No combined listening view. | Separate fullscreen presentation, sharing `SpotifyDesk`, transport and cache. | Real desktop screenshot, queue and playlist switching, Escape test. |
| Paused seek thumb could initialize at 1 ms before duration arrived and stay there. | Use normalized 0–1 position in both players, convert to milliseconds only on edit. | Runtime fraction equals position/duration. |
| Queue artwork contained `spotify:image:` addresses; Qt logged unknown-protocol warnings. | Convert the canonical 40-hex image form to Spotify's HTTPS image URL; reject unsupported schemes. | Actual queue covers displayed; service-logic regression test. |
| Old cover could remain while downloading the next cover. | Clear cover on source change, retain response identity checks. | Source inspection; fallback palette while loading. |
| Pending navigation reads could grow; late pagination could enter another library kind. | Deduplicate and bound pending reads to eight; validate target/kind, deduplicate context pages. | Execute actual QML JavaScript logic under Node with late-result fixtures. |
| System volume had visual feedback only. | 180 ms coalesced themed feedback; no startup/device-switch sound; muted/quiet/disabled paths stay silent. | Live PipeWire changes and sound-process result; original level restored. |
| External role labels repeated Upper/Lower in several places. | Compact monitor schematic with highlighted edge, display-settings action; brightness icon + level. | Bar inspection. |
| Compact workspace slots hid useful occupancy. | Tiny occupancy marks, accessible counts, Tab/Enter/Space, right-click/Menu opens existing overview at that subject. | Runtime rail state and keyboard/overview checks. |

## Ownership and cost

- No second player, Spotify login, catalogue poller or audio ownership change.
- Existing MPRIS controls and signed-in desktop bridge remain authoritative.
- Lyrics use the existing LRCLIB pipeline. Missing/unsynced lyrics remain honest.
- A 48×48 Pillow sample chooses a dark artwork-derived gradient. It runs once on
  artwork change/open, never each frame. Text stays on dark surfaces, with fixed
  theme colors. No animated blur, full-resolution background texture or shader.
- Position updates only while music is visible and playing. Lyrics use the existing
  250 ms clock. Queue refresh remains 15 seconds while visible/playing, plus actions.
- Volume feedback reuses installed libcanberra and the freedesktop sound theme.
  Sound → **Volume sound** persists an opt-out in local
  `~/.config/sensei-den/sound-feedback.json`. Quiet mode also suppresses it.
- Browsing requests may be discarded when superseded; playback mutations are not
  automatically retried. Fullscreen never transfers Spotify Connect ownership. Its playback-device button shows the reported active Connect device and opens the existing device controls; device state refreshes alongside the visible playing queue.

## Remaining boundaries

The official desktop must be signed in and the local bridge connected for rich
browsing. Its internal APIs can change with Spotify updates; the existing tested
client/repair workflow remains necessary. Fullscreen cannot cure account-side
restrictions, unavailable tracks, disconnected speakers or missing lyrics.

Cached lists can remain visible offline with a warning; they are not proof of a
live session. The legacy native Web API backend still has its upstream quota
limitation. No quota reset, credential transfer or new scraping backend was added.

The room does not pretend to be Spotify's entire application: account management,
advanced library edits and search remain in the compact widget/native client.
No destructive library-write acceptance test was run on personal playlists.

## Desktop comparison

| GNOME/KDE capability | Existing Den state / decision |
| --- | --- |
| Volume OSD, wheel control, per-app mixer and output routing | Already present; add audible level feedback with a visible opt-out. |
| Keyboard-first fullscreen | Add maximize/restore, Escape/F11, Tab and accessible icon names. |
| Pager occupancy and overview | Reuse existing overview; add compact occupancy and direct contextual access. |
| DND and notification history | Already present; reuse Quiet mode instead of another policy. |
| Display arrangement, per-display brightness, hotplug | Existing display services remain authoritative; role buttons open them. |
| Clipboard history, capture, battery/device telemetry | Existing widgets; no duplicate bar tools. |
| Night-light/color management parity | Needs a separate calibrated display audit; not changed during music work. |
| Pager wheel switching | Deferred: easy accidental switches at a screen edge; existing click/keyboard navigation remains. |
| Background effects | Static artwork tint chosen over continuous blur/visualizer load. |

## Files and rollback

Presentation: `modules/dropdowns/SpotifyFullscreen.qml`, mounted in `shell.qml`.
State/controls: `services/SpotifyDesk.qml`, `ShellState.qml`, `Ipc.qml`, `Osd.qml`.
Small changes in SpotifyDropdown/SpotifyRow/SoundDropdown and bar components.
Palette helper: `home/.local/bin/sensei-music-palette` (existing Pillow dependency).
Tests: `tests/test_music_presentation.py`; live acceptance uses disposable input
injection, no input grab, no modifier keys, and restores volume.

Installer backups remain in the normal dotfiles backup directory. Reverting this
commit and rerunning the profile installer removes the UI integration; existing
Spotify sessions, music, credentials and playlists are untouched. The optional
local sound preference can remain or be removed separately.

## Validation checkpoint

Arete: 291 unit/integration tests passed (41.316 s); 29 focused Spotify tests passed; installer backup/render/idempotence checks passed. Live widget acceptance selected the exact requested songs from liked and playlist rows, loaded 200 liked songs, 52 playlists, 24 search tracks and an 80-row queue. Listening-room acceptance verified queue/playlists, seek fraction and a real paired Escape restoring context. Main-display placement and ScreenPad → primary fallback were exercised, with focus restored afterward. Private screenshots were inspected locally and are not published.

Homie: 29 focused Spotify tests and all four new presentation tests passed. The real paired Escape acceptance also passed on DP-3, including queue/playlists and seek fraction. Its fullscreen screenshot was inspected locally. Volume feedback returned success and the original zero-volume setting was restored. The optional evdev input-test module was supplied in a disposable temporary directory, not installed into Homie’s runtime. No credentials were copied.

Current Focus/Backdrop behavior and the one-shot focus-release contract are recorded in [the 17 October polish](DEN-POLISH-V3.md). Escape exits Focus before closing the room; outside focus does not close it.
