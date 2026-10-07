# Oasis: practices, not personality cosplay

These are source-grounded practices adapted to fh1m's autonomy/robotics work.
They are not claims that these people use Obsidian, this desktop or our templates.
Research: 20+ targeted searches and primary-source inspection, including every
person explicitly requested. Their exact routines are not a universal prescription.

| Source | Useful principle | Oasis implementation |
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

No system makes greatness automatic. Oasis makes the next honest experiment,
understanding gap and retrieval test easier to reach.

## Native Obsidian CLI inspection

Verified on the actual laptop: enabled native CLI reports 1.13.7. Its `help`
exposes templates/create, daily, search, properties, tasks, backlinks/unresolved,
history, Bases query and developer inspection. [Official CLI reference](https://obsidian.md/help/cli)
and [Bases syntax/functions](https://obsidian.md/help/bases/syntax) informed the
bridge. We use native commands, with exact vault-path verification before actions;
no third-party replacement CLI and no community plugin needed for this capability.
