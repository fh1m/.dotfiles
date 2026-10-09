# Noesis native UI review

These are actual native renders of disposable, meaningful fixtures. Main images
capture Qt window contents; ScreenPad images capture the DP-2 compositor after
frame presentation and a privacy check. No private learning content is published.
Main display: 1920×1080 logical. ScreenPad: 1920×550 logical. Qt DPR: 2.
Application interface/reading scale is separate from DPR.

## ScreenPad — before and after

Same synthetic problem, 100% text scale. The update removes the duplicate action
footer, places source actions in their pane header, and separates the two working
areas with surfaces and spacing. The default is source beside shared notes;
Context remains selectable. Empty space in Notes is an editable working area.

Before:

![Previous ScreenPad](assets/desk-density-before/practice-second-display.png)

After:

![Problem beside notes](assets/recovery-sprint/practice-second-display.png)

## Figures and interpretation

The curve is explicitly illustrative fixture data, not an instrument measurement.
Figures fit the available pane height. Notes and source views scroll independently.

![Figures beside notes](assets/recovery-sprint/lab-second-figures-notes.png)

## Main application

Zed Sans remains the UI/reading family; Zed Mono remains for code. Default body
text is 16px (previously 17), UI 14px (previously 15), titles 25px (previously 28),
section headings 16px (previously 18). User scales remain adjustable.

![Course overview](assets/recovery-sprint/course-study.png)

![Active lesson](assets/recovery-sprint/lesson-study.png)

![Independent practice](assets/recovery-sprint/practice-study.png)

![Research](assets/recovery-sprint/research-study.png)

![Lab](assets/recovery-sprint/lab-study.png)

![Today](assets/recovery-sprint/today-study.png)

## Increased text scale

200% interface and reading scale, same ScreenPad. Critical controls remain
reachable; content scrolls rather than shrinking. This screenshot is a visual
check, not proof that every possible record is usable.

![ScreenPad at 200%](assets/recovery-sprint/practice-second-display-200.png)

## Verification and limits

Native pointer selection, keyboard draft editing, protected references, Hide/
return, Close/restart draft recovery and compact reasoning access are checked by
`scripts/check-noesis-studio.py --dual`. [Capture states](assets/recovery-sprint/capture-after.json)
and [short rendering sample](assets/recovery-sprint/render-performance.json)
record the measured conditions. Frame intervals are not physical input latency.
Your sustained learner trial is still required. Rich maps, full equations and PDFs
remain specialist-tool handoffs; unrelated records cannot yet be pinned per pane.

Design references: [Linear's calmer interface](https://linear.app/now/behind-the-latest-design-refresh)
for quiet chrome and predictable action locations; [Notion student dashboards](https://www.notion.com/templates/category/student-dashboards),
[University Hub](https://www.notion.com/templates/university-hub-452) and
[Easlo's Student Dashboard](https://www.notion.com/templates/easlos-student-dashboard)
for course-centered organization. Marketplace popularity is not a verified usage ranking.
