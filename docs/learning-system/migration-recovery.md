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
