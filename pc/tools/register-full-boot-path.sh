#!/usr/bin/bash
# Opt-in compatibility registration. Retain the working abbreviated EFI entry.
set -euo pipefail
test "$EUID" -eq 0 || { echo 'Requires local root.' >&2; exit 1; }
esp=ecc241c3-ebbe-4ca0-bdca-8635593f07b9
test "$(findmnt -no PARTUUID /boot)" = "$esp" || { echo 'Wrong EFI target.' >&2; exit 1; }
partition=$(readlink -f "/dev/disk/by-partuuid/$esp")
disk="/dev/$(lsblk -no PKNAME "$partition")"
test "$(lsblk -dn -o SERIAL "$disk")" = NBYC26A00A16934 || { echo 'Wrong physical disk.' >&2; exit 1; }
test -f /boot/EFI/LIMINE/LIMINE_X64.EFI
if ! efibootmgr -v | grep -q 'Homie Linux'; then
    efibootmgr --create-only --disk "$disk" --part 1 --label 'Homie Linux' --loader '\EFI\LIMINE\LIMINE_X64.EFI' --full-dev-path
fi
/usr/local/libexec/homie-boot-order repair
echo 'Full-path Homie Linux first; existing Limine recovery entry preserved.'
