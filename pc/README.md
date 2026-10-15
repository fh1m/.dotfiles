# Homie — the desk half of Digital Den

The same desktop as Arete, with direct NVIDIA rendering and desktop hardware controls.
Shared source lives in `home/`; PC-specific policy lives in `profiles/pc/home/`.
Both hosts use `~/.dotfiles` on **main**.

```sh
cd ~/.dotfiles
git pull --ff-only
python3 scripts/install.py --hardware pc       # preview
python3 scripts/install.py --hardware pc --apply
python3 pc/tools/check-homie-desktop.py
```

[Current operations and sharing](../docs/digital-den/README.md) · [Hardware](../docs/digital-den/HARDWARE.md) · [Gallery](../docs/gallery.md) · [Recovery](RECOVERY.md)

## Keep these boundaries

- Ryzen 5 3600X / GTX 1660 SUPER: native NVIDIA, LG 1080p at 75 Hz. No laptop GPU workarounds.
- Six data mounts, with Windows and preserved Linux archives read-only. `~/Drives` is the local entry; Arete uses `~/Den/Homie` over pinned SSHFS.
- Homie receives shared input without capturing its own local keyboard or mouse. Arete remains the master.
- Private pairing, credentials and personal data never belong in this repo.

## Still requires physical acceptance

Unattended boot has previously stalled or looped at the OEM screen. The firmware alias and recovery evidence are in [BOOT-EXPERIENCE.md](BOOT-EXPERIENCE.md) and the chronological [STATE.md](STATE.md). No firmware flash, partition changes or reboot was performed during the main-branch consolidation. Do not call this resolved without an actual unattended boot test.

[Original installation guide](HISTORY-INSTALL.md) and older handoffs are retained as history, not instructions to reinstall or wipe drives.
