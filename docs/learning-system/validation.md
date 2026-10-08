# Connected redesign: implementation and acceptance evidence

The connected foundation is implemented and deployed. Full P0–P8 release
acceptance remains open. This ledger distinguishes tested behavior from remaining
work; the presence of a module does not complete its milestone.

## Observed verification, 2026-10-09

- Sixteen existing factory/import tests and thirty-three new core/workflow/recovery/
  watcher/Zotero/capture/reader tests pass: 49 total. Fixtures are synthetic and disposable.
- Capture, paged query, progress and attempt CLI operations pass with PATH containing
  no Obsidian executable. Native note opening remains a separate application action.
- Merged progress rejects current-only overflow, lowered totals, negative counts,
  invalid types and zero totals; zero current and unknown total remain valid.
- Exact frontmatter delimiters, duplicate YAML keys and malformed/incomplete
  frontmatter are checked without rewriting malformed content.
- Attempts preserve failed, reference-assisted and independent outcomes. Protected
  starts correlate reference exposure; a later assistance label cannot erase it.
  An independent retry receives a new identity. Capability acceptance requires an
  explicit learner actor, criterion, evidence and explanation.
- A six-lecture course fixture keeps two task records and a project independent
  of material consumption. Ordered links and exact resume positions are retained.
- A numerical tiny-network gradient fixture preserves the missing-input-factor
  bug, correction, reference assistance and finite-difference check through a move
  and cache deletion. These outcomes describe fixtures, not the learner's ability.
- Synthetic experiment records retain their prediction, contradictory comparison,
  code/configuration fields and an unavailable external artifact reference.
- CSL metadata/DOI changes preserve resource identity and learner prose; generated
  bibliographic revisions retain their own identities. Existing annotation-export
  tests preserve learner notes and historical generated content.
- Divergent study heads refuse another update. Explicit resolution retains both
  branches. Repeated operation IDs are idempotent; changed payloads are refused.
- Duplicate record IDs block mutation. Moves and deleted caches preserve durable
  references after reconstruction. A changed-file update is tested without a full
  vault walk.
- A real disposable Linux inotify queue was overflowed. The watcher emitted an
  explicit full-reconciliation request. Watch failures are surfaced with manual
  refresh recovery rather than quiet permanent polling.
- Legacy tar restore verifies hashes and rejects unsafe manifest directories and
  destination overwrite. Restic integrity/restore verifies included file hashes;
  large MCAP data remains an explicitly classified external reference.
- Installation into a temporary home is repeatable. Python cache files are not
  deployed. Live deployment used targeted copies, replacement backups and three-way
  preservation of runtime differences; the original checkout was not installed.

## Real-vault rollout

Copy migrations passed for all four managed vaults before activation. Read-only
native Obsidian checks found no unsaved Markdown editor content. Each vault then
received a local encrypted Restic snapshot, verified restore into a new location,
metadata migration and rebuilt index check. All original prose and existing user
fields compared equal; repeated migration changed no notes.

Administrative inventory: 18 Knowledge, 40 CS, 13 Workbench and 10 robotics notes
received identity/schema additions. These counts are not learning-progress metrics.
Existing IDs stayed intact. Downloads and archives were not adopted. Private
changes remain local and were not committed to the public feature worktree.

CS retains its original map, seven stages, predictions, corrections and unclaimed
lab work. Additive stable path/order links and its explicitly declared frontier
gate were created without changing those notes. Doctor passes all four vaults.

Private rollout receipts and snapshot IDs are stored in local state; public
documentation contains no private note bodies, reader databases or credentials.
The password/repository remain local. Off-device protection remains deferred.

## Backend performance

Measured by scripts/benchmark-noesis.py with real NDJSON worker round trips.
Each warm-query sample set has 50 requests; capture has ten CLI samples.

| Records | Cold rebuild | Warm worker p95 | Largest summary response | Capture CLI p95 |
|---:|---:|---:|---:|---:|
| 100 | 0.036 s | 0.846 ms | 5,772 bytes | 140.491 ms |
| 1,000 | 0.346 s | 1.803 ms | 5,866 bytes | 105.162 ms |
| 10,000 | 3.784 s | 8.979 ms | 5,958 bytes | 104.010 ms |

An initial 10,000-record run took 9.991 seconds. Repeated FTS path scans were
replaced with row-ID deletion; the table above records the corrected result.
These are synthetic backend measurements, not Qt frame timing or native tool
startup measurements. Ten capture samples provide limited percentile precision.

A 300-second open-but-idle Python worker sample recorded zero CPU ticks (0.0% of
one core) and exited on EOF. This does not establish the entire shared Quickshell
process's CPU or memory use.

## Native observations

The disposable native window and deployed window open at 1440×880 on eDP-1.
Native IPC verifies the six-workspace interface, bounded Library results, selected
record preview and active worker/watch. Closing verifies both processes stop.
The composed window was inspected in a synthetic screenshot. The companion loads
on the configured ScreenPad and keeps a selected context without a second query
worker. The previous UI remains selectable. Pane preferences are machine-local.

The native check caught an invalid QML separator in the final watcher patch before
deployment; it was corrected and the native check passed afterward. System
qmllint returned no useful diagnostic for that error, so it is not treated as
sufficient native acceptance evidence.

## Remaining release gates and limitations

- P0: fresh consistent reader backup publication, supported Obsidian registration
  probes and exhaustive interruption/concurrent publication cases. Reader restore
  now verifies SQLite integrity and row content on synthetic populated databases.
  Actual Sioyek/Zotero snapshots restored to new private directories with matching
  rows; the actual Zotero snapshot contains no bibliography or annotation items,
  so it cannot establish a populated native annotation recovery journey.
- P1: restored-vault fork/registration conflict workflow, complete cross-vault
  resolution and broader property/concurrency/fault-injection coverage. Activities
  and captures now provide cancellation commit receipts. Operations lacking a
  receipt still report uncertainty. Capture drafts are private machine state.
- P2: populated native Zotero lifecycle and exhaustive multi-file recovery. An
  isolated installed Zotero 10.0.6 profile passed the supported local API probe;
  its root returns plain text, handled without assuming JSON. Instance/permission
  checks and native annotation revision/deletion are tested through synthetic API
  responses. Sioyek one-based pages, Zotero PDF page URIs and YouTube timestamps
  have tested command construction; populated native reader-resume acceptance
  remains open. Multiple Zotero PDF attachments require selection in Zotero.
- P3–P5: all representative end-to-end course, paper, derivation and experiment
  desktop journeys; reorder/replacement history, repository/environment launches
  and criterion-level capability presentation. Child units, questions, tasks, runs
  and artifact references now publish with durable parent links in one file.
  Artifact checks stream and distinguish unavailable, unverified, match/mismatch.
  Lab comparison controls are implemented; their complete native journey remains
  an acceptance gate. These additions do not complete the milestones by themselves.
- P6: exhaustive tab-order/resize/fallback-output matrix, repeated Qt memory
  measurements, complete specialized study layouts and long-absence journeys.
  Main placement, keyboard capture/search/workspace changes and append pagination
  have native checks. The companion uses the same visual tokens without another
  query worker. Machine preferences and unfinished attempts survive independently.
- P7: fuller role-specific agent exports, ancestor parking/manual overrides and
  repeated prerequisite bottleneck views. Path scoping, ordered-unit frontiers and
  explicit schedule/snooze/retire plans are implemented and tested. Configurable
  1/7/30-day defaults are convenience policy, never competence estimates.
- P8: Qt input/frame timing, actual warm workspace p95, host/container acceptance,
  no-growth lifecycle measurements and full release privacy/recovery matrix.
  Optional P9 tools remain uninstalled; off-device protection remains deferred.

No milestone is marked fully accepted on the strength of source files alone.
The deployment is a working connected baseline, with the above release gates
still requiring implementation or verification.


## Product coherence continuation

The shared visual language uses existing Wrayth fonts/surfaces and a single pink
accent. Read/Work/History/Connections reveal controls according to current work;
Details is optional. Native Markdown preview is selectable; equations, diagrams,
editing, PDF annotation and code remain specialist handoffs. Learn includes concept
and legacy stage records. Today separates Continue from at most five suggestions.

The 10,000 ordered-unit fixture rebuilt in 5.986 seconds, queried at p95 8.975 ms,
returned at most 5,808 bytes, suggested Today at p95 115.477 ms and captured at
p95 111.573 ms. This exercises relationships as well as flat concept records.
These remain backend measurements, not Qt input/frame measurements.

Native interaction checks caught and repaired a nonfunctional Ctrl+Enter capture
shortcut and stale selected-context state after filesystem changes. Reference
reveal waits for a successful exposure record instead of showing material before
its provenance commits. Clock-skewed activity predecessors reduce causally;
missing/cyclic predecessors fail visibly rather than silently changing state.


The native disposable 123-record window appended 50 → 100 → 123. Actual Hyprland
key delivery verified Ctrl+K, Ctrl+Shift+N, typing, Ctrl+Enter, Escape and Ctrl+2/6.
Capture took three explicit keyboard steps (open, text, save) with no classification.
An externally finalized attempt-start updated the selected context through inotify.
A full process restart recovered its exact unfinished attempt and protected reference.
The window was resized by the compositor from 1440×880 to 1000×650 Qt units;
the optional inspector collapsed. The companion was observed on DP-2 at 480×112
Qt units. Closing stopped the worker and watch. These dimensions are Qt units,
not a new measurement of the compositor's monitor scale. The main monitor remains
1920×1080 logical; screenshots and IPC assertions cover different evidence.

scripts/check-noesis-desktop.py reproduces these checks in a disposable HOME.
The before/after images show a synthetic selected task, not private content.
Before, permanent capture/progress/attempt controls competed with reading. After,
Work gives reasoning room, History and Connections are separate, and Details can
collapse. The screenshots demonstrate hierarchy; the keyboard/history checks
establish behavior. Full paper/course/Lab journey metrics remain release gates.
