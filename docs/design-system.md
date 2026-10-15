# Sensei interface

> **Current rule (2026-10-14).** The main wallpaper is the visual guide. `sensei-palette` derives the accent, surfaces and text from the image, and it writes the shell, terminal, tmux, fzf, GTK, Qt and Hyprland border colours. The Quickshell core tokens in `config/Theme.qml` read the same palette. The Signal Ledger values are only the fallback when the image has no usable colour. Amber stays fixed as the caution colour. The type and motion notes below still hold.

The wallpaper provides the color. The shell provides the instrument panel.

JetBrains Mono keeps labels, glyphs and terminal metrics coherent. Icons lead each action; smaller labels say what it does.

![Live System panel with the new cards and JetBrains Mono labels](assets/ui-system-rehaul.png)

![Main display bar](assets/bar-main-rehaul.png)

![ScreenPad bar](assets/bar-screenpad-rehaul.png)

## Color roles

`sensei-palette` derives the palette from the main display image (`palette_from_image` in `home/.local/bin/sensei-palette`). The primary colour is the image's dominant hue and is the one chromatic accent for selection and focus. Companion colours (`secondary`, `tertiary`) are also taken from the image, not invented. Backgrounds are very dark tints of the image's hue (lightness about 3.5%), so panels stay near-black whatever the wallpaper.

The values below are the live palette on 2026-10-14 (`~/.config/sensei/wallpaper-palette.json`, wallpaper `wallhaven-1q2p3v.png`). They change with the wallpaper; read the file, not this table.

| Role | Live value (2026-10-14) | Use |
| --- | --- | --- |
| Ground | `#0b0709` | Widget canvas, bars, GTK/Qt windows, terminals |
| Surface | `#140d10` | Quiet controls and cards |
| Raised | `#1f1419` | Hover and active subpanels |
| Text | `#ede8ea` | Titles and essential data |
| Muted | `#afa1a8` | Secondary readings |
| Accent (primary) | `#f91b84` | Selection, focus, active work and small indicators |
| Outline | `#3f3138` | Structural edges; never a grid around every action |

The visual weight order is **one emphasized action → selected state → ordinary action → passive reading**. Multiple toggles on one page do not all become large saturated tiles. A selected control gets a narrow rose marker and a small tonal lift; danger uses its own red role. Icons and words agree about state.

## Type and geometry

JetBrainsMono Nerd Font Propo is for headings, buttons, descriptions and form labels. JetBrainsMono Nerd Font Mono is for time, percentages, paths, telemetry, terminal and code. UI labels use sentence case and no added tracking. Russian microcopy is an accent, never the only label. Controls use a 4–5 px cut corner; panels use a 16 px cut. Bar actions use near-black cards that blend with the rail; the workspace names retain their lighter treatment. The music card keeps its slanted edge, and the clock sits directly on the black rail. Native Hyprland group bars use quiet black tabs, titles and a small active marker. A button has a minimum 34 px visual height in bars; widgets use larger targets where the layout permits.

## Motion and responsiveness

Press feedback begins immediately (60–70 ms); hover/selection settles within 130–150 ms. Dropdown geometry stays fixed during reveal; content fades and moves inside the surface. Repainting a Qt `Shape` path or running JavaScript on every animation frame is avoided. Heavy widget content is loaded on demand, with a visible loading state. Project discovery runs only when opened; wallpaper color extraction runs only when the main image changes.

## Surface map

`Theme.qml` owns the live tokens. `WidgetSection.qml`, `ControlTile.qml`, `DropdownFrame.qml` and `BarSurface.qml` own the recurring shapes and states. `sensei-palette` writes the terminal, tmux, GTK, Qt and shell-prompt counterparts.

Sources and the 40-query research log: [UI research](research/ui-design.md).
