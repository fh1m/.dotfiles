# Retry Windows on the correct disk

The first attempt wrote Windows to Dahua and used the existing NVMe EFI. Revenger is still empty. Preserve all disks until their identities are established.

## First collect the current Windows-PE disk mapping

Boot the official Windows ISO through the UEFI Ventoy entry. If the upgrade/clean-install prompt appears, choose No for this deliberate fresh installation. At the first setup screen press Shift+F10 (possibly Fn+Shift+F10). Run:

```text
diskpart
list disk
select disk 0
detail disk
```

Record the model shown. Repeat select disk N and detail disk for EVERY number from list disk. These commands only inspect. Send the model-to-number mapping to the guiding agent before proceeding. Revenger SSD 256GB is the target, not Dahua C800. Both show 238.5 GiB. Toshiba and WD_BLACK must be protected; Ventoy USB must remain online. DiskPart Disk ID is a partition-table identifier, not a hardware serial. If model is unclear, stop.

## Isolate in this Windows-PE session

Only after the fresh mapping is checked: select each confirmed Dahua, Toshiba and WD_BLACK by its CURRENT number, run detail disk again, then offline disk. Do NOT offline Revenger or the USB. Confirm list disk shows those three Offline and Revenger Online; exit DiskPart, close the console and refresh the installer drive list. Only Revenger should be an available internal install target. No clean command is needed; Revenger is already empty. If offlining fails or another internal disk is selectable, stop. Offline status is not a promise of permanent isolation across other OSes or reboots; recheck if Windows PE is restarted.

Select Revenger unallocated space, Windows 11 Pro, and let Setup create its own EFI/reserved/Windows/recovery partitions.

## Continue after the first restart

Do not select the ISO again. Use ASUS boot menu (normally F8) to select the NEW Windows Boot Manager associated with Revenger. Setup must continue from the SSD. If USB keeps starting automatically, remove Ventoy after Setup reaches its first automatic restart, then select the Revenger manager. Removing USB alone does not fix an Ubuntu-first firmware order.

If duplicate Windows Boot Manager entries are indistinguishable, stop and inspect firmware boot entries; do not pick repeatedly or restart installation. The old manager on WD_BLACK remains and is not the intended final boot path. With correctly isolated installation Windows should create/register Revenger's own manager, but this still needs observation. Keep the laptop guide available.

Finish Windows desktop setup, then verify C: and EFI on Revenger using VERIFY.md. Do not wipe Dahua or convert NVMe until the appropriate stage is verified.

References: [DiskPart detail disk](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/detail-disk), [offline disk](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/offline-disk), [Windows setup process](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-installation-process?view=windows-11).

## Handoff to a regular ChatGPT chat

The user will lose this Ubuntu Codex connection during installation. Guide interactively from photographs/output; do not assume you have terminal access or can change firmware remotely. Read this file, STATE.md and VERIFY.md. Request one checkpoint at a time. Do not send a destructive batch script or reuse any previously reported disk numbers.

### Verified diagnosis, not a theory

Original Ubuntu was inspected after the failed continuation. Dahua serial NBYC26A00A16934 has a 16 MiB reserved partition and a 238.5 GiB NTFS Windows partition, but NO EFI partition. Revenger serial B2BNDC42100667 is empty. Setup modified Microsoft boot files/BCD in the existing WD_BLACK EFI. Firmware starts ubuntu before its existing Windows manager. Setup's log ends with requesting reboot. The old-looking WD_BLACK manager is the only Windows manager observed; its physical-disk label does not establish whether its modified BCD would start old Windows or the new attempt. No successful Windows continuation has been observed. Do not tell the user to find a Dahua manager: none was created.

### Interactive checkpoints

1. Establish that the user is operating the desktop Windows installer, not the laptop. Obtain photographs of list disk and detail disk for each number. Build a fresh table: number, model, capacity, intended role. Models: Revenger SSD 256GB = Windows target; Dahua C800 = later CachyOS; TOSHIBA DT01ACA100 = protected data/backups; WD_BLACK SN7100 1TB = protected Ubuntu fallback; approximately 58 GiB USB = Ventoy. Disk ID is not the serial. If any model is ambiguous, do not guess.
2. For each confirmed non-target INTERNAL disk, separately guide select disk <its current number>, detail disk to reconfirm, then offline disk. Keep Revenger and USB online. Verify all three protected internal disks report Offline. If the operation fails, stop; do not substitute clean, delete, format or global SAN-policy changes.
3. Exit DiskPart, close command prompt, refresh Setup. Only empty Revenger should be a selectable internal target. Guide installation of Windows 11 Pro into its unallocated space. If another disk remains selectable, stop. No partitions on Dahua, Toshiba or NVMe should be deleted.
4. Explain the upcoming restart BEFORE it occurs. At the first automatic restart, do not launch the ISO again. ASUS F8 is normally the boot menu and Del/F2 enters firmware setup. Obtain a photo if necessary. Select Windows Boot Manager associated with Revenger; set that entry first in UEFI boot priority for subsequent setup restarts. Never switch to Legacy/CSM as a fix. Removing USB prevents USB re-entry but cannot override Ubuntu-first boot priority.
5. If only the WD_BLACK manager appears again, do NOT repeat the same installation blindly. Boot Windows PE, collect fresh disk mapping and inspect Revenger using list partition. Confirm it has its OWN FAT32 EFI, reserved and Windows partitions. If no EFI exists, installation isolation/partition creation failed; diagnose before deleting anything.
6. If Revenger has EFI and Windows files but its manager is missing/unusable, a verified Windows-PE BCDBoot repair is an option. Have the chat research Microsoft's current BCDBoot documentation and guide it with actual partitions/drive letters. Assign an UNUSED letter to Revenger's verified EFI only; determine the actual Revenger Windows volume letter and verify its Windows\System32 directory. Conceptual command: bcdboot <actual-Revenger-Windows-letter>:\Windows /s <actual-Revenger-EFI-letter>: /f UEFI. These are placeholders, NOT runnable commands. Never assume C: is Windows in PE or S: is free. /s targets the specified EFI but does NOT automatically create an NVRAM boot entry; use the firmware's supported boot-from-file/add-entry interface if available, or return to Ubuntu Codex for a verified Revenger efibootmgr entry. Do not omit /s while the protected NVMe is online and assume it will select Revenger. Do not format an existing EFI as a generic repair.
7. Complete Windows desktop setup. Check C: physical model/serial and Revenger's own EFI using VERIFY.md, then test a restart from disk with Ventoy removed. Do not label independent boot verified before the device identity and boot-file location are confirmed. Keep Dahua's wrong attempt until the correct Revenger boot is verified; later authorized CachyOS installation replaces it.
8. Install Codex/Git using CODEX.md and give Codex NEXT-AGENT.md. Record actual results for the returning agent. Original Ubuntu can be booted through its NVMe firmware entry if guidance/repair is needed. Do not wipe or repartition NVMe; its conversion is a later stage.

Boot media remains the verified official Windows ISO on existing Ventoy. Backups are on Toshiba ext4 and are NOT natively readable from Windows; preserve that filesystem. Personal preservation records and limitations are in STATE.md. EFI archive and private Setup logs are on Toshiba under PC-rebuild-boot-diagnosis-20261013.

For the repair nuance above: [Microsoft BCDBoot reference](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/bcdboot-command-line-options-techref-di?view=windows-11).
