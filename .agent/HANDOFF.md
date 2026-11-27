# Digital Den reliability — continuation

## Authority and boundaries

The current repair audit is `docs/digital-den/AUDIT-2026-11-27.md`.
PR #58 is merged at `3c04ce4546344a6b7db85ae5e5136cbb73dd1bea`.
It preserves unrelated uncommitted Noesis/Hermes/Spock work; do not reset,
blanket-stage or silently publish that work. The local development branch is
still `feat/zondo-hermes-den`; repair publication used
`fix/digital-den-reliability`. Do not rewrite either branch.

## Applied and verified

- Scoped deployments on both desktops; canonical `.local` host identities and
  pinned SSH identities, without DHCP/static-address changes.
- Watcher/child ownership, event-driven workspace state, truthful health,
  bounded jobs, backup integrity/restore checks, privacy and clipboard recovery.
- Actual Mesa allocation failure and Qt failed-commit freeze reproduced, then
  repaired through stamped private library prefixes, not distro replacement.
- Separate cursor THP policy supported by a same-workload allocation comparison;
  no global allocator, THP or compute-policy change.
- Native decoded-video handoffs across every currently connected output.
- Protected input/cursor/clipboard services retained their identities during
  final main-shell graphics adoption.
- Final PR workflow: 665 passed, 14 environment-specific skips, 57 subtests;
  install-safety passed. Hosted CI is not physical desktop acceptance.
- Fifty-three issues closed with per-issue verification receipts. #2, #3 and #6
  deliberately remain open pending extended memory/survival observations.

## In progress: do not claim 24-hour completion

Finite private samplers are running independently on both hosts. Treat PID plus
process start ticks as the cohort identity. Cursor sampling began before final
main-shell adoption; keep their lifetimes separate. A process deployment or
restart invalidates an uninterrupted-survival claim for that role.

Analyze completed samples for cold/1h/8h/24h PSS, swap, THP, CPU, descriptors and
PID survival; record workload/topology. Distinguish retained memory from live
allocations and swapped pages from a leak. Preserve prior observations rather
than merging incompatible cohorts. If an observed defect requires another
restart, document it and restart the relevant acceptance clock.

Private raw evidence, cores, logs, samples and rollback manifests belong in the
machine-local audit state, never this repository. Locate the existing private
continuation receipt before resuming; do not start duplicate samplers.

## Follow-up verification

A permanent opt-in native wallpaper-allocation regression was added after PR #58.
It exercises the actual production component in an isolated software Qt runtime:
original source exceeds the memory boundary (178.04 MiB peak RSS); repaired source
passes on both hosts. Hosted acceptance belongs to the follow-up PR record.
It does not launch a second live desktop, copy credentials or touch user content.

The user explicitly approved a fixed-path read-only rootfs helper after an
actual backup found unreadable root-owned SDK files. The reader is inode-pinned,
root-owned and limited to inspect/export; no general passwordless sudo or saved
password. The ordinary user backup includes a private atomic archive only after
successful preparation. See `docs/digital-den/PROTECTED-SDK-BACKUP.md`.
Actual primary backups now succeed on both hosts and the current Homie checkpoint
has been copied to Arete. Actual off-device restoration verified the archive
checksum and a protected member's content, mode and numeric UID/GID. The temporary
restore was removed; archive creation was not substituted for recovery proof.

The former 80 GiB peer-copy admission threshold was reconciled with the measured
56 MiB source repository: 80 GiB remains the working-space warning target,
20 GiB is the hard copy floor, and reserve checks remain active. No user data
was deleted. Preserve that explicit distinction in future changes.

## Requested subsequent phase

The user clarified that background observations must not stop unrelated audit
or implementation work. They still gate the corresponding issue closures, not
the whole project. Systems and visual source-audit lanes are running in the
background; a failed image-bound visual context was replaced without changing
provider. Exact coverage is incomplete and must remain explicit.
Account for every repository code file/line and verify actual Arete/Homie
behavior rather than trusting docs. The native todo list retains the full scope:
boot/resources, detailed visual parity
(including Homie's cursor), stale/hard-coded state, multi-account Codex controls,
current supported Claude usage, badge/Nerd Talk, drives and bidirectional file
access, existing audio/input/clipboard/sync, justified two-host capabilities,
Linux ecosystem research, issue-backed repairs and verified final PRs.
GTK themes, application icons and cross-host UI/UX coherence are explicitly
included. The broad audit has not been completed.

## Account audit checkpoint

A bounded source/native slice opened #61 (Codex multi-account lifecycle), #62
(Claude quota authority/freshness) and #63 (account-response ownership).
Unmodified production `CodeDesk.qml` reproduced `selected=second` while
`shown=default` in an isolated native runtime with controlled external responses.
The request-ownership fix is implemented and activated on both desktops. Seven
native regressions cover discovery order, account switching, date ranges,
removal, closure/reopen, provider changes and mismatched replies. The original
source fails the discovery regression. First live discovery and screenshots were
checked on both hosts; a synthetic invalid selection also distinguishes the
loaded fix from the old controller.

The main shell disables hot reload. Copying files was not activation: a live
probe caught old behavior until the existing supervisors replaced only the main
shells. Input, cursor and clipboard service identities/restart counts remained
unchanged. Preserve the recorded observation boundary rather than calling the
new main processes the same 24-hour cohort. `code.page` also now uses the central
monitor-aware open route rather than assigning the global dropdown name directly.

The Codex adapter currently reads one implicit app-server authentication context.
Claude Refresh currently reads saved status-line receipts and local analytics;
it does not fetch fresh subscription quota. Installed native Claude 2.1.319
`auth status` JSON was verified without a model session, but that is an
authentication observation, not quota retrieval. Verify supported provider/native
refresh before promising live data. Never copy credentials or infer remaining
quota from transcripts. Account lifecycle and current provider-quota work remain
open; the request-ownership repair does not implement those features.

## Recovery

Use the audit's documented scoped fallback and retained private-prefix backups.
Do not restart input services to test shell recovery. Keep physical input and
emergency recovery independent of shell rendering. Never turn off safety
reserves or delete user history to make a check appear healthy.
