# Discover shortest paths — reusable Noesis example

This is an example scaffold, not your learning history. No code runs when Noesis opens it.
Copy this directory into a new local Git repository before working. The implementation
starts empty; the inspectable tests contain cases and a Bellman–Ford oracle, not Dijkstra.
Consulting that oracle counts as reference assistance if it informs your reconstruction.

1. In Practice, create a problem: A→B costs 10, A→C costs 1, C→B costs 1.
   Predict distances from A and explain when a distance becomes permanent.
   Start an independent attempt, preserve your reasoning and honestly record the outcome.
2. If it fails, choose **Investigate the missing mechanism**. Ask why discovery differs
   from finalization. Connect a nonblocking prerequisite such as a greedy invariant or heap.
   Use Back or **Return to…** to recover the exact question and problem.
3. After ending the protected attempt, use **History & next steps → Connect implementation**,
   select your own Git repository, then open it in the editor. Implement `shortest_paths`.
   Commit what you wrote. Explicitly run `python check_cases.py --output observations.json`.
   A failed run is valuable evidence. Preserve its JSON before revising the implementation.
4. From the implementation, create an experiment with your prediction. Connect the
   observed JSON artifact and its code commit. Record a comparison with actual output,
   conditions, discrepancies and remaining questions. Noesis does not infer execution
   from opening an editor or saving a comparison.
5. Preserve the reusable invariant in a normal concept/Obsidian note. Link it to the
   question and evidence. Negative edges invalidate the usual greedy argument; input
   rejection is a safety contract, not proof that negative-weight paths cannot exist.
6. Choose **Try a changed problem**, even if earlier work failed. For a directed graph,
   find every vertex's shortest distance *to* a fixed destination by considering the
   reversed graph. Include isolated vertices and zero-weight edges. Hide references,
   predict first, and record independent or assisted results honestly.

Use the problem's **Question, mechanism & implementation** context to navigate the same
records. During a protected attempt these links stay out of the reasoning surface.
Keep the statement on ScreenPad while reasoning on the main display; never pin a solution
for an unaided attempt. Rich proofs and diagrams belong in Obsidian, code in Git, outputs
in immutable artifacts. A matching test run does not establish correctness or mastery.
