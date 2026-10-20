# Sensei guests — implementation record

Requested roster: Richard Feynman, George Hotz, John Carmack, Andrej Karpathy,
Jim Keller, Chris Lattner, Paul Graham, Tim Urban, Kanye West and Rick Rubin.
Authority: the ten entries in the shoulders/depth section of
https://fh1m.github.io/mongla_ws/ (read 2026-10-20).

## Contract

- Ten recognizable, transparent, high-resolution, four-frame imagegen atlases;
  matching Zondo attentive/seiza and comic sleepy listener poses.
- At least ten independently source-checked short quotations per guest. Never
  attribute original dialogue or invented personal advice to the real person.
  Mark staged dialogue and interpretation; retain source title/URL/context.
- Introduction verbatim: “Zondo as Sensei of fh1m, I have a message for Him”.
- A paced visit: arrival → introduction → quotation/context cards → Zondo's
  clarifying question → farewell. Source link, next/pause/close, manual choice.
- Existing safe placement, one-host lease, no focus/input grabs, DND, quiet,
  fullscreen safety and reduced motion. No always-on external requests.
- Optional occasional visits, bounded history, no repetitive consecutive guest
  or quote. Guest stories describe actual work; humorous actions are fictional.

## Milestones / done when

1. Research/assets: ten guests, ten verified short quotes each, provenance and
   eleven or more imagegen outputs checked for identity, alpha and frame bounds.
2. Pure visit policy: deterministic state/pagination/history tests; no compositor
   required; conservative explicit distinction between quotation and dialogue.
3. Renderer/UI: two characters fit safe wallpaper space; Zondo listens/sometimes
   dozes; cards never overlap characters; controls/attribution usable on scales.
4. Integration: opt-out/manual selection, occasional visits, field guide/docs;
   real tests on Arete and Homie, notifications/singing/input remain intact.
5. Publish: focused regression checks, inspect diff for private data, coherent
   main commits and synchronized deployment. No reboot or input capture tests.

## Ownership / rollback

Reusable assets/data/policy live in home/.local/share/sensei-companion/.
Private playback/history/settings live in ~/.local/state/sensei-den/ and
~/.config/sensei-den/. No cloud conversational service. Revert these commits or
turn off guests; preserve original character atlases and user preferences.

## Current state — 20 October 2026

Milestones 1–3 are implemented and live on Arete. Ten natural-proportion guest
atlases plus two Zondo seiza atlases are retained; rejected artwork is private.
All 100 excerpts match the inspected source corpus. Seven policy and 34 existing
companion tests passed. All ten guests passed real start/pause/next/close checks.
A file URL and two QML syntax repairs resolved the observed loading failure.

Milestone 4 has the existing Engineering → Zondo guest picker, CLI, source links,
opt-out, paced cards and safety integration. Homie deployment is deferred at the
owner's request during Windows setup. Publish the working slice before expanding.

## Expanded request

The owner now wants 100+ entries per person, including deeper stories, guidance
and inspiration. Preserve a strict distinction between verified excerpts,
sourced history, original reflections and practice prompts. Do not manufacture
100 quotations by chopping a paragraph into fragments or disguising templates
as historical advice. Record the actual content counts by kind. Extend the
source ledger and selection policy, validate and inspect live again.
