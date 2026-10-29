# One engineering loop in OMP

OMP is the working interface. Codex and Claude Code archives remain evidence, not running dependencies or instructions to execute. The model account can still be OpenAI Codex; that does not require working in the Codex CLI.

## Start and resume

```sh
omp-work mongla
omp-work rupsha
omp-work meghdhut
omp-work den

omp-work sessions meghdhut
omp-work resume meghdhut              # most recent native session in this project
omp-work resume meghdhut SESSION_ID   # exact ID or unambiguous prefix
omp-work handoff meghdhut             # historical request, reply and recorded task state
omp-work history estimator            # search originals and native imported titles
```

Mongla runs in `auv-ros2` with ROS Humble. Meghdhut runs in `drone-ros2` with ROS Humble. Rupsha runs in `rupsha_dev` with ROS Jazzy. Den runs on the host. Paths and aliases live in `home/.local/share/omp-den/projects.json`; `megdhut` and `meghdut` both resolve to `meghdhut`.

The Rupsha workspace is `~/tmp/rupsha_ws`; the container-home `rupsha_ws` path is an alias, not a second repository. Do not migrate or delete it merely because the path contains `tmp`.

Inside OMP, `/resume PROJECT_OR_TOPIC` searches the shared native history. Same-runtime selection switches in place. A selection requiring another container opens an Alacritty window in that runtime and leaves the original session open. This is deliberate: a conversation switch cannot replace the process's OS, Python environment or LSP server. Never silently execute a failed remote/container command on the host.

`/labs` explains the current runtime. Normal project launches start inside their container, so file tools, shell, Python and language servers agree. The `lab_exec` tool explicitly selects host, AUV, drone or Rupsha. Existing host sessions retain scoped shell routing for known project paths.

## The actual loop

1. Resume the relevant session. Read its latest handoff as **historical, unverified intent**.
2. Inspect current code and working-tree state. Identify which old tasks remain relevant. Do not rerun historical commands automatically.
3. Define the observable behavior and appropriate verifier. Use the existing engineering-proof skill for significant robotics work.
4. Make the smallest coherent change in the owning environment.
5. Run its build/test/smoke scenario there. Preserve logs and real artifacts for expensive experiments. An exit code is not proof that hardware did the intended thing.
6. Update the session's native todo state and leave a precise result or blocker. Use `--restore` only when deliberately resuming interrupted work; ordinary resume is not authorization to repeat physical actions.

Commands with literal arguments stay argv-based:

```sh
omp-work run mongla -- colcon list --base-paths src
omp-work run rupsha -- python3 -c 'import rclpy; print("ROS available")'
omp-work run meghdhut -- bash -c 'your explicit shell pipeline'
```

Stopped containers fail visibly. Start one deliberately with `omp-work start rupsha`; the launcher does not start old containers as a side effect of browsing history.

## What happened to old conversations

The original private backup is `~/Envs/backups/agent-history-2026-10-30/`, with `MANIFEST.sha256`. The discovery index covers host and container histories. Native OMP conversations are in `~/.omp/agent/sessions/`; all three containers share this state directory rather than making independent copies.

At this migration baseline: 682 discoverable foreign records, 653 nonempty native conversions, 29 metadata-only records retained in the original archive. Subordinate Claude transcripts are retained separately (`omp-unified extras`). A top-level count does not imply every vendor-specific internal event survived conversion.

Missing native titles were repaired through OMP's lease-aware `SessionManager.renameSessionTitle`, not by rewriting JSONL. Existing titles were preserved. Source metadata takes priority; otherwise use a literal meaningful user-request excerpt. Histories without such a request get a source/ID label, not an invented topic. Before-copies and title-basis receipts stay private under `~/.local/state/omp-den/titles-*`.

`omp-work handoff` reconstructs recorded native todo/update_plan events and shows the last request/reply. It is a historical aid, not a universal merger of all open work across branches. The full original transcript remains authoritative for details; current code decides whether a task is still needed.

Newly discovered foreign conversations can still be imported:

```sh
omp-unified list TOPIC
omp-unified import EXACT_ID --no-open
# If its original changed after the previous import:
omp-unified import EXACT_ID --new-revision --no-open
omp-work titles --apply
```

A changed original becomes a separate revision, never an overwrite of native OMP work. Selected sources are frozen into private content-hashed snapshots before conversion. The registry rejects unreadable data instead of replacing it with an empty map. An import lock prevents concurrent writers; after a process crash inspect the owner/activity before clearing a stale `~/.local/share/omp-unified/import.lock` directory.

## Access and privacy

The existing user-selected `yolo` approval setting remains. There is no stored sudo password, new passwordless-root rule, provider-token export or public service. Docker access is already privileged; use it only for authorized project work. Physical robot control, flashing, destructive changes and public publishing still need specific authorization.

OMP's own credential store is shared locally through the mounted agent directory; reauthentication belongs to OMP, not copied browser sessions. Run `omp usage` to inspect supported accounts. External MCP servers retain their own authentication. The inherited Context7 server returned HTTP 401 during Mongla's initial smoke check; use `/mcp reauth` for it when needed. Ordinary builds, native model access and primary-source web research do not depend on it.

Native OMP desktop capture currently reports unavailable on this Hyprland/Wayland backend. The narrow `den_desktop` tool fills read-only inventory/screenshots using the installed `hyprctl`/`grim`, with no input or focus changes. Screenshots stay mode 0600 under `~/.local/state/omp-den/captures`. Native foreground control still requires its live human grant. This fallback is not a blanket input-control bypass.

## Code intelligence

Native OMP LSP remains lazy/shared. The maintained `lsp.json` recognizes ROS workspace `src` directories and expires idle servers after five minutes. Clangd is installed in the actual containers; shared Pyright is pinned separately from project dependencies and run through the shared Bun runtime.

Use real compilation databases for accurate ROS/C++ includes and flags. If a build is appropriate, generate them with your project's existing colcon/CMake workflow (`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`). Do not claim complete semantic indexing just because clangd starts. Language servers reload through the native LSP reload operation after configuration changes.

## Backup and recovery

```sh
omp-work backup
```

This writes a private archive under `~/Envs/backups/omp/`, restores it into disposable storage and checks every captured content hash before publishing the archive. It includes sessions, image blobs, memory files, extensions, configuration, a consistent SQLite `history.db` backup, and import provenance. Continuously changing files cause a retry/failure rather than a silently truncated transcript.

Provider credentials in `agent.db` are intentionally excluded. Reauthenticate after machine loss. Keep the foreign-source backup as well: the OMP archive does not duplicate the original vendor archives. This is a **local backup**, not protection against laptop disk loss. Copy verified archives to private off-device storage separately. No automatic history pruning is enabled.

For recovery, extract to a new private directory first, validate `manifest.json`, and inspect with OMP using an isolated agent directory/profile. Stop owners before replacing canonical state. Do not merge active SQLite databases or run two copies of the same session writer.

## Deployment and rollback

```sh
python3 scripts/install-omp.py                 # preview
python3 scripts/install-omp.py --apply
python3 scripts/setup-omp-containers.py --apply --tools
omp-work doctor
```

The scoped installer saves changed files and a rollback manifest under `~/.local/state/omp-deployments/`. Roll back in reverse deployment order with `scripts/install-omp.py --rollback MANIFEST --apply`; rollback refuses to overwrite later edits. Container setup adds only missing links and explicit language-tool dependencies, refusing to replace a different existing object. Package removal is not part of rollback because other work may now depend on those tools.

Existing sessions are not killed or restarted. Start a new OMP session to load newly installed extensions. Retained Codex/Claude binaries and source archives can remain installed without being part of daily work.

## Why this shape

- Native OMP session storage, model authentication, memory, LSP, compaction and ownership leases do the heavy lifting.
- One project registry handles execution ownership; no new agent scheduler or always-on service.
- Shared local history and native titles provide continuity; merging unrelated transcripts would destroy causality.
- Project launchers change runtime explicitly. A shell-only proxy is insufficient for Python/LSP/container isolation.
- Backups are tested; credentials and private work never enter public dotfiles.

Sources reviewed against installed OMP 18.13.3: [CLI/session continuation](https://github.com/can1357/oh-my-pi/blob/main/docs/cli-reference.md), [session storage and title semantics](https://github.com/can1357/oh-my-pi/blob/main/docs/session.md), [extension lifecycle](https://github.com/can1357/oh-my-pi/blob/main/docs/extensions.md), [MCP discovery/authentication](https://github.com/can1357/oh-my-pi/blob/main/docs/mcp-config.md), [LSP discovery](https://github.com/can1357/oh-my-pi/blob/main/docs/lsp-config.md), and installed `foreign-session-import.ts` / `session-manager.ts`. The live package API is the compatibility boundary; rerun the harness checks after an OMP upgrade.

## Verification baseline — 2026-10-30

- All 784 entries in the original foreign-history SHA-256 manifest passed verification.
- All 653 registered native imports exist and have a title. 197 missing titles were recovered from metadata/request excerpts; 23 received explicit source-identity labels.
- Native OMP model requests completed inside Mongla, Meghdhut and Rupsha with the shared account.
- ROS imports passed in all three environments. Clangd and Pyright each completed an actual initialize → initialized → shutdown → exit exchange in every environment.
- A command invoked from the drone container routed through the host into Mongla and observed ROS Humble.
- Twelve Python regressions and four Bun regressions cover source-revision preservation, title choice, historical task state, rollback refusal after user edits, command boundaries, runtime ownership and bounded failing-tool output.
- The final private OMP backup restored and verified 3,626 files, including native skills, language settings and new foreign-revision snapshots. Credentials were excluded.
- Native Wayland capture reported unavailable; the read-only fallback enumerated the live displays and captured a real output successfully.

The initial Ubuntu package download failed because archive/security domains resolved to an unreachable `zihad.lancache.net` address. The installation succeeded using this **temporary, signature-checked** mirror override:

```sh
python3 scripts/setup-omp-containers.py --apply --tools \
  --ubuntu-mirror https://mirrors.edge.kernel.org/ubuntu
```

This does not change DNS, `/etc/hosts`, permanent apt sources or package-signature policy. No unrelated package upgrade or autoremove was performed.
