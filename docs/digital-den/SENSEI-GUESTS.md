# Visitors to Sensei

Zondo is the host, not an impersonation of fh1m. Ten illustrated guests come from
fh1m's own [shoulders section](https://fh1m.github.io/mongla_ws/).

Open **identity badge → Sensei guests** (beside Nerd Talk), or **Engineering → Zondo → Guests** to invite someone. On the visit card:
**‹ / Next** navigate, **Ⅱ** pauses, **Another guest** changes visitor, **×** ends.
The source title opens the original reading. Nothing takes keyboard focus.

```sh
sensei-den companion guest feynman
sensei-den companion guest karpathy
sensei-den companion guests off
sensei-den companion guests on
sensei-den companion guests
```

IDs: `feynman hotz carmack karpathy keller lattner graham urban west rubin`.
Invitations wait up to five minutes for safe space. Ordinary visits default to
at most one per half hour per host; `guestMinutes` in the private companion
preferences changes the interval (minimum fifteen). Quiet, DND, disabled,
suspended, fullscreen and the existing Den ownership lease take precedence.
No browser requests, conversational service or audio are needed during a visit.

## Real words versus our theatre

The initial collection has **100 short sourced excerpts: ten per person from
30 sources**. These are excerpts, not 100 full speeches. Source matching checks
spelling against a privately cached public-source corpus. It does not prove
that an archive is infallible; source kinds identify interviews, author writing
and archived material. Interpretations are labelled **our reading**, biographical
summaries **life & work**, and invented introductions **staged dialogue**.
Zondo's questions are authored for this desktop, not historical quotations.
No song lyrics or purported private conversations are reproduced.

The expanded deck has **121 selectable entries per guest**: eleven real excerpts,
eleven curated source-backed topic stories, and ninety-nine original workshop variants
(nine learning lenses for each topic). Across the roster: **110 excerpts, 110
stories, 990 workshop variants**, with 51 source records. These are not 1,210 independent historical
quotations or 990 hand-researched anecdotes. The workshop is explicitly our
writing, combining a specific topic/task with prediction, sketching, teaching,
limits, transfer and return prompts. It is intentionally inspectable rather
than an online generator inventing advice in a real person's voice.

In the guest picker, choose **Mixed**, **Real excerpts**, **Stories**, or
**Original workshop**. Mixed selection favors the real excerpts (60%, with 20%
for each other family); an explicit mode takes precedence. This keeps the larger
practice deck from drowning out the actual voices. Every visit still ends with
Zondo's own question.

```sh
sensei-den companion guest-mode stories
sensei-den companion guest-mode workshop
sensei-den companion guest-mode quotes
sensei-den companion guest-mode mixed
```

Each guest has a four-pose transparent atlas, generated using two real portrait
or speaking references. Natural adult proportions and individual faces replace
the rejected chibi series. Zondo has both front and sideways seiza atlases;
the live scene faces him toward the visitor. Occasional dozing is fictional.
Poses crossfade briefly, with all motion disabled in reduced-motion mode.

## Maintenance and privacy

- Shared code/art: `home/.local/share/sensei-companion/`.
- Source-backed topic roots: `guests/topics.tsv`; rebuild with
  `python3 scripts/build-sensei-guest-topics.py` and check with `--check`.
- Sources, reference URLs and verification hashes: `guests/catalog.json`,
  `artwork-provenance.json`, `source-audit.json`.
- Private recent selections: `~/.local/state/sensei-den/zondo-guests.json`.
- Private preferences: `~/.config/sensei-den/companion.json`.
- Full downloaded texts, reference photographs and live screenshots stay out of Git.
- Entire scenes must fit free wallpaper space; a busy or small display can defer
  an invitation. Active visits pin the existing roaming lease until dismissed.
- The renderer root uses a `file://` Loader URL so sibling QML types resolve.

```sh
python3 scripts/check-sensei-guests.py
python3 scripts/check-sensei-guests.py --corpus /path/to/private/public-source-cache
python3 -m unittest discover -s tests -p 'test_sensei_guests.py'
python3 -m unittest discover -s tests -p 'test_companion*.py'
```

Turn guests off to undo the behavior without removing Zondo. Reverting this
feature's commit restores the original renderer. No input service restart,
credential copying, system reboot or private-note migration is involved.

## Observed validation — 20 October 2026

Arete: all ten live guests started, paused, advanced to a sourced quotation and
closed through the actual renderer IPC. A screenshot confirmed Feynman and
sideways-listening Zondo with unobstructed controls. Eleven policy/content tests and
34 existing companion tests passed; artwork and all 100 excerpt matches passed.
All thirty guest/family combinations passed live start/pause/next/close checks.
The cursor renderer remained active. Homie was offline; its deployment is
explicitly deferred while the owner installs Windows. No Homie verification is
claimed. The pre-existing custom Quickshell/Qt version warning remains a
separate runtime maintenance risk.

Smooth text reveals are local and silent. Pause reveals the complete sentence and
stops automatic paging; tapping the text reveals it immediately. Reduced motion
also shows complete text. Cards size themselves from the full sentence before
revealing it, so typing does not make the layout jump. Accepted invitations are
remembered across renderer restarts instead of replaying an old request.

[Research pass: 110 targeted searches and source decisions](SENSEI-GUESTS-RESEARCH.md).
