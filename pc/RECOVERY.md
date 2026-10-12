# Recovery and continuation

## A boot menu disappears

Start with the firmware boot menu and select the independently installed CachyOS/Dahua or Windows/Revenger entry. A changed default boot order does not mean a partition is gone. Reconnect disks only with power off. Original Ubuntu remains a fallback on NVMe until its explicitly staged final conversion.

From working CachyOS, inspect `lsblk`, mount locations, `sudo efibootmgr -v` and actual EFI loader files before changing entries. If Windows is missing in Limine, use the current CachyOS `limine-scan` tool and verify which Windows it found; this PC still has an old Windows loader on NVMe. Do not remove the old Ubuntu entry prematurely.

If CachyOS fails after an update, try its previously verified LTS kernel or snapshot entry. If no installed system boots, use the verified CachyOS live USB, inspect the disks, and have the laptop/new agent guide the official recovery tools for the actual installed layout. No generic guessed chroot/mkfs/repartition commands are provided. [CachyOS documentation](https://wiki.cachyos.org/)

If Windows fails, use its installer recovery options for the verified Revenger system. Do not blindly run boot-repair commands against whatever Windows partition happens to be called C: in recovery; recovery drive letters can differ.

## Read HDD preservation files from Linux

Discover the Toshiba by serial and UUID. A read-only inspection mount is:

```sh
sudo mkdir -p /mnt/pc-backups
sudo mount -o ro,noload /dev/disk/by-uuid/3b5d6396-a091-4aac-bb67-fc0e90da988b /mnt/pc-backups
sudo ls /mnt/pc-backups
```

Use this on an unmounted filesystem for inspection. `noload` avoids journal replay; if the filesystem had an unclean shutdown, this view may omit journaled changes. Do not run a modifying repair based on a stale read-only view. Investigate the actual filesystem condition before restoration/writable mounting. Do not remount a live destination blindly or mount the same partition twice.

Backup directories are intentionally private; use sudo to inspect them rather than chmod 777. Preserve numeric ownership, permissions, symlinks and keys when restoring Linux files, adapting ownership to the new account if needed. Restore selected compatible settings after a baseline login, not an entire old distro config blindly.

Windows does not natively mount ext4. Keep the HDD intact. Microsoft documents optional WSL2 attachment of a separate ext4 disk, but that requires virtualization and is outside the no-VM baseline. A Linux live USB is a native recovery route. Windows profile recovery may need exports/original account credentials; backup files alone do not guarantee decrypting browser credentials. [Microsoft ext4 access](https://learn.microsoft.com/windows/wsl/wsl2-mount-disk)

## Git handoff when the agent/session is lost

Use the public pc branch and NEXT-AGENT.md from the laptop or new OS. No secret credential file is needed to read the public repo. Sign in afresh for Codex and GitHub writes. A fresh clone should be separate from the laptop's existing dotfiles checkout.

Before updating, inspect `git status`, fetch, then `git pull --ff-only` when clean. If another agent has pushed, review its stage log. If you have local edits or divergent commits, preserve and reconcile them; do not use reset --hard or force-push to make the warning disappear. Use one writer at a time, and never infer the other machine's state solely from this branch.

## What these protections cover

Independent EFI partitions make OS reinstall/boot recovery less coupled. Btrfs checksums can detect damaged data; repair needs a valid other copy. Snapshots help rollback but do not survive failure of their drive. Versioned copies on another physical disk protect against many individual-drive mistakes/failures; all internal drives still share fire/theft/power risks. No encryption applied now, per user preference. Zero data loss and update-proof boot cannot be promised.
