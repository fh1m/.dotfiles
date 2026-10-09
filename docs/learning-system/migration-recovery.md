# Migration and recovery runbook

1. Inventory the chosen vault and preserve a recovery copy. Do not adopt Downloads.
2. Run `noesis migrate --vault PATH` to list notes requiring identity/schema.
3. Test `noesis migrate --vault COPY --apply` on a disposable copy first.
4. Compare learner prose, unknown metadata, IDs and index results. Repeat migration
   must change no records. Duplicate IDs and malformed metadata refuse mutation.
5. Apply to one vault at a time. Migration records original files under private
   local state and leaves folders/prose intact. Interrupted application can be
   rerun; originals remain in the recorded backup directory.
6. Rebuild/query with `noesis query --vault PATH`. Cache deletion is recoverable.

`noesis backup --vault PATH` retains compatible tar snapshots. Large artifacts are
listed as external rather than silently included. Restore with the existing
`sensei-learning-backup --restore ARCHIVE --dest NEW_DIRECTORY` command.

`noesis backup --restic --vault PATH` creates an encrypted local repository under
private state, checks it, and returns a snapshot ID. `noesis recover SNAPSHOT --dest
NEW_DIRECTORY` restores and validates the included file hashes before publication.
Keep the password file with the recovery system; it is not put into public Git.
No retention/prune operation is automatic until a verified replacement exists.

These routines protect local recoverability, not laptop loss. Off-device protection
remains deferred. External artifact manifests are references, not copies. Reader
database snapshot freshness must be inspected; restoring Markdown does not prove
that reader annotations and positions work. Keep legacy recovery copies until that
acceptance is demonstrated. Never overwrite a live reader database.

## Explicit restored ownership or independent fork

A restored copy keeps its identity. To make it the registered replacement:

```sh
noesis vault-register /path/to/restored --replace-location /path/to/original
```

Matching vault identities and a unique original registration are required. The
machine registry is backed up; original contents and Obsidian's registry are not
rewritten. An independently registered copy instead needs new identities:

```sh
noesis vault-fork /path/to/source --dest /path/to/new-fork
noesis vault-register /path/to/new-fork
```

Fork publication is staged, refuses duplicate record IDs and symlinks, remaps
local record references, retains explicit provenance and leaves the source
unchanged. Editor runtime, Git internals, cache and old operation receipts are
excluded. External artifact references still need their original storage.
Close editors before forking; Noesis locking cannot lock another editor's drafts.

## Off-device protection remains unconfigured

The viable strategy is a second encrypted Restic repository on an independently
reachable disk or authenticated remote storage. Keep the password outside the
vault and obtain its own recovery copy. Copy verified local snapshots using
Restic's supported repository-copy workflow; run repository checks and restore a
snapshot to a new location before enabling retention. Never prune the only
verified copy. No remote destination or credentials have been invented or
configured by this implementation. Local recovery does not protect laptop loss.


## Encrypt verified reader snapshots alongside learning data

Use the reader snapshot path printed by the existing reader-backup routine,
checking `database_sources` in its manifest. An open Zotero fallback to its internal
backup is explicitly timestamped; it is not claimed to be fresh. For a guaranteed
current snapshot, close that reader deliberately before its normal backup.

```sh
noesis backup --vault /path/to/vault --restic --reader-snapshot /path/to/reader-snapshot
```

The command validates containment and every snapshot checksum before including
reader state in encrypted recovery. It does not copy a live database into the
vault. After `noesis recover SNAPSHOT --dest /new/vault`, its response identifies
recovered reader-snapshot directories. Restore one into another new directory:

```sh
sensei-learning-backup --restore-reader /new/vault/RecoveredReaderState/0 --dest /new/reader-data
```

Select that new data directory in the reader's supported settings before opening
it. Never overwrite the running profile. Recovered reader snapshots remain in
subsequent encrypted vault backups; explicitly supplied newer snapshots replace
older projections from the same owning source, while older Restic snapshots stay
available. Large recordings and attachments above 25 MiB are explicit external
references requiring their own protection. Automatic reader-copy pruning is
suspended until a verified retention policy is configured.


### Replacement when the original storage is unavailable

New Noesis registrations retain the vault UUID alongside their location in the
private machine-local registry. An explicit `vault-register RESTORED --replace-location ORIGINAL` can therefore verify the identity after the original disk disappears.
It keeps a registry rollback copy and changes no Obsidian registration or learner
content. A legacy missing location without a recorded identity cannot be silently
verified; keep the restored copy intact and resolve its registration deliberately.

## Portable reader location and restoration

Sioyek profile discovery includes historical HOME/.local/share/Sioyek, the portable
XDG_CONFIG_HOME/.local/share/Sioyek location, distro XDG_DATA_HOME/sioyek and reader
configuration. Equal files in different profiles retain distinct source ownership.
SQLite online backup avoids copying a live database inconsistently. Native restore
acceptance reopened an isolated profile at its saved PDF page and retained bookmark
rows. No real reader database was edited for acceptance. Existing snapshots remain;
retention/pruning and an actual off-device destination are still unaccepted gates.
