# CachyOS installation checkpoints - this desktop only

Windows preparation is complete on Revenger. Install CachyOS by booting the verified USB; it cannot replace the running Windows session from inside Windows. Keep this guide on the laptop/phone. Work one checkpoint at a time and review photographs/output before progressing. No destructive disk command is included here.

## Protected drive plan

- Revenger SSD 256GB, serial B2BNDC42100667: working Windows 11 Pro and its own EFI. Preserve the whole disk.
- Dahua C800 256GB, serial NBYC26A00A16934: ONLY CachyOS installation target. Currently holds the historical incorrect Windows attempt. Its previous personal files were archived on Toshiba; recheck preservation records before replacement.
- Toshiba DT01ACA100, serial 497KBZVMS: existing ext4 data and backups, UUID 3b5d6396-a091-4aac-bb67-fc0e90da988b. Preserve the whole disk and all existing folders.
- WD_BLACK SN7100 1TB: original Ubuntu fallback and old Windows. Linux-recorded hardware serial 252941800719; Windows exposed EUI E8238FA6BF530001001B448B42A5D1AA. Cross-check in Linux, preserve the entire existing six-partition layout.
- Ventoy: Windows detects Lexar USB Flash Drive, serial 920701043090, approximately 58 GiB. Historical Ubuntu USB serial was 900039A575382714. Both Ventoy/VTOYEFI partitions are present and the CachyOS ISO was rehashed successfully on this connected USB; recheck its Linux identity rather than assuming the serial representation is identical across OSes.

Disk numbers, Linux device names and drive letters may change after every reboot. Capacity alone cannot distinguish the SATA SSDs.

## Checkpoint 1 - firmware photo and live boot

Leave all drives connected for a READ-ONLY backup inspection; do not launch the installer yet. Finish/save Windows work and fully shut it down. Enter ASUS firmware setup and photograph current Boot/Secure Boot settings before changing them.

For CachyOS installation: UEFI mode, CSM disabled, Secure Boot disabled; do not clear/reset firmware TPM. The fresh Windows check now reports TPM absent; inspect the actual fTPM setting before restoring it. Windows C: was fully decrypted and Fast Startup/hibernation disabled. Do not clear TPM, delete/enroll firmware keys, change SATA/AHCI/RAID mode, enable overclocking or flash BIOS as a boot workaround. Exact ASUS menu wording must be confirmed from the screen.

Use the UEFI Ventoy boot entry and PC-rebuild/cachyos-desktop-linux-260809.iso. Select the offered NVIDIA live option for GTX 1660 SUPER. If boot fails, photograph the error; do not start changing partitions.

## Checkpoint 2 - inspect Linux identities and Toshiba backups

In the live terminal, collect these READ-ONLY outputs for review:

```sh
test -d /sys/firmware/efi && echo 'UEFI boot'
lsblk -o PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,UUID,MOUNTPOINTS
findmnt
sudo efibootmgr -v
```

Confirm all four disks by actual model/serial and verify Toshiba's ext4 UUID. Do not mount another partition merely because it has a familiar device letter. Follow RECOVERY.md's read-only Toshiba inspection after checking it is not already mounted. Do not perform filesystem repair or accept a format/initialization prompt.

Verify these existing folders and their preservation records, without copying private inventories into Git:

- PC-rebuild-SATA-backup-20261012-233516
- PC-rebuild-Ubuntu-personal-20261013-004137
- PC-rebuild-Windows-personal-20261013-005314
- PC-rebuild-boot-diagnosis-20261013

The historical SATA checks included metadata checks and 32 sampled SHA-256 matches; full comparison was waived. Ubuntu was live during its earlier copy and needs a final preservation pass before its deletion. Check folder availability, recorded limits, free space and representative restores. An unchecked item stays pending. If needed, copy the prepared Revenger boot backup from USB to Toshiba only after confirming that destination and separately selecting a safe writable-copy stage.

## Checkpoint 3 - physically isolate the actual install

After inspection, shut the LIVE system down completely and disconnect mains power before internal work. Disconnect/protect Revenger, Toshiba and WD_BLACK. Leave only the positively identified Dahua INTERNAL disk and Ventoy USB connected. Do not unplug internal drives while powered.

Boot the live ISO again in UEFI mode. Repeat lsblk and confirm the Dahua serial NBYC26A00A16934. The other three internal drives must be absent. If they are visible, stop before the installer. Windows DiskPart offline status does not isolate a disk from Linux. If physical NVMe isolation is impractical, obtain a reviewed Linux-side alternative rather than guessing commands.

## Checkpoint 4 - partition and final-summary photo

Use the online installer with working Ethernet, Manual partitioning and Limine. Replace ONLY Dahua's wrong Windows-attempt partitions after the identity and backup checkpoints pass. Use GPT with:

| Partition | Size | Filesystem | Mount | Flag |
|---|---|---|---|---|
| Dahua EFI | At least 4096 MiB | FAT32 | /boot | boot/ESP |
| Dahua root | Remaining available space | Btrfs | / | Linux default |

Choose Hyprland, stable repos, stock CachyOS kernel and hardware-selected NVIDIA packages. Ryzen 3600X supports x86-64-v3, not v4/Zen4. Use username fh1m and Asia/Dhaka; enter passwords locally. No encryption now, no fixed separate home partition; inspect the resulting Btrfs subvolumes after installation.

Photograph the COMPLETE final summary before Install Now. All formatting, the EFI and the bootloader must target Dahua. USB must not be formatted. If any other internal disk appears, stop. Do not use Install alongside or a guessed disk number.

## Checkpoint 5 - independent CachyOS boot

At the first restart, boot Dahua's new CachyOS/Limine entry instead of starting the ISO again. Photograph ambiguous boot choices rather than guessing. Keep the other internal drives disconnected until login/network/display work and VERIFY.md confirms root is Dahua Btrfs and /boot is its own >=4096 MiB FAT32 EFI.

Follow CODEX.md from the NEW installed Linux system, read NEXT-AGENT.md and update STATE.md with actual results. Do not apply the laptop's root dotfiles installation script.

## Checkpoint 6 - reconnect and finish the rebuild in stages

Power off before reconnecting protected drives. Discover identities again, verify both new SATA OSes through firmware direct boot and Limine, and retain original Ubuntu files for recovery. The user requested removal of its old firmware entry; any needed recovery boot must use its preserved EFI loader after verifying the NVMe, rather than expecting an Ubuntu menu entry. A changed boot order is a boot-entry checkpoint, not evidence that data must be wiped. Verify Limine's Windows choice starts Revenger C:, not old NVMe Windows. Save verified boot files/configuration on a second physical disk.

Continue CACHYOS-SETUP.md: matching LTS/NVIDIA fallback, bounded Snapper/Limine snapshots and an actual rollback test; Hyprland plus a fallback session; Vulkan/OpenGL, CUDA framework and representative ROS/Gazebo/RViz/device/network tests; periodic TRIM, selected versioned backups and storage-health monitoring.

WD_BLACK conversion is a SEPARATE LAST stage. Before it, prove both SATA OSes boot without NVMe, preserve final changed Ubuntu files offline/quiesced, verify preservation copies and restore irreplaceable HDD-only archives onto another physical drive. The future layout is 400 decimal GB NTFS for Windows/shared files and roughly 600 decimal GB Btrfs for Linux source/build/data/container storage. Later mount points: NTFS /shared, Btrfs /data, Toshiba ext4 /storage, all by discovered UUID. Never erase Toshiba to accommodate this plan.

References: [official CachyOS installation](https://wiki.cachyos.org/installation/installation_on_root/), STATE.md, VERIFY.md, RECOVERY.md, CACHYOS-SETUP.md.

## Secure Boot decision at this checkpoint

Fresh admin checks returned Secure Boot disabled and TPM not exposed; user chose to keep Secure Boot disabled for the installation. No signing, firmware-key enrollment or TPM clearing is needed for this route. Ventoy 1.1.05 is already present with a Microsoft UEFI-signed shim and its public enrollment certificate; Windows Authenticode reports an untrusted UEFI certificate root, which does not by itself determine firmware trust. Do not call Secure Boot enabled/verified merely because a BIOS menu mentions Windows UEFI Mode. The USB and CachyOS live boot still require an actual boot test.

If the user later wants Secure Boot: follow CachyOS's installed-system sbctl/Limine guide only after independent boots and key/EFI recovery copies are verified. On ASUS, heed the current guide's --microsoft-only key-enrollment exception and installed Limine config/hash-signing rules; do not blindly clear keys or sign the original ISO here. Keep private signing keys outside Git and verify both Windows and Linux after any change. This is deferred, not already performed.
