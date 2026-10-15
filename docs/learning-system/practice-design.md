# Evidence-driven practice — implemented 2026-10-08

Noesis cannot manufacture an exceptional engineer. It can reduce friction between
curiosity, honest attempts, useful feedback and demonstrable capability.

## Sources → decisions → actual behavior

| Inspected source | Principle we extract | Implementation |
|---|---|---|
| [Colin Galen: four complete caption transcripts](colin-galen.md) | Recognition, interface use, independent reasoning and transfer train different abilities | Five explicit practice modes; append new sessions without promoting confidence; hide/reveal reference |
| [Karpathy's training recipe](https://karpathy.github.io/2019/04/25/recipe/) and [Zero to Hero](https://karpathy.ai/zero-to-hero.html) | Build small, inspect data, trust an oracle before adding complexity | Build-mode prompts: baseline, data/splits, versions, shapes/units, expected output, controlled comparison and silent-failure checks |
| [Sutskever's thesis](https://www.cs.toronto.edu/~ilya/pubs/ilya_sutskever_phd_thesis.pdf) | Its experiments challenge accepted assumptions about RNN training | Our inference: preserve disputed belief, prediction and contradictory evidence rather than polishing away mistakes |
| [Sutskever interview](https://www.youtube.com/watch?v=13CZPWmke6A), selected caption passages | Intuition draws on demonstrations; brain analogies require care | Separate a motivating analogy from the tested mechanism. No claim to know his private study system |
| [Hotz's course outline](https://github.com/geohot/fromthetransistor) | Successive working layers form a build spine | Project templates ask for a smallest vertical slice; connected source → interface → implementation → measured behavior |
| [Lattner's LLVM architecture chapter](https://aosabook.org/en/v1/llvm.html) | Explicit representations and reusable interfaces make systems inspectable | Interface mode names contract and state; concept/project templates ask for a trace and safe boundaries |
| [Keller interview](https://www.youtube.com/watch?v=Nb2tebYAaOA), selected caption passages | Targets, abstraction boundaries and questioned assumptions matter | Gate/parallel/deep-descent remains; interface mode asks which failures must be understood now |
| [Carmack on functional C++](https://www.gamedeveloper.com/programming/in-depth-functional-programming-in-c-) | Separating computation from state and I/O improves tests and understandability | Build prompts and project templates ask for an oracle and computation/side-effect boundary |
| [Dunlosky et al. review](https://gwern.net/doc/psychology/spaced-repetition/2013-dunlosky.pdf) | Practice testing and distributed practice have stronger evidence than passive rereading | Recall hides source; reconstruct before feedback and schedule an evidence-based retry, without claiming permanent recall |

The Ilya/Keller interviews were accessed via locally downloaded auto-captions;
targeted passages were inspected, not a claimed full-video visual review. All four
Colin transcripts were read fully. Sources support different claims: published
learning evidence, author practice, artifact analysis and our engineering inference
are kept distinct. Famous-person success is motivation, not causal proof.

## Human reports we used — not messages sent to strangers
- [HN: Llama paper implementation](https://news.ycombinator.com/item?id=37059479):
  commenters catch subtle implementation discrepancies and discuss reference-output
  comparison. This reinforced an explicit oracle and controlled-change prompt.
- [HN: getting into ML](https://news.ycombinator.com/item?id=32480009):
  competing advice about fundamentals versus project-first work. Keep prerequisites
  task-sized and parallel; don't prescribe a universal reading staircase.
- [Reddit: active recall in Obsidian](https://www.reddit.com/r/ObsidianMD/comments/18akx02/):
  learners discuss reconstruction versus notes. A hide/reveal control addresses
  that friction without installing an automatic flashcard generator.
- [Reddit: starting smart notes](https://www.reddit.com/r/ObsidianMD/comments/1du9ybi/):
  over-structuring and repeated method changes can displace real work. Sessions
  remain optional plain Markdown; no streak, ranking or required workflow.

These are individual reports, not a representative survey. We read public
conversations; we did not contact people or post on the user's behalf.

## Native workflow
Select a note in Noesis, choose a mode, state what you intend to do, and press
**Begin practice**. Obsidian opens a new editable session. Practice lists sessions
alongside problems; the Practice Base has a Sessions view. Session identity and a
source ID are retained; the original source note is not modified.

```sh
noesis practice 'Notes/My concept.md' --mode derive \
  --goal 'Derive the update rule without looking' --open
```

Modes: `pattern`, `interface`, `derive`, `build`, `transfer`.
A new session is not a successful attempt: record the actual outcome with existing
attempt/review controls. Any hint or agent help should remain visible in its record.

## Engineering quality
One dependency-free command and native components; no new plugin, server, polling
loop or mandatory vault hierarchy. Unit checks cover source preservation, five
modes, separate unique sessions, path refusal and absence of awarded confidence.
Sixteen tests pass. Live acceptance verified session creation, native opening,
actual Sessions Base data and default-hidden Recall. A native CLI registration
race is handled by retrying only the read-only handshake; mutations are never replayed. Existing
vaults receive an additive Playbook, Sessions view and teaching protocol; existing
notes and templates are not overwritten. Factory templates improve future notes.
