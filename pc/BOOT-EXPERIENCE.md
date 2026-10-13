# Homie boot selector and OS switching

The normal menu contains **Linux**, **Windows** and collapsed **Misc**. Linux boots the managed stock CachyOS kernel on Dahua; Windows chainloads only the verified Revenger EFI partition. Misc contains Linux LTS and preserved snapshot entries. Linux remains the default with a seven-second selection window. The Signal Ledger theme uses warm ink, pale paper, pink branding, readable built-in bitmap type and the monitor's current horizontal direction (rotation 0). Firmware setup remains available through Limine's displayed `S` shortcut.

## How it stays current

`/boot/limine.conf` remains the CachyOS-managed source. The root-owned `/usr/local/libexec/homie-boot-menu` derives presentation copies at `/boot/EFI/LIMINE/limine.conf` and `/boot/EFI/BOOT/limine.conf`, which Limine checks before the root configuration. `/etc/boot/hooks/post.d/95-homie-menu` refreshes them after boot-file and snapshot changes. `/etc/limine-entry-tool.d/50-homie.conf` disables duplicate loader discovery. The kernel manager and snapshot manager continue owning kernel paths, command lines and integrity hashes; no static kernel version is embedded in our theme.

Generation verifies the mounted Dahua EFI GPT identity, expected root UUID, boot-file containment, file existence and all inherited BLAKE2 hashes before replacement. Each presentation copy is replaced atomically. Config-hash enrollment is currently disabled; enabling it requires an explicit review of these presentation configs and the enrollment hook. Do not enable it with the current installer and assume the source-file hash covers both front configs. Secure Boot remains disabled as previously observed.

Explicit installation, separate from normal home dotfile deployment:

```sh
sudo pc/tools/install-boot-menu.sh
python pc/tools/test-homie-boot.py
```

Run only from Homie's pc checkout. The installer checks the actual EFI partition, keeps private recovery copies, installs root-owned helpers, and enables the private read-only boot audit. It does not reboot or repartition storage.

## Desktop controls

The System panel's **Windows** button and the **Restart into Windows** application launcher first ask the user to save work and confirm. Normal polkit authentication authorizes the installed root helper; no passwordless policy or sudoers edit is added. The helper rediscovers the Revenger serial, capacity and EFI partition, finds exactly one active matching firmware loader, checks the actual loader on a temporary read-only mount, sets BootNext once and verifies firmware readback. It does not change BootOrder. Firmware consumes the one-time request, allowing the next ordinary restart to return through Linux's default menu.

The launcher's **Cancel Windows next boot** action cancels only a request targeting verified Revenger. The installed efibootmgr returned `Boot entry 0001 does not exist` for its standard cancellation option during acceptance. Cancellation therefore validates the exact standardized BootNext UINT16 payload and unlinks only that variable through efivarfs, then checks its absence. It preserves an unrelated selection. Actual arm/readback/cancel passed after this fix. If restarting fails, the user helper attempts cancellation and reports whether the request could remain armed.

**Choose OS** confirms a restart and requests a one-time 60-second Limine menu. Ordinary restart retains the normal seven-second timeout. Boot Loader Interface support was observed in the running Limine 12.9.0; published LoaderEntries still describe the previous menu until the next physical Limine boot.

## Acceptance and next reboot

Observed on 2026-10-14: generated top-level names are exactly Linux/Windows/Misc; both EFI presentation copies match; all inherited kernel/initramfs hashes pass; package installation produced new snapshots and the post hook updated the presentation menu; focused safety tests and portable installer checks pass. Actual desktop screenshot shows correctly aligned Windows/Choose OS actions. An isolated QEMU/OVMF firmware-only test using copied EFI files rendered the custom menu and opened Misc to show LTS and Snapshots. No host disk, Windows installation or Linux kernel was booted by this visual fixture, and no emulator remains running.

The physical firmware menu, Windows-button authentication/restart, Revenger menu boot, LTS and snapshot recovery boot are **not yet accepted**. The user will restart after this checkpoint. Once Windows starts, verify C: really belongs to Revenger and use `pc/tools/Test-HomieWindows.ps1` from an elevated native PowerShell for a read-only local report. It checks C: identity, Fast Startup, UTC RTC settings, firmware entries and NVIDIA utility availability. Reports remain under the Windows user's LocalAppData, outside Git. The script has been reviewed from Linux but is not labelled Windows-runtime-tested.

Fast Startup/hibernation must be checked from Windows before Linux NTFS writes. Linux currently uses synchronized UTC RTC; Windows alignment is pending. Do not disable BitLocker, edit offline Windows registries or write NTFS based on an assumption. Changing Windows power/clock policy is a separate witnessed native step, after confirming the new Windows instance.

The root-owned `homie-boot-audit.service` saves private read-only JSON checkpoints under `/var/lib/homie-boot-audit/` at Linux boot. Current baseline was collected. After returning from Windows, inspect the new boot ID, actual root/EFI identities, disk inventory, kernel, NVIDIA result, failed units and menu hashes; inspect the live desktop separately because a boot-time GPU query is not visual acceptance. The audit does not share data over the network or change firmware. User report/private Windows evidence is necessary to prove Windows boot; a later Linux boot alone does not prove what ran between boots.

## Recovery

Firmware direct choices remain Dahua Limine and new Revenger Windows, with Dahua EFI fallback retained. Old NVMe Ubuntu/Windows EFI files and all partitions remain preserved, though their normal firmware entries were deliberately removed. Firmware can recreate these entries; recheck their GPT identity before correcting boot order, rather than guessing from labels.

If the presentation menu needs removal, from working Linux or verified recovery media on the identified Dahua EFI, remove only the two known generated presentation files and disable `95-homie-menu`. Limine then falls back to the original `/boot/limine.conf`. Restore saved pre-theme copies instead if they existed. The first installation's private originals are under `/root/pc-rebuild-audit/boot-theme-20261014`; later installer runs announce their unique `/root/homie-boot-before.*` recovery directory. Keep the root source, kernel/initramfs files, EFI loaders and snapshot archives intact.

To disable future audit collection: `sudo systemctl disable homie-boot-audit.service`. Preserve existing reports for investigation.

References: [Limine configuration and search order](https://github.com/Limine-Bootloader/Limine/blob/v12.x/CONFIG.md), [CachyOS boot manager configuration](https://wiki.cachyos.org/configuration/boot_manager_configuration/), [boot-file hooks and local overrides](https://github.com/CatOS-dev/limine-tool), [one-time firmware boot selection](https://github.com/rhboot/efibootmgr), [efivarfs](https://www.kernel.org/doc/html/latest/filesystems/efivarfs.html), [Microsoft Fast Startup power state](https://learn.microsoft.com/en-us/windows/win32/power/system-power-states), [Microsoft powercfg](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options), [Microsoft one-time boot sequence](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--bootsequence).
