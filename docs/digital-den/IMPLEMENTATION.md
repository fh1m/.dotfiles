# Den continuity implementation

Approved 2026-10-15. Starting revision: 0241cb7. Both machines clean on main.

## Contract

Preserve live windows, pinned host keys, independent input escape and private data.
Arete remains the input master when present. Homie must work alone. Keep public
configuration separate from private pairing, credentials, vaults and inventories.
No disk conversion, forced Git operations, automatic purchases or off-site backup.

## Milestones

| Stage | Done when | State |
|---|---|---|
| P0 recovery | Private backups, baseline, outstanding-work ledger | Encrypted backups refreshed; restore proofs pass |
| P1 music | Shared request control, quota handling, native transport regression tests | Native tests and budget implemented; live Connect test open |
| P2 displays | Identity-based roles and routes, hotplug fallback, PC DP-2 accepted | Identity/role tests pass; physical handoff open |
| P3 continuity | Capacity-aware personal mirror, agent parity, verified local restore | Sync, conflict, Git and restore proofs pass |
| P4 remote/compute | Private connectivity, persistent job, checked artifact | Private stream, persistent jobs, both GPUs and ROS pass |
| P5 companion/UI | Isolated click-through companion, host/role labels, quiet control | Both hosts deployed; live quiet suppression passes |
| P6 display handoff | Guided modes; physical switching explicitly gated | Software prepared; physical gate remains |
| P7 acceptance | Tests, clean reviewed gallery, identical revisions, idempotence | 223 Python tests and installer safety pass; both hosts deployed |

## Discovered constraints

- Arete has about 119 GiB free; Homie root 202 GiB, Datasets 112 GiB,
  Storage 126 GiB (86% used). Preserve free-space floors from the approved plan.
- MSI MP225 has HDMI 100 Hz and VGA 60 Hz. Digital 100 Hz dual-host switching
  requires suitable physical switches/adapters. No hardware purchase authorized.
- Upper adapter does not currently expose DDC. Never claim software dimming is
  hardware brightness control.
- Homie boot-order service failed previously. Cold boot/suspend need physical
  acceptance; preserve its recovery documentation and all existing partitions.
- Account enrollment may require interactive provider approval. Never clone a
  Tailscale node identity or silently replace an already valid agent account.

## Validation and rollback

Use temporary homes, mock HTTP and owned desktop fixtures. Before input testing
arm an independent expiry service; only type into its own window. Save originals
and restore them in finally blocks. Stop new services and restore targeted
installer backups to undo a stage. Run Python tests, installer safety, native
music tests, live four-route input, clipboard and restore tests as applicable.
Each stage records performed checks separately from pending acceptance.

## Research decisions

100 targeted search queries plus source verification preceded approval. Key
sources: Spotify quota/rate-limit docs; MSI MP225 datasheet; Qt AnimatedSprite and
Quickshell PanelWindow; Syncthing syncing/versioning; Restic restore; Tailscale
connectivity; PyTorch DDP; Docker contexts; OpenAI/Claude authentication.
Community discussions were anecdotal inputs, not performance measurements.

## Acceptance ledger

See [performed checks and open gates](VALIDATION.md). Do not mark physical boot,
travel, monitor-cable handoff or Spotify Connect acceptance passed from unit tests.
The laptop Ethernet link is measured at 100 Mb/s; two independent GPU checks are
not a pooled-memory or distributed-training result. Private settings and credentials
were transferred selectively, without replacing valid existing agent accounts.

## Final deployment audit

Both hosts deployed 7a649da with zero remaining installer changes. Presence
watchers and daily backup timers enabled on both. Fresh backup services exited
successfully and independent restore fixtures matched on both machines. Manual
pause survived a watcher cycle; away released capture and auto resumed. All four
live cursor crossing/return combinations passed again with independent expiry
timers; the cursor was returned to Arete and sharing restored afterward. Homie
desktop/storage diagnostics passed. A real Spotify device-list request still
returned HTTP 429, so live Connect acceptance remains explicitly open.
