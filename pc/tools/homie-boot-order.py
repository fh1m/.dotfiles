#!/usr/bin/python3 -I
"""Restore Homie's explicit default order after Windows/firmware re-registration."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import time
import os
import re
import subprocess

LINUX_ESP = 'ecc241c3-ebbe-4ca0-bdca-8635593f07b9'
WINDOWS_ESP = '42c187df-43b3-420a-a824-d2723adfcc76'
OLD_ESP = '21fe17a0-2e1c-4679-966a-1e1baf560b80'


def plan(firmware, fallback_verified=False, allow_inactive_windows=False):
    entries = {}
    active = set()
    for line in firmware.splitlines():
        match = re.match(r'Boot([0-9A-Fa-f]{4})([ *])\s', line)
        if match:
            number = match[1].upper()
            entries[number] = line.lower()
            if match[2] == '*':
                active.add(number)
    def exact(guid, loader):
        matches = [number for number, line in entries.items()
                   if f'gpt,{guid},' in line and loader in line
                   and (number in active or (allow_inactive_windows and guid == WINDOWS_ESP))]
        if guid == LINUX_ESP:
            full = [number for number in matches if re.search(r'boot[0-9a-f]{4}\*\s+homie linux\s', entries[number])
                    and 'pciroot(' in entries[number]]
            if len(full) == 1:
                return full[0]
        if len(matches) != 1:
            raise ValueError('Missing or ambiguous verified firmware loader; no order changed')
        return matches[0]
    # Keep the currently booted verified fallback even if firmware recreates a
    # named option. Do not trade a demonstrated working path for an untested one.
    current = re.search(r'^BootCurrent: ([0-9A-Fa-f]{4})$', firmware, re.M)
    candidate = current[1].upper() if current else ''
    line = entries.get(candidate, '')
    if (fallback_verified and candidate in active and f'gpt,{LINUX_ESP},' in line
            and '\\efi\\boot\\bootx64.efi' in line):
        linux = candidate
    else:
        linux = exact(LINUX_ESP, '\\efi\\limine\\limine_x64.efi')
    windows = exact(WINDOWS_ESP, '\\efi\\microsoft\\boot\\bootmgfw.efi')
    match = re.search(r'^BootOrder: ([0-9A-Fa-f,]+)$', firmware, re.M)
    if not match:
        raise ValueError('Firmware order missing')
    old = match[1].upper().split(',')
    # Prior explicit user instruction excludes old NVMe Windows/Ubuntu from
    # normal boot order; keep their variables and EFI files for manual recovery.
    tail = [number for number in old if number not in (linux, windows)
            and 'bbs(hd,' not in entries.get(number, '')
            and not (f'gpt,{OLD_ESP},' in entries.get(number, '')
                     and any(loader in entries[number] for loader in
                             ['\\efi\\microsoft\\boot\\bootmgfw.efi', '\\efi\\ubuntu\\shimx64.efi']))]
    return old, list(dict.fromkeys([linux, windows, *tail]))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['check', 'plan', 'repair'])
    args = parser.parse_args()
    if os.geteuid() != 0:
        raise SystemExit('Run through sudo on Homie')
    mounted = subprocess.check_output(['/usr/bin/findmnt', '-no', 'PARTUUID', '/boot'], text=True).strip()
    if mounted != LINUX_ESP:
        raise SystemExit('Wrong mounted EFI; no changes')
    firmware = subprocess.check_output(['/usr/bin/efibootmgr', '-v'], text=True)
    fallback = Path('/boot/EFI/BOOT/BOOTX64.EFI')
    named = Path('/boot/EFI/limine/limine_x64.efi')
    fallback_verified = (fallback.is_file() and named.is_file()
                         and named.read_bytes()[:2] == b'MZ'
                         and hashlib.sha256(fallback.read_bytes()).digest() == hashlib.sha256(named.read_bytes()).digest())
    old, desired = plan(firmware, fallback_verified, args.action in ('plan', 'repair'))
    # Recheck physical Windows disk identity and the actual loader before touching
    # its active flag or ordering. No partitions or loader files are modified.
    helper = Path(__file__).with_name('homie-boot-windows' + Path(__file__).suffix)
    windows = runpy.run_path(str(helper))
    disks = json.loads(subprocess.check_output(['/usr/bin/lsblk', '-b', '-J', '-o', 'NAME,SERIAL,SIZE,FSTYPE,PARTUUID'], text=True))['blockdevices']
    entry, part = windows['target'](disks, firmware, require_active=args.action == 'check')
    if entry.upper() != desired[1]:
        raise SystemExit('Windows target changed; no order changed')
    windows['verify_loader'](part)
    inactive = not re.search(r'^Boot' + entry + r'\*\s', firmware, re.M | re.I)
    if args.action == 'plan':
        print(json.dumps({'oldOrder': old, 'proposedOrder': desired, 'reactivateWindows': inactive, 'fallbackVerified': fallback_verified, 'changed': False}))
        return
    if args.action == 'repair' and (old != desired or inactive):
        backup = Path('/var/lib/homie-boot-audit') / ('order-repair-' + str(time.time_ns()))
        backup.mkdir(parents=True, mode=0o700)
        (backup / 'before.txt').write_text(firmware)
        if inactive:
            subprocess.run(['/usr/bin/efibootmgr', '-b', entry, '-a'], check=True, stdout=subprocess.DEVNULL)
            print('Reactivated verified Revenger Windows entry ' + entry, flush=True)
    if old != desired and args.action == 'repair':
        print('Observed order drift: ' + ','.join(old) + ' -> ' + ','.join(desired), flush=True)
        subprocess.run(['/usr/bin/efibootmgr', '-o', ','.join(desired)], check=True, stdout=subprocess.DEVNULL)
        actual = subprocess.check_output(['/usr/bin/efibootmgr', '-v'], text=True)
        if plan(actual, fallback_verified)[0] != desired:
            raise SystemExit('Firmware did not retain requested order; manual BIOS review needed')
    if args.action == 'repair':
        actual = subprocess.check_output(['/usr/bin/efibootmgr', '-v'], text=True)
        if plan(actual, fallback_verified)[0] != desired:
            raise SystemExit('Firmware verification failed; saved prior state requires review')
    print('Verified Linux-first order' if old == desired or args.action == 'repair' else 'Default boot order drift detected')
    if old != desired and args.action == 'check':
        raise SystemExit(1)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as exc:
        raise SystemExit(str(exc))
