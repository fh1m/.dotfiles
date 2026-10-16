# Music / desktop UX research · 2026-10-16

25 targeted searches, then source inspection. Search results are discovery, not
proof. Official documents/code below inform implementation; community objections
are usability anecdotes, not a consensus. No new desktop framework is installed.

## Evidence → decisions

| Source | Finding / boundary | Consequence |
| --- | --- | --- |
| [GNOME media-key implementation](https://gnome.pages.gitlab.gnome.org/gnome-settings-daemon/plugins/media-keys/gsd-media-keys-manager.c.gcov.html) | Calls libcanberra with `audio-volume-change`. This is published code with a 2024 coverage snapshot, not a benchmark of current GNOME. | Reuse themed event audio, avoid synthesized alarms/custom daemon. |
| [KDE Ocean sound theme](https://github.com/KDE/ocean-sound-theme/blob/master/README.md) | Defines audio-volume-change as level feedback. | Standard theme event; no new audio asset required. |
| [GNOME sound controls](https://help.gnome.org/gnome-help/sound-volume.html) | Wheel adjustments and per-application volumes are established desktop affordances. | Preserve our existing mixer/wheel behavior. Feedback concerns default output only. |
| [Sound theme specification](https://specifications.freedesktop.org/sound-theme/latest-single/) | Themed sounds allow desktop consistency/fallback. | Depend on installed freedesktop theme and libcanberra in package manifest. |
| [GNOME keyboard HIG](https://developer.gnome.org/hig/guidelines/keyboard.html) and [accessibility](https://developer.gnome.org/hig/guidelines/accessibility.html) | Pointer-only actions exclude keyboard navigation. | Maximize is a focusable named button; fullscreen has escape and tab operation. |
| [GNOME terminal fullscreen](https://teams.pages.gitlab.gnome.org/Websites/help.gnome.org/gnome-terminal/app-fullscreen.html) | F11 is a familiar fullscreen toggle. | F11/Escape restore, explicit × closes. |
| [KDE virtual desktops](https://docs.kde.org/stable_kf6/en/kwin/kcontrol/desktop/index.html) | Pager is an interaction surface, including wheel switching. | Adopt contextual overview and occupancy; defer wheel switching to prevent accidents. |
| [KDE layout/navigation](https://develop.kde.org/hig/layout_and_nav/) and [input](https://develop.kde.org/hig/getting_input/) | Contextual tools and standard bounded controls. | Three stable areas; queue/playlists share a contextual pane. |
| [Quickshell PanelWindow](https://quickshell.org/docs/types/Quickshell/PanelWindow) | Opposite anchors fill a screen; layer and keyboard policy are explicit. | Monitor-bound overlay with no reserved space; normal shell closes it when switching UI. |
| [Qt Image](https://doc.qt.io/qt-6/qml-qtquick-image.html) | Bound image decode sizes and asynchronous loading reduce image cost. | Artwork bounded to 800px; tiny palette sample; no per-frame image processing. |
| [MPRIS Player](https://specifications.freedesktop.org/mpris/latest/Player_Interface.html) | Transport and seek capability are device-dependent. | Reuse single-shot existing control backend; gate fullscreen seek on capability. |
| [Spicetify Platform](https://spicetify.app/docs/development/api-wrapper/methods/platform) | Native platform exposes catalogue/player interfaces but remains coupled to client implementation. | Preserve repaired bridge, document version-break risk; no parallel Web API fetches. |
| [Spotify rate limits](https://developer.spotify.com/documentation/web-api/concepts/rate-limits) | 429 requires respecting Retry-After; more UI cannot fix upstream quotas. | Shared caches/bounded requests; do not resurrect quota-limited native catalogue. |
| [GNOME notifications](https://help.gnome.org/gnome-help/shell-notifications.html) | DND is a system-wide intent. | Respect existing Quiet mode for added sound. |
| [Hyprland dispatchers](https://wiki.hypr.land/configuring/core/dispatchers/) | Dispatchers and Lua signatures are version-sensitive. | Reuse existing WindowDesk overview instead of inventing focus/move shell commands. |

Practitioner counterexamples discovered: [volume feedback opt-out](https://www.reddit.com/r/kde/comments/y0n4dm/how_to_turn_off_volume_adjust_sound/),
[accidental pager scrolling](https://www.reddit.com/r/kde/comments/teakra/can_the_mouse_wheel_action_be_disabled_over_desktop/).
These motivate an explicit sound toggle and deferring wheel switching. Technical
claims above rely on primary sources, not Reddit. Some search queries returned
irrelevant material; those did not become architecture decisions.

## Exact search ledger

1. `site.help.gnome.org sound volume feedback sound`
2. `site.docs.kde.org plasma volume feedback sound`
3. `site.specifications.freedesktop.org sound naming audio-volume-change`
4. `site.github.com GNOME gnome-shell volume sound canberra`
5. `site.doc.qt.io QtQuick fullscreen Window screen visibility`
6. `site.quickshell.org PanelWindow screen anchors keyboardFocus`
7. `site.github.com/GNOME/gnome-settings-daemon audio-volume-change`
8. `site.github.com/KDE/plasma-pa feedback volume`
9. `site.developers.google.com web fundamentals media session interruption`
10. `site.spicetify.app docs Platform PlayerAPI getQueue`
11. `site.specifications.freedesktop.org mpris spec Player CanSeek`
12. `site.doc.qt.io qml QtQuick Image asynchronous sourceSize`
13. `site.help.gnome.org keyboard navigation workspaces overview`
14. `site.docs.kde.org virtual desktop pager mouse wheel`
15. `site.develop.kde.org human interface guidelines animation duration`
16. `site.developer.gnome.org hig keyboard accessibility fullscreen`
17. `site.help.gnome.org shell notifications do not disturb`
18. `site.doc.qt.io QtQuick Image color palette grabToImage`
19. `site.lrclib.net docs API synced lyrics instrumental`
20. `site.developer.spotify.com documentation web-api rate limits retry after`
21. `site.help.gnome.org displays night light`
22. `site.docs.kde.org plasma clipboard history klipper`
23. `Hyprland Lua hl.dsp send_key key state`
24. `site.quickshell.org docs ImageAverageColor`
25. `site.help.gnome.org shell keyboard shortcuts F11 fullscreen`

No new lyrics provider or DE replacement was justified. The most useful work was
correcting existing state/imagery behavior and giving existing music controls a
comfortable simultaneous presentation.
