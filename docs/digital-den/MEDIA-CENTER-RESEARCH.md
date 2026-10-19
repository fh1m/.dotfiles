# Native media expansion · 19 October 2026

This continues the 24-search Spotify investigation and the 32-search
[MUSIC-EXPERIENCE-RESEARCH](MUSIC-EXPERIENCE-RESEARCH.md) pass. Twelve additional
Google/Qt/client searches and targeted Twitch/Qt diagnostics informed this change.
These are distinct investigations, not a claim that every result was read.

| Question | Primary reference | Finding → implementation |
|---|---|---|
| Can an ordinary YouTube API key load Watch Later? | [YouTube errors](https://developers.google.com/youtube/v3/docs/errors) | Watch Later is not available through the public playlist API. Do not fabricate an API-key setup as the solution. |
| Should Google login live in an embedded view? | [OAuth policies](https://developers.google.com/identity/protocols/oauth2/policies), [native applications](https://developers.google.com/identity/protocols/oauth2/native-app) | Embedded user agents are restricted. Use the chosen existing Chrome session; no new embedded login form. |
| Can an existing tool read collections and captions? | [yt-dlp](https://github.com/yt-dlp/yt-dlp), [YouTube tab extractor](https://github.com/yt-dlp/yt-dlp/blob/master/yt_dlp/extractor/youtube/_tab.py) | Existing extraction supports account feeds, collection bounds and caption formats. Reuse it; keep the adapter bounded, on demand and replaceable. |
| Does Qt require Chromium to render video? | [MediaPlayer](https://doc.qt.io/qt-6/qml-qtmultimedia-mediaplayer.html), [VideoOutput](https://doc.qt.io/qt-6/qml-qtmultimedia-videooutput.html) | Native output supports playback and sink reassignment. Reuse installed Qt Multimedia; do not introduce an always-running Chromium instance. |
| Should every service have a separate decoder/window? | Same Qt documentation + local tests | One shared visual sink moves between inline/mini/fullscreen. An initial two-Qt-player prototype drifted and the user observed frozen frames. It was rejected. A shared MpvQt engine owns both streams and one A/V clock. |
| What does Twitch following require? | [Helix reference](https://dev.twitch.tv/docs/api/reference/#get-followed-streams), [scopes](https://dev.twitch.tv/docs/authentication/scopes/) | `user:read:follows` is required. Check actual granted permissions rather than claiming session presence implies access. |
| How are Twitch streams resolved? | [yt-dlp Twitch source](https://github.com/yt-dlp/yt-dlp/blob/master/yt_dlp/extractor/twitch.py), [Streamlink Twitch options](https://streamlink.github.io/cli/plugins/twitch.html) | Reuse yt-dlp already installed. Streamlink remains a fallback candidate, not another mandatory daemon. Authentication must not become a global header sent to arbitrary CDNs. |
| Why not embed all Twitch chat? | [Twitch embeds](https://dev.twitch.tv/docs/embed/video-and-clips/) and scopes above | Native video does not provide authorized chat or paid-account mutation. Current session has neither chat permission. Report the boundary, do not fake a full account clone. |
| Why did the live shell crash? | [Qt advanced FFmpeg configuration](https://doc.qt.io/qt-6/advanced-ffmpeg-configuration.html), local coredump | The actual stack reached Mesa/EGL `dri2_query_image` during video. Disable GPU texture conversion in the shell supervisor and repeat multi-output tests. Attribution to a particular upstream bug remains unproven. |

The twelve additional search questions covered Watch Later restrictions, native
OAuth, Qt WebEngine fullscreen/profiles, FreeTube login/import, YouTube Music
Desktop login, mpvqt, embedded Google security, practitioner experiences, iframe
restrictions and Qt hardware codecs. WebEngine was deferred. Native Qt’s separate-stream prototype failed live smoothness
tests; MpvQt was subsequently installed after source review and a working embedded
prototype. The wrapper is about 116 KiB and reuses existing libmpv. See the
[KDE source](https://github.com/KDE/mpvqt) and [mpv manual](https://mpv.io/manual/stable/)
for render lifecycle, separate audio tracks and the audio-master video clock.
The custom adapter exposes only the playback contract; it is not another player engine.

## Local observations, not general guarantees

- Selected Chrome profile could read 47 playlists and the first 50 entries each
  of Watch Later, subscriptions, followed channels and history. A second Watch
  Later page also returned 50 entries with another continuation.
- Micrograd video returned 4,180 caption lines and rendered 1920×1080 frames with
  audible native output. A music recording without supported JSON3 motivated
  WebVTT fallback. Some videos simply have no published captions.
- Twitch public discovery returned 24 live channels. A real robotics stream
  resolved to a Twitch HLS host and played using a single native A/V player.
- Existing Twitch browser session validated, but lacked following/chat API scopes;
  authenticated website following queries returned a service error too. No account
  data was silently substituted with public recommendations.
- A package download on Homie failed with mirror 404 before any package changed.
  The optional pinned media environment avoids a forced system upgrade mid-session.

Personal account names, cookies, response bodies, signed URLs and screenshots
containing private account views are deliberately not included in public docs.

## Renderer findings that changed the design

The two-player Qt prototype failed the live transfer test. A first MpvQt prototype
also failed: reparenting a decoder item or changing its live surface's screen
could free a render context still used by a render thread. The observed stack
reached `mpv_render_context_render`. A basic render-loop experiment did not cure it
and was reverted; normal threaded rendering remains enabled.

The resulting design uses fixed per-output surfaces and lazily creates a player
only when that output is used. A handoff stops the old player before loading the
destination at the saved position, volume, speed and pause state. Idle engines do
not poll or play. Each active engine has one A/V clock. Decoder startup waits for
MpvQt render readiness. The adapter targets the released MpvQt 1.2 API, tested by
building against the installed headers on both machines; master-only logging
signals were deliberately removed after the PC build exposed that mismatch.

This is a measured correction to the original architecture, not an assertion
that all third-party GPU/player bugs have been eliminated. The live harness checks
render updates and resume continuity, not only a ticking playback clock.

## Final account and recovery findings

Anonymous YouTube stream resolution returned a sign-in/bot challenge during live
testing. The same recording resolved successfully with the selected Chrome
profile. The adapter now retries that specific challenge once through normal
account access, remembers the requirement for 15 minutes, and never exports a
cookie file. Unrelated errors, including 429, do not trigger credential retries.
This follows [yt-dlp's browser-cookie support](https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-pass-cookies-to-yt-dlp).
The installed stable yt-dlp matched the upstream stable release at investigation;
blind version replacement was not the fix.

A real temporary Spotify token-request timeout exhausted the old three-start
systemd limit. The service now retries every 30 seconds without that short start
limit, so an overnight network interruption does not require opening Account.

Native YouTube output was measured through the selected PipeWire sink monitor:
30,848 signed 16-bit samples, RMS 406.97, peak 2,328. A live caption read returned
4,180 timestamped lines. These verify actual sound and source captions, rather
than merely a player reporting 'playing'. No recording or account content is
tracked here.
