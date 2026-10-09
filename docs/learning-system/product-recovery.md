# Noesis product recovery: Course and Practice slice

## Deployment truth

The sprint began with the everyday launcher, ScreenPad button and Super+Ctrl+O
opening the aca05d1 embedded UI in Wrayth. Its process was PID 2146193 and its
config was `~/.config/quickshell/wrayth/shell.qml`. The standalone host and
production desktop registration were absent. Pushing feee017 had not deployed it.
The scoped deployed files matched the older rendered source; they were not newer
local modifications. This explains the unchanged everyday appearance.

## Implemented product changes

Opening an activity gives it the working area. The collection is an explicit
return destination, preserving its selection/search/scroll, rather than a
permanent competing pane. Library opening routes supported objects to Learn,
Research, Practice or Lab. Course now has its own composition: expandable modules,
lessons, honest consumption progress, objective/source, prerequisites, assignments,
local reasoning draft, saved reading place and next lesson. Wide lessons retain
outline and work together; compact lessons disclose outline/context explicitly.

Practice uses independently scrolling statement/reasoning panes when they fit.
Compact Practice switches between these retained surfaces; attempt context and
reference reveal remain reachable. History and other operations are supporting
context. Outcome recording remains the existing protected, receipt-backed workflow.

Zed Sans is the requested UI/prose family ([original Zed font source](https://github.com/zed-industries/zed-fonts)); ZedMono Nerd Font Mono is the installed
Zed Mono family for code. Disposable font configuration includes the real installed
font directory. Bengali and mathematical fallback fonts are installed. Colors
match Wrayth's warm dark surfaces and pink identity. Routine buttons/fields/editor
surfaces no longer have a rectangle outline. Text uses explicit native glyph
rendering and full hinting; UI rows follow the interface scale independently of
reading prose. There are no tooltips. Back/Forward/Refresh have visible names,
and compact navigation explains its destinations. Tonal regions, raised action fills, bold selection, keyboard-focus underlines
and hover/pressed states distinguish controls without surrounding everything
with borders. Focused inputs retain a narrow accent marker.

## Responsibilities and preservation

The application controller owns host coordination, receipts and machine-local
preferences/drafts; Wrayth owns its launcher and bounded companion projection.
Workspace remains the data/navigation adapter and still contains substantial
shared state; it has not been fully decomposed. CourseStudio owns course/lesson
composition, PracticePage owns thinking layout, shared controls own affordances.
Existing worker/backend record and ownership contracts remain authoritative.
Course restoration adds machine-local context only; no vault schema migration.

## Native evidence

The screenshots below are **actual Qt Quick native window-content renders** of
synthetic disposable fixtures. They exclude unrelated compositor layers and
private desktop/vault content. They are not generated mockups or evidence of
human educational effectiveness. Baselines use feee017 QML with the same fixture.

| Experience | Before | After |
|---|---|---|
| Course overview | [Baseline](assets/recovery-sprint/course-before.png) | [Working course](assets/recovery-sprint/course-after.png) |
| Active lesson | [Baseline](assets/recovery-sprint/lesson-before.png) | [Objective, source and notes](assets/recovery-sprint/lesson-after.png) |
| Independent Practice | [Baseline](assets/recovery-sprint/practice-before.png) | [Statement and thinking](assets/recovery-sprint/practice-after.png) |

Supporting surfaces are retained for honest review, **not claimed as completed
redesigns**: [Research](assets/recovery-sprint/research-current.png),
[Lab](assets/recovery-sprint/lab-current.png), [Today](assets/recovery-sprint/today-current.png).
The dual-screen Lab fixture adds an explicitly illustrative synthetic curve and
an unavailable artifact. It does not establish a measured engineering result.

`capture-after.json` records logical size, Qt DPR, application scales and window
presentation for every capture. The owner's latest decision makes a full-screen
Study workspace the primary review environment: 1920x1080 logical at
100/125/150/200% application scales, with Qt DPR recorded separately. One compact
200% recovery check retains reachable statement/reasoning and attempt actions.
Earlier broader size matrices remain in Git history; they are not the current
acceptance focus. Full-screen is Qt's actual window state, independently checked
against the compositor, rather than a maximized-window label.

Study appears between Code and Sim with a book glyph. Following the owner's
numbering correction, the order is Terminal 1, Web 2, Code 3, Study 4, Sim 5,
Work 6 and Misc 7. Super+4 opens
Study; Super+Ctrl+O launches/resumes Noesis there. Other tools' existing windows
are never relocated. Full screen is the default; normal, maximized and tiled
presentation remain explicit options.
Native pointer input expands a module and opens its lesson. Native keyboard input
edits notes. Tests verify outline return, Hide/reopen and Close/restart preserve
the exact lesson, draft, parent course and expanded module. Checks also prove
four concurrent launches use one instance, reject wrong owners, preserve private
projection permissions, exclude embedded/standalone writable hosts, and isolate
Wrayth/Noesis restarts. Scoped installation is idempotent; rollback refuses later
edits and preserves unrelated files. 130 core/compatibility tests pass. Ten lifecycle
fault cases passed during this slice, including debounce, pending mutation/import,
failed save and forced termination; handoff delay in that suite is simulated.

Actual fill/token contrast: ordinary ink on working surface 14.52:1; secondary on
raised fill 6.79:1; disabled quiet text 5.66:1; selected pink on raised fill 4.63:1;
dark primary text on pink 5.05:1;
error text 7.96:1; pressed secondary text 11.13:1. Keyboard focus underlines the action label;
selected controls also change weight and fill. These checks and captures are WCAG-inspired desktop
evidence, not formal conformance or a complete accessibility audit.

## Remaining release gates

Research desk, measured Lab workbench and Today/Library product redesign remain
next slices. Full cross-owner collection return, all navigation-stack anchors,
long histories/dialog scale states, authoritative specialist handoffs and sustained
human usability remain incomplete acceptance. Older broad native suites do not
constitute revalidation of every changed composition. No personal achievement was
recorded. The populated native Zotero restore regression remains unresolved;
empty-profile controls do not establish annotated-PDF restoration. Off-device
repository configuration stays deferred by owner, post-V1.

The owner's 20–30 minute learner trial remains required release feedback. Start
with the supplied YOLO paper, then check a course and independent problem too.
Observe action discovery, source/thinking visibility, prerequisite navigation,
lost context, readability, control distinctions, menu complexity and interface
management time. Findings must change the release assessment, not be dismissed
as cosmetic. The implemented slice is reviewable; it is not a V1 completion claim.

## Live rollout

Scoped installation is live. The canonical production config is
`~/.config/quickshell/noesis/shell.qml`, with AppId and ShellId
`org.fh1m.Noesis`; its desktop entry uses the same identity. The actual launcher,
Super+Ctrl+O binding and ScreenPad bridge route to this independent host.
The embedded writable host is removed from normal Wrayth composition.

Production proof: one independent instance opened on workspace 4 (`Study`) in
actual full-screen mode at 1920x1080 logical. Cold launch to visible worker/watch
was 1.43s; one warm Hide/resume sample was 0.669s; Close completed in 0.35s.
These are single observations, not percentile budgets. Observed process RSS was
174MiB and PSS 122MiB, not incremental system-memory cost. Five-minute idle,
long-run memory trends and physical input latency remain unmeasured this slice.

Private production screenshots were inspected but are not committed. Wrayth
remained PID 2146193 through hot reloads and independent app shutdown/restart.
The three existing external windows retained their addresses and workspaces;
all 50 personal vault Markdown hashes remained unchanged. Ten native lifecycle
fault cases passed again after the window-state changes. There was no portal
identity registration warning in production; the log did contain a Qt base64
API deprecation warning. The learner trial and full release gates remain open.
The installer records backups and hash-checked rollback in
`~/.local/state/noesis-deployments/`; machine-local preferences were separately
preserved in a permission-restricted rollout directory. Production build identity
is `~/.local/share/sensei-learning/build.json`, exposed by `noesis hello`.


## Two-display Study extension

The main display remains the full-screen working page. On the installed ScreenPad
(1920x550 logical, DPR 2), a full-display configurable study workbench follows the same
selected activity and owner. It shares the existing adapter and controller: no
second learning worker, learning watcher, index, mutation queue or draft store.
In Practice, Source on the second display gives reasoning the main working area;
Context restores the statement/reasoning composition on the main display.
Only the problem statement is shown while reference material is protected.
PDFs and videos still use specialist tools; this is a bounded native preview.

The desk is visible only in full-screen Study, hides with Noesis or when the main
display leaves Study, and falls back to the original main-page composition when
the ScreenPad is unavailable. Each of its two resizable panes independently selects Source, Context, Notes &
reasoning, Figures & artifacts, or Reference preview. Views and pane proportions
are saved in machine-local preferences; sources, notes, context and figures
scroll independently. Notes use the same live draft as the main page. Protected
references and artifacts remain hidden until deliberate exposure on the main
page. “Use ScreenPad for tools” releases the panel for Obsidian, PDFs, videos or
other native apps, and “Show Study desk” returns without losing the draft. The old
compact Wrayth companion is suppressed while Noesis is open to avoid two overlays.
Existing external tool windows are not moved into the study layout.

Native fixture review captures: [main Practice](assets/recovery-sprint/practice-study.png),
[second-display problem](assets/recovery-sprint/practice-second-display.png),
[second-display Context](assets/recovery-sprint/practice-second-context.png),
[200% problem](assets/recovery-sprint/practice-second-display-200.png), and
[200% Context](assets/recovery-sprint/practice-second-context-200.png).
Real pointer clicks change pane content, edit the shared draft, release/restore the ScreenPad, and
preserve the active attempt through Hide/resume.
Physical unplug/replug and a sustained two-display learner trial remain open gates.

Renumbering is an explicit owner-requested correction to the earlier stable-ID
choice. Live workspace identities are migrated together with their existing
contents (Study 7→4, Sim 4→5, Work 5→6, Misc 6→7), retaining their monitors.
The scoped `oasis.lua` rules and shortcuts override earlier workspace defaults;
unrelated locally modified `custom-setup.lua` is preserved.


The current panes follow the selected activity; independently pinning different
records across owners is not implemented. Native scientific content remains
bounded. Full Canvas/maps, rich equations, PDFs and arbitrary application windows
use their specialist tools rather than being embedded in the panel. The free
ScreenPad control makes room for those tools without moving existing windows.


A controlled native mode probe found that installed Hyprland 0.56.2 treats
`set/unset` as the default toggle for floating-state commands. Noesis now uses
explicit `enable/disable`, verifies the native fullscreen acknowledgement before
layout dispatch, and verifies normal-mode geometry. This removes repeated
floating/tiled flips rather than concealing them with longer waits.
[Installed-version toggle parser](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/config/lua/bindings/LuaBindingsInternal.cpp).

The two-display native fixture passed pointer selection, shared draft editing,
protected-reference checks, display release/return and restart recovery. Main
images use native Qt window rendering; second-display images capture the actual
DP-2 compositor after a frame-present barrier and a privacy check. Visual review
caught and corrected a selector-label mismatch and stale presented frames.
Activity changes now clear the previous source preview until its owned response
arrives. [Figures beside notes](assets/recovery-sprint/lab-second-figures-notes.png)
and [shared reasoning](assets/recovery-sprint/practice-second-notes.png) are
retained synthetic-fixture evidence. No new dual-display performance or human
usability result is inferred from the earlier single-display measurements.

Live deployment initially exposed the production tile rule overriding Qt's
startup fullscreen request. Noesis now repairs that state using an explicit,
address-scoped fullscreen-state command when native acknowledgement differs,
then verifies it. The live check confirmed 1920×1080 logical fullscreen on Study
4 and a 1920×550 ScreenPad desk. Existing external client identities and workspace
contents were retained; the original Wrayth process remained running. The scoped
backup preserves the unrelated custom setup. The selected personal course has
no outline yet; this rollout does not fabricate one or alter learning content.

Live workspace-switch verification also caught stale monitor IPC in the standalone
host. The desk now refreshes monitor/workspace projections on compositor events;
leaving Study hides it and returning restores it without an idle polling loop.

## ScreenPad density follow-up

Owner feedback reopened the desk layout: repeated header/footer actions consumed
too much height and unbounded-looking panes obscured their roles. The desk now
uses two borderless working surfaces, one compact location bar, source actions
in pane headers, and a source/notes default. Default typography is reduced
slightly across the shared system while retaining Zed families and user scales.
Figures fit the available viewport instead of consuming a scaled fixed height.
The root README links the [native UI gallery](ui-gallery.md), including retained
same-fixture before/after images and explicit measurement limits.

The native fixture now focuses its configured main monitor before each restart,
matching the production launcher. A failed check exposed the earlier fixture
opening on the ScreenPad after pointer interaction; its 550px fullscreen geometry
was a display-placement error, not a reason to relax the viewport assertion.
