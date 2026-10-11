# Release hardening — 11 October 2026

This round closes the bounded software fault, storage-conflict, long-history and Linux portability cases below. Synthetic activity histories and external source fixtures are labelled agent validation; none are the owner's achievements. The owner trial, physical monitor disconnection and educational effectiveness remain unproven. Off-device configuration remains owner-deferred.

## Delivered behavior

- Cached reads and reconciliation refuse missing storage or a changed vault UUID before deleting cached history. Mutations carry the selected vault UUID and refuse a swapped owner before publication. Returning storage restores the same protected attempt and draft.
- **Settings → Resolve a restored or conflicting vault copy** exposes existing replacement/fork operations. Replacement requires the same owner, backs up registration and preserves original files. Fork creates independent identities at a new destination. The resulting vault can be selected in the dialog. Interrupted operations require inspection rather than blind repetition.
- **Settings → Code editor** selects Neovim or installed Zed. Exact owned files, including spaces, use argument arrays. Native Zed 1.23.2 opened and saved the scratch file in Restricted Mode. No project trust or cloud account was required. Zed's [Linux installation](https://zed.dev/docs/linux), [CLI](https://zed.dev/docs/reference/cli) and [worktree trust](https://zed.dev/docs/worktree-trust) informed this handoff.
- History presents readable event and assistance labels, with Older/Newer/Latest controls. It remains pageable rather than discarding older evidence.
- Preference publication waits until saved preferences are loaded, preventing startup saves from racing pending-operation recovery.

## Verified matrix

| Gate | Actual evidence |
|---|---|
| Publication faults | File fsync failure before replacement retains old bytes; directory fsync failure after replacement reports uncertainty; stale CAS refuses. |
| Forced termination / retry | Real child exits immediately after Markdown publication; committed witness is recoverable and retry creates no duplicate. Six concurrent processes with one operation ID publish one record. |
| Local restore | Actual encrypted Restic backup; injected restore publication failure exposes no partial destination; retry succeeds. Tampered reader snapshot refuses while the preceding verified copy remains recoverable. |
| Storage / identity | Missing root preserves cached generation; same-owner return resumes. Changed UUID at the same location refuses cached reads and CLI writes. Native replacement/fork preserves original bytes, registration backup and owner after restart. |
| Long history | Native 1,001 events across 21 bounded pages; all identities appear exactly once. Older/Newer/Latest, protected reference and draft survive storage interruption/restart. |
| Lifecycle | Twenty Hide/Open cycles stop worker/watch when hidden. Five-minute idle consumed 1.06 CPU seconds; PSS decreased from 161,609 to 66,899 KiB. These are process measurements, not physical input latency. |
| ScreenPad | Real main/ScreenPad rendering inspected. A test adapter made the supporting display unavailable, then restored it; main context survived. This is not a physical cable-unplug test. |
| Portability | CachyOS native Quickshell/Qt; existing Ubuntu 22.04 Distrobox host bridge and native guest Neovim capture; two isolated-home installations, idempotence, rollback and protection of later edits. Windows/macOS and arbitrary older Qt hosts are not certified. |
| Scale | 10k records: rebuild 3.859 s, warm worker query 47.91 ms, Today 32.263 ms, capture 148.213 ms; maximum measured worker response 7,812 bytes. |

## Zotero compatibility

[Official release history](https://www.zotero.org/support/changelog) identifies 10.0.6 and preceding 10.0.5. Both official Linux builds were tested in disposable profiles. The populated encrypted restore passes on both with the inspected initialization guard. Unpatched 10.0.5 reproduced the startup failure; the guard waits for creator/library initialization, rather than extending timeouts. The patch accepts only those versions plus the expected source signature and retains hash-checked rollback. Personal profiles were never repurposed.

[Zotero 9.0.6](https://www.zotero.org/support/9.0_changelog) lacks the local instance-identity header required for safe live imports. Noesis correctly refuses that API. Its native CSL conversion/export imported through the existing fallback; native exact annotation/page selection and populated encrypted restore passed in its isolated profile. This does not establish an ordinary UI export click path or supported live sync on 9. Use exported CSL JSON for bibliographic import, then open the PDF manually. Annotation synchronization requires a supported 10.x build. Untested releases fail the patch guard; they are not implicitly certified.

## Native evidence

- [Returning protected attempt](assets/release-hardening/returning-learner.png)
- [Oldest history page](assets/release-hardening/oldest-history.png)
- [Unavailable storage](assets/release-hardening/unavailable-storage.png)
- [Replacement review](assets/release-hardening/replace-location-review.png)
- [Fork review](assets/release-hardening/fork-location-review.png)
- [Resolved owner after restart](assets/release-hardening/resolved-vault-restart.png)
- [Zed owned code, Restricted Mode](assets/release-hardening/zed-owned-code.png)
- [Fullscreen work](assets/release-hardening/fullscreen-exploration.png)

Machine-readable results are retained beside these images. Native action assertions verify persistence and identity; screenshots alone do not establish those properties. Existing course, research, practice, drawing, numerical execution and self-service acceptance remains authoritative. No new learning schema or vault relocation is introduced.

## Checks

All 181 tests pass (165 core + 16 compatibility), including seven focused release-fault tests. Ten native shutdown cases, native coordination, scoped installation/rollback, native recovery and desktop stress acceptance pass. See retained JSON results for counts and measurements.

## Remaining release decision

The owner should perform the recorded 20–30-minute learner trial and report critical navigation/readability defects. Physical ScreenPad disconnection, physical input latency, delayed retention and educational effectiveness require their own observations. No software test can honestly substitute for these. Local recovery is not laptop-loss protection.

## Scoped live deployment

Implementation commit `308474101db2e206444ed8760d559da3ba35411d` was pushed and deployed through the backed-up scoped installer. All 89 deployed build hashes matched clean source. The independent `org.fh1m.Noesis` host at `~/.config/quickshell/noesis` passed three singleton reopens, Hide worker/watch shutdown and Close/restart context preservation. Wrayth PID 2795549 survived; unrelated window addresses, process identities and workspace placement were unchanged. The owner's original hidden state was restored. The retained deployment JSON identifies the exact rollback manifest; restore manifests in reverse deployment order.
