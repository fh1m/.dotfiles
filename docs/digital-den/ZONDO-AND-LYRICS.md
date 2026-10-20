# A listening room, and one Zondo

The media room is non-modal. Shared dropdowns also avoid modal compositor grabs
while the native Den input service is running, and dismiss on app/monitor focus
changes. The private running marker is maintained by the session lifecycle. It must never trap Den's pointer barriers. The
previous fullscreen focus grab blocked entering Homie; removing that grab passed
all four edge/return combinations with fullscreen music still open. Escape/F11,
click-to-focus controls and the existing restore/close buttons remain available.

Artwork stays left, lyrics right, separated by a display-scaled gutter. A narrow
or portrait display stacks the sections. Media prose/controls use the Noto Sans
family, with Bengali, Devanagari and Arabic script faces selected explicitly;
telemetry and shell branding retain their existing fonts. Active lines centre
and fill as their timestamp interval advances. This is **line-timed fill**, not
invented word timestamps. Manual scrolling suspends follow; Follow restores it.

Visual references inspected:
- [Lyrics Plus](https://github.com/spicetify/cli/tree/main/CustomApps/lyrics-plus)
  distinguishes karaoke, synced and unsynced data.
- [Beautiful Lyrics](https://github.com/surfbryce/beautiful-lyrics) and its actual
  animated marketplace preview demonstrate active-line focus and generous media
  composition. No Spotify/Spicetify implementation code was copied.

## Singing

Zondo follows the current complete lyric line for an approximately 18-second
sing-along episode, with a 90-second minimum between starts. Lines update with
the existing media lyric clock. Pause, expired timing, quiet mode, DND and lack
of safe wallpaper stop/suppress speech. Line length is bounded at 320 characters.
A line receipt includes its end time, preventing an old line being sung after a
cross-host transfer. No audio speech or online conversation is introduced.

An enabled, chatty Zondo can request the ordinary cached lyric lookup once per
track, even when the media panel is closed. It reuses the existing providers and
cache; there is no second lyric backend, catalogue poll or Spotify quota bypass.
Missing timing remains missing; he does not invent lyrics.

## Notifications

The existing notification daemon publishes a private, bounded plain-text receipt.
Zondo can announce new local/peer notifications, distinguish KDE Connect's phone
messages, and periodically remind about pending items without a streak or nag.
Phone cards use a cool teal accent and explicit PHONE label; desktop cards retain
the theme's pink. His small badge counts pending notices from the active Den.
DND on either participating host suppresses speech; pending state remains visible.
Opening/clearing the notification centre removes read entries from the receipt.

Only host, ID, time, app, summary, plain body and phone classification are shared
through existing pinned SSH leases. No notification actions, image payloads or
remote commands are accepted from notification content. IDs already announced
are bounded, retained privately and shared during handoff. Content stays under
`~/.local/state/sensei-den/`, never in Git. The original notification history is
the authority; Zondo's bounded delivery queue is a companion, not its replacement.

## Artwork and rendering

`zondo-singing-v1.png` and `zondo-phone-v1.png` were generated for this system with
the built-in imagegen tool, using the existing Zondo as the identity reference.
Both are transparent 1254×1254 atlases with four explicit square frame rectangles
in `activity-atlases.json`. Originals remain in the private Codex output directory;
project assets are committed here. The artwork is Zondo, not fh1m's portrait.

A sprite viewport clips to the exact scaled frame, **not** the larger square pet
surface. The old square clip exposed neighboring figures for tall frames,
creating the apparent three-Zondo bug. One decoded texture is reused; frame
changes only translate it. New poses are contextual: singing for lyrics, phone
for phone deliveries. They are excluded from random ambient activity selection.
Quiet/reduced-motion settings, one-renderer ownership and safe wallpaper placement
remain in force. Telemetry warnings speak on transitions instead of overwriting
singing or messages every sample.

### Updating the renderer

Qt retains imported JS modules for the renderer engine's lifetime. After changing
`ZondoLogic.js` or `SpeechLayout.js`, restart `den-cursor` on each host; the QML
Loader's `reloadCompanion` alone does not invalidate those scripts. This restart
is independent of `den-input`, so it does not take over or stop normal local input.
Live validation caught and corrected both an unsupported `Array.flatMap` use and
an old cached JS import; the queue policy uses compatible array operations.
