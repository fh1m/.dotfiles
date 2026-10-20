# Visitors to Sensei

Zondo is the host, not an impersonation of fh1m. Ten illustrated guests come from
fh1m's own [shoulders section](https://fh1m.github.io/mongla_ws/).

Open **Engineering → Zondo → Guests** to invite someone. On the visit card:
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

Each guest has a four-pose transparent atlas, generated using two real portrait
or speaking references. Natural adult proportions and individual faces replace
the rejected chibi series. Zondo has both front and sideways seiza atlases;
the live scene faces him toward the visitor. Occasional dozing is fictional.
Poses crossfade briefly, with all motion disabled in reduced-motion mode.

## Maintenance and privacy

- Shared code/art: `home/.local/share/sensei-companion/`.
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
sideways-listening Zondo with unobstructed controls. Seven policy tests and
34 existing companion tests passed; artwork and all 100 excerpt matches passed.
The cursor renderer remained active. Homie was offline; its deployment is
explicitly deferred while the owner installs Windows. No Homie verification is
claimed. The pre-existing custom Quickshell/Qt version warning remains a
separate runtime maintenance risk.
