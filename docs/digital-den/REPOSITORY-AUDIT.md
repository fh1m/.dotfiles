# Main-branch consolidation — 2026-10-15

## Preserved history

| Former branch | Audited tip | Treatment |
|---|---|---|
| main | 47c402a local, 43a14e0 remote | Local safety commits retained |
| pc | e3f96b2 | Merged installation/recovery/storage history; current installer retained |
| feat/homie-current-desktop | 64f3bda | Merged runtime; hard-coded desktop policy moved into profiles/pc |
| feat/first-principles-learning-system | 53b1ba3 | History merged; 540 learning/reader/renderer files integrated explicitly |
| legacy-wrayth | a863163 | Already an ancestor of main |

Annotated archive tags preserve these old tips. All branch tips must be ancestors of the published main before branch deletion. No rebasing, force push, hard reset or Git clean is part of this consolidation.

The learning branch's older desktop settings were not reapplied over the newer daily driver. Its history remains available; the supported current learning backend, templates, UI, readers, tests and renderer patches are now on main. PC overrides are explicit, rather than replacing shared laptop policy.

Fifty-six pre-existing desktop edits were reviewed, backed up and committed separately as f350f22. One private staged PhoneBridge modification in the old learning worktree is excluded from public commits and retained in a private archive. No subject vault content was imported.

GitHub audit found one open PC-to-main PR (#1) and no issues. Its install-safety check passed. Its firmware/cold-boot acceptance warnings remain valid after the merge; merging source does not prove unattended boot works.

## Validation record

Cross-profile rendering and installer idempotence are automated. Live checks cover the four configured Den crossing/return combinations, triple-Ctrl pause and resume, bidirectional text/PNG clipboard and actual service state. Main installation is previewed/applied separately on each host; private pairing is not overwritten.

Cold-start tests exposed competing same-address DTLS connections for the two source edges. The native connection layer now reuses a live matching peer, propagates liveness to its handles, and clears them together on disconnect. Three Rust regressions passed. The supervised desktop run completed 12 routed typing/Ctrl+A/click/scroll sequences (three passes of every route), followed by pause/resume. The harness also generates relative device motion: compositor warps alone are insufficient to exercise handshake retry behavior. Native receiver input stays ungrabbed and independent expiry guards remain mandatory during supervised tests.

## Working agreement

Both checkouts use main. Fetch, inspect local changes, fast-forward, validate the correct hardware profile. Keep feature experiments in disposable detached worktrees when needed, then integrate promptly. Do not maintain machine-specific development branches. Public reusable source and private live state are separate trust domains.


The PC crash reporter retained an 08:23 context-menu SIGSEGV. The running shell
was responding; the report was not evidence of a new crash during deployment.
The same null-focus/origin event crashed a disposable Qt 6.11.2 test. A local
public-Qt-API generic plugin filters only that invalid synthesized context-menu
event. Original mouse actions and valid context menus pass through. See
[the guard source and tests](../../src/qt-context-guard/README.md).


Final desktop stress: four right-clicks at the bar origin and five cycles through
System, Monitor, Calendar and Sound passed on each host with the same shell PID.
Both Qt 6.11.2 (Arete) and Qt 6.12.0 (Homie) crashed the isolated unguarded
reproducer and passed the guarded delivery plus plugin startup/shutdown tests.
The production shells loaded the guard; the historical PC crash reporter was
closed without deleting its diagnostic core. This validates the observed crash
path, not a promise that all possible Qt defects are eliminated.
