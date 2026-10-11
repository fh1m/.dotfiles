# Terminal // less render work, same control

[← Workstation](../README.md)

**Daily and deck:** upstream Alacritty 0.17 + tmux. Iosevka Nerd Font Mono, 11.8 pt, a small amount of extra cell spacing, warm text and hot-pink states.

Each new terminal owns an independent `dev_001`, `dev_002`, … tmux session. Focusing an existing terminal preserves its session. Closing a terminal detaches its client; explicitly closing a pane/window asks for confirmation.

Alacritty does not have native tabs. `Super+'` creates a **tmux window**; its bottom status line is the authoritative tab selector. Hyprland's window groups combine separate application windows. A duplicate top strip was tried and removed at the user's request.

## Native-tab fork evaluation · 2026-10-11

[Unbroken's fork](https://github.com/Unbroken/alacritty), tag `v0.17.0-unbroken-alpha5`, commit `93c9562654cc9e4206131334db2e32508c85ce3d`, built and ran in an isolated checkout. The published lockfile failed `cargo build --locked`; the disposable checkout needed lockfile regeneration.

The two-tab Wayland fixture showed a gray bar and blue active underline despite pink/black `tabs.indicator` settings. Source inspection confirmed hard-coded renderer colors and single-tab hiding. More seriously, terminating the inactive fixture's Bash process also terminated the active fixture's Zsh process. `event.rs` handles a child exit by closing the active tab, ignoring the exit event's tab identity. Only test shells were affected. The fork is **not installed as the default**.

The older [bebrws fork](https://github.com/bebrws/alacritty-tabs) last pushed source in August 2024 at audit time; it was not built. These are candidate-specific findings, not a verdict on every Alacritty fork.

Upstream's supported architecture is [external multiplexing](https://github.com/alacritty/alacritty#faq). Features used here include live configuration reload, native Wayland, keyboard URL hints, Vi mode, OSC 52 clipboard, explicit TUI-safe history keys, tmux recovery and fuzzy project navigation. Graphics previews use [Chafa](https://hpjansson.org/chafa/); full images open in a dedicated viewer.

## Keys

| Key | Action |
|---|---|
| `Super+Return`, `Alt+Return`, `Super+Q` | Focus existing Alacritty, or launch one; only Shift forces a new window |
| `Super+Shift+Return` | Force a new Alacritty window |
| `Super+'`, `Ctrl+Shift+Return` | New tmux window |
| `Super+[ / ]` | Previous / next tmux window (also `Ctrl+Alt+Left/Right`) |
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

The user service supervises the tmux server. Every new terminal gets independent windows and panes; no existing session is renamed. Use `` ` + s `` to revisit a detached session. A reboot cannot preserve live processes; tmux-resurrect preserves layouts and supported commands.

The bottom rail uses dark number/label tiles and pink active values, with space above it. Its two-row setting matters: row zero is breathing room, row one is the status line. Mouse wheel bindings use tmux commands directly in both copy-mode tables, preventing plugin overrides from swallowing wheel-down. Releasing a selection copies through `wl-copy` and exits copy mode. Shift+wheel-up and `Ctrl+Shift+Up` enter history when an agent captures ordinary scrolling.

No terminal is restarted to apply fonts or theme changes. The deck now launches Alacritty, and refresh does not inject commands into a shell. An already running legacy terminal was moved aside locally to preserve its shell; it is not launched by the updated configuration.

## Local A/B, October 2026

Same animated text, main display, empty workspace, 35-second runs; `intel_gpu_top` measured approximate Render/3D engine shares:

| Terminal | Intel total | Terminal share | Hyprland share |
|---|---:|---:|---:|
| Kitty on Intel | 75.9% | 22.6% | 49.2% |
| Alacritty on Intel | 60.2% | 6.6% | 45.9% |
| Kitty PRIME-offloaded to RTX 2060 | 55.2% | 0% Intel / ~23% RTX | 50.7% |

Alacritty saved about **16 percentage points of Intel render activity versus Kitty** in this controlled terminal workload. The compositor still used about 46%; moving the terminal does not fix every frame wait. NVIDIA Kitty cost roughly 6.3 W during that run versus about 4.4 W RTX idle. These are one-device measurements, not a general terminal ranking.
