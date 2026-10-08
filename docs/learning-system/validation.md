# Connected redesign: implementation and acceptance evidence

The connected foundation is implemented and deployed. Full P0–P8 release
acceptance remains open. This ledger distinguishes tested behavior from remaining
work; the presence of a module does not complete its milestone.

## Observed verification, 2026-10-08

- Sixteen existing factory/import tests and twenty-one new core/workflow/recovery/
  watcher tests pass: 37 total. Fixtures are synthetic and disposable.
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
| 100 | 0.034 s | 0.586 ms | 5,772 bytes | 88.336 ms |
| 1,000 | 0.333 s | 1.331 ms | 5,866 bytes | 90.460 ms |
| 10,000 | 3.394 s | 8.653 ms | 5,958 bytes | 92.915 ms |

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

- P0: meaningful reader-state restore into separate profiles; complete consistent
  reader backup validation; supported registration/version probes and exhaustive
  interruption/concurrent publication cases.
- P1: explicit restored-vault fork/registration conflict workflow, complete cross-
  vault resolution, cancellation commit-status reporting and broader property/
  concurrency/fault-injection coverage. Current cancellation reports uncertainty
  and asks for inspection; it does not instruct blind repetition.
- P2: native Zotero local-API capability/instance/permission experiment, reliable
  reader locator handoff, annotation-ID lifecycle and exhaustive multi-file import
  interruption/recovery. CSL/Markdown export fallback is the implemented adapter.
- P3–P5: richer course/context/evidence presentation, complete reorder/replacement
  history, all realistic reading/assignment/project fixtures, environment/repository
  launching and explicit external-artifact integrity checks. Current records and
  relationships provide the foundation; these integrations are not all complete.
- P6: exhaustive focused keyboard/tab/resize acceptance, changed/disconnected output
  tests, repeated Qt lifecycle/memory measurements and complete specialized study
  layouts. Main-display placement was observed; fallback behavior is implemented
  but its full hardware matrix has not been exercised.
- P7: path/context-specific recommendation scope, configurable 1/7/30-day suggestion
  policy, fuller agent-context exports and complete manual override journeys.
- P8: Qt input/frame timing, actual warm workspace p95, recommendation scale,
  host/container acceptance, no-growth lifecycle measurements and full release
  privacy/recovery/performance matrix. Optional P9 tools remain uninstalled.

No milestone is marked fully accepted on the strength of source files alone.
The deployment is a working connected baseline, with the above release gates
still requiring implementation or verification.
