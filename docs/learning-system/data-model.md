# Data model and architecture decision

Selected: Markdown + rebuildable SQLite + native QML. A browser application,
database server and replacement rich editor are unnecessary for these workflows.

Record types share UUID, type, title, provenance and noesis_schema: 2. Paths,
capabilities, concepts, resources, units, tasks, projects, experiments, questions,
misconceptions, branches, artifacts, relationships and sessions use this contract.
Unknown record types stay searchable and readable. Activities have a target with
vault_id/record_id, event, immutable UUID, timestamp and operation ID. Activity
Markdown contains the explanation/evidence body. Separate assistance is never
converted into independent success by a later event.

SQLite owns derived record locations, metadata, text, FTS, aliases, typed relations
and activity targets. A cache can be deleted and rebuilt from the vault. Generation
changes when records change. A short-lived NDJSON worker exposes read-only query,
record, timeline, relationships and recommendation requests. Explicit CLI mutations
perform writes; no arbitrary shell evaluation is available through the worker.

Ownership: learner prose remains Markdown; Zotero exports become recoverable
versioned projections; code stays in repositories; large artifacts stay in external
storage; layout preferences are machine-local. There is no synchronization of a
live Zotero database and no automatic capability award.


Child publication may own a parent_ref containing vault_id, record_id, relation
and optional order. The index projects this into the same relationship queries;
it is rebuildable, not a second source of truth. Parent and child titles/paths
may change without changing the edge. New linked units publish in one atomic
Markdown file rather than requiring a partially committed pair of files.

Cached derived states support bounded queries. Immutable study, attempt, exposure,
review-plan and comparison records remain authoritative. Causal predecessors
control reduction, not wall-clock ordering. Local operation receipts witness
capture publication; retries preserve record identity after moves. A missing
committed record is a recovery condition, not permission to recreate it.

## Native host decision — measured continuation

Retain Quickshell's ordinary `FloatingWindow` for the first release. The name of
this Qt type does not require compositor floating rules: the application now
selects maximized Workspace, tiled or normal presentation through supported
Hyprland 0.56.2 dispatcher expressions, addressed to its own PID/title-discovered
window. Mode completion is verified against compositor state and retried within a
bounded startup window. Debug/legacy switching is development-only.

An isolated native fixture measured approximately 536 ms launch-to-visible
worker/watch, a conservative 12-open p95 of 120 ms, and 17.0 ms instrumented Qt
animation-frame p95. RSS remained around 187 MiB across twelve cycles. This is the
isolated fixture shell, not a per-Noesis measurement inside the live Wrayth shell.
Worker and watches stop when the workspace closes. Frame instrumentation runs
only in the acceptance fixture, not the application.

These results do not measure physical input-to-pixel latency, sustained five-minute
idle CPU or long-term shell stability. A standalone PySide6 host could isolate the
workspace but currently adds another lifecycle/deployment boundary without a
measured requirement. Reconsider after demonstrated shell interference or a rich
content requirement that specialist handoff cannot meet. No WebEngine is added.

Display titles and bounded plain-text preview blocks are derived presentation;
source paths/prose stay authoritative and unchanged. Cache version 5 rebuilds the
new titles. The collection worker reads at most sixteen explicitly selected,
registered managed vaults, emits owner references and bounded pages, and surfaces
partial unavailable storage rather than manufacturing empty progress.

Nonblocking cross-vault `references`, `supports`, `exercises` and `pursues` links
resolve explicit vault/record IDs after moves. Blocking contextual gates remain
rejected until their global deadlock semantics are accepted.

Primary references: [Quickshell FloatingWindow](https://quickshell.org/docs/v0.3.0/types/Quickshell/FloatingWindow/),
[Hyprland dispatcher implementation for 0.56.2](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/config/lua/bindings/LuaBindingsDispatchers.cpp),
[Qt FrameAnimation](https://doc.qt.io/qt-6/qml-qtquick-frameanimation.html).

## Versioned lesson material

A material-change activity replaces a lesson's effective source, not its UUID or
learner prose. It records a reason, previous source snapshot, previous locator and
expected study head. The new source begins queued with an unknown position and
total; it never inherits completion from the replaced material. Later study and
assessment events carry the resolved source owner/version and material revision.
Finalized attempts retain their start-time source snapshot. Blocking unfinished
attempts prevents silently switching their evidence to a different lesson source.

## Lesson context and readiness

Bounded lesson projections expose owning outline/module, contextual prerequisites,
assigned problems, their latest reported outcome/assistance and the next ordered
lesson. Modules organize material and do not enter consumption totals. Next-lesson
selection uses durable ordering beyond the first outline page. Relations with
foreign endpoint ownership never become local educational members.

Readiness is a learner-authored disposition on the specific prerequisite relationship,
with reason and originating lesson scope. It never changes the concept's competence
or erases attempts. Independent reported success alone does not clear a gate. The
learner may reopen readiness with a new disposition. Relationship creation now
accepts operation receipts and safely retries after interrupted publication.

Lab projections retain the original hypothesis, captured code snapshot, configuration,
latest comparison and referenced artifacts. Only bounded local PNG figures are
previewed; other media remain references. An execution receipt is evidence of a
recorded execution, not proof that a hypothesis or personal competence is established.

## Scoped understanding claims and investigations

Schema 2 remains unchanged. New optional `capability-decision` fields are `dimension`
(encountered/use/explain/derive/implement/predict-debug/transfer/retained), `scope`,
`confidence` (unknown/low/medium/high), `evidence_kind`, and explicit boolean `independent`.
`evidence_id` remains supported for local evidence; `evidence_refs` accepts one to eight
exact `{vault_id, record_id}` references resolved through authorized ownership. Evidence
is existing authored work or an activity, never another understanding decision.

`supersedes` names an earlier decision for exactly the same capability, criterion,
dimension and scope. Competing heads remain conflicts. Optional `resolves` must name
all current heads explicitly; time order never silently resolves disagreement. Read
models reduce the complete history before returning ten criteria per generation-bound
page. Legacy decisions remain readable without inventing missing dimensions.

Unaided accepted claims require a successful protected assessment and no recorded
exposure for that attempt. This validates the recorded provenance; it cannot observe
unreported outside help. Foreign evidence is attachable but foreign unaided provenance
is conservatively uncertified here. `retained_from` and `interval_days` require an
unwithdrawn, unconflicted earlier accepted scoped ability and actual later successful
assessment, rather than a planned check. Confidence does not replace evidence.

Investigation depth is an optional existing disposition `state.depth`, with quick,
normal, deep or research-grade values. Existing `parent_ref` and relationships carry
the motivation; concepts, questions, capabilities and specialist artifacts remain
their original record types. No derived score becomes authoritative state.

Machine-local `layouts["navigation-v1"]` stores at most 32 compact scoped entries
(owner, record, path, surface and view anchors), separate from learner notes and draft
authority. Reference visibility is revalidated against recorded assistance on restore.
