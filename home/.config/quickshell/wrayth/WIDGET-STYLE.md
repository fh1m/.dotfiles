# Sensei — OLED widgets

Main wallpaper: ~/Pictures/wals/wallhaven-w5q8px.jpg. Sampled dominant coral #ff2d50; softened readable UI accent #ff718a. Widget labels #f5ecef; secondary #b3a4aa; faint #897b81. Panels use opaque OLED black; nested surfaces use two dark blue-black steps and warm neutral outlines. Selected/pressed states use subtle primary-accent tints.

All dropdowns use the widget tokens in config/Theme.qml. Original comic and album artwork keep their own colors. Compositor blur and shadows, including special workspaces and Quickshell wallpaper blur, are off in the performance profile. Kitty and both bars are opaque; the Intel display configuration is unchanged.

Fresh opens map a lightweight panel first, then reveal their content when ready. Opening 220ms OutCubic, closing 170ms InCubic; replacement panels settle their new geometry before entry. Main-display panels rise12px, ScreenPad panels move from their bottom-bar edge. Compositor shadows are disabled. No animation loop runs for static buttons.

Level controls now have a 42px rotary dial with a 2px progress ring and a thin fine-adjustment rail, plus keyboard/wheel support. Controls share 7px corners, 22px icon badges, mixed-case labels, clearer type weight, hover/press/focus feedback, and a selected-tab marker. Relevant System actions have short explanatory captions. Space/Enter and keyboard focus are handled by shared buttons; fields support selection and a restrained focus outline. Fields, multiline notes, combos and scrollbars share the palette. Spotify mini buttons share the same press feedback, and the current track has a visible selection treatment. Calendar days have hover feedback; key page sections ease in when selected.

A later content audit caught and fixed section animations targeting the parent instead of their own page. Actual visible text/data is now checked across all 30 monitor/System/audio/calendar/Spotify pages, rather than treating a clean log as sufficient. Opening captures showed intermediate states before full visibility; closing reached zero and unmapped the popup. A read-only popupmotion-<output> IPC diagnostic exposes actual reveal/state. Monitor1040×491 and clipboard1040×497 still fit ScreenPad. Main panel surfaces include6px shadow gutters; calendar content stays centered beneath its clock even when opened by IPC. Spotify transport now has its own command queue so online library operations cannot block playback controls. Next/previous explicitly preserve playing/paused intent. Forward/back checks retained playback across 50 samples; rapid volume changes were verified and the original volume/song restored. Spotify metadata still depends on the daemon and service response time.

Backups: ~/.local/state/hyprland-repair-20260926/widget-polish-123317 (before motion/control changes), and oled-glass-124344 (before wallpaper palette/glass changes). Each contains wrayth and Hyprland config trees.

Animation/performance references: https://doc.qt.io/qt-6/qtquick-statesanimations-animations.html and https://doc.qt.io/qt-6/qtquick-performance.html . Live image captures are targeted checks, not a guarantee of every frame at60fps.

Regression backup: ~/.local/state/hyprland-repair-20260926/widget-bugfix-125428. USB/Nvidia outlines match workspace #26282d. Visible-panel audit details: /tmp/sensei-visible-panels.json.
