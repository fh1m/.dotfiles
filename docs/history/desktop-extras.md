# Sensei desktop extras

Applied 27 September 2026. Backup: ~/.local/state/hyprland-repair-20260926/tray-packages-comic-063304/wrayth

- ScreenPad tray group appears only when SystemTray contains items. Native icons; left click activates, right click opens the app menu, middle click invokes secondary activation, scrolling is forwarded. Temporary test item verified appearance and disappearance.
- Identity robot scales gently while Spotify plays, returns to rest when paused. Actual rendered frames verified movement. Left click opens XKCD beneath the badge.
- XKCD latest, previous/next, random, keyboard arrows and swipe navigation. Images and JSON cached locally; title/date and caption/transcript use a compact text area. Official API: https://xkcd.com/json.html
- Top-bar network-speed block removed. System moved to the right of Sound. System → Network contains Wi-Fi list/radio/settings, live traffic rates, connection/profile tools, SSH connect/client/server config/start/stop/validation/reload, ping, firewall status/on/off/port rules, routes, DNS and listening sockets. Network scans operate only while its page is open.
- System → Packages uses pacman inventory, checkupdates and paru -Qua. Check only fetches metadata; buttons open reviewable transactions in Kitty. All/repository/AUR upgrades, selected upgrade, package details/install/removal, transaction log, orphan listing/removal, cache cleanup. Selected repository upgrades perform a full repository update; AUR targets can upgrade individually. No package transactions were executed by this task.
- Last successful check: 2136 installed, 2090 repository, 46 foreign/local; 445 repository and 15 AUR updates. Refresh with Check updates after transactions.
- Spotify popup has a darker translucent surface with existing compositor blur.

CLI helpers: ~/.local/bin/sensei-desktop-data, sensei-package-action, sensei-network-action. New services/processes are demand-driven; no permanent package/comic polling. Credentials are not embedded in these helpers.
