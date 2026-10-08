# Connected Noesis usage

Open with Super+Ctrl+O or `noesis window`. Ctrl+1–6 selects Today, Learn,
Research, Practice, Lab and Library. Ctrl+K searches; Ctrl+Shift+N focuses capture. Ctrl+N creates the current
workspace’s resource, problem or experiment; Ctrl+Enter saves its dialog.
Drag the pane divider to adjust the list/context ratio. The previous UI remains
available from the window header. The ScreenPad companion appears for a selected
context; closing the main window stops its worker and filesystem watch.

Review and apply migration as described in migration-recovery.md before recording
activities in an existing vault. Use explicit `--vault PATH` for scripts. CLI
capture, paged queries, progress, finalized attempts and history do not need
Obsidian. Opening rich notes and readers uses the existing native tools.

```sh
noesis capture --vault PATH 'A thought; classification can wait'
noesis query --vault PATH 'estimator'
noesis record --vault PATH task 'Reconstruct the derivation' --body 'Assumptions and criterion'
noesis progress --vault PATH 'Resource.md' --position 'section 3, page 17' --current 17
noesis attempt --vault PATH 'Problem.md' --result failed --assistance none --evidence 'My counterexample and rejected model'
noesis timeline --vault PATH RECORD_UUID
noesis promote --vault PATH 'Inbox/capture.md' concept --target-id RECORD_UUID
```

`record` accepts optional JSON `--data` for useful fields, without requiring a
classification form for capture. `link SOURCE_UUID TARGET_UUID RELATION` connects
records; prerequisite links require `--role gate|parallel|deep-descent`. Optional
`--reason`, `--exit-task`, `--context` and `--order` describe their job.

Courses are resources; their lectures/readings are units; assignments are tasks;
projects remain separate. Connect resource→unit with contains, unit→task with
assigns, and paths→steps with orders. Consumption events never complete tasks.
An experiment can link an external artifact with produces, preserve its prediction
in the body, and record a comparison naming code/configuration, units and discrepancy.
Missing storage is reported as artifact unavailable; it does not delete knowledge.

In Practice, start an attempt, reconstruct, record any reveal, then finalize with
outcome and evidence. Use a new attempt for an independent retry. Correlated hints,
references and agent help remain attached to that attempt even when the selected
assistance label says none. Outside assistance must be declared; otherwise it is
unknown. Success remains a reported assessment, not automatically verified ability.

`event PATH EVENT --evidence TEXT --data JSON` records comparisons, assistance,
corrections, reviews, dispositions and explicit capability decisions. Corrections
name supersedes; they do not overwrite an attempt. A capability decision must name
actor=learner, criterion, evidence_id and decision=accept|reject|withdraw. Agents
may propose evidence, but may not execute learner decisions without authorization.

Study history conflicts need a resolution event naming all competing IDs in
resolves, the chosen previous ID, the resolved state and a learner explanation.
Both branches remain readable. `--operation-id UUID` makes activity retries
idempotent; changed content with the same operation ID is refused. `--target-id`
refuses a stale path that now belongs to another record.

`noesis next --vault PATH` explains suggestions. A disposition with state parked,
abandoned, retired, skipped, passed or complete suppresses applicable suggestions;
`next --quiet` disables them. `context RECORD_UUID --role tutor` (or examiner, researcher, reviewer, archivist) exports an explicit unverified agent context. Neither operation
awards capability. Review dates are learner-selected policy conveniences. The explicit Plan a check action uses configurable retry/later/maintenance defaults
of 1/7/30 days. Schedule, snooze and retirement create new records; they preserve
earlier attempts and plans. Multiple conflicting plans require explicit resolution.

CS, engineering, robotics and shared Knowledge remain separate. Never put private
vault content, app registration, reader databases or credentials in public dotfiles.
Local recovery is documented separately; off-device protection remains unfinished.


## Connected resource work

Today offers one Continue context and at most five explained suggestions. Select a
path and choose Use path for Today to scope suggestions. Quiet hides suggestions
without changing history. Read, Work, History and Connections separate the current
material from reasoning and its durable record. Details is optional (Ctrl+I).

Add a resource, then Add lesson / chapter or Add problem in its context. Child
records own their stable parent reference, so publication is one atomic Markdown
file. Ordered lessons are independent from assignment and project outcomes.
Lessons can have their own video URL; chapters can reuse their containing book's
PDF. Save place distinguishes page, section, exercise and timestamp. Paper reading
passes remain separate from reconstruction and reproduction.

From Zotero searches the supported local read API. Imports retain server identity,
native annotation IDs and source revisions; learner analysis is never replaced.
If the local API is unavailable, import-csl/import-notes remain supported. Noesis
does not write to the Zotero database. A single PDF attachment supports a Zotero
page handoff; multiple attachments require selection in Zotero. Sioyek pages and
YouTube timestamp links resume the explicitly saved location. Equations, diagrams,
editing and reader annotation use the specialist applications via Open note/source.

Quick capture accepts text immediately. Ctrl+Shift+N opens it; Ctrl+Enter saves.
Drafts remain machine-local, private and target-scoped; they are not finalized
learning history. Capture, record creation and activity operation receipts distinguish committed,
not committed and uncertain interruption outcomes. An unavailable committed record
requires inspection instead of blind recreation. Unfinished attempts recover their
identity after reopening, moves and cache rebuilds.

`artifact-check ARTIFACT_UUID` streams a checksum and records match, mismatch,
unverified or unavailable separately from the original prediction. Large data stays
external. `sensei-learning-backup --restore-reader SNAPSHOT --dest NEW_DIRECTORY`
verifies and restores saved reader databases into a new location; it never replaces
an active reader profile.


New vaults register their location with Noesis locally. `noesis vault-register PATH`
adds an existing location without changing Obsidian's registry. For a new folder,
use Obsidian's Open folder as vault when rich editing is needed. Capture, query and
history work beforehand. Existing native registrations continue to work.

Registered copies sharing a vault UUID block affected mutations and appear in
Doctor. Noesis never silently assigns a new identity. Explicit replacement/fork
support remains a release gate; an unregistered restore stays available for
read-only validation. Noesis no longer invokes a private Electron registration
bridge or edits Obsidian's registry as fallback.


Lecture viewed / Finished reading record consumption only. Pause reading parks
that context; Resume reading restores it. Library rows expose the derived state.
Pending work under parked owners is quiet, while shared work under an active owner
remains available. Counts describe the recorded outline, not an inferred complete
university syllabus or evidence of competence. Course context scrolls at compact
sizes instead of clipping its controls.

New problems keep an explicit Problem statement section separate from reference
solutions. Protected preview shows only that declared section; legacy explanations
stay hidden until a recorded reveal. Declared problem URLs open their source.
Search accepts exact DOI forms and stable record UUIDs as well as ordinary words.
