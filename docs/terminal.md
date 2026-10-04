# Terminal // less render work, same control

[← Workstation](../README.md)

**Daily:** Alacritty 0.17 + tmux 3.7c. **Special deck:** Kitty. The deck needs Kitty's remote-control socket, image protocol and custom tab bar; replacing that one window would break the control surface. The old Kitty configuration is preserved in `backups/kitty/kitty.conf.20261004`.

| Same feel | Implementation |
|---|---|
| ZedMono Nerd Font Mono, 11.5 pt; black/red/blue palette | `~/.config/alacritty/alacritty.toml` |
| Independent terminal tabs and panes | tmux windows/panes; `BAY-NN` clients share the persistent `Sensei` window set |
| Closing a terminal preserves work | systemd supervises the tmux server; detached windows remain in `Sensei` |
| Fast image preview | `chafa image.png`; character-cell image, less fidelity than Kitty graphics |
| URL detection / navigation | Alacritty URL hints (`Ctrl+Shift+O`), Vi mode (`Ctrl+Shift+Space`) |
| Clipboard | Alacritty OSC 52 + tmux `set-clipboard external` + tmux-yank / `wl-copy` |

**No native tabs, splits, remote control, graphics protocol or Kitty kitten overlays exist in Alacritty.** tmux covers tabs/splits/session recovery; Chafa covers inline image inspection. The deck stays on Kitty for the remaining features. Alacritty's native Wayland/OpenGL path was measured on this laptop, not assumed faster everywhere. [Alacritty manual](https://alacritty.org/config-alacritty.html) · [tmux FAQ](https://github.com/tmux/tmux/wiki/FAQ) · [Kitty remote control](https://sw.kovidgoyal.net/kitty/remote-control/) · [Chafa](https://hpjansson.org/chafa/).

Graphics forks exist: [ayosec/alacritty](https://github.com/ayosec/alacritty) adds Sixel and iTerm2 protocols; [microo8/alacritty-sixel](https://github.com/microo8/alacritty-sixel) adds Sixel. Neither supplies the deck's Kitty remote-control API. They have not had the same GPU/load test on this laptop, so the measured upstream Alacritty build remains the daily choice. For full-resolution images, open the file in an image viewer or the preserved Kitty deck; `chafa` is the quick terminal preview.

## Keys

| Key | Action |
|---|---|
| `Super+Return`, `Alt+Return`, `Super+Q` | Focus existing Alacritty, or launch one; Super+Return while it is focused opens another BAY |
| `Super+Shift+Return` | Force a new Alacritty window |
| `Super+'`, `Ctrl+Shift+Return` | New tmux window (Kitty-style tab) |
| `Super+[ / ]` | Previous / next tmux window |
| `Ctrl+Shift+N` | New OS window |
| `Ctrl+Shift+L` | Next tmux pane layout |
| `Ctrl+Shift+M` | Zoom current tmux pane |
| `Ctrl+Shift+E` | Window picker |
| `Ctrl+Shift+Up` | tmux copy mode; scroll history even in a TUI |
| `` ` + | `` / `` ` + - `` | Horizontal / vertical split |
| `` ` + s `` | Session picker |
| `` ` + g `` | Fuzzy project picker; open a new tmux window in the chosen project |
| `` ` + S `` | Synchronize typing across panes in the current window; status shows SYNC |
| `` ` + Ctrl+s `` / `` ` + Ctrl+r `` | Save / restore layouts with tmux-resurrect |
| `` ` + r `` | Reload tmux configuration |

The tmux prefix is the backtick (`` ` ``). The six retained plugins each have one job: TPM loads them; copycat searches; yank copies; tmux-fzf picks windows/sessions; resurrect saves layouts; Mighty Scroll handles the mouse wheel. The overlapping mouse and session plugins were removed from the active configuration, but their installed files were left alone. The mouse wheel uses tmux history in Codex/Claude; `Ctrl+Shift+Up` is the predictable fallback. Scrollback is 50,000 lines. `TERM=alacritty` outside, `TERM=tmux-256color` inside, with RGB and OSC 52 advertised. [tmux clipboard guide](https://github.com/tmux/tmux/wiki/Clipboard) · [Mighty Scroll behavior](https://github.com/noscript/tmux-mighty-scroll).

The base session starts at login. The user service runs tmux in the foreground with restart supervision, so a successful one-shot startup cannot hide a vanished server. Each daily window gets its own `BAY-NN` view so switching windows in one terminal does not move another. On close, that view disappears; the window and its processes remain in `Sensei`. Use `` ` + s `` to revisit them. A reboot cannot keep live processes; resurrect saves layouts and supported commands on demand.

The statusline is one continuous dark rail: an operator block, linked BAY, active window in muted red, quiet inactive windows, a thin neutral separator, and the current path. Prefix, copy, zoom, and synchronized panes appear only when active. It uses ZedMono Nerd Font Mono's regular/bold faces with Alacritty's native box drawing; no underline or pointy Powerline separators.

Task windows opened by widgets use Alacritty **without attaching to the daily tmux session**, so a package or Bluetooth command cannot take over your workbench. `sim-console` explicitly offloads its terminal to NVIDIA when training mode is off; the ordinary terminal stays on Intel. A scratch Alacritty run reported RTX 2060 OpenGL 3.3 successfully. The `.desktop` entry and `xdg-terminals.list` select the same launcher.

## Local A/B, October 2026

Same animated text, main display, empty workspace, 35-second runs; `intel_gpu_top` measured approximate Render/3D engine shares:

| Terminal | Intel total | Terminal share | Hyprland share |
|---|---:|---:|---:|
| Kitty on Intel | 75.9% | 22.6% | 49.2% |
| Alacritty on Intel | 60.2% | 6.6% | 45.9% |
| Kitty PRIME-offloaded to RTX 2060 | 55.2% | 0% Intel / ~23% RTX | 50.7% |

Alacritty saved about **16 percentage points of Intel render activity versus Kitty** in this controlled terminal workload. The compositor still used about 46%; moving the terminal does not fix every frame wait. NVIDIA Kitty cost roughly 6.3 W during that run versus about 4.4 W RTX idle. These are one-device measurements, not a general terminal ranking.
