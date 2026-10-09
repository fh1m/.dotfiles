# Noesis: a calm place for difficult work

This specification adds product coherence to the approved architecture. It does
not replace the roadmap or equate a pleasing screenshot with working journeys.

## Interaction decisions and inspected references

| Observed pattern | Noesis decision | Reference |
|---|---|---|
| Linear separates orientation from content and reduces the prominence of supporting controls. | Quiet navigation; predictable location header; a focused context with optional inspector. Strong pink is reserved for focus, selection and a primary action. | [Linear design refresh](https://linear.app/now/behind-the-latest-design-refresh) |
| Linear's peek lets someone inspect a row without losing the surrounding list. Its screenshot was inspected alongside the documented keyboard behavior. | A selected context preserves the work list and navigation history. Read, Work, History and Connections disclose different operations. | [Peek](https://linear.app/docs/peek) |
| Notion offers side, center and full-page opening according to view and purpose. | Contexts open alongside a list; short capture/creation flows use a centered dialog; rich technical editing opens in the owning application. | [Database view layouts](https://www.notion.com/help/views-filters-and-sorts) |
| Raycast gives lists a predictable arrow/Enter/Escape grammar and separates actions from search results. | Arrow/Enter navigation; visible shortcuts; capture and contextual actions do not fill every list row. Existing Ctrl+K search remains stable. | [Keyboard behavior](https://manual.raycast.com/keyboard-shortcuts) |
| Readwise Reader supports keyboard annotation and hiding sidebars to regain reading space. | Inspector and reference visibility are deliberate controls. Reference exposure is recorded, and an interrupted attempt remains recoverable. | [Reading and annotations](https://docs.readwise.io/reader/docs/faqs/highlights-tags-notes) |
| Obsidian already distinguishes clean reading from editing and supports the technical content the learner owns. | Native Markdown previews give orientation. Equations, Canvas, diagrams and rich editing use Obsidian; Noesis does not pretend to replace it. | [Read and edit](https://obsidian.md/help/edit-and-read) |
| Things makes contextual filters available without requiring every task to carry a complex classification. | Immediate free-text capture; optional enrichment and explicit path scope, without a mandatory taxonomy. | [Tags](https://culturedcode.com/things/support/articles/2803581/) |

These are product adaptations, not an endorsement of copying a particular
application's colors, commercial dashboard layout or private design process.

## Visual grammar

`home/.local/share/sensei-learning/ui/NoesisStyle.qml` is the shared source for
Noesis tokens. It retains the desktop's dark/pink identity with explicit colors
and fonts, without importing Wrayth's Theme, Appearance or service graph.

- Type: 13 caption, 14 control, 15 general UI, 17 reading prose, 18 section,
  22 page heading and 28 object title. Prose uses Adwaita Sans; code uses Iosevka.
  Interface and reading scales are independent, adjustable through Settings to
  200%. Reflow and scrolling preserve critical actions at larger scales.
- Space: 4 / 8 / 12 / 16 / 24 / 32 logical pixels. Normal controls are at least
  40 high; collection rows at least 64 and expand for important wrapped text.
- Surfaces: black canvas and the two existing dark Wrayth surfaces. Rows use
  whitespace and selection backgrounds, not a stack of bordered cards.
- Borders: field affordances, focus and an actual pane boundary. An inactive
  button does not need its own frame. Focus is visible for every control.
- Pink: current selection, primary action and focus, with dark selection ink.
  Error, warning and success use distinct colors and textual labels. Ordinary
  text targets 4.5:1; large text and meaningful boundaries/focus target 3:1.
  Composited normal, hover, focus, disabled, error and selected states must be
  checked; token arithmetic alone does not complete acceptance.
- Motion: existing state-transition duration. No decorative animation or
  continuously updating graph. Lists remain virtualized.
- Popovers/dialogs: clear title, one purpose, predictable action placement,
  Escape dismissal and preserved drafts. Failed saves retain input.
- Reading: comfortable body type, selectable Markdown preview, scrollable
  content, optional details, explicit handoff for mathematics and diagrams.

## Workspaces and disclosure

Today contains Continue and a small set of explained next steps. It does not
show six miniature dashboards. An empty or long-absent context offers curiosity
and resumption without streaks, guilt or an inferred forgetting score.

Learn connects paths, courses, independently addressable units and tasks.
Consumption counts and reported assessment remain separate. A course opens its
ordered steps; a unit keeps its own page, section, exercise or timestamp.

Research supports saving a source, selecting a Zotero item, reading passes,
questions, original annotation snapshots and reader handoff. Imported material is
clearly attributed and remains separate from learner analysis.

Practice opens into work: preserved reasoning, durable attempt, deliberate
reference reveal, reported outcome and learner-selected retry/check. History
shows failure, assistance and later independent work without collapsing them.

Lab keeps the original prediction alongside comparisons, artifact availability,
checksums and linked runs. Execution success does not establish a hypothesis.

Library searches across saved knowledge. Classification is enrichment, never a
prerequisite to capture.

## Acceptance, not appearance alone

Walk through paper, course, failed problem, IMU experiment and long-absent resume
fixtures in the native desktop. Record operations, keyboard actions, context
recovery and tool handoffs separately from visual alignment. Retain a before
image, inspect main and compact sizes, and keep unpassed cases in validation.md.
The connected UI is not accepted until these journeys work without CLI repair.


## Native comparison

[Before: permanent administration controls](assets/coherence-before.png) ·
[After: a focused working context](assets/coherence-after.png).

Both use synthetic task content. The revised layout gives reasoning its own Work
region, moves capture to a short dialog, separates timeline/connections, and makes
the inspector optional. Pink and existing Wrayth type remain consistent. See
validation.md and scripts/check-noesis-desktop.py for behavioral evidence; these
images alone do not establish that a journey works.


## Research context comparison

[Before: permanent operations](assets/research-before.png) ·
[After: connected questions and implementation](assets/research-after.png).

The same synthetic paper, question and implementation are present in both captures
at 1000×650 Qt units. The updated context makes existing work discoverable alongside
the source; creation and administrative actions move into a keyboard action list.
Source opening and exact reading position remain immediately available. Resource
labels reflect the medium, and courses belong in Learn rather than Research.
The native connected-record route is verified separately in validation.md.


Interface prose now uses the installed Adwaita Sans, with the existing data font reserved for technical metadata. Today must explain its selected-vault scope and distinguish existing notes from recorded active work. No empty suggestion section or duplicate capture invitation should displace onboarding.

## Actual screenshot corrections in this continuation

Learner-facing titles use display projections, keeping full file paths in Details.
Learn's Paths & courses, Concepts and Sources avoid equating entire courses with
individual lectures. A reviewed outline opens a course and its units; modules can
contain their own readings/assignments. Creation lives under **+ New**, keeping the
header legible at compact widths. Ordinary operation feedback is prose, never a
JSON response. The development UI switch is hidden by default.

Reading blocks have bounded widths and a restrained 22/18/16 px heading hierarchy,
15 px prose and 13 px code. Duplicate title H1 is omitted in the preview; source
prose stays intact. Wiki-link labels are readable, embeds are explained, and
full-fidelity documents open in their owning application. Plain text is deliberate:
no document HTML execution, remote image loading or false equation rendering.

New native course and cross-vault captures are synthetic fixtures, inspected for
composition. They are not the user's private screenshots or human usability
results. The supplied real screenshots remain the motivating visual evidence.
The course screenshot exposed a clipped header and raw JSON footer during testing;
both were corrected and the same fixture recaptured before deployment.

[Native course outline fixture](assets/course-outline-native.png) · [Native cross-vault fixture](assets/cross-vault-native.png). Both are disposable application captures, not private vault or desktop images.


### Course outline interaction, same-content native comparison

[Before Arrange](assets/course-outline-before-arrange-native.png) and
[After Arrange](assets/course-outline-native.png) use the same six-lecture
synthetic course in the running native application. The outline now has an explicit
Arrange action, visible scrollbar and bounded lesson pages. The normal-window
restore is centered so its controls remain on-screen. These captures demonstrate
composition, not learner comprehension or completed course acceptance.

## Reader handoff and lesson replacement

Replacement uses the shared compact dialog/input tokens and a reason in human terms.
Source metadata stays contextual; replacement does not rename a learner's note.
Use Hide when the compositor cannot honor Qt minimization. A normal/workspace source
handoff preserves context, stops its worker and gives the specialist reader focus;
tiled mode keeps the two working surfaces visible. The native reader is the authority
for PDF fidelity and saved-page acceptance, rather than an attractive preview.

## Connected lesson and experiment surfaces

Lessons group prerequisites and assigned assessments beside their resume state.
Outline-return and next-lesson actions replace repeated searching. Modules have
structural labels, with no consumption counters. Primary attempt/save actions
share Ctrl+Enter; modal dialogs keep precedence. Completion messages clear when
changing contexts so earlier assessments do not appear to describe a new experiment.

Lab uses restrained headings for prediction, configuration, comparison and figures.
Recorded code/version metadata stays secondary. Original plots retain their visual
fidelity rather than being recolored by the shell. Local figure rows are not
duplicated in the generic relation list. Keyboard paging and specialist handoff
keep long technical content usable without adding a browser renderer.
