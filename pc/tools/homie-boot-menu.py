#!/usr/bin/python3 -I
"""Generate Homie's presentation menu from CachyOS-managed boot entries."""
import argparse
import os
from pathlib import Path
import re
import tempfile

ESP = "ecc241c3-ebbe-4ca0-bdca-8635593f07b9"
WINDOWS = "42c187df-43b3-420a-a824-d2723adfcc76"
ROOT = "c65659cf-f507-4376-8cfa-29f3ecc47504"
THEME = """# Homie / Signal Ledger. Generated; edit pc/tools/homie-boot-menu.py.
timeout: 7
default_entry: Linux
remember_last_entry: no
interface_resolution: 1920x1080
interface_rotation: 0
interface_branding: HOMIE / DIGITAL DEN
interface_branding_colour: f23d70
interface_help_colour: a9a29a
interface_help_colour_bright: f23d70
term_background: 00090807
term_foreground: e8e2da
term_background_bright: 1e1b18
term_foreground_bright: e8e2da
term_palette: 090807;f23d70;96b49a;d6a65e;76bcc0;b9a0bd;76bcc0;e8e2da
term_palette_bright: 39342f;f23d70;a9c6ad;e3ba7d;95d0d3;ceb6d2;95d0d3;fff8ef
term_font_scale: 2x2
term_margin: 48
"""


def render(source):
    entries = []
    for line in source.splitlines():
        match = re.match(r"^\s*(/+)(\+?)([^/].*)$", line)
        if match:
            entries.append([len(match[1]), match[3], []])
        elif entries:
            entries[-1][2].append(line.strip())
    main = next((entry for entry in entries if entry[1] == "linux-cachyos"
                 and any("rootflags=subvol=/@ " in line for line in entry[2])), None)
    if not main or not any(ROOT in line for line in main[2]):
        raise ValueError("No verified stock CachyOS root entry; existing menu preserved")
    body = [line for line in main[2] if not line.startswith("comment:") and not line.startswith("#")]
    if not any(line.startswith("path:") for line in body) or not any(line.startswith("module_path:") for line in body):
        raise ValueError("Stock kernel/initramfs paths missing")
    result = THEME + "\n/Linux\ncomment: CachyOS / development, research and compute\n" + "\n".join(body)
    result += f"\n\n/Windows\ncomment: Windows 11 Pro / Revenger / gaming and QA\nprotocol: efi\npath: guid({WINDOWS}):/EFI/Microsoft/Boot/bootmgfw.efi\n"
    result += "\n/Misc\ncomment: Recovery kernels and preserved snapshots\n"
    # Only the manager's CachyOS group belongs here; never expose old Windows/Ubuntu.
    group = next((i for i, e in enumerate(entries) if e[0] == 1 and e[1] == "CachyOS"), None)
    if group is None:
        raise ValueError("Managed CachyOS group missing")
    for depth, title, lines in entries[group:]:
        if depth == 1 and title != "CachyOS":
            break
        if depth == 1 or (depth == main[0] and title == main[1] and lines == main[2]):
            continue
        result += "\n" + "/" * depth + ("Linux LTS" if depth == 2 and title == "linux-cachyos-lts" else title) + "\n"
        result += "\n".join(lines) + "\n"
    return result


def atomic(path, data):
    if path.is_symlink():
        raise ValueError(f"Refusing symlink: {path}")
    fd, temp = tempfile.mkstemp(dir=path.parent, prefix=".homie-menu-")
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temp, 0o600)
        os.replace(temp, path)
    finally:
        Path(temp).unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", action="store_true")
    args = parser.parse_args()
    # Reject wrong machines even for privileged installation/hook execution.
    import subprocess
    uuid = subprocess.check_output(["/usr/bin/findmnt", "-no", "PARTUUID", "/boot"], text=True).strip()
    if uuid.lower() != ESP:
        raise ValueError("/boot is not verified Dahua EFI")
    source = Path("/boot/limine.conf").read_text()
    data = render(source)
    # Verify all referenced kernel files and their generated BLAKE2 hashes,
    # including recovery entries, before replacing either presentation copy.
    import hashlib
    for reference in re.findall(r'^\s*(?:path|module_path):\s*boot\(\):(/[^\n]+)', data, re.M):
        filename, separator, expected = reference.partition('#')
        file = Path('/boot') / filename.lstrip('/')
        if not file.resolve().is_relative_to(Path('/boot')) or not file.is_file():
            raise ValueError(f'Boot file missing or escapes EFI: {filename}')
        if separator:
            digest = hashlib.blake2b()
            with file.open('rb') as stream:
                for chunk in iter(lambda: stream.read(1048576), b''):
                    digest.update(chunk)
            if digest.hexdigest() != expected:
                raise ValueError(f'Boot file checksum mismatch: {filename}')
    if args.preview:
        print(data)
        return
    if os.geteuid() != 0:
        raise ValueError("Installation requires root")
    # Do not silently sidestep future config-hash enrollment.
    for config in [Path('/etc/default/limine'), Path('/etc/limine-entry-tool.conf'), *Path('/etc/limine-entry-tool.d').glob('*.conf')]:
        if config.exists() and re.search(r'^\s*ENABLE_ENROLL_LIMINE_CONFIG\s*=\s*[\"\']?yes', config.read_text(), re.M):
            raise ValueError('Config enrollment enabled; front menu requires explicit enrollment review')
    for parent in (Path("/boot/EFI/LIMINE"), Path("/boot/EFI/BOOT")):
        if not parent.is_dir() or parent.is_symlink():
            raise ValueError(f"Expected bootloader directory absent: {parent}")
    for parent in (Path("/boot/EFI/LIMINE"), Path("/boot/EFI/BOOT")):
        atomic(parent / "limine.conf", data)
    print("Homie menu refreshed: Linux / Windows / Misc")


if __name__ == "__main__":
    main()
