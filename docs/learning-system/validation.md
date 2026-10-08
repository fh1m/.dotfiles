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


### Real Today correction — 2026-10-09

Read-only inspection of the four managed local vaults found no index errors. The selected robotics vault named Noesis contains notes but zero activity records and zero next actions. Knowledge has four activities and a resumable context; CS has a path and a next action; Workbench has a project but no activities. Counts describe inventory, not learning. No private note was changed to populate Today.

A real running-window capture was inspected locally (`/tmp/noesis-real-today-before.png`); it is not a synthetic fixture or proof of workflow completion. Private screenshots remain outside public Git. The empty suggestion heading and duplicate Today capture controls were removed. Today now explains local scope, offers other managed vaults, exposes existing path/course outlines, and provides direct start actions. Prose uses installed Adwaita Sans; technical metadata retains its existing monospace font.

Practice native acceptance passed: failed independent, assisted successful, and later independent successful attempts retain distinct IDs. Explicit learner criterion decisions preserve failed evidence honestly. Restart after deleting the disposable cache recovered history and decisions. This is synthetic native interaction evidence, not a real learner observation.

Remaining Today gate: opt-in, bounded unified Continue/Search across authorized vaults with each result carrying vault identity; cross-vault selection must preserve scoped drafts and mutations. This intermediate release still queries the selected vault and labels that limit. A–F product acceptance is not yet complete.

Real deployed Today was inspected in both the selected robotics vault and Knowledge. Knowledge displayed its real Continue context and two course outlines; the original robotics selection was restored. These were local visual inspections, not click-through resume proof. Today onboarding scrolls rather than clipping at compact sizes. Current automated total: 75 tests (59 core and 16 compatibility); the added Today state test passed separately.

## Release continuation evidence — 2026-10-09

The worktree was clean at `4813ad0` at re-entry; there was no newer uncommitted
local implementation. The original dotfiles checkout was not edited. The user's
real screenshots were inspected locally; private vaults were not modified to
populate Today. Earlier vault-inventory counts are time-specific observations,
not current claims of learner progress.

New acceptance commands:

```sh
python3 -m unittest discover -s tests -p 'test_noesis*.py'
python3 -m unittest discover -s tests -p 'test_learning.py'
python3 scripts/check-noesis-desktop.py
python3 scripts/check-noesis-collection-desktop.py
python3 scripts/check-noesis-experiment.py
python3 scripts/check-noesis-zotero.py
python3 scripts/benchmark-noesis.py
```

Automated: 75 core and 16 compatibility tests passed. Added coverage includes
registered cross-vault scope and duplicate identity refusal, pagination/cursor
ownership, unavailable registered storage and malformed active-scope isolation, concurrent attempt-start refusal, research source filters, completed-material continuation,
course-resource distinction, explicit restore replacement/fork and interrupted
publication, safe bounded previews, interrupted outline retry, foreign concept
resolution after moves, and Zotero item/library-version distinction and omitted
attachment annotations. No real vault migration was used for acceptance.

The broad native disposable run passed 50 → 100 → 123 append pagination,
keyboard search/capture/Escape, 1000×650 resize, inspector, protected durable
attempt restart, DP-2 480×112 companion, stopped worker/watch, six-lecture course
with assessments untouched, creation receipts, connected paper → question →
implementation → run → comparison → paper, and failed/assisted/independent
attempts plus a learner criterion decision recovered after cache deletion.
The connected-record route still uses 28 keyboard actions plus 161 typed characters.
It does not establish actual paper reproduction or human resumption speed.

The separate cross-vault native run passed explicit collection search, opening a
CS task while Robotics was selected, and capture in CS only. Native outline
review/create yielded six lectures, two readings, two assignments and a project,
with no reported successes. Workspace was 1916×1032, Tiled 939×1008, and Window
1440×880 Qt units; compositor floating/fullscreen state was checked. No QML
warnings/errors occurred. A startup race exposed by the broad run was repaired
with bounded compositor-state verification rather than assuming dispatcher exit
established geometry. Native acceptance is run serially to avoid competing fixture
applications stealing focus; one earlier overlapping run is not accepted evidence.

Measured isolated launch: 536.13 ms; conservative warm-open p95: 119.91 ms;
instrumented animation-frame p95: 16.945 ms / 1,188 samples. Twelve-cycle RSS
ranged from 191,584 to 192,256 KiB, ending at 191,640 KiB. This small
measurement does not prove absence of long-term growth or input latency.

Current concept benchmark: 100 / 1,000 / 10,000 records rebuilt in
0.037 / 0.368 / 3.654 seconds; warm worker-query p95
0.864 / 3.026 / 29.873 ms; capture p95
109.293 / 108.028 / 106.743 ms. Largest summary was 7,808 bytes.

The executed trusted software calibration used 1,000 generated measurements
(rad/s), a committed estimator, CSV and plot references, an original contradicted
zero-bias prediction, and a second held-out check. Mean was 0.1200065 rad/s;
held-out residual mean was 0.000005331 rad/s after bias estimation. Missing artifact
storage remained explicit; Restic restored both comparisons and the code revision.
This is generated-data software evidence, not hardware measurement or Transformer
paper reproduction.

A populated isolated Zotero 10.0.6 profile imported the genuine
[Attention Is All You Need paper](https://arxiv.org/abs/1706.03762), its accessible
PDF and native annotation. Metadata/annotation edits and deletion produced three
retained projections with the resource UUID and learner analysis unchanged.
Its real API exposed two defects: item version is not library version, and local
attachment `/children` omits annotations. Collection-version checkpoints and a
bounded annotation reconciliation now handle those cases. If the bounded library
projection exceeds 1,000 annotations, import refuses and requests a scoped export;
it does not silently pretend annotations were deleted. Production imports remain
GET-only. Test authorization applies only to a disposable profile.

The authoritative remaining P0–P8 gates are in PLAN.md. Native PDF page/annotation
navigation, transfer/review, outline reorder/replacement, reader-state restoration,
Distrobox, disconnected ScreenPad and complete long-term/input/idle acceptance
remain open. Off-device protection is not configured; the encrypted strategy is
in migration-recovery.md. This evidence is not a complete-release claim.
