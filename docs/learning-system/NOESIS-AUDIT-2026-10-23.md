# Noesis audit — 23 October 2026

Scope: current source, existing learning documentation, live doctor, native ink
roundtrip, regression suites and 32 fresh research queries. Private note contents
are not reproduced. This is an engineering audit, not a claim that a learning
application has experimentally improved its owner's learning.

## Diagnosis

The current system is substantially stronger than a template factory. Markdown is
its durable authority; SQLite is a rebuilding query index. Stable IDs, publication
receipts, append-only activities, scoped evidence and specialist tool handoffs are
already present. Preserve that architecture. The missing handwriting connection
was real: the learning action opened Excalidraw while native pen scratch remained
loosely attached. This pass connects native ink to the same record history.

## Source-backed capability map

| Responsibility | Source under `home/.local/share/sensei-learning/noesis/` | Assessment |
|---|---|---|
| Stable records / provenance | `models.py`, `scopes.py`, `index.py` | Reuse UUIDs, typed references and rebuilding index; paths are not identities. |
| Attempts / assistance / retries | `activities.py` | Preserve append-only history; an assisted outcome remains assisted. |
| Capability evidence | `frontier.py` | Encountering, using, explaining, deriving, implementing, predicting/debugging, transferring and retaining are distinct. Protected independent claims require successful unassisted attempts. |
| Courses / resource units | `courses.py`, `materials.py`, `outlines.py` | Ordered work and resume positions exist; completion does not establish competence. |
| Papers / annotations | `zotero.py`, `sources.py`, `imports.py`, `readers.py` | Retain bibliography and annotation provenance; specialist tools own their data. |
| Experiments / artifacts | `experiments.py`, `exploration.py` | Preserve predictions, baselines, code references and external artifacts. |
| Next actions / tutor context | `policies.py`, `views.py` | Explainable actions and manual control; do not replace with opaque mastery scores. |
| Multiple vaults | `collection.py` | Intentionally separate vaults supported; each collection is bounded to 16 registered vaults. |
| Native handwriting | `ink.py`, `exploration.py` | Added linked editable journal, owned PDF background and recoverable derived preview. |

## Findings and priorities

| Priority | Observed evidence | Action / regression proof |
|---|---|---|
| P1, repaired | `sensei/drawing.py:learning` created Excalidraw; native scratch was outside the connected record workflow. | Native ink artifact linked to selected origin; identity retries preserve actual stroke bytes. |
| P1, repaired | Backup used a general 25 MiB limit, smaller than the new 64 MiB owned-background allowance. | Bounded exception only for UUID-owned journals/backgrounds; regression test. Large arbitrary datasets remain excluded. |
| P1, runtime dependency | Installed Qt 6.12.0 with local Quickshell stamped 6.11.2; actual build reproduced incomplete-MOC-type failure. | Attributed upstream compatibility port in the pinned build. Do not restart the desktop until a matched build succeeds. |
| P2, repaired | `scripts/audit-noesis-qml.py` depended on an unavailable historical commit. | Audit current working tree by default, optional explicit revision, clear invalid-ref failure; inventory regenerated. |
| P2, next | `policies.py:137` uses `timeline(identity)[-10:]`; `index.py:246` reads full history before slicing. | Add a bounded latest-events query for tutor context. This is a verified scaling risk, not a measured current UI fault. Full causal reducers may still need history. |
| P2, deployment boundary | Homie doctor reports no active Noesis vault. | Choose/register its intended local or mounted vault explicitly; do not silently duplicate private laptop learning content. |
| P2, user acceptance | Software tests cannot establish pressure comfort, legibility or learning benefit. | Draw on plain/ruled/graph paper, annotate a real paper, reopen next day and independently reconstruct one result. |
| P3, optional | Native handwriting has no guaranteed searchable text representation. | Add optional local transcription with original strokes retained and uncertain text marked; never silently replace learner reasoning. |
| P3, evidence durability | A working notebook is mutable. | When a claim needs an immutable figure, attach a dated/hash-addressed snapshot to its evidence. Do not treat the current preview as a frozen historical claim. |

## Smallest useful next learning slice

1. Capture a paper or lecture and state the question it serves.
2. Write a prediction, derivation or diagram in its linked notebook.
3. Attempt a concrete problem or implementation before revealing a solution.
4. Compare with source, numerical check or measured observation.
5. Preserve the first incorrect assumption and assistance actually used.
6. Reconstruct later without the source; test a changed case before claiming transfer.

Use gate/parallel/deep-descent prerequisites to repair the smallest current blocker.
Do not require a prerequisite degree before an interesting build, and do not let
repeatedly missing fundamentals disappear into the backlog. A future view should
surface recurring blockers from actual attempts, with an inspectable explanation.

## What not to add

No mandatory handwriting, bulk folder migration, automatic competence from OCR,
new always-on ink server, extra export owner, universal flashcard schedule, or
single mastery percentage. Canvas remains for maps, Xournal++ for ink, Zotero for
bibliography, repositories for code, and experiment tools for large runs. Noesis
connects the work and evidence instead of replacing those applications.

## Validation

- Noesis: **172 tests passed**; drawing helper: **9 passed**.
- Real Xournal++ native export and PDF annotation roundtrip passed, including vault
  relocation, unchanged original PDF and preserved identity. Rendered synthetic
  graph fixture visually inspected; no private learner content used.
- Headless dialog check confirmed native-ink default and controls; offscreen image
  capture was unavailable. This is not a claim of physical pen or visual desktop acceptance.
- Existing doctor passed on Arete; Homie lacks an active vault.
- Historical scale measurements remain in `validation.md`; they were not rerun
  during a concurrent runtime build and are not presented as fresh benchmarks.

See [research and limitations](INK-RESEARCH.md), [daily ink workflow](INK.md), and
[living execution status](INK-PLAN.md). Future improvements should earn their place
by reducing resume/capture friction or strengthening independent evidence—not by
increasing note counts, plugin counts or dashboard density.
