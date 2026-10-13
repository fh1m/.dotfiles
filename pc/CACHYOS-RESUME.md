# Resume the rebuild from installed CachyOS

This handoff is for the NEW installed Dahua system, not a promise that installation succeeded. The last published Windows preparation checked Revenger and the media; new Linux installation results must be measured locally. The short prompt is in CACHYOS-PROMPT.txt.

## Start the native Linux agent

After installing CachyOS, boot its SSD with the other internal drives still disconnected. Confirm network and a usable terminal. Install native baseline tools and Codex, using the official OpenAI CLI installer:

```sh
sudo pacman -Syu --needed git curl
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Open a fresh terminal and run `codex --version`. If PATH has not refreshed and the documented default installer location exists, use `$HOME/.local/bin/codex`. Do not run Codex as root and do not copy Windows/laptop credentials into Linux. Sign in locally with your own ChatGPT account when Codex starts. GitHub authentication for pushing is separate; follow CODEX.md and keep credentials out of Git.

For a first clone, only when `$HOME/.dotfiles-pc` does not already exist:

```sh
git clone --depth 1 --filter=blob:none --sparse --branch pc --single-branch https://github.com/fh1m/.dotfiles.git "$HOME/.dotfiles-pc"
git -C "$HOME/.dotfiles-pc" sparse-checkout set pc
cd "$HOME/.dotfiles-pc/pc"
codex "$(cat CACHYOS-PROMPT.txt)"
```

If the checkout exists, inspect branch, origin and worktree, then fetch and pull --ff-only on a clean pc branch; preserve local changes or divergence. Do not clone over it or reset it. Start the agent from pc/ so AGENTS.md applies. Cloning does not install dotfiles. For a graphical Codex session, paste the one-line text from CACHYOS-PROMPT.txt and point it to this checkout.

Source: [official OpenAI Codex CLI installation and sign-in](https://learn.chatgpt.com/docs/codex/cli).

## First agent actions: prove the installed system

Read AGENTS.md, STATE.md, CACHYOS-INSTALL.md, NEXT-AGENT.md, VERIFY.md, RECOVERY.md, CODEX.md and CACHYOS-SETUP.md before changes. Discover the actual machine and whether it is installed Linux or a live ISO. If it is installed CachyOS, do not repeat the Dahua installer cleanup merely because an older stage log describes its wrong Windows attempt.

Verify actual root on Dahua C800 serial NBYC26A00A16934, Btrfs; its own FAT32 EFI mounted at /boot and at least 4096 MiB; installed Limine; NVIDIA module/userspace; failed units, network, free space, Btrfs subvolumes and snapshot coverage. Collect the Linux outputs in VERIFY.md and current firmware entries. Prove restart and cold boot with USB removed before declaring independent boot.

If Revenger, Toshiba or WD_BLACK remain disconnected, record them as unavailable rather than failed. Finish Dahua's independent boot before asking the user to fully power off and reconnect them. Internal cable work requires shutdown and mains disconnection.

## Reconnect, restore and workstation stages

1. After reconnecting, rediscover all identities. Revenger B2BNDC42100667 = Windows. Toshiba 497KBZVMS / ext4 UUID 3b5d6396-a091-4aac-bb67-fc0e90da988b = protected data/backups. WD_BLACK's Linux hardware serial was 252941800719; Windows exposed EUI E8238FA6BF530001001B448B42A5D1AA. Reconcile those identifiers from actual Linux outputs. Never use stale disk numbers or device letters.
2. Inspect Toshiba backup folders/records and meaningful sample restores. Preserve all existing data and historical copies; monitor its finite space. Original Ubuntu's final changing files still need checked preservation before NVMe deletion. Restore compatible selected personal files/settings to a second physical drive without blindly overwriting the fresh distro configuration.
3. Normal OS boot choices must contain only new Dahua CachyOS and new Revenger Windows. The user explicitly requested removal of old Ubuntu and NVMe Windows firmware entries, and Windows preparation removed those two entries. Their files and partitions remain intact. Preserve recovery copies; do not automatically recreate old normal-menu entries. Verify Limine chainloads Revenger's EFI, not the old Microsoft directory on NVMe. Test firmware direct boot and menu boot into each new OS; save verified EFI/config copies on another physical drive.
4. Complete CACHYOS-SETUP.md with measured results: adapt desktop Hyprland/dotfiles without laptop ScreenPad/hybrid-GPU settings; add a usable fallback session; match NVIDIA modules to stock and LTS kernels; verify LTS boot, bounded snapshots and an actual recoverable rollback. Confirm TRIM, storage health, selected versioned backups and low-space monitoring. Keep Zen 2/v3 compatibility, default mitigations and CPU power settings.
5. Validate real workloads: Vulkan/OpenGL/game smoke test, Turing-compatible CUDA framework GPU operation; pinned ROS Humble/Jazzy Ubuntu containers when official dependencies matter, GPU/GUI/device access, DDS discovery and representative Gazebo/RViz workload. Test actual USB/serial hardware and use proper udev/groups. No VMs are required; containers remain project-specific and must be tested.
6. Windows pre-install checks passed for NVIDIA 617.42, AMD chipset 8.08.12.551, Realtek LAN/audio, system integrity, filesystem, Defender, independent EFI and reconnect boot. Remaining Windows items included activation, an unidentified USB Code 43 device and audible playback checks. Confirm current results rather than assuming those are fixed by Linux setup. Fresh pre-Linux inspection showed Secure Boot disabled and TPM absent; user chose to keep Secure Boot disabled. Do not clear TPM, enroll keys or flash firmware as a guessed fix. Record any later firmware/photo decision.

## Final NVMe stage: conditional, separate and offline

Proceed toward the full requested rebuild, but do not treat a fresh Linux login as authorization to skip preservation conditions. Before NVMe conversion, prove Windows/Revenger and CachyOS/Dahua both boot without NVMe; preserve final Ubuntu files and any new service data from an offline/quiesced source; verify those copies and representative restores; ensure irreplaceable Toshiba-only archives have another physical copy. Keep Toshiba intact throughout.

Only after those stage conditions pass, use an offline/live environment and exact rediscovered WD_BLACK identity for its planned replacement. Desired split: 400 decimal GB NTFS (about 372.53 GiB), remainder roughly 600 decimal GB Btrfs (about 559 GiB before layout overhead). Account for actual usable capacity; do not assign guessed device paths or reuse Windows disk numbers. Later Linux mount points are /shared (NTFS), /data (Btrfs) and /storage (Toshiba ext4), by discovered UUID. Inspect and validate every destructive operation against the exact target; no generic disk-clean script.

Finish restoration, boot tests, backup recovery, workstation acceptance and documentation. Update STATE.md after each meaningful stage with machine/date/evidence/failures/pending items, commit only reviewed public pc/ files and push pc using one writer at a time. Never commit private inventories, raw personal logs, backups, recovery secrets, signing keys, credentials or ISOs. Follow existing user authorization for necessary reversible work and stage-qualified operations without repeatedly asking generic permission; missing evidence is a checkpoint to resolve, not permission to guess.
