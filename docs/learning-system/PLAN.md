# Noesis: connected learning, research and engineering

Backend specification, 2026-10-08. The [revised V1 roadmap](v1-roadmap.md) governs the proposed application execution sequence and is approved for implementation. Hosting parity must pass before adaptive redesign. The data/safety contracts below remain authoritative.

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

## Authoritative release burn-down — 2026-10-09 continuation

This table supersedes earlier "remaining" statements for the changed slices.
A row is complete only when every release gate is accepted; implementation and
fixture acceptance are reported separately. **The first release is not complete.**

| Milestone | Accepted implementation / evidence | Remaining release gate |
|---|---|---|
| P0 | Existing safe writes/receipts/backup tests retained; executable calibration restored through Restic. Populated native Zotero annotations and PDF restored through encrypted recovery and reader restart; repeated backups preserve reader state. | Complete interruption/concurrency matrix and verified retention policy; latest Zotero restore startup regression must pass its corrected native rerun. |
| P1 | Opt-in bounded registered-vault Continue/Search; results carry owner identities; native selection/capture writes only to owner. Explicit restored-location replacement and new-identity fork, with interruption tests; newly registered identities support replacement after original-storage loss. Nonblocking cross-vault references survive moves. | Cross-vault contextual gate/deadlock policy and GUI relationship creation; disappearance/reappearance and conflict acceptance at larger scale. Global relevance and generation/cache-bound cursors now have regression coverage. |
| P2 | Populated isolated Zotero 10 profile with genuine Transformer PDF, native annotation edits/deletion, three retained import projections, stable resource UUID and learner prose. Installed API version/annotation omissions repaired. | Genuine annotation → agent-authored reconstruction → committed implementation → executed Eq. 1 checks accepted; full Transformer reproduction is outside V1. Annotation-specific handoff remains. Latest isolated Zotero restore restart timed out; corrected harness rerun is pending because a normal reader owns the API. Sioyek restored page acceptance remains valid. |
| P3 | Reviewable outline import with modules, six lectures, readings, two assignments and project; interruption retry avoids duplicates, consumption and assessment separate. Native import into new/existing courses accepted, immutable Arrange with keyboard focus recovery and 123-lesson pagination. | Native lesson → prerequisite → learner readiness → assignment → assessment → module/course return and cache-loss resume accepted. Native material replacement preserves source/edition evidence. Complete combined source-reader/outline acceptance and returning-learner inspection remain. |
| P4 | Distinct failed, assisted and independent attempts; durable restart/cache-loss recovery; learner criterion decisions. Native changed-task transfer, seven-day check scheduling and explicit protected check assessment survive cache deletion/restart. | Long history usability and realistic elapsed-time returning-learner acceptance. |
| P5 | Executed trusted calibration with generated data, Git revision, units, CSV/figure references, contradictory original hypothesis, held-out check, unavailable-artifact report and restored comparisons. | Native Lab prediction/configuration/measurement/local-figure composition accepted in the learning-day fixture. Complete external-tool handoff remains. This is generated software evidence, not hardware evidence or full-paper reproduction. |
| P6 | Proportional typography retained; display-title projections, grouped Learn, bounded preview, visible statement and contextual controls. Address-scoped Workspace/Tiled/Window controls, compact companion and repeated lifecycle measurements. | Complete realistic visual-state matrix, disconnected ScreenPad, physical input latency and sustained live-shell stability. Five-minute isolated open idle passed at 0.0133% of one CPU core. |
| P7 | Completed/retired/parked material excluded from Continue; owner-scoped suggestions retain reasons. | All journey-specific recommendation cases and learner priority controls. |
| P8 | Automated suites, repeated temporary-home installation and privacy separation retained; 10k index benchmark remains within budget. Actual running Distrobox host capture and headless guest Neovim mappings accepted without installation. | Full native/recovery/portability acceptance. Off-device destination remains deliberately unconfigured; preservation strategy is documented. |

No real vault was populated, relocated, merged or migrated for these tests.
Optional tracking integrations stay outside this release. Quickshell remains the
host pending evidence that isolation benefits justify another application runtime.

## V1 boundary and next acceptance cycle

V1 essentials remain reliable courses, papers, independent practice, experiments,
owner-aware cross-vault navigation, readable native working surfaces and tested
recovery. Sophisticated recommendation models, specialized experiment services,
advanced spaced-repetition integrations and external dashboards are post-V1. This
does not defer honest histories, safe writes or learner-controlled evidence.

The next cycle closes complete journeys rather than adding record types: course →
lesson → prerequisite → assignment → assessment → resume; paper annotations →
reconstruction → implementation → executable verification; failed practice →
assistance → changed-problem transfer → an explicitly performed later check; and
experiment → measurement/artifact → comparison. Cross-vault relevance and cursor
stability must be independently reproduced before search acceptance is closed.
A realistic disposable learning day will distinguish automated native interaction
evidence from human usability observations. The release remains partial.

The current release acceptance matrix is [release-acceptance.md](release-acceptance.md).
It distinguishes reproduced slices, partial milestones, V1 blockers, learner-trial
readiness and explicit post-V1 deferrals. It does not supersede failed recovery
evidence with passing model tests. The native learning-day fixture now spans CS,
mathematics, a genuine paper equation and an executed generated-data experiment.
