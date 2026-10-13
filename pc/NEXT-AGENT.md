# Paste this into the next Codex session

If this session is on the NEW installed CachyOS desktop, use CACHYOS-RESUME.md and CACHYOS-PROMPT.txt for the current continuation. Verify its actual root/EFI first; do not rerun old Windows retry or Dahua wipe instructions from historical stage logs. The last Windows preparation does not establish that Linux installation passed.

Continue my home desktop rebuild from branch pc of https://github.com/fh1m/.dotfiles. Read pc/AGENTS.md, pc/README.md, pc/STATE.md, pc/VERIFY.md, pc/CODEX.md, pc/RECOVERY.md and pc/CACHYOS-SETUP.md first. Keep all existing laptop dotfiles intact.

Current native Linux checkpoint: Dahua runs CachyOS with its own 4 GiB EFI and Btrfs root; the desktop pc profile is deployed. Read pc/DESKTOP-DEPLOYMENT.md and the latest STATE.md stages. The previous wrong Windows attempt on Dahua was replaced during the isolated installation; do not repeat installation or historical wipe steps. Revenger, Toshiba and WD_BLACK are currently disconnected. Finish isolated Linux boot/recovery and reconnect identity/preservation checks next.

Latest user decisions: keep Secure Boot disabled for installation. Remove old Ubuntu and NVMe Windows firmware entries; keep their files and NVMe partitions intact. The normal OS menu should contain only new Revenger Windows and future Dahua CachyOS. Read CACHYOS-INSTALL.md for the staged live backup inspection, Dahua-only isolation and installation checks. Do not recreate an Ubuntu normal boot entry automatically; its preserved EFI files are an emergency recovery resource.

First determine whether you are running on my laptop, original Ubuntu desktop, new Windows desktop or new CachyOS desktop. If you are on the laptop, guide my desktop installation and review my reported outputs; do not apply the desktop disk plan to your local laptop. Ask which installation checkpoint I reached if the live environment and STATE.md do not establish it.

I chose Windows 11 Pro on Revenger SATA 256GB serial B2BNDC42100667, CachyOS on Dahua SATA 256GB serial NBYC26A00A16934, Toshiba HDD serial 497KBZVMS for ext4 data/backups, and WD_BLACK SN7100 NVMe serial 252941800719 for a LATER split of 400 decimal GB NTFS and approximately 600 decimal GB Linux Btrfs. Do not touch Toshiba or the current NVMe installation during the two SATA OS installs. Verify disk identities and boot-file locations; device letters/disk numbers can change.

At the documented preparation checkpoint, both SATA disks were empty verified GPTs. The original Ubuntu and old Windows on NVMe remained intact. SATA, current Ubuntu and Windows personal copies were stored on Toshiba, with their exact paths and verification limitations in STATE.md. Current Ubuntu was still live, so its final changes need another preservation pass before any later deletion. Both official ISOs and USB copies matched published SHA-256 hashes; Ventoy was safely unmounted. Do not assume any new OS installation or boot test has passed merely because media is ready.

Help me verify what I installed using VERIFY.md: correct root/C: target, independent EFI on each SATA SSD, working native NVIDIA graphics/CUDA, network, visible Windows/CachyOS boot choices, direct firmware boot of each, and original Ubuntu fallback. If the conditions differ, explain the observed problem and resolve it safely before further destructive steps. Install/use Codex natively on Windows and Linux; I prefer avoiding VMs. Encryption is deferred, Pi excluded for now, and game installations/mods can be discarded. ROS Humble/Jazzy environment compatibility matters alongside ML and gaming.

Then progress through the staged CachyOS workstation plan. Do not blindly apply ASUS laptop ScreenPad/hybrid-GPU settings, force x86-64-v4/znver4 onto my Zen 2 CPU, or disable security mitigations for guessed performance. Benchmark and check actual driver/runtime compatibility.

Git is our shared handoff, not a live messaging connection. Fetch before changes; coordinate one writer at a time; update STATE.md with date, machine, observed evidence, failures and remaining work, then commit/push pc. Do not force-push or commit secrets, personal files, backups, browser/Codex profiles, raw logs, signed download links or ISOs. Existing authorization covers necessary reversible work and this rebuild; do not repeatedly ask generic permission. Do not infer readiness for destructive work from missing evidence.


## Pending user Windows round trip (2026-10-14)

User will reboot after the custom Linux / Windows / Misc menu checkpoint. Read BOOT-EXPERIENCE.md and latest STATE.md first. Root-private /var/lib/homie-boot-audit contains baseline and boot-time observations; compare the new boot with actual live compositor/NVIDIA/firmware and disk identities. Confirm the user actually booted Revenger Windows, checked C: identity and returned; do not assume it from reboot alone. Test-HomieWindows.ps1 provides a native read-only report. Physical theme/direction, one-time Windows action, native Windows portrait/Fast Startup/UTC and recovery kernel tests still need witnessed acceptance. BootNext was cleared at handoff. Paired input work remains paused; do not restart old injection fixtures against changed monitor geometry.


Latest acceptance override: user reported unattended OEM-logo/black-screen reboot loop; do not call the previous round-trip gate passed. Corrected observed Windows/firmware reordering and old NVMe entry recreation; homie-boot-order.service now enforces verified Linux-first policy during Linux startup. User must next test unattended startup without BIOS. Read latest BOOT-EXPERIENCE.md/STATE.md and compare private audit before promising a fix. Pink wallpaper/menu refresh is installed; protected EFI files/partitions remain preserved.
