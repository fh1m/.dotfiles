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
