# Widget, Spotify and phone reliability — 2026-09-28

Backups in this directory retain each changed source and the native Spotify transport binary.

## Changes
- Phone actions queue (up to 12), coalescing identical queued actions. Unrelated controls remain usable during operations. Identical D-Bus/status snapshots do not rebuild UI models.
- NetworkManager state changes trigger delayed KDE Connect refresh; paired unreachable devices retry discovery every 15 seconds. Saved Android Tailscale IP discovery remains configured. No firewall, routing or pairing credentials changed.
- Phone Setup includes Samsung background/Always-on settings and official Termux:Boot services documentation.
- Spotify uses playlist /items endpoint and modern item wrapper while retaining legacy track wrappers. Fresh cache namespace avoids old malformed playlist caches.
- Library/history and paginated rows remove duplicate URIs; playlist main rows open collections, separate Play controls play them.
- Native transport correctly reports ready when local playback events establish active ownership, even if the remote playback API is empty.
- Popup content loads asynchronously and waits for a sized, ready panel before reveal. Focus-grab cleanup during opening/switching no longer prematurely closes panels.
- Notifications allow safe bold/italic/underline, line breaks and entities, strip unsupported tags and active content. No inline remote HTML images/links. App icons, gentler 18px entry, animated dismiss and hover-paused lifetime.
- Fixed missing collection-title binding and rotation pause warning; Spotify allowed in generic dropdown IPC.

## Validation
Python syntax and modern/legacy item/dedup checks passed. API returned 50 distinct playlists, 50 playable items for a tested playlist, and 7 distinct recent tracks. Local playlist playback started, Next changed track with playback continuing; paused afterwards because playback was stopped before test. Phone is paired/reachable and retains live notifications after user network-change test. Main popup open/close checks: Phone, USB, Monitor, System, Sound, Calendar, Spotify. Phone tabs retain 457px height. Hyprland config errors blank.

## Remaining verification
Authenticated mobile-only phone features still need a sustained off-Wi-Fi test. Current paired socket is LAN after the user switched Wi-Fi back on. Tailscale itself and unpaired private KDE transport were previously verified over mobile data. Radio handoff cannot guarantee zero downtime; Android process/network availability is required. Termux SSH/Boot, Android sync device pairing and authorized ADB/scrcpy still require phone-side installation/permissions. No blanket claim that every Android feature is tested.

## References
https://developer.spotify.com/documentation/web-api/tutorials/february-2026-migration-guide
https://userbase.kde.org/KDEConnect/en
https://github.com/termux/termux-boot#usage
https://tailscale.com/docs/features/client/android-app-split-tunneling
https://support.google.com/work/android/answer/9213914
https://quickshell.org/docs/v0.1.0/types/Quickshell.Services.Notifications/Notification/

Final checks: no new QML warnings/errors after fixes. Closed shell consumed 3 CPU ticks over five seconds; phone push watcher zero. Volume controls accepted 66 then restored 65. Phone panel four exercised tabs remained 457px.
