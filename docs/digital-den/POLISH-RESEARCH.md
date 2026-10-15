# Companion and daily-tools polish research — 2026-10-16

32 fresh targeted search queries in eight batches, followed by direct checks of the technical sources below. Search breadth is not a quality score. Not every returned project was installed or exhaustively audited. Reddit direct-page retrieval failed for two discussions; their indexed excerpts are anecdotal context only. Technical decisions rely on official documentation/source, not community popularity.

## Decisions reflected in code

| Question | Evidence | Choice and limit |
|---|---|---|
| Replace the renderer with a pet framework? | [wl_shimeji README](https://github.com/CluelessCatBurger/wl_shimeji) and [Hyprland clipping issue](https://github.com/CluelessCatBurger/wl_shimeji/issues/17) | Keep our existing independent Quickshell renderer. The project explicitly excludes official Hyprland support; its published resource figures are not our benchmark. No third-party mascot assets/code imported. |
| How can it avoid covering code? | [PanelWindow layers](https://quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/) and [HyprlandToplevel IPC freshness](https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/HyprlandToplevel/) | Bottom layer, geometry-safe corner candidates, refresh after window/workspace events plus a 15-second fallback. Hide when no space. Geometry selection is our engineering policy, tested separately. |
| How much animation? | [Qt performance](https://doc.qt.io/qt-6/qtquick-performance.html), [FrameAnimation](https://doc.qt.io/qt-6/qml-qtquick-frameanimation.html) | Property animation for short movement; slow sprite-frame changes only in bounded bursts. No 60 Hz JS timer, extra web runtime or shader. Our grid contains distinct poses, not interpolated video. |
| Can the learner opt out? | [W3C reduced motion guidance](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html) | Independent motion, chatter, quiet and visibility controls. This is an accessibility-inspired desktop policy, not a claim of WCAG certification. |
| What should it say? | [DesktopPet source/README](https://github.com/Imzl-zl/desktop-pet) compared with existing Den behavior | Keep local curated tips/context and truthful backup completion events. No XP for token spending, fake test success, productivity scoring or inferred mastery. No network/model calls. |
| How should terminal chrome look? | [tmux style/format reference](https://github.com/tmux/tmux/wiki/Getting-Started), [Alacritty configuration](https://alacritty.org/config-alacritty.html) | Less filled pink, host context and concise counts; retain font metrics and working navigation/clipboard bindings. Semantic ANSI success/error/type colours stay distinct. |
| Can shell polish stay cheap? | [zsh hook functions](https://zsh.sourceforge.io/Doc/Release/Functions.html#Hook-Functions) | Keep existing timing/hooks; SSH host context uses built-in variables. No new per-prompt external process, random startup message or animation. |
| Must every editor action animate? | [Neovim diagnostics](https://neovim.io/doc/user/diagnostic/), existing native configuration | Preserve quiet diagnostics and manual floats. Optional :DenTip only; wallpaper accent and ANSI output agree with the terminal. No new plugin. |
| What do practitioners dislike? | [Theming a command-line stack](https://www.reddit.com/r/unixporn/comments/x0ekjd), [matching terminal/editor themes](https://www.reddit.com/r/neovim/comments/1iozmfq) | Indexed reports favor consistency but are not consensus or causal evidence. Reuse existing palette generation instead of installing another theme manager. |

## Search ledger

### Batch 1

- `Qt Quick animation performance timers animations reduced motion`
- `Quickshell Hyprland toplevel windows positions PanelWindow input mask Region`
- `GitHub wl_shimeji Hyprland desktop mascot performance`
- `GitHub eSheep desktop pet Linux Wayland mascot`

### Batch 2

- `Qt Quick AnimatedSprite sprite sheet animation interpolation`
- `Qt Quick FrameAnimation Timer animation performance best practices`
- `Hyprland IPC activewindow cursorpos window events documentation`
- `Quickshell HyprlandToplevel geometry monitor workspace documentation`

### Batch 3

- `tmux manual status-style window-status current format pane border copy mode`
- `Alacritty configuration font offset glyph_offset line spacing colors documentation`
- `zsh prompt expansion prompt_subst RPROMPT preexec precmd docs`
- `Neovim colorscheme transparent background diagnostic virtual text winborder documentation`

### Batch 4

- `site:reddit.com/r/unixporn desktop pet widgets distraction terminal coherent theme`
- `site:reddit.com/r/hyprland desktop pets shimeji wayland`
- `site:news.ycombinator.com desktop pets animation distraction`
- `site:reddit.com/r/neovim diagnostic virtual text distraction colorscheme`

### Batch 5

- `WCAG animation from interactions prefers reduced motion five seconds pause`
- `Microsoft Clippy interruptions agent user attention research interface`
- `peripheral awareness displays animation distraction desktop research`
- `desktop pet window avoidance GitHub Wayland QML`

### Batch 6

- `GitHub AM desktop pet Linux QML companion assistant`
- `GitHub desktop-pet wayland tauri shimeji window collision`
- `Qt Quick Text wrap implicitWidth binding loop documentation`
- `Quickshell FileView watchChanges reload documentation`

### Batch 7

- `site:github.com/tmux/tmux/wiki Getting-Started mouse copy-mode status`
- `site:alacritty.org config live_config_reload selection save_to_clipboard`
- `site:neovim.io doc diagnostic float severity virtual_text`
- `site:zsh.sourceforge.io Doc Release Hook-Functions precmd preexec`

### Batch 8

- `site:github.com/kovidgoyal/kitty shell integration command duration semantic prompt`
- `site:github.com/folke/snacks.nvim animate performance dim notifier`
- `site:news.ycombinator.com terminal color theme readability contrast`
- `site:reddit.com/r/unixporn consistent theme colors terminal neovim tmux`


