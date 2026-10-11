# Terminal workflow

Alacritty renders the terminal; tmux owns persistent shells and projects. New
terminal windows create independent `dev_001`, `dev_002`, … sessions. The counter
survives closed sessions. Existing project and legacy sessions stay intact.

| Action | Key |
|---|---|
| Focus terminal, launch only if none exists | Super+Enter or Alt+Enter |
| New terminal and independent session | Shift+Super+Enter or Shift+Alt+Enter |
| Previous / next tmux window | Ctrl+Alt+Left / Right |
| Previous / next grouped desktop tab | Super+Alt+Left / Right |
| Tmux command prefix | Backtick |
| Previous / next tmux window, prefix alternative | Prefix, Left / Right |
| Split side by side / above and below | Prefix, `\|` / `-` |
| New window in current directory | Prefix, Enter |
| Pane navigation | Prefix, h / j / k / l |
| Zoom pane / change layout | Prefix, z / Space |
| Sessions / windows tree | Prefix, s / w |
| Project picker | Prefix, g |
| Search pane history | Prefix, / |
| Explicit history access in agent TUIs | Ctrl+Shift+Up; Shift+PageUp |
| History when application captures mouse | Shift+wheel up |
| Exit history mode | Escape |
| Detach while shells keep running | Prefix, D |
| Resume a named session explicitly | `sensei-tmux --attach dev_001` |
| Native Alacritty vi mode | Ctrl+Shift+Space |
| Literal prefix for editor | Prefix, b |

Ordinary Shift-arrows belong to the application. Alacritty leaves editor
Ctrl+Shift combinations alone. Clipboard, true color and extended keys are enabled
in tmux. Mouse input goes to applications that request it; other wheel scrolling
enters tmux history without launching a process-tree scan for each tick.

Keep related windows in a session and use names that describe work. Use the
session tree or existing fzf picker to resume; don't create terminals just to
find a previous shell. Existing copycat, yank, tmux-fzf and resurrect remain;
there is no extra overlapping scroll plugin or always-running workflow framework.
Resurrect restores layout/commands when requested; it is not a checkpoint of
process memory or a guarantee that a server survives a machine reboot.

The status rail has one blank row above it. This intentionally costs a terminal
row to give content breathing room. It retains the existing colored text segments
and mouse targets. History is bounded at 200,000 lines; multiple independent
sessions cost memory, so close work deliberately when finished. Pane/window
closure still asks for confirmation.

## Why these choices

[tmux's guide](https://github.com/tmux/tmux/wiki/Getting-Started) documents that
grouped sessions share windows: grouping was the cause of apparently independent
terminals showing the same work. Independent sessions fix ownership; explicit
resume keeps persistence useful. [Formats](https://github.com/tmux/tmux/wiki/Formats)
and the [clipboard guide](https://github.com/tmux/tmux/wiki/Clipboard) support
native status composition and terminal clipboard interoperability.

[Alacritty bindings](https://alacritty.org/config-alacritty-bindings.html),
[configuration](https://alacritty.org/config-alacritty.html) and
[native features](https://github.com/alacritty/alacritty/blob/master/docs/features.md)
provide vi navigation, scrollback search, hints and explicit escape sequences.
Use these alongside tmux history rather than adding another renderer or plugin.
The Iosevka font and rendering settings remain; navigation bindings are explicit.

Practitioner reports informed workflow choices, not performance claims:
[a workflow discussion](https://www.reddit.com/r/tmux/comments/1g4ptly/whats_the_tmux_workflow/)
favors understanding sessions/windows and developing a small useful binding set;
[status spacing](https://www.reddit.com/r/tmux/comments/rascjp/adding_space_between_tmux_status_bar_and_prompt/)
highlights the tradeoff of a second status row. These are anecdotes, not consensus.
No GPU/CPU improvement is claimed from keyboard changes.

## Package and power controls

System → Packages keeps output and responses in the widget. Default, yes, no and
arbitrary one-line selections are supported; closing the panel does not terminate
the worker. A graphical password prompt temporarily releases the shell focus
capture, then restores it. Passwords do not enter transaction logs. Prompts are
not blindly accepted. [Paru's manual](https://github.com/Morganamilo/paru/blob/master/man/paru.8)
defines the pager and sudo flags used by the worker; review output uses `cat`.

The top-bar battery control owns Battery & power. Telemetry comes from UPower and
Linux power_supply, charging controls from the installed asusctl, and profiles
from the existing system76-power helper. See [UPower properties](https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.UPower/UPowerDevice/)
and [kernel units](https://docs.kernel.org/power/power_supply_class.html).
Current-rate charging estimates are approximate; missing estimates remain
unavailable. Firmware counters are labelled as reported, not independently verified.
Graphs contain real bounded samples collected only while the panel is open.
Charging limits change only when clicked; a one-shot full charge uses asusctl's
existing one-shot facility. This changes neither fan overrides nor sudo policy.
