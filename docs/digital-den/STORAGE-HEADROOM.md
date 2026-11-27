# Working headroom, not automatic cleanup

The desktop must report storage pressure without deleting a project, dataset,
recording, private note or build cache to make a gauge look healthy.

## Check

```sh
sensei-status storage
pytest -q tests/test_storage_budget.py tests/test_backup_peer_copy.py
```

System Monitor → Storage shows the same root-filesystem assessment. Zondo uses
that assessment for a debounced critical-storage warning. These are projections
of one implementation, `home/.local/share/sensei/storage_budget.py`; there is no
new background disk scanner.

The measurement uses `statvfs().f_bavail`: space available to an ordinary user,
not filesystem blocks reserved for root. Defaults:

- **80 GiB working reserve.** Below this is `reserve-deficit`, not a healthy disk.
- **20 GiB critical threshold.** Below this is `critical`.
- Missing measurements or invalid configuration are `unknown`, never zero usage
  or a false healthy result.

A private override belongs in `~/.config/sensei-den/storage-budget.json`:

```json
{"reserveGiB": 80, "criticalGiB": 20}
```

Both values must be finite, positive and ordered. Changing the display's reserve
is not permission to lower the separate backup-copy safety reserve.

## What this audit actually established

On 27 November 2026, an explicitly approved package-cache cleanup recovered
21.91 GiB. A later root measurement reported approximately 34.37 GiB available
on Arete; Homie's pre-build measurement was approximately 21.37 GiB. These are
point-in-time observations, not space guarantees. Both were below the working
reserve. Building software and collecting evidence change the available space.

The read-only directory inventory encountered permission errors. Its home,
cache and local-state totals are **lower bounds**, and those categories overlap.
Do not add them together, treat an inaccessible directory as empty, or publish
individual private filenames. No personal files, robotics datasets, repository
histories, transcripts or unrelated build caches were removed.

## Retention and placement

- Keep working source and small text on the normal development filesystem.
- Put large recordings, datasets and reproducible experiment outputs on an
  explicitly selected data volume. Use existing UUID-based mounts; never replace
  a missing data mount with an accidentally writable directory on root.
- Keep experiment receipts beside the project, with links/checksums for external
  data. Synchronization is not backup.
- Package archives are reproducible cache, but also support rollback. For routine
  maintenance, review a two-version installed-package retention policy rather
  than repeating the exceptional all-cache cleanup used during this incident.
  No new automatic pruning job was enabled by this audit.
- Keep bounded operational logs and completed-job retention separate from user
  artifacts. A log-size cap must not truncate the actual dataset or report.
- Never prune original conversations, private notes or plug-in caches as a
  resource optimization. Select and approve an archival destination first.

## Backups must fail honestly

Repository checks now propagate Restic failures. Weekly integrity/restore
verification was exercised against the configured repositories on both hosts;
restored synthetic markers matched their recorded checksums. Consistent local
restoration is evidence of recoverability, not proof of a fresh off-device copy.

Peer copying checks the repository generation, expected snapshot age and
available destination space again before copying. A destination below its
configured 80 GiB reserve must return a visible blocked receipt. It must not
silently copy yesterday's snapshot or reduce that reserve to make the test pass.
That capacity block was still present during this audit.

Free space by an approved placement/retention decision, then retry the copy and
verify the destination snapshot. Until that succeeds, do not describe peer
backup as current or protection against losing the source machine.
