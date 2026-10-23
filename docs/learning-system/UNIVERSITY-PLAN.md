# University and connected learning implementation

Approved: 2026-10-23. UIU BSCSE, Fall 2026 entrant. Notion owns academic and
personal planning; private Noesis records own learning evidence and academic facts.
Multiple views share a coordinated application host; Arete and Homie get private
replicas. Firm academic warnings allow explicit, preserved exceptions.

## Milestones and proof

- [ ] P0: baseline backups, source register, dual-host runtime diagnosis.
- [ ] P1: independent windows, per-window drafts and routing, monitor handoff.
- [ ] P2: source-versioned curriculum, academic ledger and degree audit.
- [ ] P3: Notion account connection, five collections, bounded API and offline queue.
- [ ] P4: revised/cancelled calendar events, persistent academic agenda.
- [ ] P5: versioned private replicas, conflicts and recovery verification.

## Acceptance

Degree/elective arithmetic; course → ink → assessment → retrieval; warnings and
recorded overrides; Notion duplicate/offline/conflict/auth tests; calendar revision
and cancellation; multiple display/window draft survival; dual-host continuation;
restore proof. Completion never implies competence.

## Decisions and constraints

- Existing vault content and preferences are private and preserved. No public
  transcript, credentials or personal timetable. No enrollment inferred from a
  recommended curriculum sequence.
- Authenticate Notion interactively; account setup is user-dependent. Linux wrapper
  is not assumed to provide official offline support. No password copying.
- Official source discrepancies stay unresolved, including ENG 1101 versus ENG
  1011 in a published prerequisite. No invented academic exceptions or retake rules.
- Public source fetching is subject to UIU availability; publish verified source
  snapshots and explicitly staged/unverified imports, never invented course data.
- Small commits, scoped deployments and private rollback manifests. No desktop or
  input-sharing restart. No automatic submissions, payments or registration.

## Execution ledger

Started from main a05a871, clean. Private Arete baseline includes a SQLite backup
of the calendar rather than copying its live WAL files. Previous planning research
covered 30+ UIU queries and 20 management-tool queries; preserve citations and
limitations with imported source versions.


### 2026-10-23 implementation checkpoint

Implemented, with acceptance still in progress:

- Coordinated window sessions now own their drafts, selected vault, navigation,
  preferences and operation receipts independently. Closing and reopening a child
  retains drafts and clears its exit latch. Existing primary state remains readable.
- UIU source-versioned catalogue contains 122 distinct course entries; 117 required
  credits plus the 9/15 elective baskets total 141. Full course descriptions and
  policy reconciliation remain incomplete. Three published prerequisite issues
  remain visible. Nine verified early-trimester dates are explicitly partial.
- Academic append-only records separate enrollment, attendance, assessments,
  official results and overrides. Corrections preserve original attendance events.
  Assessment weights are validated as a merged record before writing. Retakes do
  not silently select a GPA rule. `academic configure --vault PATH` pins the private
  fact owner by vault identity; changing a window's vault cannot split those facts.
- Notion workspace rename and sign-in requirement were verified. Five connected
  collections and Academic/Explore/Calendar views exist. The native desktop client
  was upgraded to 7.40.0-2 on Arete and installed on Homie; authentication remains
  machine-local. Connector access is not an unattended desktop REST credential.
- Notion adapter preserves stable IDs on updates, owns only declared properties,
  persists offline work and exposes revision conflicts. Its connection token goes
  through stdin into private mode-0600 configuration. No private identifiers or
  tokens belong in this document or repository.
- Calendar imports retain revisions, reject older and foreign-source changes,
  and reject unsupported individual recurrence edits before altering a series.
  Partial Notion records with unset properties remain valid agenda entries.
- Existing five Syncthing replicas were discovered rather than duplicated. Conflict
  copies are retained and excluded from normal note indexing. Replica configuration
  and independent recovery acceptance remain deployment tasks.

Verification: `python -m unittest discover -s tests -p 'test_noesis_*.py'`
178 passing; `test_calendar_revisions.py` 4 passing; native offscreen fixture
passes ink, independent child, close/reopen draft retention, University and Plan
modal loading. These do not constitute physical monitor/hotplug acceptance.

Review fixes: fresh Notion setup initializes its collection map; aggregate
assessment validation precedes append; nullable Notion selects do not crash the
agenda; secondary close clears its exit flag; occurrence cancellation cannot
cancel an entire recurring series. No transcript or enrollment was inferred.

Remaining gates: actual multi-display/draft/display-removal acceptance; local
Notion scoped authorization and live round-trip; complete source descriptions,
verified equivalence/retake/FYDP allocation; timetable recurrence exceptions;
dual-host record continuation, conflict resolution and restore proof. No milestone
is marked complete merely because its code or UI exists.
