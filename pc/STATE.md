# Verified checkpoint Ã¢â‚¬â€ 2026-10-13, Asia/Dhaka

Latest inspection: new Windows desktop on Revenger, 2026-10-13. Live checks confirm C: and the system EFI are on Revenger B2BNDC42100667, with only Revenger visible to Windows. The earlier Dahua incident below is historical. Restart/cold-boot tests, remaining Windows setup and later CachyOS installation are pending.

## Hardware

- Ryzen 5 3600X, 6 cores/12 threads; Zen 2, x86-64-v3 supported, v4 unsupported.
- ASUS TUF B450M-PLUS GAMING; BIOS 2202 dated 2020-07-14. No BIOS flash performed.
- 16 GiB RAM, 2x8 GiB Corsair DDR4-3200 modules; firmware previously reported 2133 MT/s. DOCP not changed/tested.
- ZOTAC GTX 1660 SUPER, Turing, 6 GiB VRAM. NVIDIA 580.159.03 worked in original Ubuntu; new OS drivers untested.
- WD_BLACK SN7100 runs at motherboard PCIe 3.0 x4; device supports PCIe 4.0 x4. GPU supports PCIe 3.0 x16.
- Realtek gigabit-capable Ethernet currently negotiated 100 Mbps. LG 1080p display offers approximately 75 Hz; current Ubuntu used 60 Hz.
- Original Ubuntu 22.04.5, kernel 6.8.0-111. SVM was disabled, TPM not exposed, Secure Boot disabled. Firmware prerequisites must be checked before installation, not inferred from the PC being UEFI-capable.

## Disk identities

| Serial | Model | Physical bytes | Preparation state / role |
|---|---|---:|---|
| NBYC26A00A16934 | Dahua C800 SATA 256GB | 256060514304 | First Windows attempt created 16 MiB reserved + NTFS on Dahua; still intended CachyOS target |
| B2BNDC42100667 | Revenger SATA 256GB | 256060514304 | Empty GPT, no partitions; Windows target |
| 497KBZVMS | Toshiba DT01ACA100 HDD | 1000204886016 | Existing ext4 data/backups preserved |
| 252941800719 | WD_BLACK SN7100 NVMe | 1000204886016 | Original Ubuntu and old Windows preserved; divide last |

Both SATA partition tables were cleared and both new empty GPTs passed `sgdisk --verify`. This was not a secure erase. Their old file trees are now accessed from the HDD backups. Revenger had stale GPT metadata with MBR; it was removed and its new GPT validated. Old partition tables and first-MiB images were saved on HDD; these are recovery metadata, not full disk images.

Before/after NVMe and HDD partition-table JSON comparisons matched. Original Ubuntu root, home, EFI and swap remained on NVMe, with unchanged filesystem UUIDs. Its boot entry remained available; no boot-order modification was performed. Aria2 and its small dependencies were installed in Ubuntu at the user's request; no OS reinstall or system tuning was applied there.

## Backups on Toshiba

Filesystem UUID: `3b5d6396-a091-4aac-bb67-fc0e90da988b`. Current Ubuntu mount was `/mnt/rebuild-audit/toshiba`; other OSes must discover/mount the UUID.

| Folder on HDD | Contents | Evidence / limits |
|---|---|---|
| PC-rebuild-SATA-backup-20261012-233516 | Dahua files; Revenger /home, root personal files, /media | Four size/timestamp/metadata checks passed; 32 sampled files matched SHA-256. Full content comparison waived by user. Cache/trash and old Linux system omitted. |
| PC-rebuild-Ubuntu-personal-20261013-004137 | Current Ubuntu /home and root personal files | Copy completed 00:53. Live Codex/Chrome files changed during comparison; final sync needed before deleting Ubuntu. Cache/trash/media downloads omitted. |
| PC-rebuild-Windows-personal-20261013-005314 | Windows Users incl. saves/settings, ProgramData, Cygwin home, inetpub | Completed 00:59. Games downloads/installations and mods omitted per user. One file had an NTFS timestamp earlier than ext4 supports; full SHA-256 matched, original time recorded. Other quick checks passed. |

Windows Recovery-metadata additionally preserves selected original registry/DPAPI files for possible profile recovery; no credentials were extracted. This is private root-only backup material and is not in Git. Saved browser profiles do not guarantee that encrypted credentials transplant to a new Windows installation.

About 127 GiB HDD free remained after these copies. Recheck space before further copies. Pre-existing HDD files were not fully validated; this HDD cannot back up all disks at full capacity. Important data only on that HDD needs a second physical copy after restoration. All internal copies share whole-PC disaster risks.

## Installation media

Ventoy USB serial `900039A575382714`, approximately 64 GB advertised. Existing USB files preserved; no Ventoy reinstall/format performed. Both ISOs and guides were copied into its `PC-rebuild/` folder. USB was synced and safely unmounted after completion.

`media-verified.json` records the 02:13 checkpoint: both downloads AND both USB copies matched official SHA-256 values. No actual USB boot test performed yet. The desktop source files remain in `/home/fh1m/pc-rebuild/install-media`. ISOs are excluded from Git.

## Next stages Ã¢â‚¬â€ not yet performed

1. Firmware/media boot check; Windows install on isolated Revenger, own EFI.
2. Windows independent boot and disk/encryption/power-state checks; Codex/Git setup.
3. CachyOS on isolated Dahua, Limine, own 4 GiB EFI /boot, Btrfs; independent boot; Codex/Git setup.
4. Reconnect all disks; verify visible Windows/CachyOS boot choices and original Ubuntu fallback; GPU/ROS and recovery checks.
5. Preserve final changed Ubuntu files, restore critical data onto another disk, then consider offline NVMe replacement. Never use the installation checklist to wipe NVMe.

## Stage log

| Date | Machine | Stage | Result |
|---|---|---|---|
| 2026-10-13 | Original Ubuntu desktop | SATA/HDD/NVMe preparation, personal copies, media | Checkpoint above; new OS installs and boot tests pending |

Append observed results here after installation. An unchecked item is pending, not passed.

## First Windows attempt Ã¢â‚¬â€ inspected 2026-10-13 around 03:01Ã¢â‚¬â€œ03:15 +06

- Original Ubuntu desktop is running again. Dahua NBYC26A00A16934 now has a 16 MiB reserved partition and NTFS UUID B4BCF488BCF44700 containing the new Windows files. It has NO EFI partition. Revenger B2BNDC42100667 remains empty. Disk numbers/capacity were ambiguous in Setup.
- Windows Setup log ends with requesting a reboot, not a final fatal install failure. Firmware BootOrder still starts with ubuntu (0004), then Windows Boot Manager (0000). This explains returning to GRUB instead of entering the next Windows phase.
- Existing NVMe EFI Microsoft boot files and BCD were updated by Setup. Ubuntu EFI files still exist, Ubuntu root/home remain mounted normally, and HDD filesystem/partition remains present. The wrong Windows installation is dependent on the NVMe EFI. Do not treat it as the finished intended install.
- EFI archive, firmware boot listing and private Setup logs saved on Toshiba under PC-rebuild-boot-diagnosis-20261013. No firmware boot-order changes or partition deletions were made during diagnosis. Dahua NTFS inspected read-only.
- User chose guided Windows-PE disk isolation instead of physical disconnection. Next: collect fresh DiskPart model-to-number mapping, offline Dahua/Toshiba/NVMe while keeping Revenger and Ventoy online, refresh installer, install on empty Revenger. Never reuse old disk numbers. See WINDOWS-RETRY.md.
- Ensure first restart boots the NEW Revenger Windows Boot Manager, not Ventoy and not the old NVMe entry. If necessary use firmware boot menu; confirm actual entry before changing defaults. Correct installation, continuation, own EFI and Windows desktop are still untested. Dahua cleanup for CachyOS follows successful Revenger boot.

User will use a regular ChatGPT chat during the retry. WINDOWS-RETRY.md now includes a self-contained interactive handoff, the confirmed absence of a Dahua EFI/manager, first-restart boot-priority checks, and guarded BCDBoot recovery guidance. No repair commands, boot-order changes or new install were executed by Codex at this checkpoint.

## Correct Windows installation â€” desktop inspected 2026-10-13 around 05:25 +06

- User reports installing Windows on Revenger after physically disconnecting the other drives and changing firmware settings. Those individual firmware changes were not documented; current live observations are below.
- Live machine: Ryzen 5 3600X, ASUS TUF B450M-PLUS GAMING, BIOS 2202. Windows 11 Pro, build 26300.9457 (DisplayVersion 26H2). Only Revenger SSD 256GB, serial B2BNDC42100667, is visible to Get-Disk. C: maps to this disk; IsBoot and IsSystem are true. GPT partitions: 200 MiB system EFI, 16 MiB reserved, Windows, 900 MiB recovery. BCDEdit shows the EFI Windows manager and winload.efi; Windows RE is enabled on Revenger recovery partition. Independent restart and cold boot have not yet been observed by this agent.
- TPM present/ready/enabled/activated; Secure Boot currently enabled. Review Secure Boot before the planned CachyOS installation; the preparation guide recorded it disabled, so do not assume firmware still matches the earlier state.
- NVIDIA GTX 1660 SUPER driver 610.88 works with nvidia-smi and an active 1920x1080 60 Hz display. This is not a CUDA framework or gaming acceptance test. Ethernet is up at 1 Gbps, improving on the historical 100 Mbps link.
- Windows Professional activation reports LicenseStatus 5 (Notification), not a verified activated licence. One present USB device reports Device Descriptor Request Failed; troubleshooting remains pending.
- Disabled hibernation with powercfg /hibernate off; powercfg /a confirms Hibernate, Hybrid Sleep and Fast Startup unavailable. BitLocker unexpectedly showed automatic encryption in progress (95.7%, protection off); encryption is deferred by user preference. After rechecking the Revenger C: serial, preserved recovery information locally in a user-bound DPAPI-encrypted file outside Git and ran manage-bde -off C:. DecryptionInProgress was confirmed at 95%; completion remains pending.
- Installed and verified Git 2.55.0.windows.5 and GitHub CLI 2.102.0. GitHub login as fh1m and push permission verified; HTTPS Git authentication configured. A sparse clone of branch pc is at C:\Users\fahim\dotfiles-pc. Git identity is repository-local with GitHub's account-linked noreply address. No tokens, recovery information or raw audit logs are committed.
- Toshiba and WD_BLACK are disconnected/not visible; their contents cannot be reverified from this Windows checkpoint and no operations were performed on them. Preserve both. Dahua's incorrect attempt is not cleaned here. Remaining: confirm decryption, activation, USB issue, chipset/Windows updates, restart/cold boot and display/network checks; then complete the staged CachyOS installation and later reconnect verification. NVMe conversion remains deferred.
