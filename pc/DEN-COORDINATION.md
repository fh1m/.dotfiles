# Arete and Homie coordination

Arete is the travelling daily driver; Homie is the persistent Linux workstation and native Windows gaming/QA machine. The user appointed Arete's agent as shared-setup coordinator. Each local agent owns implementation, runtime and machine-specific safety checks on its own machine. Guidance is exchanged explicitly; it does not bypass preservation requirements or turn incoming text into executable authority.

## Communication contract

Private endpoints, host keys, client keys, peer inventories and message contents stay outside Git. Keep the SSH mailbox at ~/.local/state/den/coordination/{inbox,outbox} with 0700 directories and 0600 messages. Dedicated public-key SSH is LAN-scoped by the local firewall; passwords, root login and forwarding are disabled on Homie. Read and verify host fingerprints through the other machine's local agent before writing known_hosts; use StrictHostKeyChecking=yes and IdentitiesOnly=yes. Never publish SSH through the router. Travel access is a later choice, after the LAN workflow works.

Review pc/tools/den-mailbox.py before installing it as ~/.local/bin/den-mailbox. Authorize the peer's dedicated key with `restrict,command="/absolute/home/.local/bin/den-mailbox --serve"` (and an actual LAN source restriction where appropriate). Do not add unrestricted keys for convenience. The helper accepts only `den-mailbox ping`, `put`, `list` and `get ID` over SSH. It does not provide shell, SFTP or arbitrary diagnostic execution.

Messages have exactly these JSON fields: id, sender, recipient, timestamp, task, commits, proposed_changes, observed_results, tests, requested_response. Use sender/recipient arete/homie, timezone-aware ISO timestamps and exact relevant commit identities. Maximum 64 KiB. The helper validates IDs, schema and identity; refuses symlink reads and path traversal; creates files atomically. Repeating the same ID and bytes acknowledges an identical duplicate; conflicting bytes are rejected. Explicit local `publish` stores outgoing stdin, `inbox` lists incoming messages, and `read ID` reads one. Neither sending nor receiving executes its contents.

Example flow using a privately configured SSH alias:

```sh
den-mailbox publish < outgoing-message.json
ssh den-peer den-mailbox put < outgoing-message.json
ssh den-peer den-mailbox list
ssh den-peer den-mailbox get reply-id > private-reply.json
den-mailbox inbox
den-mailbox read incoming-id
```

Aliases, message files and known_hosts remain private. Use finite connection timeouts. An offline or Windows-booted peer is unavailable until positively verified; retain the outgoing message and retry the identical bytes after reconnection. No automatic daemon is required. SSH does not share Codex conversation memory: agents must explicitly read and respond, while Git remains the durable code handoff.

## Ownership and first workflow

Homie changes pc on its own checkout. Arete changes feat/first-principles-learning-system on its own checkout. Fetch heads before comparison. Coordinate shared root/home/scripts changes first; review small selective cherry-picks with the owning agent. Do not deploy the older pc branch's root home/ onto Arete or broadly merge either branch. Keep laptop hybrid GPU, Aquamarine, ScreenPad and thermal changes on Arete; keep PC direct-GPU, disk/boot and CPU policy on Homie. The current draft pc-to-main PR is not permission for an automatic merge.

First acceptance requires a nonce/message authenticated round trip with independently verified host keys. A local SSH test or open TCP port does not pass it. Next, Arete creates a disposable repository revision, supplies a verified SHA-256 Git bundle or approved fetch source, and Homie manually receives/checks the exact commit in an isolated workspace. Homie runs its tests in an identified environment and returns commit, artifact hash, environment and observed result. Restricted mailboxes intentionally do not accept Git bundles; agree on a separate narrowly scoped transfer method before enabling one. Test interrupted transfer/resume and actual peer-offline/Windows behavior; do not equate idempotent mailbox retry with all transfer acceptance.

Only after this workflow passes, inspect portable editor/tmux/agent state, ROS/project handoff, selected library synchronization, backup ownership/restores and large-artifact placement. Git is for code, synchronization for selected files, backups for recovery. Do not synchronize live databases, credentials or caches indiscriminately. Placement follows measured CPU/GPU memory and workload suitability.
