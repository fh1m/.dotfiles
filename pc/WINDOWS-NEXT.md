# Windows completion and CachyOS entry checkpoint

Use this together with STATE.md and VERIFY.md. Windows is installed on Revenger B2BNDC42100667 with its own system EFI. Read the latest stage log for checks that actually passed; this page describes the next procedure, not results.

## First restart: prove the isolated Windows boot

1. Finish the running driver/update/health operations. Confirm Revenger C: is fully decrypted and Fast Startup/hibernation are disabled.
2. Leave Revenger as the only internal disk. Remove Ventoy if connected, save work, and use Windows Restart. Choose the Revenger Windows Boot Manager if firmware opens a menu.
3. Return to this Windows desktop and run VERIFY.md checks again. Confirm C: still maps to serial B2BNDC42100667 and note the new boot time. Recheck device errors, NVIDIA, Realtek network/audio, update status and any restart requirements. Perform a full shutdown and cold boot of Revenger before claiming both boot tests passed.
4. Activation needs a valid Windows 11 Pro licence/digital entitlement. Installation or driver success does not imply activation. Use Settings > System > Activation for the actual status; no bypass/activation utilities.

## Reconnect checkpoint: inspect before installation

Power off fully and disconnect mains power before touching internal cables. If reconnecting all drives for inspection, return to Revenger Windows through the firmware boot menu and obtain fresh model/serial mappings. Do not initialize/format Toshiba when Windows cannot read its ext4 filesystem. Its backups and Ubuntu on WD_BLACK remain protected. Disk numbers may change.

For the actual CachyOS installation, prefer Dahua as the only available INTERNAL disk, with Ventoy connected. Preserve/disconnect Revenger, Toshiba and WD_BLACK. If physical isolation is unavailable, stop for a verified Linux-side isolation procedure; Windows DiskPart offline state is not reliable isolation across another OS boot.

## Firmware and live-media photo checkpoint

- Keep UEFI boot; disable CSM. Current Windows inspection found Secure Boot enabled. CachyOS's official installer guide requires Secure Boot disabled. Record the current settings, disable Secure Boot for the Linux installation after Revenger decryption is verified, and keep firmware TPM enabled. Do not clear TPM, erase keys, change SATA/AHCI mode, overclock or flash BIOS as an installation fix.
- Boot the UEFI Ventoy entry, then PC-rebuild/cachyos-desktop-linux-260809.iso. Use the offered NVIDIA live option for the GTX 1660 SUPER.
- Before changing partitions, collect photos/output of `test -d /sys/firmware/efi && echo 'UEFI boot'` and `lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,UUID,MOUNTPOINTS` from the actual desktop live session.
- Verify Dahua C800 serial NBYC26A00A16934. It currently contains the WRONG Windows attempt from the historical incident; do not assume it is still empty. Only after reviewing the fresh identity and isolation may that Dahua installation be replaced for the already-authorized CachyOS stage. Do not use disk size alone to identify either 256GB SSD.
- Planned layout: Limine; Dahua GPT; at least 4096 MiB FAT32 EFI mounted at /boot with boot/ESP flag; remaining space Btrfs mounted at /. Hyprland, stable repositories, hardware-selected NVIDIA driver, Zen 2/x86-64-v3 support. Review the final summary photograph before installation.

Do not repartition WD_BLACK in this stage. Test both SATA systems and preservation copies first, as AGENTS.md requires. Keep a laptop/phone guide available because this Windows agent cannot operate while the desktop boots the live ISO.

References: [CachyOS installation](https://wiki.cachyos.org/installation/installation_on_root/), [post-install verification](VERIFY.md), [recovery](RECOVERY.md).
