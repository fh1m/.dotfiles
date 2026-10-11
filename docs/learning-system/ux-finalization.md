# UX finalization — first implementation slice

Baseline: clean source and installed build `a7928c9cd11cd560466f9a21423f1226d9e22f85`; all 89 installed manifest hashes matched. Noesis was closed; Wrayth was independently running. This report covers the first reviewable slice of the approved four-milestone plan, not the entire UX release.

## Delivered behavior

- Ordinary bar, desktop and keyboard entry resume work. The bar has explicit Start learning / Quick capture actions in a Quickshell popup with keyboard focus, Escape and outside dismissal. Qt popup-window experiments were rejected after native visual inspection; no such implementation is deployed.
- Repeated Open no longer refreshes and reconstructs an already visible working context. Native checks retain the current editor focus and an unfinished creation sheet.
- Manual Hide flushes drafts and hides both study surfaces. Specialist handoff retains its distinct, existing ScreenPad behavior.
- Reading has a persistent activity title and one task-action row. Source preview and learner notes share the working area; drawing/code/Obsidian/context actions remain wired. The old Work, history, connections and priority actions remain accessible in Learning options.
- ScreenPad does not automatically switch main Practice to reasoning-only. Practice retains its title at increased scale. A reproduced editor implicit-width binding loop was corrected locally.

No record schema, learning semantics, source authority or backend mutation contract changed. No private vault was modified by acceptance.

## Reproduced native workflows

`scripts/check-noesis-ux-entry.py` creates an ordinary documentation source through Start learning → Continue → Save in a disposable owner. It types a reading draft; reopens while editing; opens another Start learning sheet and reopens again; preserves the sheet; dismisses it; creates a linked question; returns with Alt+Left; hides; resumes; closes; restarts; verifies the exact source/owner and original draft. It captures fullscreen 100%, fullscreen 200% and normal 150% states. Its JSON distinguishes agent validation from learner achievement.

`scripts/check-noesis-bar-entry.py` runs the actual ArchiveButton and NoesisBridge in an isolated shell. It verifies ordinary Open and repeated Open use one application window/process, then activates Start learning and Capture through native keyboard input. Native popup contents are captured separately and visually inspected. This does not claim that the personal bar was clicked or that the owner has tested it.

The drawing, code and Obsidian commands retain their existing operations. Genuine external-tool round trips were not rerun by these two checks; their prior evidence remains in core-learning-evidence.md. The shutdown suite labels its handoff simulation explicitly.

## Evidence and checks

- 165 core tests and 16 compatibility tests passed.
- Scoped installation checks passed: dry run, repeated installation, rollback, later-edit protection and preservation of unrelated files.
- All ten native shutdown/recovery checks passed, including unfinished draft debounce, pending mutation/import, failed preference saving, forced termination and uncertain receipts: [shutdown-acceptance.json](assets/ux-finalization/shutdown-acceptance.json).
- Native entry evidence: [entry-acceptance.json](assets/ux-finalization/entry-acceptance.json).
- Native bar evidence: [bar-acceptance.json](assets/ux-finalization/bar-acceptance.json).
- Same-content reading before/after and additional native scale captures: [gallery](ui-gallery.md).

Logical sizes, application text scales and Qt DPR are separate. No new physical input-latency or educational-effectiveness result is claimed.

## Next checkpoints

The early owner trial is pending: 30 minutes with an unfamiliar source, without coached shortcuts. Observe discovering actions, source/reasoning visibility, question creation, tool return, ScreenPad usefulness and time spent managing the interface. Owner feedback should change the remaining design before it spreads across every workspace.

M1's broader shared navigation/context-menu work remains. M2 shared controls/Settings/Help; M3 Course, Research, Frontier, Lab, Today, Library, media and full-history filtering; and M4 sustained/native matrix acceptance remain open. Existing P0–P8 hardening is preserved; physical ScreenPad unplug and owner review remain explicit gates. Off-device configuration stays deferred.
