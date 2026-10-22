# Pen integration and learning audit — 23 October 2026

Goal: write, derive, diagram, annotate and reconstruct inside the same connected
learning history, using the XP-Pen without turning Noesis into another ink engine.
The user authorized implementation and a fresh research-backed audit.

## Discovered

- Native pen profiles/white Xournal++ scratch already exist in `sensei-draw` and
  `sensei/drawing.py`, with reconnect handling and drawable-area mapping.
- `drawing.learning()` creates Excalidraw, not a native pressure-aware notebook.
- Scratch attachment creates an unparented artifact in the active vault; editable
  files remain outside it. Returning to a particular lesson is indirect.
- Noesis already has stable UUID artifacts, typed parent references, operation
  receipts, recovery, Canvas/Excalidraw and external-tool handoff. Reuse them.
- PDF annotation belongs to Xournal++/Zotero, not a new QML renderer. The installed
  Xournal++ CLI supports saved journals and batch PDF export; a disposable probe
  confirmed same-directory background paths remain relative.

## Implementation choice

Extend the existing drawing artifact with native ink (`.xopp`), white plain/ruled/
graph paper and optional copied PDF background. Bind it to the selected record.
Keep editable ink, background and generated PDF together in its owned exploration
folder. Save resumes the same notebook. Derived preview refresh watches only the
explicit current journal, reusing the existing drawing watcher; no new service.
Preserve Canvas/Excalidraw. Do not require another Obsidian plugin or award learning
competence for producing ink. Ordinary handwritten notes stay free-form; optional
reconstruction prompts belong in the linked Markdown record, not compulsory forms.

## Milestones

1. **Source/research audit:** done when current paths and 32 fresh targeted query
   strings are recorded, primary references read, competing tools compared.
2. **Durable ink:** done when repeated creation preserves identity and strokes,
   notebooks/PDF backgrounds survive relocation, and failed export preserves the
   last preview. Add regression tests before deployment.
3. **Native entry:** done when Noesis creates/opens linked ink, the tablet helper
   resumes it, save refreshes its PDF and source/preview remain distinguishable.
4. **Verification:** run Noesis/drawing suites, disposable real Xournal++ export
   and native UI checks. Physical pressure/handwriting acceptance is separate.
5. **Audit handoff:** document current capabilities, verified gaps, learning-science
   implications and ranked next changes; commit reusable code/docs only.

## Preservation / rollback

No migration or bulk vault reorganization. New artifact format is additive. Test
in disposable vaults; no fake learner claims in real notes. Live files get a local
backup before targeted deployment; revert those files to undo integration. Existing
journals remain readable by Xournal++ and exported PDFs by ordinary readers.
Machine-local current-document state is ignored. User-authored content stays private.

## Verification status

- Research: 32 query strings recorded; evidence matrix distinguishes research,
  official documentation, engineering practice and practitioner anecdotes.
- Durable ink: identity retry/stroke preservation, relative paths, failed/raced
  export preservation and bounded backup policy covered by regression tests.
- Real native roundtrip: Xournal++ exported a journal, created a PDF-background
  journal and reopened it after vault relocation. Original PDF hash unchanged;
  fixture render visually inspected. No learner evidence claim created.
- Automated suites: Noesis 172, drawing helper 9, legacy learning 16 passed.
- Scoped installer: dry run and two disposable deployments passed.
- Headless dialog: native ink default, paper and PDF controls loaded; ScreenPad
  surface replaced only in disposable fixture. No physical handwriting claim.
- Runtime: Qt 6.12 compatibility port built successfully; running desktop retained.
  Keep the running desktop untouched; installer rollback preserves old files.
- Physical follow-up: user's earlier pressure check is not a fresh acceptance test
  of this new linked workflow. Test a real lesson/derivation when convenient.
- Homie: reachable, Qt 6.12; no active Noesis vault. Deploy reusable tools only,
  leaving private content authority and vault choice explicit.

## Deployment receipt

Committed as `2ddb2a5` and pushed to main. Scoped deployment completed on Arete and
Homie with per-machine rollback manifests under `~/.local/state/noesis-deployments/`.
Both drawing watchers are active. Arete doctor has no warnings. The Qt 6.12 native
runtime built successfully and was checked on Homie before activation; no desktop
or input-sharing restart was performed. Headless ink dialog and real Xournal++
PDF/relocation roundtrips passed on **both** machines. Homie still deliberately has
no active vault selected; disposable fixtures were used there.

Preview export runs in one bounded background worker so a slow export cannot block
tablet reconnect/mapping. Final drawing suite is 9 tests. The new notebook can be
physically checked when the user next writes; no unattended test can certify hand
comfort or actual learning outcomes.
