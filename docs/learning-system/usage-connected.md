# Connected Noesis usage

Open with Super+Ctrl+O or `noesis window`. Ctrl+1–6 selects Today, Learn,
Research, Practice, Lab and Library. Ctrl+K searches; Ctrl+Shift+N focuses capture. Ctrl+N creates the current
workspace’s resource, problem or experiment; Ctrl+Enter saves its dialog.
Drag the pane divider to adjust the list/context ratio. The previous UI is available only with the development option enabled. The ScreenPad companion appears for a selected
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


Research now keeps related questions and implementations in the reading context.
Actions (Ctrl+.) opens a keyboard list: arrows select, Enter acts, Escape dismisses.
Start implementation creates a connected project; an existing Git directory is
optional. Open implementation uses the existing terminal and Neovim. It does not
execute the repository's code. A run created under that implementation records the
observed commit, working-tree state and observation time; missing storage remains
explicitly unavailable. A dirty commit reference does not contain uncommitted edits.

Neovim launched this way keeps the initiating vault and record identity. Observation
and gold-snippet capture mappings connect their new records to that implementation,
even after the global active vault changes. Outside this handoff, the existing
active-vault behavior remains available. Container/environment profiles are still a
separate unfinished acceptance gate.

Compare prediction and observation starts with the run's original hypothesis.
Ctrl+Enter saves the comparison and its code snapshot. Questions, implementations,
runs and artifacts remain separate notes with durable relationships. Alt+Left and
Alt+Right return through working contexts without searching for filenames.

## Continue across learning vaults

On Today or Library, select **All learning vaults** (`Ctrl+Shift+K`). This is a
read scope across registered managed vaults, not a merged vault. Search results
and Continue show their origin. Opening a result selects its owning vault before
any work can be saved. Drafts stay keyed by vault and record. Select **This vault**
to return to a local view. Downloads and unmanaged directories are excluded.
Unavailable storage is reported; available registered vaults remain searchable.

Learn separates **Paths & courses**, **Concepts** and **Sources**. A course opens
its outline; a module opens its children. Individual lectures do not display empty
course statistics. The Library remains the flat universal search view.

## Import a course outline

In Learn choose **Import outline** (`Ctrl+Shift+O`). Enter the JSON file path,
review the expanded outline, then create it. Start from
[the example](examples/course-outline.json), replacing its titles and optional
source URLs. This example is an organizational scaffold, not an imported MIT
syllabus. Entries reference earlier parents by key. Up to 300 entries are supported.
Repeated imports of the same outline resume an interrupted publication without
creating another course. A changed file requires another review. No lecture
completion or independent success is manufactured during import.

## Window and document modes

The title-bar presentation selector offers **Workspace** (recommended maximized
study), **Tiled**, and **Window**. `Ctrl+Alt+M` cycles them. Normal geometry is
remembered separately. The ScreenPad companion remains a small context surface.
The legacy interface is available only with `NOESIS_DEVELOPMENT=1`.

Native previews provide bounded readable orientation, code and heading blocks.
They do not execute HTML or load remote images. Full equations, tables, images,
Canvas and diagrams open through **Open note** in Obsidian; source PDFs open in
Zotero/Sioyek through their supported handoffs. Source prose is never rewritten
for presentation. File paths remain available in Details.


## Course outlines and arranging lessons

In Learn, **New → Import a course outline** reviews a local outline before
publication. Select an existing course and press Ctrl+Shift+O (or use its empty
outline action) to add lessons to that course without replacing its note.
The review lists lessons, readings and assignments; repeating the same reviewed
import reuses their identities. A sample manifest is in examples/course-outline.json.

Choose **Arrange** on the course outline, select a lesson and use the arrow
buttons or Alt+Up/Down. Ctrl+Shift+R enters or leaves Arrange. Changes are immutable
activities; positions, attempts, original prose and source links stay intact.
Load more lessons (Ctrl+Shift+PageDown) appends another 50 rows. Module rows open
their own outline. Native tests cover a 123-lesson course, not just six items.

For scripts, use `noesis course-import --vault PATH FILE --apply --operation-id UUID
--expected-digest REVIEW_DIGEST --course-id EXISTING_UUID`. Omit course-id to create
a course. `noesis outline-move --vault PATH COURSE_UUID UNIT_UUID up|down
--operation-id UUID` uses the current durable history head and refuses stale edits.
Replacing material is a separate unfinished acceptance gate; rearranging does not
silently replace a source or erase old evidence.


After an independent successful problem attempt, open its contextual menu and
choose **Try a changed problem**. Write the new statement; Noesis creates a separate
problem linked to the original and selects transfer mode. Earlier assistance and
failures remain in the original history. **Plan a check** schedules a learner-chosen
later assessment; scheduling is not a claim that the assessment has been performed.
Use Ctrl+Enter to save the check dialog and Ctrl+Shift+Tab to move backward out of
the reasoning editor.

Inside an existing Distrobox environment, the Neovim capture integration uses the
host bridge and host Noesis configuration. An explicit NOESIS_VAULT still takes
precedence. A supported existing host-spawn is required; Noesis does not install it
automatically. Code provenance records the selected file's repository, and reports
uncommitted changes instead of presenting unrelated commits as evidence.


To answer a scheduled problem check, use **Perform planned check** in the contextual
menu. This starts a protected attempt linked to that specific plan. Write your
reconstruction before revealing references, then save the outcome and declared
assistance. A failed, partial or successful result fulfills the plan without claiming
competence; failures remain failures. Unknown or incomplete outcomes leave the
check pending. Choose another check deliberately when a retry is useful. Ordinary
practice does not fulfill a check just because it happened more recently.

## Replace a lesson and resume its reader

In a lecture or reading context, open the action menu and choose **Replace lesson
material**. Enter a source URL or existing local document and a short reason. The
lesson identity, notes, earlier positions and assessments remain intact; the new
material starts without a saved place. Finish an active attempt before replacing it.
Whole new book editions can be separate resources rather than replacing every unit.

Save a page, section or timestamp in Read. **Ctrl+Shift+Enter** opens the source at
the supported saved location. Workspace/normal mode hands focus to the reader and
hides Noesis; reopen it with Super+Ctrl+O or the companion Resume action. Tiled mode
keeps the study context beside the reader. **Hide** also preserves unfinished drafts.

Collection search considers matches across all selected authorized vaults. Each
result keeps its owning vault. If indexed material changes while paging, refresh
the search: the application refuses an obsolete page rather than silently skipping
or duplicating results. An unavailable vault is reported while fresh queries can
still show the available scopes.

## Study a lesson without losing the course

Open a course/module outline and select the current lesson. Its reading view shows
**Before this lesson**, **Exercises and assignments**, and **Next lesson**. Click a
row or use Ctrl+Alt+Down for the first prerequisite, Ctrl+Alt+Right for the first
assignment, Ctrl+Alt+Left to return to the owning outline, and Ctrl+Alt+Up for the
next lesson. Alt+Left returns to the previous context with its saved place intact.

Use **Connect a prerequisite** (Ctrl+Shift+P) to find existing material in the same
vault and explain its role. After working through it, **Ready to continue?**
(Ctrl+Alt+R for the first gate) records your explicit lesson-scoped readiness decision.
Successful attempts alone never clear this gate or award general competence.

In Work, Ctrl+Enter starts an attempt or saves its outcome; select outcome and
assistance explicitly. Ctrl+Tab leaves the reasoning editor for the controls.
Ctrl+Enter in a dialog saves that dialog. Reference exposure remains attached even
when you subsequently choose none. Ctrl+PageDown/PageUp scrolls the reading context.

Lab shows original prediction, captured commit/configuration, latest observation,
units, uncertainty, conclusion and next test. Data/figure rows open their artifact
context; local bounded PNG figures preview in place. Missing files retain their
references and histories. Open the implementation in the existing editor and run
your chosen code deliberately; Noesis does not execute imported code automatically.


## Supporting context on ScreenPad

Choose Source, Context or Figures and select **Keep here** before opening another
activity. The kept pane is read-only and labels its own activity and vault. Notes
always belong to the activity selected on the main page; their header names it.
Choosing Notes or Reference releases a kept context rather than redirecting edits.
Use **Follow active activity** to resume automatic following, **Refresh kept context**
after an external change, or **Open kept activity on main** to return to that exact
record. Kept identity and scroll anchors survive Hide and Close; restored anchors
are clamped to the available pane. The record content is fetched again, not stored
as a second document or draft.

Kept material is concealed during protected attempts and while the active activity
is being checked. It is unavailable when its owning vault is not active, the record
is missing, or ownership changes. Return to its owning vault before viewing it.
No same-name or same-UUID foreign record is substituted. **One pane** gives a larger
reading region; **Use ScreenPad for tools** releases the display for specialist apps.
