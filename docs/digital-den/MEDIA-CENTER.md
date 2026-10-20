# The Den media center

Open the music badge. The three primary sections are Spotify, YouTube and Twitch;
Spotify’s library views live beneath its own section. All share transport controls;
Ctrl+Space and the media keys control the source you chose. Browse another tab
without losing play/pause, skip, seek or volume. Choosing Spotify music releases
native YouTube/Twitch audio; resolving a failed video never stops existing music.

## YouTube

Search videos, lectures or music, or paste a video, channel or playlist URL.
Thumbnails open video **with sound**; headphones choose audio only. Queue and
local bookmarks are separate from your Google account. Queue entries can be
removed or moved earlier/later. There is no automatic unrelated-video autoplay.

My playlists, Watch Later, Subscriptions, Channels and History read the selected
Chrome profile on demand. Collections load 50 entries per page. Load more also
works inside playlist/channel collections. Account progress is never fabricated.
The local profile selection is `~/.config/sensei-den/youtube.json`:

```json
{"browser":"chrome","profile":"Default","keyring":"gnomekeyring"}
```

Choose the actual profile on each machine. Install `python-secretstorage` and
unlock its normal login keyring. Sign in through Chrome, never an embedded OAuth
form. Cookies are decrypted in memory by yt-dlp; no plaintext cookie file or
password is exported. Refresh re-reads the current session. Do not copy browser
credentials to Homie. Without a configured profile, public search/playback work when YouTube permits
anonymous access. A sign-in challenge retries the explicitly selected profile
once, then remembers that requirement for 15 minutes. There is no retry loop
for rate limits. Local saved items remain available even when YouTube is offline. Read-only account views do not create playlists,
change subscriptions, remove history or mark a video watched on Google.

During video playback:

- Mini-player floats over applications; drag its title or select another display.
- Fullscreen uses the selected attached display; exit/close controls stay visible.
- Escape restores the inline player. Space/K toggles, F changes fullscreen/mini,
  left/right seeks ten seconds when this video window has keyboard focus.
- Quality selects 360/480/720/1080p and reloads an existing recording at its position.
- Playback speed, chapters, captions and searchable transcript are available.
- Select a transcript line to seek. Follow tracks the current line; dragging the
  transcript turns following off. Language selection distinguishes automatic captions.

Audio remains available when the ordinary widget closes. Closing the ordinary widget while watching sends video to the mini-player.
Each attached display has a fixed surface with a lazily created player. Only
one player runs: a display transfer stops the old one and resumes the destination
at the saved position, volume and speed. Same-display inline/mini/fullscreen
changes reuse it. Inline mode positions the surface over the widget’s video slot.
No decoder item or live render surface is moved across QML render contexts.
Cold display transfers can buffer; startup waits for render-context readiness.
Closing a linked video stops its native audio; returning inline keeps playing.
Spotify candidate previews remain explicitly **silent** until you choose YouTube.

Captions are publisher/YouTube data, not guaranteed for every recording. JSON3
and WebVTT are supported; unavailable languages are reported without stopping
playback. No fabricated lyrics/transcripts. This does not bypass regional, age,
paid-content or account restrictions. Signed stream URLs stay in memory.

## Twitch

Live now, channel/topic search, recording URLs and local saved channels work
without a browser window. Native playback uses libmpv through KDE’s MpvQt, with one clock for both sound and picture;
mini/fullscreen and display controls are shared with YouTube. Refresh is manual;
there is no background discovery polling. Account playback explicitly uses the
selected Chrome session for the next stream through yt-dlp’s cookie jar. It does
not forward an OAuth header to video CDNs. Public playback remains the default. A channel can be offline normally.

Account checks the selected Chrome session and reports actual permissions. The
session tested on Arete is valid but lacks `user:read:follows`, `chat:read` and
`chat:edit`. The followed-channel website query was also denied. These are real
limits, not a broken-login claim: Following reports the restriction; public
search and locally saved channels remain usable. Chat, subscriptions, donations,
moderation and account mutations stay on Twitch. No messages are sent silently.
The isolated website GraphQL adapter is unofficial and may change independently
of the supported Helix API. Its failure does not erase local bookmarks.

## Ownership and storage

| Owner | Responsibility | Durable data |
|---|---|---|
| go-librespot + native catalogue helper | Spotify Connect, library, queue | Private Spotify state/config |
| `YouTubeDesk.qml` + MpvQt | One synchronized native A/V engine and explicit queue | Queue is session-only |
| `SpotifyDesk.qml` | Shared controls, source ownership, video sink | No signed URLs persisted |
| `youtube_music.py` | YouTube catalogue, private collections, captions | Private caches and local saved items |
| `twitch_media.py` | Bounded channel reads, HLS resolution, session checks | Private cache/local bookmarks |
| `MusicVideoWindow.qml` | Mini/fullscreen presentation, display choice | In-memory layout |

Local saved collections: `~/.local/share/sensei-spotify/{youtube,twitch}-library.json`.
Caches: `~/.cache/sensei-spotify/`. Treat account collections as private. The existing
encrypted backup includes the Spotify data directory; caches are disposable.
Never publish these personal collections with the dotfiles.

## Installation and recovery

Core packages: `mpvqt` (reuses installed mpv), `qt6-multimedia`, `yt-dlp`,
`python-secretstorage`, existing CAVA. Build the small Qt module once:

```sh
scripts/build-media-qml.sh # also included by scripts/build-native.sh
```

The shell adds its user module directory to QML imports and defaults to OpenGL,
as required by MpvQt. A missing module disables native video with a useful setup
message; it does not stop the rest of the shell. Rebuild after library upgrades.
Normal install uses the repository installer with the machine's hardware profile.
A package-mirror transition on Homie required this optional isolated fallback:

```sh
uv venv ~/.local/opt/sensei-media-tools
uv pip install --python ~/.local/opt/sensei-media-tools/bin/python \
  'yt-dlp[default]==2026.8.19' 'secretstorage==3.5.0'
```

The media command uses that interpreter for YouTube/Twitch and Spotify video discovery.
If Deno is unavailable, yt-dlp uses an installed Node runtime. Once distro packages
are healthy, removing the optional environment returns to system tools.

A live multi-output test caught Mesa `dri2_query_image` crashing the shell during
video presentation. The shell supervisor now defaults the documented Qt setting
`QT_DISABLE_HW_TEXTURES_CONVERSION=1`: mapped video frames avoid decoder-owned GPU
texture import while leaving hardware decoding available. YouTube/Twitch now use
MpvQt instead of that two-decoder Qt FFmpeg path, while independent silent
previews/camera previews can still use Qt. This is a compatibility workaround,
not proof the upstream driver bug is eliminated. Override with `0`
only for controlled diagnostics. No compositor/input services are restarted.

If a recording expires, Play resolves a fresh URL. If account reads fail, unlock
the selected profile's keyring and refresh. Public results and saved items remain.
The heavy Spotify desktop client is unnecessary for the headless backend.

## Reproducible live checks

Start a native video, then run this explicit foreground test (it temporarily moves
that video and pauses/resumes it; never moves your pointer):

```sh
python3 scripts/check-media-desktop.py --pid SHELL_PID --outputs eDP-1,DP-1,DP-2
```

Use only attached outputs. A missing chosen display falls back to the main one.
The receipt checks output routing, rendered size, actual render updates, A/V sync,
clock advancement and pause/resume. It restores the previous presentation mode.
A ticking clock alone is deliberately insufficient.

The Spotify service retries failed startup every 30 seconds without exhausting a
short systemd start limit. This repairs recovery after a temporary network/token
timeout; it does not bypass Spotify account or service restrictions.

## Verified on the deployed build

- 423 automated tests passed, plus Python compilation, ShellCheck and diff checks.
- Arete: four attached outputs passed rendered-video/clock/sync/transport checks.
- Paused display transfer preserved the exact position; only one engine played.
- YouTube: actual sink-monitor audio, 4,180 caption lines, selected-profile
  collections, paginated Watch Later and public search were exercised.
- Twitch: real live HLS video rendered; public discovery returned live channels.
- Homie: native build, 1080p picture, advancing playback and actual sink-monitor
  audio were verified. Its private Google views depend on its own login keyring.
- Spotify: the headless service recovered, loaded 52 playlists and resumed a real
  liked track after releasing native video. Homie was left paused.

Public screenshots use a public lecture and public search, never private account
collections. The test receipts omit stream URLs and account identifiers.

## 2026-10-20 polish

Mini-player has explicit previous/play-pause/next controls plus seek, volume,
restore and display selection. Its video viewport preserves 16:9. The listening
room's **Lyrics view** centres large live lyrics over the art-derived wash.
Tools fade after 3.5 seconds during playback; pointer movement reveals them and
hovering the toolbar keeps them available. Escape/F11 still exits.

A real YouTube response exceeded the bounded metadata limit because of expanded
translated subtitles. `youtube:skip=translated_subs` removes that redundant
expansion while retaining publisher captions and the size limit. Actual native
playback then advanced with video frames; this does not guarantee availability
for restricted or captionless recordings.
