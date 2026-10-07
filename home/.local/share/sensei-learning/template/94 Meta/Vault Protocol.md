# Small schema, useful links

Numbered folders retain the seed vault's roles: Home, Foundations, Courses,
Labs, Concepts, Questions, Errors and Bugs, Sources, Visuals, Reviews, Projects,
Real World, Future Branches, Inbox, Daily, Templates, Bases and Meta.

Common properties: `type`, `status`, `domain`, `created`. Use `confidence` (0–5)
and `review` (YYYY-MM-DD) for recall-bearing notes. Do not fill optional fields
until they help a real view or decision. Keep learning `layer`, `course`, `stage`
and `source` where they already have meaning.

Concept states: seed → working → solid → revisit. Questions: open → resolved.
Labs/projects: planned → active → complete (or failed). Prerequisites: active →
passed, with demonstrated exit-test evidence. Sources: inbox → skimmed → active →
extracted; canonical is a trusted reference, rejected/archived is retained provenance.
Branches: parked → selected; a branch never silently becomes an active gate.

## Dependencies are roles at an interface
Path/project/frontier notes use `gates`, `parallel`, `deep_descent`: lists of
quoted wikilinks. Operational prerequisite notes use `depends_on` for their
smaller prerequisites, plus `prerequisite_class` and `serves` to show the specific
build they support. A prerequisite's class is contextual; split role notes if
it is a gate for one build and an optional descent for another.

Edges point **from the thing being learned to its prerequisite**. This direction
must remain acyclic. General conceptual links and future branches are not edges
in the prerequisite DAG. Keep the minimum understanding and exit test in prose.

Equations: symbols, units, assumptions, sanity check and boundary case. Software:
representation, state transition, invariant, concrete trace and failure condition.

Sources need a reason and a served question/build. Errors preserve original
belief, contradiction, corrected model and earlier-detection heuristic. Raw agent
output belongs in `90 Inbox/Agent Drops`, not a mastered Concept.

Git stores Markdown and durable defaults. Never track workspace/session files,
plugin mutable state, credentials, caches, build output or giant raw recordings.
Store large experimental evidence separately and link to its path + checksum.
