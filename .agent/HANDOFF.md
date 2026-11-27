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

After the current repair/PR/extended-observation work is complete, the user
requires exactly two source-led audit subagents. Do not launch them early or
replace current tasks. Account for every repository code file/line, and verify
actual Arete/Homie behavior rather than trusting docs. The native todo list
retains the complete additional scope: boot/resources, detailed visual parity
(including Homie's cursor), stale/hard-coded state, multi-account Codex controls,
current supported Claude usage, badge/Nerd Talk, drives and bidirectional file
access, existing audio/input/clipboard/sync, justified two-host capabilities,
Linux ecosystem research, issue-backed repairs and verified final PRs.

## Recovery

Use the audit's documented scoped fallback and retained private-prefix backups.
Do not restart input services to test shell recovery. Keep physical input and
emergency recovery independent of shell rendering. Never turn off safety
reserves or delete user history to make a check appear healthy.
