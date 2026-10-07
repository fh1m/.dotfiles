# First-principles learning system — implementation ledger

## Baseline
CachyOS/pacman, Hyprland Lua, Quickshell, Alacritty, zsh, tmux and shared Neovim.
The installer renders/copies `home/`, backs up replacements and retains selected
helper links. Development changes in the original checkout are unrelated and
remain untouched. This isolated feature worktree starts at d0b3a9b.

Canonical seed: `~/Downloads/how sand becomes magic`; it has a local Git history,
learner-written answers and the open Obsidian registration. The extracted ZIP
copy is older. Bases, Canvas, daily notes and templates are configured. CLI probe
reports **not enabled**; URI navigation is the supported fallback. Existing four
community plugins are retained, no new plugins planned. Python YAML is installed.

## Architecture / decisions
Keep the numbered seed ontology and learner prose. Extend with Projects, Real
World, Future Branches and Meta. A subject-independent maintained template is
installed through the existing `home/` deployment. `sensei-learn` is a small Python
CLI; local state is outside dotfiles. Core Bases query Markdown, no separate DB,
daemon, automatic mastery, generated encyclopedia or Quickshell dashboard.
Gate/parallel/deep-descent are dependency roles, not three giant curricula.
New vaults are private local Git; never configure a remote automatically.

## Migration / recovery
Verified private snapshot and SHA256 manifest:
`~/.local/state/sensei-learning/backups/20261008-020018`.
Move active CS to `~/Study/Obsidian/Learning/how sand becomes magic`, preserving
`.git`; old path becomes a symlink. Archive starter + ZIP separately. Update the
app registry only after verified relocation; no deleting duplicate notes. Preserve
existing vault Git dirt. Full original backup supports rollback.

## Milestones / done when
- [x] M1 discovery: canonical copy, CLI, deployment, original changes and backup identified.
- [ ] M2 factory: generic subject, doctor, dry-run/refusal/idempotency tests pass.
- [ ] M3 CS: preserve learner answers; clear next build, classified prerequisites,
  linked project/real-world/branch, critical navigation repaired and doctor passes.
- [ ] M4 integration: launcher, Neovim actions, Alt+Shift window arrows and editor
  transparency deployed; input and live app checks pass.
- [ ] M5 handoff: concise docs, isolated commits, exact staged secret/state review,
  feature branch pushed without unrelated changes or private subject notes.

## Intended changes
`home/.local/bin/sensei-learn`, template under `home/.local/share/sensei-learning`,
launcher desktop entry, additive Neovim plugin, installer/package declaration,
terminal/compositor integration, tests and this documentation. CS changes are
local subject data, not copied into the public dotfiles. Existing worktree dirty
configs receive only targeted live edits; not a whole-worktree install.

## Validation / acceptance
Unit tests, Python compile, factory dry-run, temporary Classical Mechanics vault,
subject doctor (YAML, Canvas, links, dependency DAG, configured paths, tracked
volatile state), installer test/idempotency in temporary HOME, actual Obsidian
URI open and Bases inspection, Neovim action load, isolated tmux modified-key
transmission. No invented experiments, grades, percentages or measured results.
Update this ledger as milestones pass; report remaining limits honestly.
