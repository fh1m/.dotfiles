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

`config/NoesisStyle.qml` is the shared source for Noesis tokens. Colors inherit
Wrayth's Theme; fonts inherit Appearance. Noesis-specific components use these
tokens without changing the rest of the desktop.

- Type: 12 caption, 13 control, 15 body, 22 section heading, 30 major title.
  Interface/body use the established proportional UI family. Code uses the
  established data family. Sentence case controls; uppercase is limited to small
  section labels.
- Space: 4 / 8 / 12 / 16 / 24 / 32 logical pixels. Controls are 34 high; dense
  two-line rows are 62. Dialogs and main regions align on this scale.
- Surfaces: black canvas and the two existing dark Wrayth surfaces. Rows use
  whitespace and selection backgrounds, not a stack of bordered cards.
- Borders: field affordances, focus and an actual pane boundary. An inactive
  button does not need its own frame. Focus is visible for every control.
- Pink: current selection, primary action, focus and actionable errors. Status
  meaning is expressed with text as well as color.
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
