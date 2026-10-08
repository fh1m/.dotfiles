# First-principles learning system — implementation ledger

## Baseline
CachyOS/pacman, Hyprland Lua, Quickshell, Alacritty, zsh, tmux and shared Neovim.
The installer renders/copies `home/`, backs up replacements and retains selected
helper links. Development changes in the original checkout are unrelated and
remain untouched. This isolated feature worktree starts at d0b3a9b.

Canonical seed: `~/Downloads/how sand becomes magic`; it has a local Git history,
learner-written answers and the open Obsidian registration. The extracted ZIP
copy is older. Bases, Canvas, daily notes and templates are configured. CLI initially disabled; user enabled it. Native CLI now verified at 1.13.7.
All navigation and note operations use native CLI with vault-path checks. Existing four
community plugins are retained, no new plugins planned. Python YAML is installed.

## Architecture / decisions
Keep the numbered seed ontology and learner prose. Extend with Projects, Real
World, Future Branches and Meta. A subject-independent maintained template is
installed through the existing `home/` deployment. `sensei-learn` is a small Python
CLI; local state is outside dotfiles. Core Bases query Markdown, no separate DB,
polling daemon, automatic mastery or generated encyclopedia. Oasis is a compact
subject selector and on-demand frontier panel, not a second note database.
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
- [x] M2 factory: generic subject, doctor, dry-run/refusal/idempotency tests pass.
- [x] M3 CS: preserve learner answers; clear next build, classified prerequisites,
  linked project/real-world/branch, critical navigation repaired and doctor passes.
- [x] M4 integration: launcher, Neovim actions, Alt+Shift window arrows and editor
  transparency deployed; input and live app checks pass.
- [x] M5 handoff: concise docs, isolated commits, exact staged secret/state review,
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

## Steering incorporated
Learning center named **Oasis**. Research 11 sources/people; native bar/dropdown,
Neovim actions and keyboard workflows; no polling daemon. Existing software,
robotics and ML work receives experiment scaffolds, not celebrity impersonation.

## Executed refinement
CS relocated with compatibility link; starter folder/ZIP archived. Workbench and
Noesis backed up and additively adopted; their original folders and notes remain.
Subjects is the widget's default view; CS has no privileged role. Native CLI
registration uses the inspected vault-chooser bridge, avoiding cached-registry
races. ID plus path verification resolves duplicate archive names safely.
Obsidian reading font 17px; live zoom 115% verified. No new community plugins.
Daily private snapshot timer enabled; checksum restore verified in a disposable
destination. Backup snapshots exclude runtime/plugin/Git state; off-device backup
requires an explicit second trusted device.

## Validation observed
Ten factory tests pass; temporary native-CLI vault created, templates expanded,
Bases returned new experiment rows, and registry/folder test state removed.
Native metadata cache reported no broken Home links. Three real vaults pass
structural doctor. Neovim Oasis command/mappings load; tmux uses M-S arrows;
Hyprland configerrors empty. Live ScreenPad composition inspected via screenshot.
Installer tests exposed two pre-existing portability/idempotency bugs: hard-coded
home paths and relinked helper reporting. Both repaired; temporary-HOME repeat
install now passes without changes. No whole-home reinstall was performed.

## Handoff state
Task-only implementation committed on the feature branch; private CS structural
upgrade committed locally as 30b88a2, with earlier learner/config/Canvas edits left
uncommitted. Installed community-plugin files remain on disk but are no longer
tracked. Local snapshot restore, exclusion/refusal checks, ten factory/adoption
tests and rendered installer/systemd checks pass. Public branch contains reusable
code, defaults, research and a Subjects-only screenshot; no subject notes, app
registry, session state or credentials. Push verification recorded at handoff.


## Noesis lifelong-learning expansion — 2026-10-08
Approved: connected Knowledge vault plus independent vaults; persistent native
main-display window; Zotero + Sioyek. Preserve pre-existing work and subject notes.
Main monitor eDP-1 is 1920×1080 logical; ScreenPad is 1920×550. Obsidian 1.14.4
currently runs native Wayland; verify readability without unnecessary restart.

Milestones (done when):
- [x] N1: fix CLI identity/races, network factory and native acceptance checks.
- [x] N2: optional paper/course/problem/resource/snippet records, append-only
  attempts and progress; repeatable imports preserve learner notes; tests pass.
- [x] N3: Zotero and inspected Sioyek installed, readers launch, settings backed
  up; annotated-PDF boundaries and exports documented and checked.
- [x] N4: shared Knowledge vault, flexible templates/Bases/Canvas and Obsidian
  handbooks work; Workbench remains an engineering studio.
- [x] N5: Noesis is a resizable, persistent 1440×880 main-display window; bar
  raises it; no click-away dismissal; data/preview actions responsive and bounded.
- [x] N6: native end-to-end disposable learning workflow, backup/restore,
  installer repeatability and private-state review pass; task-only branch pushed.

Use Markdown as learning authority, Zotero for citations/annotations, Sioyek for
focused reading, Neovim/Distrobox for implementation. No custom rich editor,
mastery inferred from reading time, idle polling, private notes in public Git,
cloud accounts, or archived-plugin dependency. Stable IDs survive path changes.
Source imports own their generated excerpt files, never learner-written bodies.
Research search inventory: 58 targeted queries; source provenance recorded in
research.md. The four requested Colin Galen captions were inspected; paraphrases and source links are in research.md.


### Expansion acceptance evidence
Fourteen factory/import tests pass, including identity after rename, flexible
paths, repeat imports and traversal refusal. Native Obsidian acceptance created
notes, Canvas, evidence, study positions and recall; Study/Practice/Evidence Bases
returned actual rows. Annotation re-import preserves learner prose and embeds once.
The disposable vaults and their native registrations were removed afterward.
All four real vaults pass structural checks. Knowledge is the default, with real
queued sources, not invented mastery. Existing CS and engineering notes remain.

Readers: official Zotero 10.0.6 and Sioyek 2.0.0 installed under ~/.local/opt with
checksummed, repeatable setup. Zotero is native Wayland; Sioyek stable uses XWayland.
Excalidraw was reused from the existing installation and its live load verified.
Snapshot restore and overwrite refusal pass. Reader SQLite snapshots pass integrity
checks; open Zotero uses its timestamped internal backup rather than claiming live
freshness. Local snapshots are not off-device disaster protection.

Main-display persistent window, focus-away survival, watcher shutdown on close,
empty Hyprland configerrors and additive Neovim mappings verified. Warm opening
samples were 82–146 ms; a quiet 3-second shell sample used ~1% of one CPU core.
These are spot checks, not a promise of universal frame-time performance.
Installer repeatability and diff/secret review pass. Public code contains no private
vault content or transient Obsidian state. Subject notes remain local/private.
