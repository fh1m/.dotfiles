# Sensei: responsive desktop — 27 September 2026

## Your controls

- Name badge: left-click operator information; right-click XKCD.
- Clock: left-click calendar; right-click weather, directly beneath the clock.
- Spotify: circular album art rotates every 12 seconds while playing, freezes at its angle when paused; logo removed from the bar. Existing left-click music studio and right/middle play-pause remain.
- App shortcuts focus the most recent matching window across workspaces; launch only if absent. Add Shift for a new window. Kitty: Super+Enter / Alt+Enter / Super+Q. Chrome: Alt+W. Files: Alt+F. Calculator: Super+P / hardware Calculator key. Power menu: Super+Ctrl+P. Shell/hardware action shortcuts remain action shortcuts.

## Weather

Dhaka, Celsius, km/h, Asia/Dhaka by default. Set a city in the popup (Open-Meteo geocoding picks the first matching result). Preferences: ~/.config/sensei-weather.json. Cached responses: ~/.cache/sensei-weather.

Today includes current/feels-like temperature, rain, humidity, wind/gust/direction, pressure, cloud cover, UV, visibility, sunrise/sunset and available AQI/PM2.5/PM10. Hourly charts and rows, 16-day forecast, date-selectable history. Recent past is explicitly labelled archived forecast; older dates use historical model/reanalysis data. Modelled data is not a local weather-station measurement or an official severe-weather warning service. Current conditions refresh every 15 minutes; bulk forecast/air-quality hourly. Requests only occur at these intervals or on explicit refresh/city/history actions. Offline results retain their original timestamp and show an error/stale state.

## Responsiveness

Wi-Fi renders retained/cached access points immediately and scans independently. No scan clears the visible list. Scanning runs only while Wi-Fi is visible. Network speeds use a single persistent sampler reading complete /proc/net/dev snapshots each second with a monotonic clock. Physical uplinks are selected dynamically, avoiding VPN double counting; reset/reconnect starts a new baseline. Explicit byte-rate units and interface names appear in Network.

Theme editor/wallpaper pool UI is loaded on demand and released after closing. Its custom preview palette no longer overrides Qt's built-in palette property. GPU telemetry uses direct NVML reads instead of launching nvidia-smi repeatedly, retaining the runtime-suspended guard and real CUDA-process detection. Spotify volume is synchronized on shell startup and native volume changes, with optimistic slider updates preserved.

## Validation and audit

Python checks: cache hits, city persistence, offline fallback, recent/older history routing. Live current/forecast/historical APIs returned Dhaka data. Window tests verified focus versus new-window for all four apps, including Chrome on another workspace; test windows were closed and original focus restored. Loaded shortcut tuples have no duplicates.

Artwork pixels changed during playback and remained identical across paused captures; Spotify volume UI and backend agreed. Original playback/volume were restored. A temporary CUDA context appeared as a real compute process and was released. Tray fixture appeared and disappeared. Calendar, sound, comic, operator, monitor, clipboard and weather panels loaded on their intended displays. Calendar/weather sit beneath the clock (x420,y52 on the 1920-logical-width main display). GTK dark preference, fonts, active keyring, sound/portal/clipboard services and both 60 Hz displays were checked. No failed user/system services or Hyprland configuration errors. Screenshot PNG matched the clipboard; two recordings (one per display) decoded as H.264/AAC under Videos/Screencasts. Original clipboard restored. Isolated tmux checks passed, including no printed hex codes. Existing no-fade window/workspace animations preserved.

Raw measurements and widget geometry: ~/.local/state/hyprland-repair-20260926/responsive-weather-070413/audit.json and performance.json. CPU percentages refer to one core and are short samples, not an exhaustive frame-time benchmark. Initial samples immediately after shell restart include startup compilation and must not be treated as sustained idle load. Use the settled-idle-paused sample for idle.

Dedicated GPU runtime suspension was subsequently verified: /sys/bus/pci/devices/0000:01:00.0/power/runtime_status reports suspended, and the widget shows sleep with zero utilization and no active contexts. Both outputs/rendering remain on Intel. This does not establish that earlier descriptor findings alone caused the wake state. Memory includes shared graphics/font pages: the hidden Kitty portal's ~761 MiB RSS corresponds to ~189 MiB proportional memory. Cached memory is reclaimable and was not purged.

No package upgrades/removals or research-feature installs were performed. Full research list remains in UNIXPORN-IDEAS.md.

## Backup / rollback

Backup: ~/.local/state/hyprland-repair-20260926/responsive-weather-070413. It contains the previous .config/quickshell/wrayth, .config/hypr, desktop-shortcuts and robot-bench-data. Restore those config trees and robot-bench-data, then reload Hyprland and restart the Wrayth shell. The new helpers can remain unreferenced; do not delete personal weather/cache/clipboard data. Current session GPU fixes and monitor arrangement remain intact.
