# Home PC — start here

Follow this document in order from your laptop while installing the desktop. Branch: **pc**. The repository's root README and existing dotfiles describe the laptop; leave them intact.

**Chosen layout:** Windows 11 Pro on Revenger; CachyOS on Dahua; Toshiba ext4 data/backups; WD_BLACK split last, after both new OSes work. This guide deliberately stops before NVMe conversion. No install is error-proof: unexpected hardware, firmware or installer results are a checkpoint to investigate, not a reason to guess.

Read [STATE.md](STATE.md) for the actual preparation evidence. Installation ISOs and USB copies are verified; installed OSes and boot behavior are not yet tested.

**Current Windows checkpoint:** Windows now runs on Revenger with its own EFI. Follow [WINDOWS-NEXT.md](WINDOWS-NEXT.md) for the restart/reconnect checks and safe entry into CachyOS installation; consult [STATE.md](STATE.md) for actual results. The earlier wrong-Dahua installation and recovery procedure remain documented in [WINDOWS-RETRY.md](WINDOWS-RETRY.md).

## 1. Before shutting down Ubuntu

- Keep this page open on the laptop. Give its Codex agent [NEXT-AGENT.md](NEXT-AGENT.md), identifying it as the **laptop guide**, not the desktop. It must not run this desktop disk plan against the laptop.
- Close/save work in Ubuntu. Current Ubuntu personal files are copied, but it remains live; keep the NVMe intact throughout these installs. A final sync is needed before its later deletion.
- Ventoy contains `PC-rebuild/Windows11_Client_x64_en-gb_26300_9457.iso` and `PC-rebuild/cachyos-desktop-linux-260809.iso`, plus offline instructions. It was safely unmounted; leave it physically connected. Select the correct image, not an old Ubuntu ISO already on the USB.
- Label the two 256GB SATA SSDs by their physical model/serial: **Revenger B2BNDC42100667 = Windows**, **Dahua NBYC26A00A16934 = CachyOS**. Size alone cannot distinguish them.
- Do not format Toshiba or the WD_BLACK. Their original contents and partition layouts are preserved.

## 2. Firmware and disk isolation

1. Shut the PC down fully, disconnect mains power before internal work, and identify cables/drives by their labels. Do not unplug internal drives while running.
2. For Windows setup, make **only Revenger** available as an internal disk. Protect/disconnect Dahua, Toshiba, and the NVMe. Physical isolation is the simplest way to prevent Windows using Ubuntu's existing NVMe EFI partition. If you cannot safely remove the NVMe or isolate disks, have the laptop agent guide a verified Windows-PE offline-disk method before proceeding. Merely changing boot priority does not hide a disk from an installer.
3. Enter ASUS UEFI setup. Use UEFI boot, not Legacy/CSM. Do not change SATA/AHCI mode, overclock, or flash BIOS as part of a guessed fix. Record original settings.
4. Check AMD firmware TPM. ASUS documents **Advanced → AMD fTPM configuration → TPM Device Selection → Firmware TPM**; exact wording can vary with this older BIOS. TPM was not exposed in Ubuntu, so it is not already proven enabled. Do not clear TPM/reset keys blindly. If that option is absent or setup reports unsupported hardware, stop and inspect with the laptop agent. [ASUS TPM instructions](https://www.asus.com/sg/support/faq/1046215/)
5. Keep Secure Boot at its existing disabled setting for the initial CachyOS install, as its official guide requires. Enabling signed Secure Boot is a separate later task; the motherboard's capability and Windows requirements must still be checked. Do not replace this with an unsupported-hardware bypass. [CachyOS prerequisites](https://wiki.cachyos.org/installation/installation_on_root/)
6. Choose the USB's **UEFI** entry in the firmware boot menu. Verify Ventoy reports UEFI mode. Ventoy's F5 Tools → Temporary Control Settings can disable its Windows 11 hardware-check bypass; use stock hardware checks for this supported-hardware installation. If any expected feature is missing, ask the laptop agent to investigate before installing. [Ventoy control settings](https://www.ventoy.net/en/doc_ctrl_settings.html)

## 3. Install Windows 11 Pro on Revenger

1. In Ventoy, select the Windows ISO in `PC-rebuild/`; start in normal mode. Official Ventoy WIMBOOT mode is an alternative if the normal boot fails. A boot failure does not call for changing disk partitions. [Ventoy WIMBOOT](https://ventoy.net/en/doc_wimboot.html)
2. Choose the preferred language/keyboard. The downloaded image is English International x64. Select **Windows 11 Pro** when offered.
3. Select **I don't have a product key** if needed. The ISO is free to download; activation still needs a valid Pro key/digital licence. A prior Home licence does not activate Pro. Existing matching activation may reactivate this motherboard, but it has not been checked. [Microsoft activation](https://support.microsoft.com/en-us/windows/activation/activate-windows)
4. Choose the clean/custom installation path. Select **Revenger's unallocated 238.5 GiB space**, after verifying isolation/identity. Windows creates its own EFI, reserved, OS and recovery partitions. Do not select the approximately 58 GiB Ventoy USB. Do not delete, clean, shrink or format another drive. Screen labels can change between releases; resolve uncertainty before confirming deletion.
5. Let setup reboot. When the installer restarts, choose the newly installed Windows Boot Manager instead of starting the USB installer again. Complete OOBE with the account setup actually offered. Do not follow speculative registry/email tricks from unrelated tutorials.
6. Confirm the Windows desktop, network, keyboard/mouse and display work. If networking is unavailable, use the laptop or original Ubuntu to obtain the actual adapter's official driver; do not use driver-booster tools or random driver packs.

### Windows checkpoint

Open PowerShell and run the read-only checks in [VERIFY.md](VERIFY.md). `C:` must be on Revenger and its own EFI must be there. If this differs, stop before installing Linux or moving data.

Then in **administrator** PowerShell:

```powershell
powercfg /H off
manage-bde -status
```

The first disables hibernation/Fast Startup for clean OS switching. The second checks encryption. Encryption is deferred: if new `C:` is encrypted, confirm it is the new Revenger system volume and retain any recovery information before using Windows settings to turn encryption off; wait for decryption to finish. Do not decrypt unrelated existing volumes by assumption.

Install official AMD chipset and NVIDIA GTX 1660 SUPER drivers, apply ordinary Windows updates, and reboot to test. Aggressive debloating comes **after** baseline validation; retain recovery, servicing, Defender and needed app installers. No Atlas/custom ISO.

Install Codex/Git using [CODEX.md](CODEX.md), or continue receiving guidance from the laptop until both OSes are ready. Tell the agent to validate this checkpoint and update STATE.md before moving on.

## 4. Install CachyOS on Dahua

Follow [CACHYOS-INSTALL.md](CACHYOS-INSTALL.md) first for the current media, firmware, backup-inspection and physical-isolation checkpoints. User chose Secure Boot disabled and only the new Windows/CachyOS normal boot entries; keep original Ubuntu files and the NVMe layout intact for emergency recovery.

1. Shut down fully and isolate **Dahua only** as the internal installation target; preserve the completed Revenger, Toshiba and NVMe. Leave Ventoy connected. Restore a recorded supported UEFI configuration if you changed it; boot USB in UEFI mode.
2. Select the CachyOS Desktop ISO in `PC-rebuild/`. Use its NVIDIA live boot option if offered for this Turing GTX 1660 SUPER. If the live session cannot display normally, diagnose its offered fallback rather than guessing kernel flags.
3. In the live terminal, check:

```sh
test -d /sys/firmware/efi && echo 'UEFI boot confirmed'
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS
```

Verify Dahua `NBYC26A00A16934`. If UEFI is not confirmed, reboot the USB correctly. The Toshiba/NVMe/Revenger must not be installation targets.

4. Launch the online installer with functioning Ethernet. Choose **Limine**. Select **Manual partitioning**, then Dahua's existing empty GPT. Create:

| Partition | Size | Format | Mount | Flags |
|---|---:|---|---|---|
| Dahua EFI | **4096 MiB** | FAT32 | **/boot** | boot/ESP |
| Dahua root | Remaining space | Btrfs | / | default Linux |

Do not make a fixed separate /home partition; use the distribution's Btrfs subvolume layout. Leave NVMe allocation, disk swap sizing and encryption for their later stage. **4096 MiB is the current Limine minimum**; the earlier 2 GiB note was corrected before any Dahua partition was created. [Official manual partitioning](https://wiki.cachyos.org/installation/installation_on_root/)

5. Choose **Hyprland**, the user's keyboard-first preference. Install one desktop in the installer. A fallback session can be added after the base system is working. Keep stable repos, the normal CachyOS kernel and hardware-detected NVIDIA packages. Ryzen 3600X supports **x86-64-v3**, not v4/Zen4 repos.
6. Set username `fh1m`, choose your password locally, and region/timezone Asia/Dhaka. Do not store passwords in this repository.
7. Review the entire final summary. Only Dahua should be partitioned/formatted; EFI and bootloader must be on Dahua. If any other disk appears in destructive operations, go back. Install, reboot into CachyOS, and test login/network/display before applying personal dotfiles.

### CachyOS checkpoint

Run the Linux checks in [VERIFY.md](VERIFY.md). `/` must be Dahua Btrfs and `/boot` its own FAT32 EFI, with NVIDIA working. Install Codex/Git from [CODEX.md](CODEX.md). Ask the agent to validate the installed system before deploying the laptop's dotfiles or a long list of optimizations.

## 5. Reconnect drives and finish the boot menu

1. Power off before reconnecting all original disks. Firmware may select a different default after installation; use its boot menu to choose CachyOS on Dahua. Do not interpret a missing menu as lost files or reinstall anything.
2. In CachyOS, verify all four identities and boot entries with [VERIFY.md](VERIFY.md). The completed Windows must have its own EFI on Revenger; original Ubuntu remains on NVMe.
3. Run `sudo limine-scan` to discover Windows if needed. If Windows does not appear, ask Codex to inspect the actual Revenger EFI UUID and current Limine configuration; do not copy examples with guessed UUIDs. Set a visible menu timeout and default CachyOS. The Windows menu entry should chainload Revenger's own EFI loader. [CachyOS dual boot](https://wiki.cachyos.org/installation/installation_on_root/)
4. Test menu boot to **new Windows**, menu boot to **CachyOS**, and firmware direct boot of each SSD. Confirm the Windows entry opens the new Revenger install, not the old NVMe Windows. Keep original Ubuntu files for emergency recovery; its old firmware entry was removed at the user's request. Do not recreate a normal Ubuntu menu entry automatically.
5. Keep known-working boot entries/configuration, EFI backups, a fallback kernel and bounded Btrfs snapshots. Windows/firmware updates can still change boot order; [RECOVERY.md](RECOVERY.md) explains the route back. No claim of update-proof boot is made.

## 6. Resume with Codex; stop before NVMe conversion

Give the new agent [NEXT-AGENT.md](NEXT-AGENT.md). It must audit your installed Windows/CachyOS and complete [VERIFY.md](VERIFY.md), then apply the staged [CachyOS setup plan](CACHYOS-SETUP.md) using measured results. The existing laptop dotfiles remain intact until a desktop-specific profile is reviewed.

**Do not divide the WD_BLACK as part of this checklist.** It still hosts Ubuntu and the old Windows. Later, after both new OSes boot independently, preserve the final changed Ubuntu files, restore/check critical data on another physical disk, and perform the NVMe conversion from an offline/live environment. Desired sizes are **400 decimal GB ≈ 372.53 GiB NTFS**, with remaining usable capacity **approximately 600 decimal GB ≈ 559 GiB Btrfs**. Two partitions on one NVMe are not two independent backups.

The Toshiba stays ext4. CachyOS reads it natively; Windows has no native ext4 access. Optional WSL2 access is separate from the native Windows plan; do not format the HDD for convenience. Use an NTFS shared area later for deliberate cross-OS files and keep Linux build/container/Proton data on Linux storage.

## Where to go next

- [STATE.md](STATE.md): evidence and shared stage log.
- [VERIFY.md](VERIFY.md): commands and success conditions for the next agent.
- [CODEX.md](CODEX.md): install Codex on either OS; clone this branch separately from laptop dotfiles.
- [NEXT-AGENT.md](NEXT-AGENT.md): copy/paste continuation prompt.
- [RECOVERY.md](RECOVERY.md): boot trouble, backup access and Git coordination.
- [CACHYOS-SETUP.md](CACHYOS-SETUP.md): researched workstation tuning, not changes already applied.
