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
The Lab capture has a hypothesis, not fabricated measurements/figure evidence.

`capture-after.json` records logical size, Qt DPR, application scales and window
presentation for every capture. The owner's latest decision makes a full-screen
Study workspace the primary review environment: 1920x1080 logical at
100/125/150/200% application scales, with Qt DPR recorded separately. One compact
200% recovery check retains reachable statement/reasoning and attempt actions.
Earlier broader size matrices remain in Git history; they are not the current
acceptance focus. Full-screen is Qt's actual window state, independently checked
against the compositor, rather than a maximized-window label.

Study appears between Code and Sim with a book glyph. Workspace order is
1,2,3,7,4,5,6 so existing workspace IDs and windows are preserved. Super+7 opens
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

Production proof: one independent instance opened on workspace 7 (`Study`) in
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
