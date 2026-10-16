#!/usr/bin/python3 -I
"""Validate Revenger and set/cancel only its one-time firmware boot target."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

SERIAL = "B2BNDC42100667"
ESP = "42c187df-43b3-420a-a824-d2723adfcc76"


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def target(disks, firmware, require_active=True):
    disk = next((d for d in disks if d.get("serial") == SERIAL), None)
    if not disk or disk.get("size") != 256060514304:
        raise ValueError("Verified Revenger disk absent or identity changed")
    part = next((p for p in disk.get("children", []) if p.get("partuuid") == ESP and p.get("fstype") == "vfat"), None)
    if not part:
        raise ValueError("Revenger EFI identity/filesystem mismatch")
    matches = []
    for line in firmware.splitlines():
        match = re.match(r"Boot([0-9A-Fa-f]{4})([ *])\s", line)
        if match and (not require_active or match[2] == "*") and f"gpt,{ESP}," in line.lower() and "\\efi\\microsoft\\boot\\bootmgfw.efi" in line.lower():
            matches.append(match[1])
    if len(matches) != 1:
        raise ValueError("Expected exactly one active verified Revenger Windows firmware entry")
    return matches[0], part["name"]


def verify_loader(part):
    # Read the actual verified EFI volume without modifying its files.
    with tempfile.TemporaryDirectory(prefix="homie-windows-", dir="/run") as directory:
        subprocess.run(["/usr/bin/mount", "-o", "ro,nosuid,nodev,noexec", f"/dev/{part}", directory], check=True)
        try:
            loader = Path(directory) / "EFI/Microsoft/Boot/bootmgfw.efi"
            with loader.open("rb") as stream:
                if stream.read(2) != b"MZ":
                    raise ValueError("Windows EFI loader missing or invalid PE signature")
        finally:
            subprocess.run(["/usr/bin/umount", directory], check=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["check", "arm", "cancel"])
    args = parser.parse_args()
    if os.geteuid() != 0:
        raise ValueError("Use the installed helper through pkexec or sudo")
    disks = json.loads(run("/usr/bin/lsblk", "-b", "-J", "-o", "NAME,SERIAL,SIZE,FSTYPE,PARTUUID"))["blockdevices"]
    firmware = run("/usr/bin/efibootmgr", "-v")
    entry, part = target(disks, firmware)
    next_entry = re.search(r"^BootNext: ([0-9A-Fa-f]{4})$", firmware, re.M)
    if args.action == "cancel":
        if next_entry and next_entry[1].lower() == entry.lower():
            # efibootmgr -N on this installed version rejects absent Boot0001.
            # efivarfs supports unlinking a variable; validate its exact UINT16
            # payload and remove only our verified Windows BootNext request.
            variable = Path('/sys/firmware/efi/efivars/BootNext-8be4df61-93ca-11d2-aa0d-00e098032b8c')
            if variable.is_symlink():
                raise ValueError('Refusing symlinked firmware variable')
            payload = variable.read_bytes()
            if len(payload) != 6 or int.from_bytes(payload[4:], 'little') != int(entry, 16):
                raise ValueError('BootNext changed; refusing cancellation')
            variable.unlink()
            if re.search(r"^BootNext:", run("/usr/bin/efibootmgr"), re.M):
                raise ValueError("Firmware retained BootNext after cancellation")
        print("Windows one-time boot cleared; unrelated selection preserved")
        return
    verify_loader(part)
    if args.action == "arm":
        if next_entry and next_entry[1].lower() != entry.lower():
            raise ValueError("Another one-time boot request exists; refusing to replace it")
        run("/usr/bin/efibootmgr", "-n", entry)
        result = run("/usr/bin/efibootmgr")
        if not re.search(rf"^BootNext: {entry}$", result, re.M | re.I):
            raise ValueError("Firmware did not retain requested Windows BootNext")
    print(f"Verified Revenger Windows EFI; Boot{entry}" + (" armed once" if args.action == "arm" else "; no boot selection changed"))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as exc:
        raise SystemExit(str(exc))
