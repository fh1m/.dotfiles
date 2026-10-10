# Self-service learning from an empty vault

This slice adds one shared Start learning flow, not source-specific lessons or a second learning database. Open it from Today/the global toolbar, Ctrl+N, search or the Wrayth Noesis bar button. Paste a source, choose a file or Zotero item, or enter a question/topic. Choose its format and supply a title. Continue opens the existing record form; Save enters the existing working page. Manual metadata and unit creation are intentional; automatic transcripts, titles and outlines are unsupported.

## Native click paths actually exercised

Every Noesis learning record below was created using real native controls in an initially empty disposable managed vault. External test setup provided an empty vault, isolated Zotero source library, isolated Obsidian registry and Git/editor skeletons. It did not construct Noesis learning records. QtTest delivered actual clicks, scrolling, selector choices and clipboard/key input. All outcomes are agent validation examples, not owner achievements.

- Video: Start learning → paste lecture URL/title → Continue → Save → Set a reading place → Save reading place → Save study note → Edit complete note in Obsidian. Native Obsidian opened the exact owned note; the Noesis launcher returned to context.
- Documentation: Ctrl+N → URL/title → Documentation → Continue → Save → Ask a source-linked question. Start a concept, return to the question, Connect a deeper mechanism → optional deeper study → visit → Previous activity. The exact original question identity was recovered.
- Playlist: Start learning → Playlist → Save → Course options → Add lesson or chapter twice → Course outline → Arrange → select second lesson → move up → Done. Units were created/reordered through the UI, without manifests.
- Practice/code: Start learning → Practice problem → statement → Start independent attempt → reasoning → Outcome & assistance → explicit partial/agent outcome → Record attempt outcome → History & next steps → Connect implementation → Open code. Native Neovim opened the exact skeleton. Agent-authored code was saved and executed in that editor's terminal; five expected/output cases matched. Begin a run → prediction → Record comparison → Connect artifact retained actual output bytes and Git revision. No independent learner claim was made.
- Paper: Start learning → Choose from Zotero → select a real isolated native bibliography item → import → Research working page → Save place → Research actions → Ask a question → Learning options → Connect implementation. This source fixture has no attachment/annotations; the populated PDF/revision/restore harness is separate.
- Return: launcher `window --start` opened the same Start flow; an unavailable local PDF remained an owned record. Close/restart recovered the selected activity. A separate native check verified exact record identity, unfinished Start draft recovery, fullscreen, 200% scale and ScreenPad capture ownership.

## Visual inspection

The [gallery](ui-gallery.md) and [guide walkthrough](user-guide.md) retain actual native screenshots. Reading initially wasted a permanent pane when the source had no native preview; the corrected page collapses that pane and prioritizes notes/questions. Source reading stays in the authoritative browser/reader. Help uses the system's existing typography/theme, readable Markdown and native screenshot walkthroughs. No tooltips or new visual control system was introduced.

Normal and fullscreen captures, 200% application scale and the physical ScreenPad were inspected. Scale is distinct from Qt DPR. The instrumented frame p95 was 16.27 ms over 65 frames in the fixture; this is neither physical input latency nor a sustained performance certification.

Machine-readable evidence: [native acceptance](assets/self-service/acceptance.json), [layout/resume](assets/self-service/layout-acceptance.json), [actual outputs](assets/self-service/executed-outputs.json). Exact executed code/checker are retained next to the outputs. The source commit in these reports is the pre-commit base with dirty worktree explicitly recorded; deployment identity is recorded separately after commitment.

## Reliability and limits

145 core tests and 16 compatibility tests pass. All ten native shutdown scenarios pass, including draft debounce, mutation/import waiting, forced termination, failed save and uncertain receipts. The specialist shutdown handoff in that fault harness is explicitly simulated; real Obsidian/editor handoffs above are native. Scoped installation passes twice, rollback and later-edit protection; unrelated files remain intact.

Zotero startup/restoration is now fixed for the inspected installed build: [diagnosis and rollback](zotero-startup-evidence.md). Minimal-vault imports no longer require a legacy folder map, and unrelated duplicate source views no longer block a paper import. Ambiguity for the requested source still fails safely.

Vault creation/adoption and advanced recovery are not fully native self-service setup. Automatic source extraction is unsupported. Generic experiments run in existing tools, with explicit evidence attachment. Full PDF annotation selection, unavailable-source handoff diagnostics, long-term learner retention, broader P0–P8 fault/desktop gates and the owner's real usability trial remain open. Off-device configuration stays deferred. No plugins, new execution stack, cloud service or personal-vault migration was installed.
