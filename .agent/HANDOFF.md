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

The first finite samplers were interrupted by the 28 November OOMd event.
Keep their partial evidence; do not report a completed 24-hour observation.
Start replacement independently supervised cohorts after the final activation,
with PID plus process-start ticks as identity. A deployment/restart resets the
uninterrupted-survival clock for that role.

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

The Codex multi-account backend is integrated and activated. Five existing Arete
contexts and Homie's native profile returned real limits. Monitoring add/remove
does not alter sign-in or active-account selection; cancelled/removed generations
cannot repopulate the current view. Nineteen Bun regressions passed.

Native Claude `/usage` now succeeds through the pinned CodexBar CLI, explicitly
using its CLI source and a user-approved isolated probe directory. There is no
model prompt, cookie import or credential copying. The new `claude_quota.py`
adapter and `sensei-code` cutover were exercised against the real account:
identity matched, subscription windows were returned, and transcript analytics
were not loaded. Source tests cover identity/organization isolation, invalid
measurements, age preservation, bounded refresh and authentication changes.
The widget cutover is deployed; Homie's provider trust/refresh acceptance remains
separate and requires interactive approval. Never copy another host's trust.
Never reintroduce saved status-line activity as current provider quota.

## Recovery

Use the audit's documented scoped fallback and retained private-prefix backups.
Do not restart input services to test shell recovery. Keep physical input and
emergency recovery independent of shell rendering. Never turn off safety
reserves or delete user history to make a check appear healthy.

## OMP crash recovery — current

The 28 November 03:13:49 interruption was **systemd-oomd** selecting the old
terminal scope under global RAM/swap pressure. There was no coredump or verified
individual allocation culprit. Do not call it a fixed Bun exception or confuse
it with the separately proven Mesa/Qt defects.

Arete's recovered main now runs in `sensei-shell.service`, independent of the
coding terminal. The real launching-unit termination smoke passed. The new
GUI helper must use transient **services**, not synchronous scopes: the actual
scope negative control lost its test app on launcher termination. The service
version survived and preserved cwd, literal arguments and ROS/CUDA paths.
Do not restart the main before checking that its cgroup contains only owned
watchers, not already-launched user applications.

The owned app, quota, UI-freshness, rollback, CPU and companion repairs are
integrated. Both main shells run in their independent `sensei-shell.service`.
The integrated native run passed 764 tests and 57 subtests, with three skips;
later companion/peer-path changes passed 45- and 40-case targeted batches.
The full source audit remains partial and #2/#3/#6 retain independent 24-hour
acceptance gates. Do not call an interrupted cohort complete.

Named LAN SSH uses `den-peer-connect` discovery with existing host-key pins;
global mDNS return-path success is NOT established on Arete. The typed operator
ping must use the explicit paired executable path: noninteractive SSH lacks
the user bin directory. Actual application presence now reports Together.
Input startup resolves/pin-checks the peer and waits for root policy readiness.
The native preflight passed without starting capture; preserve user-paused
state and independent input/clipboard service identities.

All eleven Syncthing folders reached idle/error-free on both hosts; a real
forward/reverse/deletion journey passed. Generated vendor images/rootfs are
excluded, not deleted. Homie's video replica moved to the data volume with its
former copy retained. Synchronization is not backup.

Actual native GTK3/4 windows were inspected on both hosts. GTK3's invalid
`:root` rule is removed; `Adwaita-dark` and its required `gnome-themes-extra`
asset now work on Homie as well. Keep Zed Mono/Iosevka, Kora, OLED/pink overrides
and the existing artwork. Screenshot targets must be checked against the actual
invoking output and allowed to settle, not assumed to be the primary monitor.

Zondo's location controls no longer erase reduced motion. Reduced-motion Homie
can receive a static lease; quiet/suspended gates remain. Live compositor state
verified one actor on Homie and none on Arete. Canonical roaming is now enabled;
private preimages exist. Physical drag/toss/games and long animation acceptance
remain unclaimed.

Git-AI's global Trace2 consumer wrote late into disposable test repositories.
The test-session-only event override prevents that race; ordinary development
attribution and global Git configuration remain unchanged.


Native provider safety follow-up: pinned CodexBar can auto-accept its dedicated
probe's trust prompt. `claude_quota.py` now refuses a provider process unless
that exact native profile already trusts the dedicated directory. It never
writes/copies that consent. The guarded Arete refresh succeeded; Homie has the
pinned binary installed but its real backend honestly requires approval.
Nineteen native-quota tests passed, including a harmless child that must never
launch without consent.

Actual SSHFS forward/reverse/delete and both file-manager launches passed.
The separate completed one-minute samples measured main-render CPU medians
0.30%/0.25% of one core on Arete/Homie, with final PSS158.6/358.6MiB and
swap221.8/199.4MiB. Do not report those as total-desktop CPU or a long soak.

The final intended-source export passed 764 tests, 57 subtests and three skips
in 151.98 seconds, independently of original Noesis/Notion working changes.
Homie Hacker News also loaded eight Show/eight Ask items through its native UI.
Two Homie-only Bluetooth commits are preserved at
`refs/remotes/homie-reviewed/main`; their full three-component delta is already
retained by canonical source, with its additional corrected power-action label.
Reconcile history without resetting Homie's checkout or including unrelated WIP.

PR #65's first CI run found nine Qt-query fixture timeouts on the clean runner.
The supervisor now discovers `qtpaths6`, Arch's explicit Qt6 path, then `qtpaths`;
fixtures model the query protocol independently. Thirteen selection cases passed.
Both actual supervisors completed version-mode smoke at Qt 6.12.0 after scoped
deployment without main-shell restarts. The original ABI safeguards remain.

## Post-merge companion/session follow-up

PR #65 merged at `3bd55db`; #68 merged at `35cf5aa`. Issues #61/#66/#67 are closed.
Both checkouts reached that `main` baseline without reset. The current owned
audio follow-up remains separate from original unstaged Noesis/Notion work.

New reproduced issues: #66 reaction-round counters survived restart; #67
companion queries forced compositor index zero even with a selected session.
The reaction initializer is shared. The existing socket-validated selector moved
to `desktop_session.py` and is reused by the launcher/operator. Two session
regressions failed before; 62 related cases pass after. Both native context-free
protocol probes work. Backend deployment restarted only `den-watch`.

The games UI defers guest configuration behind an explicit control; native
before/after screenshots verify that games no longer hide below that list.
`shell.qml` disables unsafe file-triggered reloads, so activation used only the
inspected shell services. Input, clipboard and cursor service identities stayed
unchanged. Never clear the user's input-pause marker or restart those services
as a side effect of UI deployment.

Real layout-test jobs passed on both hosts: four tests each, matching input
hashes/source commit, explicit 1 CPU/512 MiB/60s/1 MiB-log bounds. Both checksummed
JUnit artifacts were fetched privately and parsed. This is not a GPU benchmark.

The games/session export passed 767 tests, 57 subtests and three skips in
156.87s, peak1GiB/no swap. The later audio activation now has main PIDs
Arete3328113 and Homie3526986. Protected input/clipboard/cursor state and PIDs
stayed identical. Both native mixer screenshots retain coherent fonts/icons.
An actual 74-frame/2.43s audio-free native recording captured open/close/reopen;
observed readiness0.490/0.195/0.484s is not a percentile or global-FPS guarantee.

The sole final finite collector on each host is
`den-audit-ui-final-20261128-19f24781.service`. Superseded owned collectors were
stopped, not erased or declared passed. Never poll collectors or close #2/#3/#6
from a short sample. Physical input remains unavailable to the current Wayland
harness; no actual pointer/gameplay/keyboard-traversal claim.

## Audio recovery follow-up

Issue #69: actual CLI failures were falsely reported as empty devices; native
QML also erased last-known context. New code preserves that context, blocks
stale controls, separates query/action errors and recovers without hiding failed
actions. Errors are visible above controls; semantic tab icons are explicit.
The full intended-source suite passed 773 tests/57 subtests/3 skips in157.40s,
peak1GiB/swap392KiB. Actual healthy metadata and native UI were checked on both
hosts. All audio defaults/gains/mutes/ports/profiles stayed identical; the stopped
Den route remains off. No microphone/conversation recording or audio-server
restart occurred. Protected physical-control identities remain unchanged.
