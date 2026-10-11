# Rendering tuning — 27 September 2026

Applied higher-quality Qt distance-field text (quality 104) to bar labels and animated tickers. Existing families, text sizes and monitor scales retained. Fontconfig antialiasing remains grayscale with slight hinting; embedded bitmap glyphs disabled in favour of scalable outlines.

Hyprland blur changed from size 6 / passes 2 to size 8 / passes 2, with existing optimization rules retained. Animation curves now start gently; open/close scale excursions are smaller (96% / 97%), workspace transitions 380 ms with 14% travel. Window/fade duration matching retained.

Hyprland --verify-config passed; runtime configerrors empty. Calendar, sound and system panels opened successfully. Screenshots inspected on both monitors: 60 Hz main, 60.017 Hz ScreenPad. Short before/after compositor CPU samples both 2.5% of one core. Nvidia runtime status remained suspended. These checks do not constitute an exhaustive frame-time benchmark or guarantee zero dropped frames under every workload.

Backup: /home/fh1m/.local/state/hyprland-repair-20260926/smooth-render-055954

Already-open GTK applications may require restarting to pick up fontconfig changes. Quickshell restarted successfully to refresh its font and reload caches.

Follow-up: removed the focus pulse overlay; regular workspaces use slide with no crossfade (340 ms). Disabled fadeSwitch, fadeIn and fadeOut to avoid application-wide brightness pulses. Window entry uses popin 94% (300 ms); exit uses popin (240 ms). Local widget reveals remain separate.
