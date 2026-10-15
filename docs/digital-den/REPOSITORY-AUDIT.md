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

One cold-start test reached a crossing before the second DTLS connection was ready. The harness now waits for receiver arming and retries the boundary rather than asserting a fixed handshake delay. This does not prove zero connection latency. Native receiver input stays ungrabbed and the independent expiry guard remains mandatory during supervised tests.

## Working agreement

Both checkouts use main. Fetch, inspect local changes, fast-forward, validate the correct hardware profile. Keep feature experiments in disposable detached worktrees when needed, then integrate promptly. Do not maintain machine-specific development branches. Public reusable source and private live state are separate trust domains.
