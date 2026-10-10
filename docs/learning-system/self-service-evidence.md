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

Normal 1440×880 logical and fullscreen 1920×1080 captures, 200% application scale, Bangla/mathematical input and the physical 1920×550 ScreenPad were inspected at DPR 2. Scale is distinct from Qt DPR. The instrumented frame p95 was approximately 16.3 ms in the fixture (exact samples are retained in the layout report); this is neither physical input latency nor a sustained performance certification.

Machine-readable evidence: [native acceptance](assets/self-service/acceptance.json), [layout/resume](assets/self-service/layout-acceptance.json), [actual outputs](assets/self-service/executed-outputs.json). Exact executed code/checker are retained next to the outputs. The source commit in these reports is the pre-commit base with dirty worktree explicitly recorded; deployment identity is recorded separately after commitment.

## Reliability and limits

145 core tests and 16 compatibility tests pass. All ten native shutdown scenarios pass, including draft debounce, mutation/import waiting, forced termination, failed save and uncertain receipts. The specialist shutdown handoff in that fault harness is explicitly simulated; real Obsidian/editor handoffs above are native. Scoped installation passes twice, rollback and later-edit protection; unrelated files remain intact.

Zotero startup/restoration is now fixed for the inspected installed build: [diagnosis and rollback](zotero-startup-evidence.md). Minimal-vault imports no longer require a legacy folder map, and unrelated duplicate source views no longer block a paper import. Ambiguity for the requested source still fails safely.

Vault creation/adoption and advanced recovery are not fully native self-service setup. Automatic source extraction is unsupported. Generic experiments run in existing tools, with explicit evidence attachment. Full PDF annotation selection, long-term learner retention, broader P0–P8 fault/desktop gates and the owner's real usability trial remain open. Off-device configuration stays deferred. No plugins, new execution stack, cloud service or personal-vault migration was installed.

## Scoped live deployment

Initial source deployment: `c75153858fe5c176449db1272cc8e1c79f9113cc`, pushed to the feature branch. Backup manifest: `/home/fh1m/.local/state/noesis-deployments/20261010-201630-959159/manifest.json`. Twenty files changed; the only Wrayth replacements were ArchiveButton and NoesisBridge. The source was clean at deployment.

Production launch identified one registered `org.fh1m.Noesis` standalone window at `~/.config/quickshell/noesis`, using shared UI at `~/.local/share/sensei-learning/ui`. Hide stopped the worker; reopen retained the instance and selection; Close exited. The original Wrayth PID 2146193 remained alive. The configured Super+Ctrl+O route still opens/resumes the independent host; the reviewed and deployed bar route calls Start learning. The direct launcher Start request was exercised live. A physical bar click and the owner usability trial remain for the owner. Later guide-only changes are deployed through the same scoped installer; the exact current commit is available in installed `build.json` and the final report.

## Typography and reachable controls

The desktop initially had only Extended Zed Sans faces. Noesis now bundles the original [Zed Sans 1.2.0 release](https://github.com/zed-industries/zed-fonts/releases/tag/1.2.0) Regular/Bold/Italic/Bold Italic faces under SIL OFL 1.1, with source hashes and license retained in `ui/fonts`. This follows the owner’s requested typeface, rather than silently replacing it with Zed’s newer aliases. UI/reading text uses the shared family and scale tokens; code uses the existing Zed Mono Nerd Font Mono. Native Qt FontInfo confirms Regular, Bold and fixed-pitch Mono resolution. Disposable profiles preserve read-only access to desktop font directories, so screenshots no longer rely on fallback faces. The guide loads screenshot textures only while open, with bounded preview decoding.

Ctrl+K and Find anything previously tried to focus a hidden field on working pages. Both now open visible search; native search → Start learning passes. Start/Help/Zotero dialogs participate in the shared modal guard. All declared shared UI signals have handler connections; that static audit supplements, rather than replaces, the native journeys. Missing PDF handoff now has a retained screenshot proving an explicit error and preserved owner/record.

The final self-service fixture uses isolated Zotero API port 23129 and a test-owned adapter endpoint, allowing it to run alongside the owner’s unchanged running reader on 23119. Production adapter security/ownership contracts and default loopback endpoint remain unchanged. The installed default endpoint was verified separately against the real profile through GET-only reads.
