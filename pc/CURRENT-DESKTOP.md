# Homie — current Sensei desktop

The desktop is based on Claude's audited base `b3f5b55259db706e1198490b1851541a337b80e5`, with the completed launcher/firewall fixes from `07a3b89b5bef7e2e17bd7c31677d844b2a84a1ac`. Laptop configuration and repositories are read-only to this PC work. PC changes live on `feat/homie-current-desktop` in `~/.local/share/dotfiles-worktrees/homie-current`.

## Hardware and policy

Ryzen 5 3600X, 6 cores / 12 threads; 16 GB RAM; GTX 1660 SUPER, 6 GiB VRAM. One LG 1920×1080 screen at its advertised 74.973 Hz, scale 1, landscape. Native NVIDIA rendering, hardware cursor, restrained blur/shadows and 94% Alacritty opacity retain the desktop's GPU capabilities. No laptop PRIME, Intel backlight, ScreenPad, battery-idle or ASUS hardware controls are installed by the PC profile.

The shared artwork, design tokens, wallpaper palette, fonts, widgets, notifications, clipboard, launcher, seven workspaces, automatic tabs, terminal, tmux, zsh and Neovim come from current main. PC hardware facts, power controls and GPU/video wrappers adapt the existing working PC implementation. The primary monitor is not mistaken for a laptop external workspace half. Misc remains workspace 7 on the desktop. Wallpaper controls list actual connected outputs. Desktop display brightness uses verified DDC, not software dimming.

Noesis's published runtime and factory come from `53b1ba340647c4fc583b82243b9942833150cf32`, resolving main's external runtime dependency. No private vaults, browser profiles, pairing credentials or agent accounts are copied. Obsidian and python-yaml are installed. Existing account data stays local. Existing terminal buffers/sessions survive; new terminals use independent `dev_*` sessions. Alacritty reads generated wallpaper colours from `sensei-colors.toml`; its settings remain separately managed. Generated tmux colours are seed-only. Installing again after palette generation is idempotent.

## Deploy and check

```sh
cd ~/.local/share/dotfiles-worktrees/homie-current
python3 scripts/install.py --hardware pc             # review
python3 scripts/install.py --hardware pc --apply
python3 scripts/test-install.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 pc/tools/check-homie-desktop.py
```

The packaged Quickshell is used; a compatibility symlink at the canonical private-binary path lets the existing shortcut commands resolve it. No private renderer or laptop GPU library is transplanted. The supervised shell is `sensei-shell`; Hyprland starts it on login. SSH starts on boot, accepts public-key authentication, and the control key is restricted to LAN sources with forwarding disabled. The verified host key is pinned on Arete; new private connection files are separate from Claude's active laptop configuration. Passwords and connection keys are not in this repository.

NVIDIA CDI was generated for the installed driver. The packaged CDI refresh path is enabled. Docker's disposable GPU test identifies the GTX 1660 SUPER; a CUDA matrix operation in the existing ML virtual environment matches its CPU reference. ARM binfmt is present. No storage partitions, mounts, firmware entries or boot order are changed by the desktop deployment.

## Acceptance evidence

- Ten Python tests and the installer backup, rendering, symlink and idempotence checks pass.
- Eleven read-only desktop harness checks pass, with no Hyprland config errors.
- Real Code/Study/Misc/Terminal selections update the animated rail and remain selected.
- Two new terminal windows have distinct ungrouped tmux sessions; three tiled windows become tabs; removing the fixtures restores ordinary tiling. Original focus and user terminal buffers are preserved.
- System, GitHub/Code and Noesis launch; disposable factory creation/doctor reports no errors or warnings. Hardware labels reflect Ryzen/GTX facts. Screenshots are inspected privately.
- Fresh SSH authentication, nonce integrity and the live host fingerprint pass. A sample fresh connection takes approximately 139 ms.
- A four-second idle sample reports about 0.2% of one CPU core for the desktop shell, 0% for hidden Noesis, GPU 0% / 39°C / 427 MiB. These are observations, not performance guarantees.

## Recovery and boundaries

The original desktop snapshot is under `~/.local/state/homie-control/backups/`; `rollback.json` records the exact location. Each installer apply also saves replaced files under `~/.local/state/dotfiles-backups/`. The old shell tree remains available. To roll back, use a TTY or working terminal, stop the Sensei shell cleanly, restore the selected Hyprland/terminal/shell files and original helper links from those backups, reload Hyprland, and start the old shell. Do not restore or delete browser profiles, agent credentials or learning content.

A pre-existing `homie-boot-order.service` fails because its firmware loader selection is ambiguous. It was recorded without modifying firmware. Unattended boot/Windows return still requires its own hardware-backed acceptance; this desktop work does not claim to resolve that earlier boot experiment. Cold login, physical suspend/resume and interrupted network recovery have not been performed. Kitty's empty old auto-created deck was retired; the user's normal Alacritty window remains open. Obsidian CLI enablement and private vault/account synchronization remain user-local choices.

## Den follow-up

Laptop-master input and clipboard sharing is documented in [Den](den/README.md). Existing tmux was reloaded without closing sessions: two rows now show the quiet spacer and instrument rail, not the default pane listing. Missing optional TPM is guarded. The System panel exposes Ethernet and disables unavailable CPU modes. `nm-connection-editor` is installed for native wired-connection management.

The latest main installer also preserves palette-owned files and avoids matching-symlink drift; the PC profile already includes these protections while separating generated Alacritty colours into their own seed-only fragment. Its managed font/binding settings remain deployable. Claude’s uncommitted laptop files were inspected only and not transplanted.

Homie retains its existing UFW policy. The firewall status action reads UFW on this host; laptop-only nftables-table assumptions are not transplanted. The launcher-history load guard is shared from current main.
