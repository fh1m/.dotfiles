# Den polish / 2026-10-17

## What changed

- Music buttons share a softer room-specific treatment, readable labels and consistent corners.
- **Focus** (F while the room has keyboard focus) leaves artwork, metadata and a subtle progress rule. Hover the top edge for controls. Escape leaves Focus first, then restores the widget. F11 restores directly.
- The display chooser moves the same room, preserving playback/context. **Backdrop** puts it below applications. A one-shot compositor focus grab is released on outside interaction; switching display focus does not dismiss the room. This does not grab input devices or restart sharing services.
- External position icons again include Upper/Lower text. ScreenPad explicitly says Utility. The top identity mark/host label is slightly more legible. Both hosts use shared sources.
- Restored the previous button-style tmux rail from commit ca8bc12, preserving the spacer and explicit no-underline policy. Updated the palette template too, so the next wallpaper change cannot undo the choice. Reloading retains sessions.
- Companion chatter no longer depends on a six-minute uninterrupted stay on one display. It offers an arrival greeting and periodic tips/wit. Busy screens can show a short line in their measured bar perch; text cannot occupy neighboring controls.
- Notification announcements contain counts and app names, not bodies or titles. Events coalesce; DND holds event announcements. Occasional quiet-desk reminders acknowledge pending counts, and leaving DND can announce the backlog. Quiet mode suppresses chatter. Metadata remains local/volatile.
- Added eight original, explicitly playful lines. They do not pretend that tests passed, backups succeeded or research claims were verified.
- Neovim already had debugging, testing, diagnostics, Git/GitHub, tasks, snippets and learning tools. Enabled mini.move, mini.splitjoin and hex-color preview from the existing locked mini.nvim dependency; added no competing completion/editor framework. Code buffers now inherit terminal transparency.
- Field guide gathers LSP-attached maps from the maintained source as well as actual runtime/lazy maps, and makes the Space leader visible.
- README adds a bespoke generated night-shift illustration and slow vector signal animation with a reduced-motion fallback. The illustration is labelled, separate from actual desktop evidence.

## Spotify reliability boundary

The signed-in desktop bridge remains the catalogue source; MPRIS remains transport.
The repaired route does not revive the old exhausted developer-API path. A detected
429/quota response now creates a shared 60-second read cooldown. Cached lists stay
available with a warning; uncached reads explain the wait. No mutation is replayed.
A normal outage keeps previous cached data. Corrupt cooldown metadata cannot crash
browsing. Cooldown state is user-private cache, not part of Git.

This reduces avoidable requests. It cannot promise unlimited upstream access,
account availability, eternal compatibility with Spotify internal APIs, or offline
streaming. Playlist creation/addition, queue selection/addition and existing
transport remain available through their adapters; advanced playlist/queue editing
that lacks a reliable adapter still belongs in the official client. Personal
playlists were not used for destructive write tests.

## Research → decisions

| Primary source | Applied decision |
| --- | --- |
| [Neovimcraft](https://neovimcraft.com/) | Compared the existing toolset with the catalogue; preserved its already broad capabilities rather than adding another distro. |
| [mini.move](https://github.com/nvim-mini/mini.move), [mini.hipatterns](https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-hipatterns.md), mini.splitjoin in the installed library | Small editing improvements without a new dependency tree. Alternative movement keys preserve existing pane/agent shortcuts. |
| [Aerial](https://github.com/stevearc/aerial.nvim), [Trouble](https://github.com/folke/trouble.nvim), [Snacks profiler](https://github.com/folke/snacks.nvim/blob/main/docs/profiler.md) | Existing outline/diagnostic tools already cover these jobs; no duplicate picker/profiler framework added. |
| [Quickshell PanelWindow](https://quickshell.org/docs/types/Quickshell/PanelWindow), [IPC](https://quickshell.org/docs/v0.3.1/types/Quickshell.Io/IpcHandler/) | Screen-bound presentation, explicit focus policy, unique enabled IPC targets. |
| [Spotify rate limits](https://developer.spotify.com/documentation/web-api/concepts/rate-limits), [Spicetify Platform](https://spicetify.app/docs/development/api-wrapper/methods/platform) | Caching/backoff and clear ownership; no quota-bypass claim or repeated transport actions. |
| [GNOME notifications](https://help.gnome.org/gnome-help/shell-notifications.html.pa) | DND is a user intent; companion must not bypass it with duplicated message previews. |
| [PyTorch distributed](https://docs.pytorch.org/docs/stable/distributed.html) | Keep independent traceable jobs useful; do not claim that different GPUs over home Ethernet automatically form a faster training device. |

Practitioner reading: [HN Agent Paperclip](https://news.ycombinator.com/item?id=47063723)
shows a concrete local companion use case, not proof of learning or wellbeing
benefits. [Unixporn discussion](https://www.reddit.com/r/unixporn/comments/10zigxs)
contains conflicting experiences with decorative desktops. The practical choice
here is short optional messages, safe placement and no extra LLM daemon.

Useful existing Den features worth using more: project-aware editor launch,
Overseer tasks, independent remote jobs with receipts, clipboard continuity,
LSP call hierarchy, debugger/test panels, and Obsidian links from source context.
They are preferable to filling the bars with new buttons.

## Validation and limits

- Full Python suite: 293 tests passed after the catalogue cooldown additions.
- Spotify focused suite: 31 passed; includes global cooldown and cached-data preservation.
- Companion policy/lease suite: 10 passed.
- Host and running auv-ros2: actual Neovim fixture passed theme/tutor, lazy loading,
  snippets, Tree-sitter parsing, formatter presence, configured Python/C++ debug
  adapters, initialized basedpyright + Ruff, real hover and shortcut ownership.
  This is not an executed hardware-debugging session or a test of every stopped container.
- Live music: moved the same open Focus room through all four Arete displays;
  switched display focus without dismissing it. Real paired Escape restored the
  widget after the focus-policy repair. Screenshots inspected privately.
- Live companion: a test notification produced a visible text-only announcement
  with its count/app name. No message content was copied into companion metadata.
- Installer render/backups/idempotence checks passed. Sessions and private data retained.

Rollback: revert this pass and rerun the normal hardware profile installer. The
companion is optional (`sensei-den companion quiet on` or `hide`). Music Focus is
presentation-only. No drive, sudoers, GPU, firewall or credential changes.
