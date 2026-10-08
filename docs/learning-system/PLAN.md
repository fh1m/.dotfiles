# Noesis: connected learning, research and engineering

Approved implementation specification, 2026-10-08. Supersedes the earlier architecture in legacy-ledger.md.

Markdown remains authoritative. Zotero owns bibliography/original annotations;
Noesis owns versioned projections and separate readable activity records. SQLite
is a rebuildable local cache. QML orchestrates specialized applications rather
than replacing editors, math tools, readers or development environments.
Existing vaults remain separate. Downloads is excluded from automatic adoption.
No consumption counters, time, note counts or agent output award competence.

## Milestones and acceptance gates

| Phase | Required behavior | Release gate |
|---|---|---|
| P0 correctness/recovery | Merged progress validation, explicit vault scope, strict parser, bounded errors, containment and streaming backups | Fault reproductions and restored disposable data; desktop behavior inspected |
| P1 independent core | UUID records/vaults, schema 2, immutable activity, rebuildable index, NDJSON queries | Closed-Obsidian capture/search/progress/attempt; moves/cache deletion; copy migrations |
| P2 research | Stable resource aliases, bibliographic/annotation revisions, reading locators and reproduction links | Repeat import preserves identity and analysis; interruptions/readers absent |
| P3 course | Ordered units, separate consumption/task/project evidence | Six lectures, readings, two assignments, project, reorder and precise resume |
| P4 practice/evidence | Five practice modes, assistance, independent retry, delayed review and explicit learner capability decisions | Failure, assisted success, independent result and transfer remain distinct |
| P5 experiments/artifacts | Hypothesis, environment/code versions, measurements, discrepancies and external artifacts | Reconstruct a synthetic experiment; missing disk and contradictory outcome preserved |
| P6 workspace | Today/Learn/Research/Practice/Lab/Library; bounded models, context/history, keyboard navigation and ScreenPad companion | Main and fallback placement, resize, focus, stale replies, lifecycle and screenshots |
| P7 policy/agents | Deterministic explained next actions; manual controls; role-specific unverified agent contexts | Recommendations accurately reflect evidence and can be overridden |
| P8 hardening | Installation, recovery, performance, privacy, native/container integration | Behavioral fixtures and all acceptance budgets pass |
| P9 optional | Quarto, MLflow, DVC, Anki, additional readers, off-device recovery | Separate justified scenario; never required for core |

## Non-negotiable contracts

UUIDs identify records; paths/titles locate and label them. References include
vault identity. Unknown user fields and original prose survive migration. Duplicate
identities block mutations. Restored copies retain identity and need explicit
replacement/fork handling before concurrent registration. Source aliases never
replace resource UUIDs. Fuzzy titles produce candidates, never automatic merges.

Activities are separate Markdown records in Activity/YYYY/MM. Each attempt names
its target/session, mode, scope, outcome, assistance, assessment/evidence, timestamp
and provenance. Corrections supersede rather than erase. Study events maintain
linked state heads; competing heads must be resolved explicitly. Existing counters
are legacy baselines. Human editing remains possible; append-only is tool behavior.

Prerequisites belong to a target/context and contain gate/parallel/deep-descent,
reason, minimum understanding and exit evidence. Only blocking educational edges
participate in progression-cycle checks. Capability acceptance is learner-controlled
and names criterion, scope and evidence; there is no overall mastery percentage.

Worker requests carry version, request ID, vault, filters/cursor and generation.
Default pages are 50 summary records; bodies/history load on demand. Mutations use
explicit vault/target/operation IDs. Workers have no shell-execution protocol.
Watches run while open; overflow triggers reconciliation and failure is visible.

## Migration and recovery

Inventory and back up before mutation. Test copies; review per-vault dry-runs;
add identity/schema without relocating notes. Preserve uncertain legacy history as
unknown and mechanically convertible text in place. Activate one vault at a time.
Administrative events do not rewrite learner prose. Keep the previous UI available
until native acceptance passes. Never run a wholesale installer on the live home.

Small Markdown belongs in private local Git and recoverable backups. Files above
25 MiB and recordings/datasets are external references unless explicitly retained.
Use encrypted deduplicated local Restic backups, serialized jobs and restore into a
new directory. Keep legacy tar snapshots readable and do not prune the only
verified recovery copy. Reader databases require consistent snapshots and meaningful
reader-state restore checks. Cache is excluded. Off-device protection is deferred.

## Performance and validation budgets

Warm query p95 <=150 ms; capture acknowledgement p95 <=200 ms; input feedback
<=50 ms; warm workspace <=500 ms; cold 10,000-record rebuild <=8 s; summary pages
<=64 KiB. No process/periodic indexing when closed; idle worker average <0.1% of one
core over five minutes; no continuing memory growth across lifecycle cycles.
These are acceptance targets, not claimed results.

Tests use synthetic/disposable data. Validate schema/migration, races, interruptions,
imports, assistance/evidence, Unicode/malformed metadata, watcher recovery, missing
tools/artifacts, moves/cache rebuild, restores, desktop geometry/input and install
repeatability. Inspect public staged files for private notes/state/credentials.

## Evidence ledger

See validation.md for measured results and remaining release gates. A phase is not
complete merely because its source files exist. Full release requires all P0-P8
behavioral/native/recovery/performance gates. Optional integrations are separate.


## Product coherence continuation — 2026-10-09

The additional product directive is part of P2–P8, not a replacement roadmap.
Visual consistency is built alongside the workflows: shared Wrayth tokens,
quiet navigation, contextual Read/Work/History/Connections, optional details,
auto-preserved drafts, precise resource resume and a small intentional Today.
See visual-language.md for inspected product patterns and implementation rules.

Completed implementation slices include durable unfinished-attempt recovery,
append pagination, concept inclusion, path-scoped next actions, ordered-unit
frontiers, explicit review plans, local Zotero read/import projections, native
reader locators, child-owned parent references and capture commit receipts.
Native acceptance and remaining journey gaps stay in validation.md. Research,
course and Lab are not declared complete because their primitives exist.


The next research/development slice adds contextual action navigation, visible
questions/implementations, an existing-repository Neovim handoff, code snapshots
for experiment runs, and initiating-scope Neovim captures. Native connected-record
acceptance passes; full reader/annotation/execution journeys remain in the ledger.


2026-10-09 product correction: real selected robotics Noesis vault has notes but no activity; Knowledge and CS contain resumable or path contexts. Verified all four indexes without errors, preserved private content. Scoped Today onboarding and proportional prose typography deployed; real empty and Knowledge Today inspected. Unified authorized-vault Continue/Search and A–F native product gates remain open. Practice criterion decisions now passed native restart and cache-loss recovery.
