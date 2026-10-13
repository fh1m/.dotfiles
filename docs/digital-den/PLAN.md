# Arete + Homie

Arete is the travelling workstation. Homie is the home workstation and native Windows QA/gaming machine. Arete coordinates shared architecture; each local agent owns its runtime. Communication is explicit authenticated SSH mailbox exchange, not an unrestricted remote executor.

## Verified baseline

- Bidirectional key-only mailbox, pinned independently relayed host fingerprints, forced command, bounded/idempotent JSON messages: working. Private connection material is outside Git.
- Exact laptop revision `5dba0dd`: Homie verified source hashes and ran 20 isolated display-helper tests without real display commands.
- Arete: RTX 2060 6 GiB, laptop Intel/NVIDIA display split; 100 Mb/s wired adapter advertises no gigabit mode. Do not force negotiation or copy GPU policy to Homie.
- Homie: Ryzen 3600X, GTX 1660 SUPER 6 GiB, 16 GiB RAM, gigabit Ethernet. Only the 256 GB Dahua Linux disk is connected, roughly 204 GiB free. Larger storage is a future target, not available capacity. Protected disconnected disks remain untouched.
- Monitor orientation: Homie to the right of Arete.
- Canonical shared UI: current Sensei components, icons, fonts, metrics and behavior. PC effects remain its local policy. First PC-only bar/icon slice approved; broader identity/Code service parity is a separate dependency migration.

## Milestones

1. **Input:** mutually authenticated Deskflow, PC server/laptop client, confirmed Wayland capture and emulation, tested modifiers/scroll/release. Done when actual events reach a disposable receiver and local control can be recovered. No autostart until the trial passes. Lan Mouse is a fallback with explicitly selected backends; an upstream portal crash report is relevant to installed versions.
2. **Storage:** authenticated/encrypted SMB3 named share on a verified filesystem, no guest or whole-home export. Laptop uses user-session mounts so offline Homie cannot block boot. Done when a disposable file makes a checksum-verified round trip and unauthorized access fails. Random share credentials are encrypted to the peer before transport and stored in the OS keyring, never in Git or plaintext messages.
3. **Daily integration:** small `den` command and existing System tools actions for input/storage/status. Private endpoints and preferences stay local. Done when common actions work without copying shell commands, including a clear offline state.
4. **Robotics:** reproducible container/image and code-revision handoff, compatible ROS distributions, actual publisher/subscriber and representative build/test. Separate namespaces and explicit environment metadata. Data archives/ROS recordings live on storage; active builds stay local.
5. **Compute:** matched environments and small correctness fixtures before throughput benchmarks. Later evaluate two-node NCCL/DDP against single-node throughput on the actual link. Neither aggregate VRAM nor speedup is inferred from two cards. User asked distributed training as a later stage.
6. **Recovery:** restore selected data into a disposable destination and document Windows/offline/reconnect behavior. Network storage, synchronization and independent backup are different services.

## Boundaries

No disk formatting, RAID creation, partition resizing, boot changes, forced network negotiation, broad firewall opening, secret logging or blanket branch merge. Larger storage requires fresh physical identities/mounts and existing preservation gates. Windows input and Linux services while Windows is booted need separate physical acceptance.

Private per-machine settings, keyrings, TLS/SSH keys and message bodies do not belong in this repository. Reusable commands/configuration templates and sanitized acceptance results do.

## Acceptance log — 2026-10-13

- Storage: encrypted peer round trip and independently acknowledged fixture SHA passed; guest denial verified by Homie. Native GVfs/file-manager opening passed. Share uses current Linux disk only.
- Integration: `den status` verifies peer identity; System panel IPC reports authenticated online/current process state. 241 laptop tests passed before the scoped input-consent repair; focused tests rerun after it.
- Input: original paired test **failed**. Nonce stayed on Homie; Arete received no expected text or wheel event. Logical switch/TLS connection was insufficient. Both sides stopped the trial.
- Source diagnosis: Deskflow selected X11 without XDG_SESSION_TYPE. Scoped unit now sets Wayland. Numeric log level repaired (log level is an integer in QSettings). Native backend exposed existing Phone-only portal gate; separate app/executable-bound Den consent added without enabling Phone. Bridge build and all four CTest checks passed. Actual event acceptance remains pending. Isolated systemd-run tests reproduced `/proc/PID/exe` EACCES under filesystem namespace sandboxing; scoped bridge drop-in resolves it while retaining caller checks and other hardening. Native session is now sustained.
- PC UI: canonical first slice published at `7c6d590`; PC owner continues semantics/terminal changes independently. No laptop GPU policy deployed to PC.
- Next: actual pointer-barrier activation with pre-existing bounded fixture device, receiver focus verified, then nonce/modifiers/mouse/wheel/recovery. Only then persistence; then isolated ROS cross-host correctness fixture.

- Final reusable integration validation: 243 laptop tests passed, nine focused Den checks, mailbox scratch identity/idempotency/conflict verification, four bridge CTests, live panel state readback and a second encrypted storage checksum round trip. Private SSH/TLS/SMB data excluded.
