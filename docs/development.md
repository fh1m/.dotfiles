# Code belongs to its environment

One Neovim configuration. Host tools on Arch; ROS tools in their Distrobox.
The status line tells you which one. [Editor guide](../home/.config/nvim/LEARN.md)

## Start working

```sh
sensei-dev open ~/Envs/dockers/auv-ros2/Ros_workspaces/mongla_ws
sensei-dev open ~/Envs/dockers/drone-ros2/Ros_workspaces/your_project
sensei-dev open ~/Projects/your_project
```

The launcher detects container homes, enters through **Distrobox**, prepares the
editor on first use, and reuses the matching tmux window. `--new` forces another.
The saved project picker also discovers workspaces under container homes.

For unusual layouts, register the environment once:

```sh
sensei-dev configure /path/to/project --container drone-ros2 \
  --ros-setup /opt/ros/humble/setup.zsh --overlay /path/to/project/install/setup.zsh
sensei-dev configure /path/to/project --python /path/to/venv/bin/python
sensei-dev doctor /path/to/project
```

Use `--container host` for an explicit host project. Exact registrations override
parent registrations. Local paths and interpreter selections live in
`~/.local/state/sensei-dev/projects.json`, not Git.

## The editor

Space opens the discoverable command groups. `Space h k` searches keys;
`K` reads documentation; `gd/grr/gri` follows definitions/references/implementations.
The [packaged guide](../home/.config/nvim/LEARN.md) is also `Space h l` inside Neovim.

Python uses basedpyright for types and Ruff for lint. C++ uses clangd with real
compile commands. For colcon, run the selected-package build task, then the
compile-database refresh task. An existing regular project database is preserved.
Compile commands stay in the container where their include paths are valid.

Formatting honors actual formatter configuration. A build-system-only
`pyproject.toml` does not opt your project into formatting. Manual formatting is
always available; automatic save formatting has a 300 ms ceiling.

## Agents are companions

`Space a c/a` opens Codex/Claude next to the editor in the same environment.
`Space a y` copies explicit context. Git hunks and Diffview show what changed.
Authentication stays in each environment; no credentials are copied by this setup.
Missing native CLIs are provisioned on demand; existing installations are retained.

## Understand what you ship

Learning uses ordinary editor tools, not a second application to maintain:
documentation, signatures, outlines, snippets, tests, debugger scopes, Git history,
Markdown notes and code-review buffers. `Space h a` captures the selected code and
asks about its contract, alternatives, failure cases and evidence.

Obsidian is the knowledge surface: the same Markdown can be edited in Neovim,
linked in Canvas, queried by Bases or illustrated in Excalidraw. The optional
engineering vault is `~/Study/Obsidian/Engineering/Workbench`. Existing vaults
stay untouched. Every registered vault is discovered; extra paths are supported
in `~/.config/sensei-dev/knowledge.json`, with no count limit. New registrations
can be picked up in an existing editor with `:DevVaultsReload`.

`Space k o` opens the project in Obsidian, `Space k c` its Canvas, `Space h s`
its drawing, and `Space k S` searches across vaults only when requested.
Project/code links use the local `sensei-dev://` handler to return to Neovim.
Choose a different destination with `sensei-dev knowledge PATH --vault NAME`.
To provision this optional default on another host:
`python3 ~/.dotfiles/scripts/setup-knowledge.py`.

## Verified scope

The active host and `auv-ros2` passed headless checks for native Tree-sitter,
snippets, formatter availability, debugger adapter setup, both Python LSPs,
hover responses and key ownership. Six Python tests cover launcher isolation,
registry safety and 12 vaults, including preserving existing notes.
A real Markdown buffer loaded Obsidian integration successfully. These checks
are not a claim that hardware-attached ROS debugging or every stopped container
has been exercised. Provisioning new environments remains on demand.

## Provision another environment

```sh
sensei-dev setup /path/to/project --container NAME
# Host, or from an already entered Distrobox:
python3 ~/.dotfiles/scripts/setup-dev.py --activate
```

The container must expose the shared dotfiles repository and have Python 3, Git,
curl, a C compiler and zsh. Node and editor tools are user-local. Current upstream
Tree-sitter Linux binaries require newer glibc than Ubuntu 22.04; provisioning
compiles the CLI through Cargo when necessary, with two workers. Rust must be
available for that fallback. Every required parser is checked before activation.

Host and container plugin/Mason/native-parser directories are separate to prevent
ABI mixing. Plugins use the committed lockfile; updates are explicit.
Optional Rust/Go servers attach only when installed. QML uses the host Qt qmlls.

## Recovery

Activation moves the previous configuration, plugin data, cache and state into
`~/.local/state/sensei-dev/backups/TIMESTAMP`. It also backs up `.zshrc` before adding
the user-local tool PATH include. The old container `/usr/bin/nvim` is untouched.

To restore a trial configuration: move the new `~/.config/nvim` symlink aside,
move the backup's `nvim` directory back to `~/.config/nvim`, and restore its
`local-share`, `local-state`, and `cache` directories to the original Nvim paths.
Move the user-local `nvim` symlink aside to use the old container executable.
The staged `sensei-nvim` links can be removed; project files and Python environments
were not replaced.

## Agent input and long-output history

Application keys have priority: Shift/Alt arrows and Shift+Tab pass through to
Codex, Claude and Neovim. Tmux navigation uses the backtick prefix:
`prefix Left/Right` switches windows; `prefix h/j/k/l` changes panes.
Modified keys are forwarded when the application requests the extended protocol.

- Wheel: scroll the application when it requests mouse events, otherwise tmux history.
- Shift+PageUp or Ctrl+Shift+Up: explicitly enter tmux history, even over a fullscreen app.
- In history: PageUp/PageDown, arrows, `/` search, `v` select, `y` copy; `q` or Escape returns to the running app.
- Shift+PageDown: move down in tmux history.
- Shift+Enter: a distinct modified Enter; agent apps can use it for multiline prompts.

`sensei-dev` starts Codex with `--no-alt-screen`, so its output stays in the normal
terminal buffer. (A `tui.alternate_screen = "never"` setting in `~/.codex/config.toml`
does the same and is not tracked here.) New sessions retain normal
terminal output in tmux's 200,000-line history. Already-running fullscreen Codex
sessions keep their current rendering mode until resumed/restarted. Previously
unretained terminal output cannot be restored by changing tmux history settings.
App transcript views remain useful for output the application has not printed.

The old wheel override is replaced by tmux-native conditional routing; no process
scan or subprocess is launched on each wheel tick. Isolated attached-PTY checks
verified modified-arrow/Tab/Enter transmission and 2,500 lines of retained history.
See [Codex configuration](https://developers.openai.com/codex/config-reference/)
and [Claude terminal setup](https://code.claude.com/docs/en/terminal-config).

## Small editing comforts

`Alt+Shift+h/j/k/l` moves a line or visual selection; `gS` splits/joins arguments. Hex colors preview in place. These use the already locked mini.nvim library. Normal code buffers inherit terminal transparency, while menus and floats retain a readable surface. The desktop field guide now includes the LSP-attached maps and renders the Space leader explicitly.
