# Write where the learning happens

Select the concept, question, course unit, problem or experiment in Noesis.
Choose **Draw / Diagram → Pen notebook**, choose white/plain, ruled or graph paper,
and optionally select a PDF background. Create/open it in Xournal++.

Write freely. Saving refreshes a PDF preview through the existing drawing watcher;
**Refresh ink PDF** forces it, and **Read ink PDF** opens the preview. Reopening the
same record resumes its journal. The drawing helper's learning action uses native
ink; its ordinary scratchpad remains available for unstructured work.

The editable `.xopp`, optional `background.pdf`, and derived `preview.pdf` live
together under the vault's `Explorations/<operation UUID>/`. The Markdown artifact
links back to its origin. Moving the vault preserves relative background paths.
Original PDFs are untouched. Zotero annotations do not synchronize automatically.

For a useful learning loop: predict or derive on paper; check against a source or
small program; preserve the mistaken model; later reconstruct without looking.
Use Noesis' existing attempts/evidence/review actions to record the result. Merely
saving handwriting never awards competence.

CLI: `noesis drawing-create --help`, `noesis drawing-publish RECORD_ID`,
`noesis drawing-preview RECORD_ID`. Supply `--vault PATH` when outside the active
vault. Existing Canvas and Excalidraw modes remain available.

Backups include owned journals/backgrounds up to 64 MiB. Other large-file limits
remain unchanged. Keep an off-device copy: local snapshots do not survive disk
failure. Preview export failures preserve the last valid PDF; fix the journal or
background and retry. Xournal++ can always open the editable source independently.

Undo: use the scoped installer's recorded rollback manifest. New notebooks remain
ordinary files; no vault migration or content deletion is necessary.
