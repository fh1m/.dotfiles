# Music experience: lyrics, video and spectrum

19 October 2026. This extension executed **32 additional targeted searches**, beyond the earlier 24-query backend pass. Results are leads; source checks and live behavior govern implementation.

| Question | Checked material | Decision and limitation |
|---|---|---|
| Lyric coverage without false matches? | [LRCLIB API](https://lrclib.net/docs), existing matching code, live exact lookup. | Exact recording, cleaned title, duration-qualified search, independent plain text. Never manufacture timing. |
| Independent fallback? | [lyrics.ovh source](https://github.com/NTag/lyrics.ovh); README retrieved. | Bounded documented endpoint. Missing lyrics do not interrupt playback. |
| Practitioner pain? | [r/musichoarder discussion](https://www.reddit.com/r/musichoarder/comments/1jj723p/batch_embedding_non_synced_lyrics_to_songs/) read. | Local overrides and remembered per-recording corrections. Anecdote does not prove universal coverage. |
| Another framework? | [Mopidy architecture](https://docs.mopidy.com/stable/reference/architecture/), Spotatui docs. | Reuse existing widget and ownership; no third permanent player. |
| Low-cost spectrum? | [CAVA config](https://github.com/karlstav/cava/blob/master/example_files/config), README fetched; local Cava.qml read. | Reuse shared 48-band output monitor; no microphone or duplicate analyzer. Hidden music views do not update bars. |
| Video discovery? | [yt-dlp docs](https://github.com/yt-dlp/yt-dlp/blob/master/README.md), [mpv manual](https://mpv.io/manual/stable/). | Five explicit candidates cached a day. Search result is not verified official attribution. |
| Stable preview? | Installed mpv/yt-dlp and live extraction test. | Preflight before silent compact preview; Spotify keeps audio. Recording timing may differ. Browser search fallback. |
| Unlimited content? | Spotify support/developer search and client documentation. | No universal-coverage or permanent-access claim. Missing material is normal. |
| Hacker News? | Thread request failed; earlier HN request returned 429. | No claim of reading inaccessible discussion or community consensus. |

## Executed queries

1. `LRCLIB API get search duration instrumental synced lyrics documentation`
2. `site.github.com/NTag/lyrics.ovh API lyrics documentation`
3. `site.github.com/tranxuanthang/lrcget LRCLIB matching lyrics`
4. `site.github.com/Lyricsify LyricsGenius lyrics API authentication`
5. `site.github.com/mopidy/mopidy music library frontend playback architecture`
6. `site.github.com/devgianlu/go-librespot issues lyrics playlist Connect`
7. `site.github.com/LargeModGames/spotatui cava visualizer lyrics native`
8. `site.github.com/karlstav/cava raw output format stereo fifo configuration`
9. `site.quickshell.org docs cava audio visualization PipeWire`
10. `site.github.com/quickshell-mirror/quickshell audio visualizer Cava`
11. `site.github.com/yt-dlp/yt-dlp ytsearch flat playlist dump json documentation`
12. `site.mpv.io manual keep open no audio video window wayland`
13. `site.developer.spotify.com music videos Web API support video playback`
14. `site.support.spotify.com music videos availability official`
15. `site.github.com/metabrainz/musicbrainz-server recording video relationships`
16. `site.musicbrainz.org relationship music video recording youtube`
17. `site.reddit.com/r/unixporn cava music visualizer resource usage`
18. `site.reddit.com/r/spotify Linux lyrics alternative API rate limit`
19. `site.news.ycombinator.com Spotify lyrics librespot music player`
20. `site.github.com/Lyricify/Lyricify-App lyrics sources synced`
21. `site.pipewire.org pw-cat monitor target audio capture documentation`
22. `site.freedesktop.org MPRIS media players priority selection`
23. `site.github.com/badminton99/lyse LRCLIB cached lyrics`
24. `site.github.com/spicetify/cli lyrics plus fullscreen lyric offset`
25. `site.mpv.io manual ytdl format video only audio no stream`
26. `site.github.com/yt-dlp/yt-dlp YouTube js runtime EJS cookies error`
27. `site.lrclib.net docs rate limiting user agent search`
28. `site.github.com/karlstav/cava readme input pipewire pulse output raw`
29. `site.github.com/koeqaife/quickshell cava visualizer bars`
30. `site.github.com/RayZ0rr/lyrics lyrics caching local lrc`
31. `site.reddit.com/r/linux music videos mpv spotify lyrics widget`
32. `site.github.com/LargeModGames/spotatui search lyrics visualizer config`

## Deliberately omitted

No permanent embedded browser, automatic listening-history upload, random video autoplay, invented timing, credential rotation, indiscriminate site scraping or second analyzer. Existing artwork colors, fullscreen, focus/backdrop and timed seek are reused.

