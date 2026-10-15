#!/usr/bin/python3 -I
"""Restore Homie's explicit default order after Windows/firmware re-registration."""
import argparse
import os
import re
import subprocess

LINUX_ESP = 'ecc241c3-ebbe-4ca0-bdca-8635593f07b9'
WINDOWS_ESP = '42c187df-43b3-420a-a824-d2723adfcc76'
OLD_ESP = '21fe17a0-2e1c-4679-966a-1e1baf560b80'


def plan(firmware):
    entries = {}
    for line in firmware.splitlines():
        match = re.match(r'Boot([0-9A-Fa-f]{4})\*\s', line)
        if match:
            entries[match[1].upper()] = line.lower()
    def exact(guid, loader):
        matches = [number for number, line in entries.items()
                   if f'gpt,{guid},' in line and loader in line]
        if guid == LINUX_ESP:
            full = [number for number in matches if re.search(r'boot[0-9a-f]{4}\*\s+homie linux\s', entries[number])
                    and 'pciroot(' in entries[number]]
            if len(full) == 1:
                return full[0]
        if len(matches) != 1:
            raise ValueError('Missing or ambiguous verified firmware loader; no order changed')
        return matches[0]
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


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['check', 'repair'])
    args = parser.parse_args()
    if os.geteuid() != 0:
        raise SystemExit('Run through sudo on Homie')
    mounted = subprocess.check_output(['/usr/bin/findmnt', '-no', 'PARTUUID', '/boot'], text=True).strip()
    if mounted != LINUX_ESP:
        raise SystemExit('Wrong mounted EFI; no changes')
    firmware = subprocess.check_output(['/usr/bin/efibootmgr', '-v'], text=True)
    old, desired = plan(firmware)
    if old != desired and args.action == 'repair':
        print('Observed order drift: ' + ','.join(old) + ' -> ' + ','.join(desired), flush=True)
        subprocess.run(['/usr/bin/efibootmgr', '-o', ','.join(desired)], check=True, stdout=subprocess.DEVNULL)
        actual = subprocess.check_output(['/usr/bin/efibootmgr', '-v'], text=True)
        if plan(actual)[0] != desired:
            raise SystemExit('Firmware did not retain requested order; manual BIOS review needed')
    print('Verified Linux-first order' if old == desired or args.action == 'repair' else 'Default boot order drift detected')
    if old != desired and args.action == 'check':
        raise SystemExit(1)
