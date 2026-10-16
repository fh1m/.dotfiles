#!/usr/bin/bash
# Explicit PC-only root installation; normal home deployment does not alter EFI.
set -euo pipefail
test "$EUID" -eq 0 || { echo 'Run through sudo on Homie.' >&2; exit 1; }
test "$(findmnt -no PARTUUID /boot)" = ecc241c3-ebbe-4ca0-bdca-8635593f07b9 || { echo 'Wrong EFI target.' >&2; exit 1; }
tool_dir=$(cd -- "$(dirname -- "$0")" && pwd)
backup_dir=$(mktemp -d /root/homie-boot-before.XXXXXXXX)
cp -a /boot/limine.conf /etc/default/limine "$backup_dir/"
for directory in /boot/EFI/LIMINE /boot/EFI/BOOT; do
    if test -e "$directory/limine.conf"; then cp -a "$directory/limine.conf" "$backup_dir/$(basename "$directory")-front.conf"; fi
done
wallpaper=/home/fh1m/Pictures/wallpapers/wallhaven-1q2p3v.png
if test -f "$wallpaper"; then install -o root -g root -m 600 "$wallpaper" /boot/homie-wallpaper.png; fi
for name in menu windows audit order; do
    install -D -o root -g root -m 755 "$tool_dir/homie-boot-$name.py" "/usr/local/libexec/homie-boot-$name"
done
mkdir -p /etc/limine-entry-tool.d
printf 'FIND_BOOTLOADERS=no\n' > /etc/limine-entry-tool.d/50-homie.conf
printf '#!/bin/sh\nexec /usr/local/libexec/homie-boot-menu\n' > /etc/boot/hooks/post.d/95-homie-menu
chmod 755 /etc/boot/hooks/post.d/95-homie-menu
/usr/local/libexec/homie-boot-menu
/usr/local/libexec/homie-boot-windows check
cat > /etc/systemd/system/homie-boot-order.service <<'UNIT'
[Unit]
Description=Restore verified Homie Linux-first firmware order
After=local-fs.target
Before=homie-boot-audit.service
ConditionPathIsMountPoint=/boot
ConditionPathExists=/sys/firmware/efi

[Service]
Type=oneshot
ExecStart=/usr/local/libexec/homie-boot-order repair
TimeoutStartSec=20s
UMask=0077

[Install]
WantedBy=multi-user.target
UNIT
cat > /etc/systemd/system/homie-boot-audit.service <<'UNIT'
[Unit]
Description=Private Homie boot verification checkpoint
After=local-fs.target systemd-modules-load.service homie-boot-order.service
ConditionPathIsMountPoint=/boot
ConditionPathExists=/sys/firmware/efi

[Service]
Type=oneshot
ExecStart=/usr/local/libexec/homie-boot-audit
UMask=0077
TimeoutStartSec=90

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable homie-boot-order.service
systemctl start homie-boot-order.service
systemctl enable homie-boot-audit.service
systemctl start homie-boot-audit.service
printf 'Installed. No reboot scheduled. Recovery copies: %s\n' "$backup_dir"
