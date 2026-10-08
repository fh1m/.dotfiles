# Connected redesign: implementation and acceptance evidence

The connected foundation is implemented and deployed. Full P0–P8 release
acceptance remains open. This ledger distinguishes tested behavior from remaining
work; the presence of a module does not complete its milestone.

## Observed verification, 2026-10-09

- Sixteen existing factory/import tests and fifty-six new core/workflow/recovery/
  watcher/Zotero/capture/reader/scope tests pass: 72 total. Fixtures are synthetic and disposable.
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
| 100 | 0.034 s | 0.754 ms | 6,572 bytes | 109.515 ms |
| 1,000 | 0.339 s | 1.261 ms | 6,666 bytes | 103.238 ms |
| 10,000 | 3.476 s | 9.006 ms | 6,758 bytes | 101.804 ms |

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

- P0: fresh consistent reader backup publication, supported native registration handoff acceptance
  and exhaustive interruption/concurrent publication cases. Reader restore
  now verifies SQLite integrity and row content on synthetic populated databases.
  Actual Sioyek/Zotero snapshots restored to new private directories with matching
  rows; the actual Zotero snapshot contains no bibliography or annotation items,
  so it cannot establish a populated native annotation recovery journey.
- P1: restored-vault fork/registration conflict workflow, complete cross-vault
  resolution and broader property/concurrency/fault-injection coverage. Activities
  captures and record creation now provide cancellation commit receipts. Operations lacking a
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


Noesis registration now owns only its private machine-local location registry.
Synthetic checks preserve the native registry byte-for-byte, register/capture with
Obsidian absent, retain unknown registry fields, reject restored duplicate UUIDs
without changing either copy, and permit independent capture when the native
registry is malformed. Native process detection covers Electron, standalone and
AppImage shapes. The read-only CLI startup handshake has an eight-second deadline;
mutating native commands are never retried. Existing native registrations remain
usable; new ones use the supported manual Open folder as vault fallback.
Replacement/fork and full cross-vault reference resolution remain unfinished.


The native fixture now opens a six-lecture course with two problem sets and one
project using actual Ctrl+K → text → Down → Enter. Its two consumed lectures leave
assignment/project outcomes untouched. At 1000×650 Qt units, the context has a
340-unit scroll viewport for 548 units of content instead of overflowing fixed
panels. Lecture/read completion and pause/resume are explicit actions; paused
ownership suppresses pending work, while a shared unit with an active parent stays
available. New problems have a separate declared statement section; protected
preview does not expose following reference sections or infer a legacy statement.

Exact DOI/UUID search resolves resource identity without returning whole metadata.
Study activities preserve source URL/edition/revision and owned projection pointers.
Zotero search pagination appends and binds subsequent pages to the same server
instance. These are reliable workflow increments, not complete native paper/Lab
acceptance. The course fixture uses CLI setup; it does not prove UI course creation.

Schema checks refuse future-version downgrades while keeping their records readable.
Migration preserves original CRLF body bytes and backup bytes. A 10,000-event
causal history reduces without recursive traversal or quadratic dependency setup.
The full automated suite passes 72 tests (56 connected-core and 16 compatibility).

Record-creation fault checks interrupt before and after atomic publication, retry
after a move, retain the reserved identity/parent order, refuse changed payloads,
and refuse recreation of an unavailable committed record. Ctrl+N and Ctrl+Enter
provide a discoverable creation action in each workspace, including Practice.

The native check creates a problem through Ctrl+4 → Ctrl+N → title → Ctrl+Enter
and verifies one saved record with its committed receipt. QML logs contain no
errors or warnings for the tested main/compact/companion lifecycle.


## Connected research/development slice — 2026-10-09

Nine additional checks cover observed Git revisions, dirty and uncommitted trees,
missing storage, atomic project creation failure, receipts after disconnection,
stable capture links after moves, native Neovim vault binding, and stale reader
identity refusal. Neovim's actual headless runtime executes the bridge test; the
external launch command itself is tested as an argument vector, not as proof of a
complete native editing session.

The disposable native desktop completes paper → question → implementation → run
→ comparison → paper using actual keyboard delivery, dialogs and history. It checks
all parent identities and the comparison's retained Git snapshot. Setup creates
only a synthetic local repository; no CLI repairs are used for the connected route.
The route does not yet prove paper PDF annotation, populated Zotero lifecycle,
execution/reproduction, or a container handoff. Those remain release gates.

Context Actions replaces permanently visible administrative buttons. Related
questions and implementations are visible beside the source context. Comparison
and review dialogs capture initiating vault/target IDs; reader opening refuses a
stale target and reports a native handoff rather than raw JSON. Git inspection uses
bounded read commands with optional locks disabled; no code is automatically run.

The measured connected-record route uses 28 keyboard actions plus 161 typed
characters (including the repository path), with no filename hunting or metadata
copying. Artificial key-delivery delays are not a human resumption-time metric.
Research excludes course/book resources; Learn retains their units and concepts;
Library remains universal. This classification has explicit query tests.

After the source-kind query changes, current concept benchmarks are: 100 records,
0.039 s cold / 1.122 ms warm query p95 / 117.509 ms capture; 1,000 records, 0.347 s /
3.299 ms / 148.592 ms; 10,000 records, 3.784 s / 30.010 ms / 132.470 ms. Summary
responses remain below 7,809 bytes. These replace the earlier table for this slice;
Qt frame timing, populated native readers and complete lifecycle memory measurements
remain unfinished. Synthetic before/after research captures are in visual-language.md.
