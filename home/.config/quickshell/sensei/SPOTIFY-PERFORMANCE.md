# Spotify and widget responsiveness — 27 September 2026

The full path is widget input → compiled local bridge → loopback UDP daemon → native Librespot player → per-client PulseAudio stream → PipeWire → laptop speakers. Spotify Web API is reserved for catalogue/account operations, not transport controls.

## Measured bottlenecks and changes

- Local status calls measured roughly 2 ms with the C bridge, versus roughly 80 ms for the Python path when quiet and up to 300 ms during compilation. Transport and catalogue work now use separate processes so loading a library cannot block pause, skip or volume.
- Native playback events update cached metadata and wake the widget. Current playback metadata takes priority over delayed MPRIS snapshots. Artwork remains visible while its replacement loads; cached art uses the fast local path.
- Skip commands preserve playing/paused intent explicitly. Native queue loading preserves subsequent songs; playback continued automatically at a natural track boundary during observation. A startup pause guard no longer pauses the first deliberate play command.
- Cold Spotify audio loads were taking approximately 2.7–3.4 seconds after the transport command had already arrived. The next known track is now preloaded earlier, rather than waiting until the last 30 seconds of the current track. Only one next track is requested; shuffle uses Spotify’s actual next-track response rather than guessing. Audio cache is limited to 256 MiB. Uncached or unavailable tracks still depend on Spotify/network response times.
- Playback Web API refreshes are coalesced, background queue refresh is throttled, and the daemon no longer duplicates terminal-interface library/genre/artwork requests. The widget loads library pages on demand. This reduces API bursts and rate-limit pressure.
- Spotify-specific PulseAudio latency tuning reduced observed stream buffering; global PipeWire settings were preserved. No continuously running transport polling loop was added for paused music.

## Shared controls and idle work

Sound uses native PipeWire controls for instant feedback. Its detailed device snapshot follows audio events while open with a slow fallback, rather than repeatedly spawning six commands. One combined pactl listing replaces five separate listings. Slider controls hold a chosen value until acknowledgement to avoid snapping backwards.

Spectrum processing stops when unused. Song-title width transitions are eased. Display brightness requests coalesce separately for each display so adjusting one cannot discard a pending adjustment to the other.

System/monitor page opacity bugs were fixed and all 30 monitor, system, sound, calendar and Spotify pages were checked for visible content. USB/Nvidia outlines match occupied-workspace outlines. Shared controls now use compact knobs, thin progress rails and uniform fields without duplicate focus underlines.

## Maintenance

The background client is a locally patched spotify_player 0.25.1 build at `~/.local/share/sensei-spotify-client/bin/spotify_player`, with source beside it. The bridge source is `helpers/transport.c`; the Python helper retains catalogue features. Rollback copies are under `~/.local/state/hyprland-repair-20260926/`. Package upgrades do not overwrite this private binary; rebuild it deliberately when upgrading its source.

Verification included isolated transport fixtures, playing/paused skip checks, volume burst/restore checks, visible-widget audits and passive audio-loader logs. Cold-load latency is not a guarantee of instant playback. No personal caches, clipboard history or user files were deleted.

Reference: [PipeWire PulseAudio client latency configuration](https://pipewire.pages.freedesktop.org/pipewire/page_man_pipewire-pulse_1.html).

Final verification: local status samples after compilation: [2.88, 2.6, 2.85, 3.23, 4.04] ms. A three-second paused sample measured Spotify 0%, Quickshell 1.7%, Hyprland 2.3% of one CPU core; this is a short observation, not a long-term benchmark. Latest startup still logs Spotify Connect transfer/context warnings before the explicit local queue is restored; playback and preloading recovered successfully. No claim of a completely warning-free upstream client. Temporary build output (about 1.1 GiB) and the redundant disabled external cache timer were removed; the player now enforces its cache limit internally.

Bluetooth follow-up: the earlier PULSE_LATENCY_MSEC=60 experiment was removed after remaining audible jitter. Spotify now uses normal CPU priority (Nice=0) and its normal PulseAudio stream buffer: observed tlength 25,580 bytes at 44.1 kHz stereo S16, roughly 145 ms, versus 7,936 bytes (~45 ms) in the earlier experiment. Local transport command speed remains independent of that audio queue. See BLUETOOTH-AUDIT.md for the headset-specific send-buffer fix and packet evidence.

## Explicit device ownership

Daemon initialization/reconnect no longer automatically transfers Spotify playback. The recovery helper does not silently reclaim a missing device. Devices highlights the user's selected device separately from the server's reported active device. Native event hooks carry the local device ID and player PID; live local playback can override stale cloud metadata, while an explicitly selected remote device remains authoritative. Native controls use local playback ownership to avoid routing a track-change command to a stale foreign device. Explicit local queue/context starts activate the integrated player before loading; background preloading does not activate it.

Spotify Connect remains account-wide: another client can explicitly transfer playback. This change prevents our automatic device competition; it cannot prohibit the Spotify server from accepting another client's request. Transport fixture checks include stale foreign metadata, explicit remote selection, volume bounds, UTF-8 metadata and skip intent.
