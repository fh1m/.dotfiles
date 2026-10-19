# Music backend research — 19 October 2026

This pass ran the 24 targeted queries below, followed by source-code checks and live tests. Search counts are not evidence of quality. Primary implementation source and observed runtime behavior decide the integration.

| Question | Source and evidence | Decision |
|---|---|---|
| Why is the bar empty? | Local spotify-player logs: repeated public API 429s; native-event resolver calls public track metadata. | Remove that dependency from normal transport and browsing. |
| Lightweight playback and library? | [go-librespot source](https://github.com/devgianlu/go-librespot/tree/bd3fa7407eb1ab595295446e1be50cb9663e69cb), API spec and daemon/library code inspected. | Pinned headless Connect service, loopback only; shared adapter. |
| Large collections? | Source separates context URI enumeration from a bounded metadata cache; original endpoint caps enumeration and lacks page parameters. | Maintained pagination patch; preserve track order and repeated tracks; don't call a partial result complete. |
| Public API resilience? | [Spotify rate limits](https://developer.spotify.com/documentation/web-api/concepts/rate-limits) and [quota announcement](https://developer.spotify.com/blog/2026-07-23-web-api-quota-updates). | No developer-key rotation; preserve cooldown and saved rows. |
| Global search and richer edits? | [Spotatui native search](https://github.com/LargeModGames/spotatui/blob/main/src/infra/spotify/search.rs), playlists, CLI and credential source inspected. | Evaluate an on-demand catalogue helper with streaming disabled, not a second always-playing daemon. Persisted query hashes can expire; preserve local library search. |
| Lyrics? | [LRCLIB](https://lrclib.net/docs), existing local implementation, [practitioner discussion](https://www.reddit.com/r/unixporn/comments/1rskqyc/oc_lyse_tui_synced_lyrics/). | Keep existing cached timed lyrics and seek-on-line behavior; don't start a duplicate lyrics process. Practitioner comments are qualitative, not proof. |
| Accurate bar position and media keys? | [MPRIS Player specification](https://specifications.freedesktop.org/mpris/latest/Player_Interface.html). | Match the selected backend's player; local status uses milliseconds, clear loading acknowledgements. |
| Heavy desktop fallback? | Existing Spicetify bridge and native adapter inspected. | Preserve explicit rollback, never auto-launch the desktop when headless succeeds. |
| Official embedded SDK? | [Hardware onboarding](https://developer.spotify.com/documentation/commercial-hardware/onboarding). | Partner onboarding is not a drop-in personal workstation backend. |
| Discovery services? | [MusicBrainz developer resources](https://musicbrainz.org/doc/Developer_Resources), [ListenBrainz docs](https://listenbrainz.readthedocs.io/en/latest/), [Last.fm API](https://www.last.fm/api). | Don't send listening history or add accounts automatically. Prefer a local saved-library surprise and explicit saved moments. |
| Can it be guaranteed forever? | Connect libraries use unofficial service interfaces. HN thread request returned HTTP 429; no claim to have read the inaccessible discussion. | No permanence claim. Pin source, test recovery and keep rollback. |
| Resources and actual sound? | Local status, PipeWire output-monitor measurement, process RSS, queue transition tests. | Report measured output, not merely HTTP 200. Restart must recover login without automatically stealing playback. |

## Executed targeted searches

1. `site.github.com/devgianlu/go-librespot context tracks pagination metadata max_tracks`
2. `site.github.com/devgianlu/go-librespot library playlists folders rootlist`
3. `site.github.com/LargeModGames/spotatui search CLI native Web API`
4. `site.github.com/librespot-org/librespot metadata playlist collection SpClient`
5. `site.github.com/librespot-org/librespot Spotify Connect reconnect volume takeover`
6. `site.github.com/devgianlu/go-librespot skip debounce metadata queue`
7. `site.developer.spotify.com Web API rate limits Retry After 2026`
8. `site.developer.spotify.com Web API changes 2026 development mode`
9. `site.lrclib.net docs synced lyrics search duration`
10. `site.github.com/spotify/pedalboard loudness normalization audio`
11. `site.mpris.org Media Player 2 position Seeked metadata`
12. `site.pipewire.org PulseAudio stream monitor latency`
13. `site.github.com/LargeModGames/spotatui plugins library playlist search native limitation`
14. `site.github.com/hrkfdn/ncspot librespot library search API`
15. `site.github.com/jpochyla/psst Spotify API search library`
16. `site.github.com/devgianlu/go-librespot issues library large playlist`
17. `site.reddit.com Spotify alternative client API quota library Linux`
18. `site.news.ycombinator.com Spotify librespot client music library`
19. `site.reddit.com unixporn music widget lyrics spotify`
20. `site.github.com/spicetify/cli lyrics plus fullscreen`
21. `site.musicbrainz.org doc API rate limiting recordings`
22. `site.listenbrainz.org developer API recommendations music`
23. `site.last.fm api terms get similar tracks`
24. `site.github.com/quickshell-mirror/quickshell Mpris Spotify metadata`

Follow-up checks included the official hardware onboarding boundary, actual Spotatui CLI/native source, a Reddit discussion read, the HN access failure, and source-level pagination diagnostics. No public messages were sent.


## Integration outcome

Spotatui v0.46.0 CLI search was verified without its TUI, with streaming disabled;
playback ownership stayed on go-librespot. Its MCP server alone is **not** a
standalone catalogue service: without a running TUI it exposes an offline
executor. We therefore use the tested CLI boundary, not a permanent second player.
Playlist creation is deferred: the inspected native implementation defaults to
public visibility, which would be a poor implicit publishing action.
The release archive SHA-256 is pinned in `scripts/setup-headless-spotify.py`.
