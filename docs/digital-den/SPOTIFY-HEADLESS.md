# Music without the desktop client

## Ownership

`SpotifyDesk.qml → sensei-spotify[-control] → spotify_headless.py → 127.0.0.1:3678`

One go-librespot service owns playback, queue, Connect identity and native library.
Spotatui runs only for catalogue searches, with streaming, Discord RPC and update
checks disabled. It uses its own private configuration and cached session.
Neither normal route needs the quota-exhausted developer Web API.

## Setup

```sh
python3 scripts/setup-headless-spotify.py --build --apply --catalog
python3 scripts/install.py --hardware zenbook --apply # pc on Homie
systemctl --user daemon-reload
systemctl --user enable sensei-go-spotify.service
sensei-spotify-control backend headless
```

Go build needs the platform audio development packages. Both source revision and
release checksum are pinned in the installer. Source is GPL-3.0; the local patch
adds a bounded queue snapshot and paged context access. Build output stays outside
Git. Existing compatible local credentials are reused without printing them;
otherwise Account → Sign in pairs the device. Spotify Premium is required.

## Widget

- Playlists, Liked Songs, saved albums and followed artists; Load more preserves
  ordering and repeated playlist entries. Metadata may arrive after track URIs.
- Global search by tracks/albums/artists/playlists. Ten results per category,
  cached for ten minutes; saved-library matching remains usable after failure.
- Play/pause, single-step skip, seek, shuffle/repeat, volume, upcoming queue,
  enqueue, save/remove liked tracks and add to a selected existing playlist.
- Existing artwork, timed lyrics, fullscreen and distraction-free views.
- **Save moment / Resume moment** retain the latest twenty explicit bookmarks,
  including context and position. **Surprise me** samples the full Liked library.

Not claimed: offline downloads, full remote-device discovery, playlist creation,
reordering/deletion or unlimited search results. Unsupported mutations fail
explicitly instead of starting another client. Account restrictions and unofficial
service changes still apply; no promise of permanent immunity to rate limits.

## Recovery and privacy

```sh
systemctl --user restart sensei-go-spotify.service
sensei-spotify-control status
sensei-spotify library playlists
sensei-spotify search 'Daft Punk' tracks
```

Restart recovers saved login but does not automatically take playback ownership.
Account → Use official Spotify explicitly switches back and stops the headless
service. Switching back is equally explicit. No playback mutation is automatically
retried after an ambiguous HTTP error. Read failures preserve cached library rows;
429s honor a persisted cooldown.

Private files: `~/.config/sensei-go-spotify/`,
`~/.local/share/sensei-spotify/catalog-helper/`,
`~/.local/share/sensei-spotify/moments.json`. Protect their credentials through the
existing encrypted backup, never a public Git commit. Catalogue caches under
`~/.cache/sensei-spotify/headless/` are disposable. Service binds loopback only.
The backend-selection migration checkpoint is under
`~/.local/state/sensei-spotify-migrations/`.

## Verification — 19 October 2026

Actual account: 52 playlists, 575 Liked Songs reached across twelve pages.
Global search returned ten tracks while playback URI and ownership stayed stable.
Native playback reached playing state; one Next matched the upcoming queue item.
Pause, resume, volume and authenticated restart were exercised. PipeWire output
monitor captured nonzero audio (98,304 samples; RMS 1411.6; peak 4850, signed16).
No microphone recording was retained. Live widget inspected on the main display:
bar metadata, artwork, 52 playlist rows and queue populated without desktop Spotify.

Regression commands:

```sh
python3 -m unittest discover -s tests -p '*spotify*.py'
# From the pinned go-librespot build checkout:
GOMAXPROCS=2 go test -tags=test_unit ./daemon
```

Tests cover validated URIs, single-send skips, context preservation, stale-cache
recovery, failed writes, transition acknowledgements, pagination and offline search.
The initial process sample was approximately 58 MiB RSS; this is a short sample,
not an idle benchmark. Larger caches and metadata workloads can increase memory.

## Listening-room additions

Lyrics are independent of Spotify's developer quota. Exact LRCLIB lookup falls
back to cleaned-title lookup, conservative duration-qualified search and lyrics.ovh
plain text. Positive cache lasts thirty days; negative matches expire after fifteen
minutes. Provider outages preserve saved lyrics and are not cached as permanent
misses. Instrumentals are explicitly labeled. No universal coverage is claimed.

Retry bypasses the online cache. Local file opens the private override directory:
`Artist - Title.lrc` for timed lyrics, or `.txt` for plain text; its HOW-TO file
names the current song. Per-recording ±0.25s corrections persist across restarts.

The pink spectrum consumes the existing shared CAVA output, not another analyzer.
Its view stops updating when hidden. The listening-room spectrum button toggles it.

Videos opens five on-demand YouTube search candidates. Preview plays silently
inside the widget; Spotify remains the soundtrack. It deliberately favors H.264
MP4 up to 720p: the initial selected codec stalled Qt playback, while the H.264
route was visually verified with advancing time and 1280×720 frames. Preview is
not synchronized with the Spotify recording. Closing clears the video source.
Pop out uses mpv; YouTube search is available when extraction fails. No cookies,
permanent downloads, automatic next video or unrelated audio takeover are used.

[Additional 32-query research and decisions](MUSIC-EXPERIENCE-RESEARCH.md).
