# Architecture map

This is the map of the repository, written from the code. Each area names the file that is the source of truth and the design note that explains why it is shaped that way. When a note and a file disagree, the file wins.

## The repository

| Path | What it is | Rendered or built? |
|---|---|---|
| `home/` | Everything that lands in `$HOME`: shell, Hyprland, Quickshell, Neovim, tmux, scripts in `.local/bin`. `@HOME@` placeholders are replaced with the home path. | Rendered by `scripts/install.py` with backups. |
| `scripts/` | Installer, `doctor.py`, GPU configuration, the Quickshell build, the test installer, and the screenshot/gallery capture scripts. | Run by hand. |
| `system/` | Root-owned files: Bluetooth, `etc`, `usr`. Installed with sudo; sudo is never stored in the repo. | Installed by the installer. |
| `src/` | Native helpers (Bluetooth, Spotify). | Built by `scripts/build-native.sh` and `build-spotify.sh`. |
| `tests/` | Smoke and recovery checks: `dev-smoke.lua`, `terminal-input-smoke.py`, Python tests for the launcher and knowledge tools. | Run by hand. |
| `packages/` | Package lists: core, optional, robotics phone. | Read by the installer. |
| `docs/` | Design notes, measurements and operating guides. | Not rendered. |
| `vendor/` | Third-party sources, with licences in `THIRD_PARTY.md`. | Not rendered. |

## The desktop

- **Compositor.** Hyprland is configured in Lua. `~/.config/hypr/hyprland.lua` loads `custom-setup.lua` (the machine's monitors and motion), `hypr-sensei.lua` (layer rules, the deck window rule, special-workspace blur and dim) and `workspace-apps.lua`. `hypr-sensei.lua` is a symlink into the Quickshell tree, so the rule set and the shell that depends on it stay in one place. Notes: [gpu-and-chrome](gpu-and-chrome.md), [performance](performance.md).
- **Shell.** Quickshell, configured in `home/.config/quickshell/sensei/`. `shell.qml` composes the surfaces: background, bar, deck, dropdowns, notifications, launcher, picker, session overlay, lock. Panels are `PanelWindow`s on the layer shell; they are created per screen with `Variants`.
- **State.** `services/` holds singletons (`QtObject`/`Singleton` in QML). `ShellState` is the shared state of what is open and where. Services wrap a system source: `Wifi` (nmcli), `Lock` (PAM through `assets/pam.d`), `Wallpapers`, `Effects` (writes `~/.config/sensei/effects.json`), `Deck` (the special workspace), `Vuln`, `Planner`, and others.
- **Look.** `config/` holds the design tokens (`Theme`, `Appearance`, `NoesisStyle`). The motion scale is in `Appearance.duration`; every animation uses one of its four durations. Read [design-system](design-system.md) and [DESIGN.md](../home/.config/quickshell/sensei/DESIGN.md) before changing colour or motion.
- **Control seams.** `services/Ipc.qml` is the one place the shell is driven from outside: `qs -c sensei ipc call <target> <fn>`. Some targets exist for tests and recordings (`qa`, `daemons`, `glitch`, `overlay`). They are documented in the handler comments and are not user features. The `lock` target can lock and report state; it has no `unlock`, by design.
- **Deck.** A Hyprland special workspace holding one Alacritty window (`sensei-deck`, running `sensei-tmux`), with the HUD, signal, planner and vulnerability panels drawn around it by `modules/deck/DeckOverlay.qml`. The terminal is placed by Hyprland, from coordinates the shell computes. Measured cost and what is still open: [performance](performance.md#deck-open-measured-ab-2026-10-14).

## External dependencies outside this repository

- **`noesis-ui`.** `modules/learning/` imports `../../noesis-ui`. In the live tree that path is a symlink to `~/.local/share/sensei-learning/ui`, which is not in this repository. `shell.qml` instantiates `NoesisCompanion` unconditionally, so a machine without that folder logs `Type ... unavailable` errors on load. Either the folder becomes a tracked dependency, or the companion is guarded by a flag. This is an open decision.
- **Quickshell binary.** `sensei-shell` selects a local build under `~/.local/opt/sensei-quickshell` only when its Qt version stamp matches. See [installation](installation.md).

## Claude Code and Codex

- `~/.local/bin/sensei-claude-statusline` is the Claude Code `statusLine`. It records `rate_limits` into `$CLAUDE_CONFIG_DIR/sensei-usage.json` (mode 600) and passes the same stdin to the user's own `statusline-command.sh`.
- `~/.local/bin/sensei-code` gathers usage for Claude (per account, from each config directory), Codex, OpenCode and GitHub activity. It reads token counts, timestamps and repository metadata; it does not read message text.
- The Agents dropdown (`modules/dropdowns/CodeDropdown.qml`, data from `services/CodeDesk.qml`) shows them.

## Neovim

`home/.config/nvim/` is lazy.nvim. `lua/sensei/plugins.lua` declares the plugins; `lsp.lua`, `debug.lua`, `tasks.lua`, `format.lua`, `environment.lua` hold the behaviour they share. `environment.lua` resolves the Python interpreter for LSP, DAP and neotest from one place. `lazy-lock.json` pins every plugin. `:MasonToolsInstall` installs the tools listed in `plugins.lua`.

## Verifying a change

- Quickshell: sync the file to the live tree with the same `@HOME@` render, check `~/.local/state/sensei/shell.log` for `Configuration Loaded` and no new `ERROR`.
- Neovim: `nvim --headless "+Lazy! install" +qa`, then start once and check for errors.
- Scripts: run the matching test in `tests/`.
- Anything visible: take a screenshot of the output it appears on (`grim -o <output>`) and look at it.
