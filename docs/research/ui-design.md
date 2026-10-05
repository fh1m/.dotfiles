# UI research ledger

Forty focused searches were run on 2026-10-05 across ten source groups. This is a decision record, not a recipe to clone another desktop.

| Searches | Focus | Decision |
| --- | --- | --- |
| 1–4 | Material color, type, buttons, navigation | Use semantic surface roles and limited accent emphasis. |
| 5–8 | Android Material 3 color containers, expressive controls, type and navigation | Use a stable type scale; selected controls differ from ordinary actions. |
| 9–12 | Fluent color, typography, motion and shapes | Prefer subtle controls when many actions share a panel. |
| 13–16 | Apple typography, color, toolbar and motion | Keep toolbar groups legible; feedback stays brief. |
| 17–20 | Carbon dark color, type, button and tab guidance | Tabs represent views, not destructive actions; labels must fit. |
| 21–24 | Atlassian dark colors, typography, buttons and tabs | Use neutral selected surfaces when saturated ones become noisy. |
| 25–28 | GNOME and KDE controls, view switching and Kirigami | Preserve familiar desktop actions and keyboard access. |
| 29–32 | Qt Quick shapes, text, controls and animation | Animate color/transform, not shape geometry; keep QML work off each frame. |
| 33–36 | Quickshell loaders, panels, persistence and Hyprland workspaces | Lazy-load heavy panels; keep focus and popup geometry stable. |
| 37–40 | end-4, Caelestia, Noctalia and illogical-impulse shell repositories | Borrow integration patterns, not their visual palette. |

## Strongest primary references

- [Material 3 color roles](https://developer.android.com/reference/kotlin/androidx/compose/material3/ColorScheme): surface-container levels allow hierarchy without painting each button the accent.
- [Material Web buttons](https://github.com/material-components/material-web/blob/main/docs/components/button.md): filled, tonal, outlined and text actions carry different emphasis.
- [Fluent button guidance](https://fluent2.microsoft.design/components/web/react/core/button/usage): many minor actions should be subtle; text and icon contrast must remain clear.
- [Fluent tabs](https://fluent2.microsoft.design/components/web/react/core/tablist/usage): short parallel labels, one format, and no clipped tabs.
- [Fluent typography](https://fluent2.microsoft.design/typography) and [layout](https://fluent2.microsoft.design/layout): role-based sizes and deliberate spacing are more useful than letter spacing everywhere.
- [Fluent shapes](https://fluent2.microsoft.design/shapes): related controls in one container should not have awkward gaps between their corners.
- [Apple buttons](https://developer.apple.com/design/human-interface-guidelines/buttons) and [toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars): group related controls and keep symbol-plus-label actions distinct.
- [Apple dark mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode) and [motion](https://developer.apple.com/design/human-interface-guidelines/motion): secondary labels need distinct contrast; feedback should be brief.
- [Carbon tabs](https://www.carbondesignsystem.com/building-blocks/core/components/tabs/guidelines): tabs group related views and should respond without waiting on unrelated data.
- [Qt Quick performance](https://doc.qt.io/qt-6/qtquick-performance.html) and [Shape](https://doc.qt.io/qt-6/qtquick-shapes-qmlmodule.html): changing Shape paths can retriangulate on the CPU; avoid heavy per-frame script work.
- [Qt Quick Controls customization](https://doc.qt.io/qt-6/qtquickcontrols-customize.html): style a shared control instead of duplicating visuals in each widget.
- [Matugen](https://github.com/InioX/matugen): image-derived color is an input, not a mandate to tint every surface.

## Findings from the rendered workstation

The first blue/cyan companion clashed with the hot-pink main wallpaper; the later yellow companion was worse. The neutral-plus-rose version restores the wallpaper as the dominant chromatic field. A row of individually filled and bordered controls looked segmented; separated quiet cards are easier to scan than either that rail or free-floating text. ZedMono's fixed cell pitch made button prose look over-spaced, so headings and actions use Manrope while machine values retain ZedMono. The System page was rebuilt as grouped Connections, Levels, Power and Workspace cards; all five tabs have measured widths and fit their labels. Clipboard and Monitor now use the same quieter card surface. The tmux status line uses the same accent for active work, neutral inactive windows, and no continuous status command pipeline.
