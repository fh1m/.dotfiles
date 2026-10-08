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
