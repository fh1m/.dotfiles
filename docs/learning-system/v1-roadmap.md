# Noesis V1 — revised decision-ready roadmap

Status: approved for implementation by the owner on 2026-10-09. Revised 2026-10-09 following owner review. This document supersedes the V1 execution sequence; the existing data model, safety contracts and evidence ledger remain authoritative.

## Release boundary and evidence

Continue from `aca05d1`. Markdown learning records, stable IDs, existing histories, local encrypted backups, rebuildable indexes and prior native acceptance remain the foundation. V1 changes application hosting, composition and continuity. No backend rewrite, private-vault relocation, automatic competence awards or untrusted project execution is included.

The earlier audit reported 107 core tests and 16 compatibility tests passing. The 107 core tests were rerun successfully during this session. Existing prototype timings establish feasibility only: 1.11s cold launch, 144ms warm-open p95, 17.30ms animation-frame p95 and roughly 190MiB RSS. PSS, sustained use, physical input latency and educational effectiveness are unproven. Zotero restored native startup remains an unresolved release gate.

Implementation began before the owner's revised instruction arrived. Uncommitted host extraction, launcher, bridge and layout experiments exist only in the feature worktree. No live desktop or personal vault deployment occurred. The rendered disposable host failed QML import validation. These changes are unaccepted experiments and must not become the parity baseline. After approval, preserve them separately and reconstruct the sequence below from the reviewed baseline. The owner has now authorized resumption; the reviewed baseline is restored and prior experiments are retained separately.

Configured off-device backup remains **Deferred by owner — Post-V1 infrastructure priority**. Its absence is an explicit limitation, not a V1 configuration task.

## Architecture decision

Use an independent Quickshell application for V1. Retain the embedded Wrayth host as a selectable rollback. PySide6 remains a post-V1 alternative; no new runtime dependency or WebEngine is introduced.

Keep one maintained Noesis UI module under `sensei-learning/ui`, with compatibility wrappers at existing Wrayth locations. The standalone process receives only its learning controller, UI tokens and necessary Qt/Quickshell adapters. It does not import Wrayth's service graph. Establish unchanged functional behavior before changing composition or styling.

Quickshell documents distinct [AppId and ShellId pragmas](https://quickshell.org/docs/v0.3.0/guide/advanced/): AppId supplies application identity; ShellId identifies the configuration across paths. Neither replaces an explicit launcher/IPC protocol.

## M1 — prove independence before redesign

Each substep has a separate reviewable change, test evidence and rollback checkpoint. Passing one gate authorizes the next within the approved implementation scope; no broad live installation occurs.

| Step | Deliverable | Exit gate |
|---|---|---|
| M1a: dependency audit | Inventory every imported module, singleton reference, child process, file watch, timer and IPC handler from `aca05d1`; record its proposed owner and transitive dependencies | No unexplained Wrayth dependencies; import closure loads in an isolated rendered installation |
| M1b: unchanged-UI host | Stable standalone entry; existing layouts, controls, drafts, actions and learning behavior run under independent identity | Same fixtures/actions as embedded baseline; no unresolved QML warnings; host failure leaves Wrayth healthy; parity screenshots |
| M1c: controller boundary | Extract application state and adapters; retain backend protocol and receipts; distinguish visibility, mutations, persistence and exit | Exact owner/target requests, stale-response rejection, draft preservation and shutdown fault cases pass |
| M1d: desktop integration | Single-instance launcher; Wrayth bridge/ScreenPad; configurable placement; desktop registration; scoped specialist return | Concurrent launch, stale projection, unavailable monitor, both restart directions and both placement modes pass |
| M1e: rollback/install checkpoint | Scoped replacement backups and explicit host selection; two temporary-home installations; documented rollback | Only one learning host active; rollback restores routing/UI without deleting records; repeated installation is idempotent |
| M1f: UX foundation | Versioned scales/layout preferences, corrected shared tokens, control variants and adaptive shell | Compact and scaled foundation passes inspection; no learning-surface redesign starts before M1b–e pass |

A failed host/parity gate stops dependent integration and redesign. Performance regressions are investigated before accepting the boundary.

## Dependency inventory and component ownership

This inventory comes from the baseline source, not the unaccepted extraction. M1a must expand broad imports into an exact symbol/transitive-import manifest and validate it against native loading.

| Existing dependency | Current location/responsibility | V1 owner and boundary |
|---|---|---|
| `Oasis` state, active vault, section, collection/path scope, selected context, geometry, quiet mode | `services/Oasis.qml`; workspace, dialogs, window and companion call it | Application controller owns durable preference/context state; page owns transient selection/display state; bridge receives bounded projection only |
| `Oasis` drafts and preference-save timer/process | Controller writes `window.json`; workspace owns editor/capture debounce | Controller owns serialized persistence queue; pages submit owner/record keyed snapshots; bridge never receives drafts |
| `Oasis` operation, receipt, cancel, operation IDs and result signals | Controller's mutation `Process` and receipt lookup | Application mutation coordinator owns lifecycle and retained operation scope; backend owns authority and commit receipts |
| `Oasis` status snapshot, preview reader and legacy watcher | Controller processes and refresh debounce | Application query adapter; preserve compatibility initially, then avoid duplicated index/watch activity; no shell ownership |
| NDJSON worker, filesystem watcher, reconcile/search/draft timers | `NoesisWorkspace.qml` | Application query/watch adapter owns lifecycle; page consumes bounded results and rejects stale generations; workers stop on Hide |
| Zotero search process and stale-query checks | `NoesisZoteroDialog.qml` | Application reader adapter, scoped to dialog request and owner; import remains explicit mutation |
| Compositor client lookup, mode dispatch/check/retry, geometry writer | `NoesisWindow.qml` | Window/compositor adapter; all persistence routed through the controller's serialized queue |
| Config/frontier/preferences `FileView` | `Oasis.qml` | Application config/persistence adapter; learning watches disabled while hidden; cheap machine-local config watch only where necessary |
| `ShellState.dropdown`, bar actions and `Ipc.qml` dropdown routing | Wrayth shell/service graph | Wrayth bridge translates launch/capture/resume; standalone has no `ShellState` import |
| `Theme.widget*` | Window chrome and `NoesisStyle`; legacy dropdown | Narrow Noesis token source; freeze baseline values for parity; correct tokens only after hosting gates |
| `Appearance.font.data`, `Appearance.duration.state` | `NoesisStyle` | Explicit Noesis font/motion settings; no appearance singleton graph copied into standalone |
| `qs.config`, `qs.services`, `qs.components` imports | Learning components/window/workspace/dialogs and legacy dropdown | Replace with explicit learning-only module imports; resolve every symbol. Keep legacy dropdown/chamfer shell dependencies confined to rollback |
| `noesis`, `oasis`, `noesis-window`, `noesis-companion` IPC | Controller/window/companion | Versioned app control; temporary old-name forwarding in bridge; diagnostic endpoints expose bounded state and omit drafts |
| Screens, window modes, `Quickshell.execDetached` handoffs | Window, companion and action adapters | Application/window adapter owns main window; Wrayth owns companion placement; tools retain their own windows/lifecycles |

Backend owns Markdown, indexes, managed-vault authorization, identity resolution, locks, imports and receipts. Specialist tools own original PDFs, bibliography/annotations, rich editing and code execution. UI presentation never becomes learning authority.

## Process identity, coordination and IPC contract

Production AppId: `org.fh1m.Noesis`. Production ShellId: `org.fh1m.Noesis`, explicit and stable. Entry: `$XDG_CONFIG_HOME/quickshell/noesis/shell.qml`. Desktop file and icon use `org.fh1m.Noesis`; native compositor identity and portal registration must be verified on the installed runtime. Disposable tests use distinct ShellIds/AppIds/runtime locations, so they cannot target production by accident.

The launcher resolves one canonical config path and targets IPC by that path. It serializes launch attempts using a machine-local lock and also uses Quickshell duplicate prevention. Discover readiness through a versioned handshake; process ID alone is insufficient. An instance token and PID/start identity distinguish restarts and PID reuse. Concurrent launches focus the existing instance; startup races await readiness without repeating accepted requests. A timeout reports diagnostics rather than spawning another host. Incompatible protocol reports a visible error and never kills a process to force an upgrade.

Proposed control protocol v1:

| Operation | Contract |
|---|---|
| `hello` / `status` | Protocol version, instance token, process identity, visibility, pending-write state and accepted request status; bounded output, no learning bodies or drafts |
| `open` / `resume` | Envelope with version, request UUID, exact owner `{vault_id, registered_location}`, optional `record_id`, requested surface and navigation anchor; resolve stable identity against authorized managed collection |
| `capture` | Same owner envelope; optional related record identity; open a draft and acknowledge readiness. Never save or submit capture merely because it was requested |
| `hide` | Preserve context/drafts; stop learning worker/watch; let existing mutation finish under its original owner |
| `exit` | Begin graceful shutdown; report pending/saved/uncertain/failed states; never imply acceptance means process exit or durable mutation completion |
| `close` | Compatibility alias for Hide; existing shell callers retain context. The visible Close button and window-manager close use graceful `exit` behavior |

Request acknowledgement distinguishes received, ready, rejected and uncertain. Request UUIDs are deduplicated within the instance; a lost acknowledgement across restart prompts inspection rather than silent replay. Launcher commands cannot run arbitrary backend mutations. Paths/titles are locators, never substitutes for stable ownership. Owner/path disagreement, unavailable owner, identity collision and unauthorized vaults fail explicitly; there is no fallback to the current vault.

Companion projection v1 contains version, publisher instance/start identity, update timestamp, visibility, owner reference, record ID, bounded title, surface and resume anchor. Store atomically in a permission-restricted directory/file (0700/0600). It contains no body, draft, history or mutation authority. Unsupported versions/malformed state clear the display. Publisher liveness and instance handshake validate projected context; timestamps alone do not establish liveness. On stale state or absent app, offer neutral Open rather than a misleading active session. Wrayth performs no learning indexing and routes all capture/resume requests through the launcher.

Tests cover Wrayth restarting while Noesis remains active, Noesis restarting while Wrayth survives, projection recovery, launch contention, readiness failure, PID reuse/stale files, unknown versions and exact owner handoffs. Restart tests use disposable shell instances first; any live shell restart requires separately scoped execution authorization.

## Placement, Hide, Close and recovery

Placement preference is explicit: current workspace or configured dedicated workspace. Initial setup offers both, with dedicated `Noesis` as the suggested choice. The owner selected dedicated Noesis as the default during implementation; current-workspace placement remains available. Configure workspace name and preferred main display; use available-display fallback. Remember Workspace/maximized, Window or Tiled presentation independently. Focusing an existing instance brings the user to that instance's workspace rather than silently relocating it. Explicit placement changes affect Noesis only. Existing Zotero, Obsidian, terminals and browsers are never forcibly moved.

Hide snapshots navigation and drafts, flushes pending draft debounce, hides the window and stops query/watch activity. It preserves the process and learning context; an outstanding mutation continues with its retained owner. Failed persistence remains visible on return.

Close intercepts both application and window-manager close. Capture the latest editor/capture state, drain debounce and the serialized preference queue, stop new mutations, then wait for active mutation/import/handoff completion and receipt resolution. Import preview itself can stop safely; a committing import cannot be blindly cancelled/retried. Show what is pending and allow returning to the application. Uncertain commit status blocks ordinary exit until inspected or explicitly acknowledged; preserve the operation reference for restart. Failed save keeps input and the application open.

Specialist handoff flushes the return context/draft before launch. It may hide according to explicit preference, but never converts a successful handoff into an implicit destructive close.

Forced termination/power loss is a recovery test. Recover the last acknowledged durable draft/preferences and inspect pending operation receipts. Clearly disclose the possible loss of text still within the autosave debounce; do not claim graceful-shutdown guarantees apply to abrupt termination. No speculative new recovery architecture is added unless the tests expose a specific safety defect.

Required shutdown cases: draft debounce, concurrent preference/geometry save, active mutation, committing import, uncertain receipt, unavailable storage, specialist handoff, forced termination and restart. Test with disposable fixtures and fault injection.

## M2 — sequential product slices

M2a completes Course + Practice. Courses expose expandable modules, current lesson, edition-specific source/place, prerequisite readiness and separate independent assessment. While studying, course navigation replaces the generic collection list. Practice presents independently scrollable statement and reasoning beside each other where usable; compact layouts stack both with accessible scroll. Label active attempt, exposure and assistance; keep previous evidence reachable through bounded pagination.

Inspect full, normal, compact, tiled and scaled states using the same realistic fixtures before accepting M2a. Validate controls, focus, task discovery and protected-reference behavior. Resolve serious defects before reusing the composition patterns.

Then implement M2b Research, M2c Lab and M2d Today/Library in order. Research promotes bibliography, purpose/pass/place, annotations, questions and reconstruction; Lab promotes prediction, code/configuration, measurement, discrepancy and artifacts; Today promotes exact resumption, a few active paths and explained next actions. Library retains searchable, owner-labelled collection navigation. History/connections become contextual sections. Reuse the same shared controls and validated patterns; no six-way parallel redesign.

Add only bounded history/annotation pagination and missing owned projections required by these slices. Preserve old evidence, generations, owner checks and existing callers. No final-50-only inaccessible history. Derived-index changes remain rebuildable.

## UI design and acceptance

Retain dark surfaces/pink identity and the planned type/spacing defaults: 28px title, 22px heading, 18px section, 17px reading, 15px UI, 14px controls and 13px metadata; 40px controls; expanding rows of at least 64px; 4/8/12/16/24/32 spacing. Reading uses proportional Adwaita Sans, approximately 1.5 line spacing and 60–85 characters; retain code font and verify installed Bengali fallback. Interface and reading scales are independent, 100–200%, without multiplying Qt device-pixel scaling twice.

Use SplitView with task-specific persisted/clamped sizes. Wide layouts allow collapsible navigation and a 280–360px inspector; medium/compact layouts use drawers or overlays. Focus preserves visible navigation escape. At larger text scales reflow controls into wrapping toolbars/overflow menus, collapse supporting panes and scroll bounded dialogs. Never shrink text or clip primary actions to make space.

Shared Primary/Secondary/Tertiary/Danger buttons distinguish actions through labels, structure and state as well as color. Fields have persistent labels, accessible names and retained failed input. Dialogs are viewport-bounded and scrollable with reachable submission. Important titles wrap; selectors expose readable full labels. Every shortcut has a mouse equivalent. Escape dismisses the top layer; Tab order is predictable; reasoning retains indentation with visible editor-exit guidance.

Contrast targets: 4.5:1 ordinary text, 3:1 large text and meaningful boundaries/focus indicators. Test actual composited normal, hover, pressed, focus, selected, disabled, error and busy states; disabled content remains legible but clearly inactive. Candidate tokens remain muted `#9b938a`, boundary `#807870`, error `#ff8585`, dark selected ink. These values require verification, not assumed compliance.

Matrix: Today, long course, long-title annotated paper, math preview/handoff, protected problem, long history, measured Lab, large Library, validation-error dialog and compact/tiled states. Sizes: 1920×1080 logical, about 1440×880, 1000×650 and tiled widths. Scales: 100/125/150/200%; record Qt DPR separately. Inspect action reachability, glyphs, collisions, complete labels, focus, empty/loading/error states and retained scroll/selection/drafts. Capture matched-content before/after images. Automated checks and screenshots are evidence of behavior/layout only.

## M3 — complete journeys

Complete Course source → saved place → prerequisite assessment → assignment → next lesson → restart; Research paper/annotation → reconstruction → authored implementation → bounded executed verification → paper return; Lab prediction → code/configuration/data/units/figure → comparison → next test; and Today continuity across authorized owners. Add validated source-annotation handoff, supported nonblocking cross-vault picker, editor/artifact return context and durable manual Today pins/priorities. No copying concepts or introducing global blocking policy.

Journeys A–F from release acceptance remain mandatory: first principles, university learning, research, engineering, daily continuity and desktop lifecycle. Use disposable mutation fixtures; inspect personal material read-only. Unavailable storage/artifacts/readers stay explicit and interruptions recover without CLI repair.

## Bounded Zotero diagnosis

Begin one bounded diagnostic pass after approval alongside M1a–b. Controls: unchanged-data restart, direct-copy restart and restored-copy restart, using isolated profiles and only test-owned processes. Record actual process tree/exit, preferences/profile locks, database integrity/schema/version, attachment paths, API errors and native reader behavior. Preserve sanitized diagnostics outside temporary cleanup. Do not increase timeouts without evidence.

Allocate one initial diagnostic pass and one evidence-led repair/retest pass before returning attention to product slices. Carry unresolved results openly into M4. If evidence indicates an unsafe or upstream limitation, document a recoverable manual procedure: preserve original profile/data, restore into a separate directory, select it through Zotero's native profile/data-directory configuration, verify annotation/page/PDF state and return to Noesis. Never kill/repurpose personal Zotero or edit its live database. The fallback is accepted only if demonstrated on disposable restored data. Opening the PDF alone does not satisfy restored native annotation/state acceptance. An unresolved critical restore gate prevents a full V1 reliability claim; only the owner may explicitly accept a limited release.

## M4 — reliability and learner acceptance

Finish local publication/receipt interruption, unavailable/reappearing storage, conflicts, restoration, installation and sustained lifecycle acceptance. Retain the existing query/capture/page/rebuild budgets; measure independent-host launch, frame timing, five-minute idle CPU, RSS and PSS across repeated cycles and a sustained session. Keep instrumented frame timing separate from physical input latency.

Reserve a **20–30-minute real learner trial with the owner** before release. Use approved material and no fabricated achievements. Begin with research at the owner’s preference, but acceptance still covers courses, practice, engineering experiments and continuity; trial order does not narrow product scope. Observe discovering primary actions, simultaneous source/reasoning access, prerequisite navigation, returning from tools, lost context, readability, button distinctions, menu complexity and time spent managing the interface. Record task completion, hesitations, detours, action counts and owner comments separately from automated evidence. The observer may clarify tasks but should not teach hidden shortcuts to conceal discoverability defects.

Owner feedback is release feedback. Resolve critical navigation/readability/action-loss defects and retest affected tasks. Lesser issues require explicit disposition. Educational effectiveness remains unproven by a brief usability trial.

Reconcile PLAN, release acceptance, validation, visual specification and usage guide into one current burn-down. Report implemented behavior, automated tests, native/visual inspection, owner trial and remaining limitations separately.

## Rollout and execution order

After explicit approval: preserve unaccepted experiments; return to reviewed parity baseline; M1a → M1b → M1c → M1d → M1e → M1f → M2a Course + Practice → inspect/fix → Research → Lab → Today/Library → M3 integrated journeys → M4 recovery/desktop/performance → owner trial/fixes → release review. Zotero diagnosis stays bounded alongside early hosting work and closes at M4.

Every milestone has a scoped backup, known rollback point and evidence ledger. Deploy only reviewed Noesis/UI/bridge/launcher/registration files. Host switch waits for pending writes, disables the other host and verifies one active host. Rollback restores host routing/UI/preferences with explicit preference-version handling; never deletes newly created learning records. No wholesale live installer, unrelated dotfiles overwrite, destructive migration or force-push is authorized.

V1 completion requires journey, recovery, accessibility and learner-trial gates. Off-device setup, PySide6, MLflow/DVC, semantic recommendations, advanced repetition, replacement PDF/rich editors and inferred competence remain outside this release.
