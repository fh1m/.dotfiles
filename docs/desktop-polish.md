# Desktop polish · 11 October 2026

The running shell now uses `sensei`: configuration, IPC, services and helper paths agree. Upstream credits and captured historical evidence retain their original names. Noesis remains a separate application. The original local files are recoverable under `~/.local/state/dotfiles-backups/desktop-polish-20261011`.

## Everyday controls

- `Super+Space`: compact launcher.
- `Super+Return`: focus the existing terminal; add Shift for a new independent `dev_NNN` session.
- `Super+Left/Right`: move between grouped windows, or ordinary windows when ungrouped.
- `Super+'`: create a tmux window. The bottom tmux rail is its selector; there is no duplicate top terminal rail.
- `Super+Shift+Space`: Obsidian scratchpad Canvas in the active vault.
- `Super+Alt+P`: select a screenshot region and save an observation with its image in the active vault.
- `Super+Ctrl+D`: reversible quiet mode, preserving the previous notification setting.

The workbench tools also live in System. Clipboard history copies text or images with one click; recording can be paused. Native window groups form at three ordinary windows and separate at two. Tab titles support focus, middle-click close and drag reordering.

The identity panel has Code, Agents, Nerd Talk and Hacker News. Discovery is fetched on demand and cached for an hour. HN opens discussion links, displays Show HN and Ask HN separately, and retains cached stories offline. Independent request collectors prevent tab changes from misrouting results or interpreting cancelled output as a feed error. Quotes rotate when opening the panel; their source is linked.

## Terminal

Iosevka Nerd Font Mono is 11.8 pt with cell offsets `x=1`, `y=4`. Configuration reloads in existing Alacritty windows. The tmux rail stays at the bottom with one blank row above it. Direct copy-mode wheel commands prevent plugin overrides from swallowing downward scrolling; selection release copies through Wayland.

The deck also launches upstream Alacritty. It does not inject refresh commands into active shells. The evaluated native-tab fork was rejected after an inactive child exit killed the active test shell; see [the exact evaluation](terminal.md). Existing user processes were preserved.

## Verification

- Full regression suite: 211 tests passed, including HN cache/offline handling and clipboard round trips.
- HN: real API returned eight Show and eight Ask stories. Rendered on the main monitor; rapid Code/Nerd Talk/HN switching retained both feeds without stale errors.
- Disposable desktop windows: third window grouped, left/right changed tabs, closing one dissolved the remaining two.
- Disposable tmux server: upward history position 5, downward position 2; live copy-mode release and wheel bindings checked.
- Private clipboard fixture: text and PNG copied byte-for-byte with correct MIME; paused and sensitive selections excluded.
- Workbench fixture: repeated scratch opens preserved learner-written text; cancelled capture produced no evidence note.
- Host and Noesis installers: dry run, idempotence, backups and rollback passed. Hyprland reports no configuration errors.

These checks do not claim that remote Spotify devices, every package-manager prompt, or every physical mouse interaction was exercised. Closed Spotify transport channels are tested to avoid restarting playback or replaying an action; external-device sessions remain untouched.

## Sources and decisions

[Alacritty FAQ](https://github.com/alacritty/alacritty#faq), [tmux clipboard documentation](https://github.com/tmux/tmux/wiki/Clipboard), [Hyprland dispatchers](https://wiki.hypr.land/configuring/core/dispatchers/), [Hacker News API](https://github.com/HackerNews/API), and [Karpathy's recipe](https://karpathy.github.io/2019/04/25/recipe/) informed the integrations. Public HN discussions about engineering rabbit holes suggested a lightweight browsing surface, not a background news crawler. Practitioner anecdotes were inspiration, not performance evidence.
