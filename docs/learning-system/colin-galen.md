# Colin Galen — four-video study

## What was actually inspected
Complete locally downloaded English auto-captions: approximately 16,390 words
across all four videos. Rolling caption duplicates were removed before reading.
This is a transcript study, not a claim to have inspected every on-screen diagram.
Auto-captions have errors: for example, the intuition video contains an apparent
intuition/insight substitution. Raw transcripts stay outside Git; this is synthesis.
Nothing here establishes that the learner has watched or mastered the material.

## 1. Intuition: recognize components, then justify
[Video](https://www.youtube.com/watch?v=1f6N2UrCK6o)

Colin distinguishes fast recognition from the reasoning needed to develop and
check a solution. Instead of memorizing entire answers, associate **features of a
problem with useful solution ideas**, including the questions, simplifications and
reasoning that lead to them. Explain why the association works and when it fails.

He describes rapidly studying hard problems and their solutions to expand this
recognition repertoire. But he explicitly limits this technique: it does not train
independent reasoning adequately by itself. Actually struggling, solving and
justifying gives deeper understanding. Test intuition by predicting a high-level
approach, then checking it with proofs, examples and counterexamples.

**Use here:** separate pattern-study from independent attempts. A recognized method
is not a solved problem. Preserve the original guess, evidence and a changed case.

## 2. Black boxing: usable contract before internals
[Video](https://www.youtube.com/watch?v=RDzsrmMl48I)

Understand what a tool does, its operations, inputs/outputs and computational
costs before learning every implementation detail. His examples include sorting,
Fenwick trees and suffix arrays. This opens access to problems that would otherwise
wait behind a long sequence of prerequisite study.

He recommends tested libraries and interface documentation, then small applications
to become comfortable. Internals still matter later, especially for modification.
The point is earlier meaningful use, not pretending an opaque tool is understood.

**Use here:** document the contract, assumptions, costs, one working example and
one failure case. Treat sufficient interface knowledge as the immediate gate;
mechanism study can run in parallel or become a deliberate deep descent. For
hardware and safety-sensitive work, required failure knowledge remains a gate.

## 3. Hard concepts: try to invent, then reinforce
[Video](https://www.youtube.com/watch?v=Dm68uFy6gus)

Begin with the purpose and big picture. Reveal details gradually while keeping
clear what each part contributes. For a difficult piece, understand the problem it
solves and honestly attempt to construct a solution before reading the explanation.
When independent effort stops being useful, use hints or inspect the solution.
Then break that explanation into manageable pieces too.

Reinforcement includes application to difficult cases, explaining in your own words,
and exploring variations: alter an assumption, seek a counterexample, ask why a
step exists. Return later and reconstruct rather than merely recognize. He calls
this a slow method suited especially to difficult, important concepts.

**Use here:** retain attempts; hide explanations during reconstruction; record what
could and could not be explained. Use the full process selectively, not as a
mandatory ceremony for every API parameter or incidental fact.

## 4. Creative problem solving: broaden, explore, discriminate
[Video](https://www.youtube.com/watch?v=-jmxvq0rF9o)

His generator/filter/explorer model is a practical metaphor: propose ideas,
discriminate between them and develop promising ones. If stuck, relax early
judgment, write unusual possibilities, try simpler or altered cases and combine
relevant past ideas. Briefly stepping away can help escape fixation.

For longer-term practice, combine diversity with substantial effort on individual
hard problems. He does not require solving every problem before benefiting from
it. Train discrimination with nearby wrong approaches and small variations, not
just polished correct solutions. He also acknowledges evolving his advice about
how much diversity matters.

**Use here:** keep candidate ideas and rejection evidence. A dead end becomes
useful when its failed assumption is explicit. Rotate problems when thought is no
longer productive; neither an arbitrary timer nor endless struggle is the objective.

## Synthesis for Noesis — our application, not Colin's prescribed software
1. State the capability and the problem that makes a concept useful.
2. Establish the smallest reliable interface contract needed to act.
3. Choose deliberately: pattern exposure, independent attempt, or deep study.
4. Record an actual prediction/attempt before revealing an answer when appropriate.
5. Extract the reusable cue, mechanism and boundary after feedback.
6. Reconstruct, test a changed case and implement or measure when relevant.
7. Let demonstrated transfer update confidence; reading completion updates position.

The existing resources, problems, attempts, concepts, errors and recall views can
hold this evidence without another plugin or mandatory new folder hierarchy.

## Limits
These are an accomplished competitor's learning recommendations, not universal
experimental results. Claims about permanent memory, IQ, unlimited ability and
specific subconscious mechanisms require separate scientific evidence. Do not
interpret a useful metaphor as literal brain architecture. Competitive-programming
success also does not by itself validate a method for every research or engineering
setting. Test usefulness against your own independent work and delayed transfer.
