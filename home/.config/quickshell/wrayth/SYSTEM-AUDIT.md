# Sensei daily-driver audit — 27 September 2026

## Changes applied

- CPU/RAM/GPU graph cards, network graph cards and CPU thread tiles now have stable numeric repeater models. History updates change their properties without recreating widgets every 500 ms.
- Process rows are updated in a persistent PID-based ListModel, moved when rankings change, and updated only on the Processes page. Graph network ceilings use powers of two rather than continuously changing arbitrary scales.
- Dropdown titles are bold and at least 13 logical pixels. Header height is 44 pixels with a separate 11-pixel Sensei subtitle at y29. Monitor/clipboard content heights compensate so they still fit ScreenPad.
- Album artwork retains its previous image while loading (Qt retainWhileLoading), and the helper publishes downloads atomically. Song/collection metadata selects the largest returned image.
- Spotify queue fetches have their own process so library requests cannot block the queue. Identical queue responses do not reset the list. Old context responses cannot reopen an abandoned collection. Library results are retained separately by kind so delayed albums/liked responses cannot replace the wrong tab.
- Volume feedback polls cached local state at 300 ms only while an action is pending; no permanent additional timer. Rapid slider changes are coalesced, with optimistic UI retained until confirmed.
- Ctrl+Left previous song, Ctrl+Right next song, Ctrl+Up +5% Spotify volume, Ctrl+Down −5%; Ctrl+Space remains play/pause. These are global and take precedence over application Ctrl+arrow actions. Loaded bindings have no duplicate tuples.
- plocate file indexing excludes /home/fh1m/.cache and /home/fh1m/.local/share/Trash. These directories occupy approximately 65 GiB and 78 GiB respectively. Nothing was deleted. Existing idle I/O/Nice19 scheduling remains.

## Boot findings

The recorded boot is 27.600 seconds: firmware 6.377, GRUB loader 7.149, kernel 0.923, initrd 2.648, userspace 10.500. This boot originally entered GNOME; it is not a measured fresh boot of the final Hyprland configuration. Next-login AccountsService Session=hyprland-intel and GDM autologin are configured.

GRUB already has timeout=0 in both defaults and generated configuration, so there is no menu countdown to remove. Loader time cannot be assumed to be a seven-second timeout. No speculative video-mode/firmware changes were made.

NetworkManager-wait-online accounts for 5.504 seconds before network-online. Docker, NoMachine and the two reCamera services depend on it. The running auv-ros2 container was preserved. GDM starts at userspace ~3.95 seconds and does not wait for network-online, so removing that wait would not necessarily speed access to the desktop. Network logs show initial wireless scan/association and DHCP rather than a 60-second timeout. plocate's 46.7-second initial scan runs in parallel and was not on the graphical target critical path; cache/Trash exclusions reduce future needless indexing.

There are no failed system or user units and no current Hyprland config errors. Existing boot history contains earlier GNOME/Hyprland crashes, an OpenCV Qt Python crash, unsupported Wi-Fi multicast registration messages and Nvidia driver thermal-limit/lock assertions. These are not all errors in the current shell. The Nvidia assertions are a remaining driver-level finding: no unverified driver swap, kernel removal or module unload was applied to a working dual-display/CUDA system. Cold boot, suspend/resume and driver assertions require follow-up observations in a new session; this audit cannot promise they are eliminated.

## Validation

Both displays retain the correct 4K modes, scale2 and vertical placement, at 60 Hz. Monitor geometry x12,y1087,1040×491 and clipboard x12,y1081,1040×497 remain within ScreenPad. Calendar is beneath the clock x420,y52,1080×862. Other widgets, dark GTK, fonts, brightness, keyring service, screenshot/recording paths, power/idle configuration and tray behavior passed the live audit.

An 18-frame targeted capture found no blank CPU graph frames across sampling updates after the repeater fix. This is a targeted flicker check, not exhaustive animation benchmarking.

Natural Spotify song completion advanced to another song while playing. A burst of slider requests settled at the last requested volume; +5/−5 controls agreed with backend state. Original paused song, progress and volume were restored. Cached playlists/liked songs returned in about 80 ms; albums/artists requests ~0.55 s in this sample. Library pagination and remote network latency remain real constraints, not instant full-account loading.

Dedicated Nvidia GPU reports runtime suspended with zero active contexts when idle. A short settled sample measured shell ~2.4% and Hyprland ~2.6% of one CPU core, Spotify 0%; the monitor overview shell sample was ~5% after graph stabilization versus ~8.4% in the earlier sample. These are short comparable observations, not a guaranteed performance bound or a full frame-time benchmark. CPU temperature varied 76–83°C with the existing quiet fan mode2 and running robotics work; thermal/profile choices were preserved.

Backup: ~/.local/state/hyprland-repair-20260926/final-audit-073142 (shell, Hyprland, Spotify helper and old updatedb.conf). Previous approved-plan backup: responsive-weather-070413. Raw live audit/performance records remain there. Restore /etc/updatedb.conf from the new backup to undo the indexing exclusion.

## References

Qt image retention: https://doc.qt.io/qt-6/qml-qtquick-image.html
Network startup dependencies: https://networkmanager.pages.freedesktop.org/NetworkManager/NetworkManager/NetworkManager-wait-online.service.html
Ideas researched but not installed: UNIXPORN-IDEAS.md (24 suggestions).
