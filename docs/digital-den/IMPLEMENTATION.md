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
| P0 recovery | Private backups, baseline, outstanding-work ledger | In progress |
| P1 music | Shared request control, quota handling, native transport regression tests | Pending |
| P2 displays | Identity-based roles and routes, hotplug fallback, PC DP-2 accepted | Pending |
| P3 continuity | Capacity-aware personal mirror, agent parity, verified local restore | Pending |
| P4 remote/compute | Private connectivity, persistent job, checked artifact | Pending |
| P5 companion/UI | Isolated click-through companion, host/role labels, quiet control | Pending |
| P6 display handoff | Guided modes; physical switching explicitly gated | Pending |
| P7 acceptance | Tests, clean reviewed gallery, identical revisions, idempotence | Pending |

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
