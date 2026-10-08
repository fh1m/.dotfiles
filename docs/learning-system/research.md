# Noesis: practices, not personality cosplay

These are source-grounded practices adapted to fh1m's autonomy/robotics work.
They are not claims that these people use Obsidian, this desktop or our templates.
Research: 20+ targeted searches and primary-source inspection, including every
person explicitly requested. Their exact routines are not a universal prescription.

| Source | Useful principle | Noesis implementation |
|---|---|---|
| [Andrej Karpathy — training recipe](https://karpathy.github.io/2019/04/25/recipe/) and [Zero to Hero](https://github.com/karpathy/nn-zero-to-hero) | Inspect data, start with a checkable baseline, add verified complexity incrementally. | ML experiment scaffold: tiny-batch check, baseline, leakage checks, ablation, actual observations. |
| [George Hotz — From the Transistor](https://github.com/geohot/fromthetransistor) | Build the layers that make the next abstraction possible. | Preserve the CS course spine; small gate tests and runnable builds. |
| [Ilya Sutskever et al. — Sequence to Sequence](https://arxiv.org/abs/1409.3215) and [Learning to Execute](https://arxiv.org/abs/1410.4615) | Examine a concrete learning mechanism and the experiment supporting it. | Paper reconstruction: predict, redraw the mechanism, reproduce a small baseline, test a counterexample. This is our adaptation of published research, not a claim about his private study routine. |
| [John Carmack — long-form interview](https://lexfridman.com/john-carmack/) and [Quake source](https://github.com/id-Software/Quake) | Read an engineer's discussion and actual production implementation together. | Source-reading lab: trace one path, inspect state/ownership, measure and perturb. This exercise is our synthesis, not a claimed Carmack note-taking method. |
| [Richard Hamming — You and Your Research](https://www.cs.virginia.edu/~robins/YouAndYourResearch.html) | Deliberately identify consequential questions and gaps. | Weekly review: important open problem, tractable next experiment, blocked assumption. |
| [Richard Feynman — Cargo Cult Science](https://calteches.library.caltech.edu/3043/) | Make disconfirming evidence visible. | Failed-model ledger; observations, inference and source claims remain separate. |
| [Russ Tedrake — system identification](https://underactuated.mit.edu/sysid.html) | Connect dynamics models to measured behavior. | Robotics lab: units, frames, excitation, sensor timing, uncertainty and validation data. |
| [Andrew Ng — practical error analysis](https://see.stanford.edu/materials/aimlcs229/transcripts/MachineLearning-Lecture11.html) | Diagnose error sources before choosing an improvement. | Baseline, error categories, targeted experiment and counterexample. |
| [Bret Victor — Learnable Programming](https://worrydream.com/LearnableProgramming/) | Make execution and state observable. | Code trace, debugger state and connected diagrams rather than passive code copying. |
| [Michael Nielsen — Augmenting Long-term Memory](https://augmentingcognition.com/ltm) | Design deliberate recall around material worth retaining. | Reconstruction queue; selective factual cards remain optional, not the whole system. |
| [Paul Graham — How to Do Great Work](https://paulgraham.com/greatwork.html) | Follow real curiosity toward a frontier and finish small work. | Capability goals plus parked future branches; curiosity does not become prerequisite debt. |
| [Dunlosky et al. — learning-technique review](https://acs.ist.psu.edu/ist521/dunloskyRMNW13.pdf) | Retrieval and distributed practice deserve priority over familiar-looking rereading. | Reviews ask for reconstruction and record the learner's evidence, not time-on-page scores. |

## fh1m's work determines the fit

Software/agents: define the contract and oracle; review a real diff, trace a
mutation, write a counterexample and replace a small part yourself.

Robotics: frame, unit, timebase, latency, failure recovery and hardware interfaces
are first-class evidence. A simulator success is not a hardware result.

ML/research: reproduce a baseline before claiming novelty; separate train/test,
measure what changes, record a failed hypothesis, then choose one informative test.

No system makes greatness automatic. Noesis makes the next honest experiment,
understanding gap and retrieval test easier to reach.

## Native Obsidian CLI inspection

Verified on the actual laptop: enabled native CLI reports 1.13.7. Its `help`
exposes templates/create, daily, search, properties, tasks, backlinks/unresolved,
history, Bases query and developer inspection. [Official CLI reference](https://obsidian.md/help/cli)
and [Bases syntax/functions](https://obsidian.md/help/bases/syntax) informed the
bridge. We use native commands, with exact vault-path verification before actions;
no third-party replacement CLI and no community plugin needed for this capability.


## Lifelong-learning expansion
58 targeted searches covered learning research, official reader/editor APIs,
researcher/developer primary work and community reports. Search count is not a
quality claim; noisy results were rejected. Community discussions inform friction
and failure cases, not scientific effectiveness or private celebrity routines.

| Source | Decision |
|---|---|
| [Karpicke & Blunt](https://pubmed.ncbi.nlm.nih.gov/21252317/) | Use reconstruction evidence, not note-count progress. The tested advantage of retrieval does not make diagrams useless. |
| [Dunlosky review](https://acs.ist.psu.edu/ist521/dunloskyRMNW13.pdf) | Selective retrieval and distributed practice; reading/highlighting remains source processing, not proof of learning. |
| [Keshav's paper-reading guide](https://www.cs.princeton.edu/courses/archive/spring21/cos563/papers/HowToRead.pdf) | Scale reading passes to the goal; connect a deep pass to reconstruction/implementation. |
| [PLOS paper-reading rules](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1008032) | State why this paper matters, question its claims and inspect unfamiliar concepts. |
| [Karpathy's build-nanogpt](https://github.com/karpathy/build-nanogpt) | Small understandable implementation steps with runnable evidence. |
| [USACO practice advice](https://usaco.guide/general/practicing) | Appropriate challenge, deliberate attempts, editorials as feedback and later reconstruction. |
| [Zotero PDF reader](https://www.zotero.org/support/pdf_reader) | Citation/page-linked annotations; explicit exported PDFs for external readers. |
| [Zotero syncing](https://www.zotero.org/support/sync) | Separate data and attachment sync; never put the live database in generic file sync. |
| [Sioyek usage](https://sioyek-documentation.readthedocs.io/en/latest/usage.html) | Technical reading, reference previews, history and portals; preserve media keybindings. |
| [Quickshell FloatingWindow](https://quickshell.org/docs/v0.3.0/types/Quickshell/FloatingWindow/) | A persistent normal window rather than a click-away layer popup. |
| [Zotero Integration repository](https://github.com/community-archive/obsidian-zotero-integration) | Repository redirected to community archive during inspection. Supported exports avoid depending on it. |
| [Community paper implementation discussion](https://www.reddit.com/r/learnmachinelearning/comments/1c4lbl8/) | Reproduction scope, prerequisites and implementation ambiguity deserve explicit records; popularity is not validation. |

### Colin Galen: supplied videos inspected through captions
Auto-generated English captions were retrieved locally with yt-dlp; they can contain
transcription errors and are not republished in this repository.
- [Intuition / hard problems](https://www.youtube.com/watch?v=1f6N2UrCK6o): repeated exposure and recognizable structures motivate a problem/attempt trail, then independent transfer checks.
- [Black-box method](https://www.youtube.com/watch?v=RDzsrmMl48I): use an interface's inputs/outputs before descending into its implementation; this fits parallel/deep-descent prerequisites. It does not mean copying without later testing or understanding.
- [Hard concepts](https://www.youtube.com/watch?v=Dm68uFy6gus): examples, insights and deliberate reflection motivate connections between a concept, concrete cases and its purpose.
- [Analytical problem solving](https://www.youtube.com/watch?v=-jmxvq0rF9o): deliberate creative problem work is an activity to record and test. Broad subconscious/neuroscience explanations are not treated as established science.

Lattner/compiler work and Keller's public engineering material were searched for
first-principles and interface practices. No verified personal vault routine was
found or fabricated. Noesis makes source tracing, models, boundary cases and
experiments possible; it does not claim a famous-person recipe or literal brain map.

### Search inventory
Groups searched: Obsidian Bases/Canvas/CLI; Zotero PDF annotations, metadata,
sync/storage, native exports, citation keys and integration maintenance; Sioyek
highlights/portals; Zathura SyncTeX; each of the four supplied video IDs; Colin
Galen practice; USACO and AoPS; retrieval, spaced practice, self-explanation,
productive failure and active learning; Karpathy (three queries), Sutskever
(two), Hotz (two), Lattner, Keller, Carmack (two); Reddit Obsidian/GradSchool/
AskAcademia/Anki/ML implementation; Hacker News paper reading, programming
recall and scientific notes; Keshav, PLOS, Distill, MIT OCW, MIT learning science,
Harvard study strategies; plugin performance/review; Syncthing and Restic;
Quickshell window APIs and Zotero annotation export support.

### Deliberately rejected
A browser learning app, mandatory flashcards, imported-annotation-as-understanding,
celebrity imitation, a graph advertised as a brain replica, duplicate PDF annotation
authorities, archived-plugin dependence, automatic cloud signup and always-running
index polling. Existing specialized tools beat rebuilding their editors.

[Complete four-video synthesis and limits](colin-galen.md).
