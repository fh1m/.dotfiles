# University and connected learning

Notion holds plans. Noesis holds reasoning, handwriting, attempts and evidence.
Course completion, earned credits and independent ability remain separate.

Open Noesis, then **Plan** for Academic/Explore planning or **Learn → University**
for the degree catalogue and academic ledger. The Noesis Notion workspace has
Goals/Paths, Terms, Course Enrollments, Tasks and Schedule with native relations.
Your actual enrollment, sections and results start unknown.

## Windows

`noesis window` raises the most recently used view.
`noesis window --new --monitor DP-1` creates another independent view.
Use New window and Move to display in the header. Drafts, selection and vault
belong to that window. Close saves its state; Hide keeps the current session.
Window files are machine-local, never part of the shared knowledge repository.

## Connect planning

Sign into Notion on each machine. In Notion, create a scoped internal connection
and share only the private Noesis root with it. In Noesis → Plan → Connection,
enter the root UUID and token. Do not paste the token into chat, shell history or
Git. The chat connector and unattended desktop API are separate authorizations.

Use Sync now to fetch remote plans and submit queued edits. Offline Save plan
persists an operation locally; it is not a confirmed remote write. Conflicts stay
pending until explicitly resolved. The adapter edits declared properties only;
page bodies and learner analysis are not overwritten. The API has no atomic
compare-and-set, so concurrent edits still require care. Native Notion view
customization remains available in its client.

## Academic facts

`noesis academic configure --vault /absolute/private/vault` chooses one owner by
stable vault identity. Register the matching replica on another machine; do not
create a second academic ledger. `noesis academic audit` reads that owner even
when a different subject is open.

Record attendance, enrollment, assessments, confirmed results and explicit
exceptions in University. Correcting attendance appends a new record for the
same course/date/session; it does not erase the prior event. Multiple classes on
one date need distinct session identifiers in the advanced form. Assessment
scenarios do not become official grades. Retake GPA policy remains unresolved
until supported by official records. Warnings are advisory, with preserved
reasons for overrides.

The bundled UIU catalogue applies Summer 2026 onward. It contains 122 courses
and 141 required degree credits including elective baskets. Its indexed official
source and unresolved prerequisite discrepancies are recorded alongside it.
Descriptions are not completely reconciled; do not treat a linked source as an
imported description. The active Fall 2026 calendar contains only independently confirmed registration
and class-start dates. Seven previously indexed archive entries were withdrawn
from the agenda and retained for review; exam/installment dates are not guessed.

## Agenda, sources and recovery

`noesis academic sources` reports staged source checks; daily refresh never
silently changes accepted academic rules or dates. `noesis academic refresh`
checks official pages on demand. `noesis academic calendar-export --output PATH`
exports accepted dates. Import with `sensei-calendar import PATH`; identical UIDs
update with history rather than duplicating. Unsupported single-occurrence
recurrence edits are rejected rather than cancelling a whole series.

`noesis replica status` shows existing Syncthing replicas and conflicts.
`noesis replica protect --folder-id ID` preserves existing ignores and adds
exclusions for volatile state and plugin data. Conflict copies remain on disk;
normal indexing excludes them to avoid duplicated identities. Resolve them by
comparing both originals. Sync and staggered versions are not independent backup.
Use the existing learning backup and restore workflow for recoverable snapshots.
Tokens and window state remain machine-local. Notion export does not recreate
all workspace relations; keep metadata and integration configuration separately.

## Rollback and current limits

Scoped deployments save manifests under `~/.local/state/noesis-deployments/`.
`python scripts/install-noesis.py --rollback MANIFEST --apply` restores only files
that still match the deployed hashes; later edits block rollback for safety.
Private profile backups are outside Git. Closing Noesis is sufficient for its UI
upgrade; a full desktop restart is unnecessary.

See UNIVERSITY-PLAN.md for behavioral evidence and outstanding acceptance gates.
Live Notion round trips require the scoped connection; no generated activity,
completed lecture or AI-written answer awards competence.


A chat-connector snapshot may be available before desktop authorization. It is
explicitly dated and read-only: clicking its record opens Notion. It does not
update automatically, and it cannot acknowledge queued edits. Enter the scoped
connection for normal desktop round trips; API sync replaces the snapshot with
its own fetched records. Connector credentials never leave the connected tool.
