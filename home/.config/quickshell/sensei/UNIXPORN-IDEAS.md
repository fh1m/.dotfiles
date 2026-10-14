# Sensei desktop: proposals only — 27 September 2026

No proposed packages, font settings, blur settings or replacement dotfiles were applied.
Reviewed recent Hyprland showcases and monthly/top examples. Reddit’s cached top index is not a reliable live ranking.

| Inspiration | Proposal for this ZenBook | Implementation candidate |
|---|---|---|
| [Yen Shell](https://www.reddit.com/r/unixporn/comments/1wni8gq/hyprland_yen_shell_quickshell_go/) | Swipe drawers on the ScreenPad; music/status expands only when useful | Existing Quickshell, touch gestures and event-driven models; retain current shell |
| [Aphotic Hypr](https://www.reddit.com/r/unixporn/comments/1w6t22x/hyprland_come_build_your_own_modular_environment/) | Project profiles: ROS, simulation, training; restore apps and workspace placement together | Small project launcher scripts + existing workspace manager |
| [Bruteon](https://www.reddit.com/r/unixporn/comments/1vmg29f/hyprland_for_the_neo_brutalism_lovers_3/) | Consistent card sizes, restrained offset shadows, clearer hierarchy in calendar and control widgets | Existing QML components; keep black/red/blue rather than its pastel palette |
| [Battery-aware setup](https://github.com/matteogini/dotfiles) | Optional battery-lite profile with fewer effects and slower invisible-widget sampling | Keep Quickshell; adapt profile scripts rather than replacing it with another bar |
| [Matugen](https://github.com/InioX/matugen) | Match neutral surfaces across GTK, Kitty and shell to wallpaper | Constrained templates; preserve blue/red accents and exclude cyan/purple |
| Personal robotics adaptation | On-demand ScreenPad telemetry and project controls: ROS topic rates, serial terminal, robot SSH, training logs | [PlotJuggler](https://plotjuggler.io/) + project scripts; no permanent extra monitoring daemon |

## Fonts: preview before changing
Keep Iosevka/Zed Mono and current comfortable text sizes. Compare QtRendering versus CurveRendering on installed Qt, static small text versus animated ticker text, consistent font weight and placement on device pixels. Keep grayscale antialiasing as the baseline; compare slight hinting versus no hinting on both displays. Do not apply a universal subpixel layout without checking the actual panels.
[Qt text rendering](https://doc.qt.io/qt-6/qml-qtquick-text.html)

## Blur: readability first
Prototype selective frost for bar, popups and transparent Kitty. Compare current size 6/passes 2 with size 8/passes 2; assess contrast against the real wallpaper and measure animation frame pacing on both displays. More passes are not automatically better. Keep content readable and avoid animated wallpaper running continuously on battery.
[Hyprland blur options](https://wiki.hypr.land/configuring/core/config-options/)

My recommendation: consistent typography/spacing first, selective blur second, then project profiles and on-demand ScreenPad telemetry. The best showcases have one coherent visual language, motion that explains state changes, and useful controls rather than duplicate widgets.


## Expanded research: 24 capabilities — suggestions only

Reviewed older highly rated posts, including [end-4, July 2025](https://www.reddit.com/r/unixporn/comments/1ls4xdv/hyprland_my_virginity_defense_ft_quickshell/) and [fluid setup, March 2026](https://www.reddit.com/r/unixporn/comments/1s84jik/hyprland_as_fluid_as_it_gets/), plus official docs and project sources. These are capabilities or adaptations, not claims that each project installs cleanly on this Hyprland release. No new research feature below was installed.

| Idea | Personal use | Primary reference |
|---|---|---|
| 1. Touchpad workspace gestures | Finger-following movement | [Hyprland](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/) |
| 2. ScreenPad touch gestures | Drawers, swipes, long-press actions; plugin compatibility required | [Hyprgrass](https://github.com/horriblename/hyprgrass) |
| 3. Tabbed window groups | Related terminal, reference and debug windows | [Dispatchers](https://wiki.hypr.land/configuring/core/dispatchers/) |
| 4. Project scratchpads | Summon ROS, SSH and experiment terminals | [Pyprland](https://github.com/hyprland-community/pyprland) |
| 5. Lost-window recovery | Restore offscreen dialogs after monitor changes | [Pyprland](https://github.com/hyprland-community/pyprland) |
| 6. Focused reading layout | Center one working window | [Pyprland](https://github.com/hyprland-community/pyprland) |
| 7. Alternative tiling layouts | Scrolling/manual layouts; verify release compatibility | [Catalogue](https://github.com/hyprland-community/awesome-hyprland) |
| 8. Project launch profiles | Custom adaptation: Code, simulator, terminals on named workspaces | [Dispatchers](https://wiki.hypr.land/configuring/core/dispatchers/) |
| 9. Direct shell shortcuts | Avoid qs client process launches on frequent actions | [GlobalShortcut](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/GlobalShortcut/) |
| 10. Reload state retention | Preserve UI tabs and expanded sections | [PersistentProperties](https://quickshell.org/docs/v0.3.0/types/Quickshell/PersistentProperties/) |
| 11. Engineering command palette | Files, apps, calculations, scripts | [Vicinae](https://docs.vicinae.com/) |
| 12. Unit-aware calculations | Custom adaptation for engineering quantities | [Launcher inspiration](https://github.com/AvengeMedia/DankMaterialShell) |
| 13. Screen translation | Technical documentation in unfamiliar languages | [Illogical Impulse](https://github.com/end-4/dots-hyprland) |
| 14. Local assistant drawer | Optional on-demand Ollama; substantial model resource cost | [Illogical Impulse](https://github.com/end-4/dots-hyprland) |
| 15. Screenshot annotation | Mark dimensions, wiring and errors | [Satty](https://github.com/Satty-org/Satty) |
| 16. Live drawing / whiteboard | Explain robot mechanisms above applications | [Wayscriber](https://github.com/devmobasa/wayscriber) |
| 17. Presentation spotlight / zoom | Highlight small diagram details | [Wayscriber](https://github.com/devmobasa/wayscriber) |
| 18. Recording-only input HUD | Show shortcuts during tutorials | [Wayscriber](https://github.com/devmobasa/wayscriber) |
| 19. ROS telemetry on ScreenPad | Custom adaptation: topic plots below coding/simulation | [PlotJuggler bridge](https://github.com/PlotJuggler/plotjuggler_bridge) |
| 20. Robot camera / TF workspace | Dedicated live debugging arrangement | [Foxglove](https://docs.foxglove.dev/docs/getting-started/frameworks/ros2) |
| 21. Training-job drawer | Custom adaptation: logs, checkpoints, elapsed time | [Backend candidate](https://github.com/AvengeMedia/dgop) |
| 22. Consolidated monitoring backend | Evaluate replacing many separate probes | [dgop](https://github.com/AvengeMedia/dgop) |
| 23. Actual audio-level indication | Peak data rather than playing flags alone | [PipeWire integration](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Pipewire/Pipewire/) |
| 24. Optional night warmth | Manual override for color-sensitive engineering work | [Hyprsunset](https://github.com/hyprwm/hyprsunset) |

Best fit: project profiles, ScreenPad ROS telemetry, engineering scratchpads, screenshot annotation and command palette. Favor on-demand integrations over permanent daemons.
