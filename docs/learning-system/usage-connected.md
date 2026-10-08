# Connected Noesis usage

Open with Super+Ctrl+O or `noesis window`. Ctrl+1–6 selects Today, Learn,
Research, Practice, Lab and Library. Ctrl+K searches; Ctrl+Shift+N focuses capture.
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
outcome and evidence. Use a new attempt for an independent retry. Correlated hints,+references and agent help remain attached to that attempt even when the selected
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
`next --quiet` disables them. `context RECORD_UUID --role tutor|examiner|researcher|
reviewer|archivist` exports an explicit unverified agent context. Neither operation
awards capability. Suggested review intervals are policy conveniences, not a
validated competence scheduler.

CS, engineering, robotics and shared Knowledge remain separate. Never put private
vault content, app registration, reader databases or credentials in public dotfiles.
Local recovery is documented separately; off-device protection remains unfinished.
