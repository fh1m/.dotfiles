#!/usr/bin/env python3
"""Preview or deploy user dotfiles with explicit hardware profiles and rollback."""
import argparse
import datetime
import json
import os
import re
import shutil
import stat
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATE_FILES = {'.config/hypr/chrome-gpu.json', '.config/hypr/zenbook-controls.json',
               '.config/wrayth/profile', '.config/wrayth/runner', '.config/wrayth/wallpapers.json',
               '.config/spotify-player/app.toml'}


def render(data, home, hardware):
    try:
        text = data.decode().replace('@HOME@', str(home)).replace('/home/fh1m', str(home))
    except UnicodeError:
        return data
    if hardware == 'generic' and text.startswith('-- Personal setup layered'):
        text = re.sub(r'hl\.monitor\(\{.*?\}\)\n', '', text, flags=re.S)
        text = re.sub(r'hl\.workspace_rule\(\{ workspace = "[16]", monitor = .*?\}\)\n', '', text)
        text = text.replace(', monitor = id == 6 and "DP-2" or "eDP-1"', '')
    if hardware == 'generic':
        text = text.replace('readonly property var bottomBarScreens: screens.filter(s => s.name === "DP-2")',
                            'readonly property var bottomBarScreens: { const secondary=screens.find(s=>s.name==="DP-2"); return secondary?[secondary]:barScreens; }')
    return text.encode()


def desired_files(home, hardware):
    sources = {}
    roots = [ROOT / 'home']
    if hardware == 'pc':
        roots.append(ROOT / 'pc/home')
    for root in roots:
        for source in sorted(root.rglob('*')):
            if not source.is_file() or source.name.endswith('.example') or '__pycache__' in source.parts:
                continue
            relative = source.relative_to(root).as_posix()
            if hardware == 'pc' and (relative == '.config/environment.d/vaapi.conf' or
                                     'zenbook' in relative or relative.endswith('wrayth-battery-idle.service') or
                                     relative.endswith('/wrayth-battery-idle')):
                continue
            sources[relative] = ('file', render(source.read_bytes(), home, hardware), source.stat().st_mode & 0o777)
    # Select the final helper link before comparing/writing; don't copy and
    # relink it every run. This also makes a second deployment idempotent.
    external = ROOT / 'home/.config/quickshell/wrayth/external'
    for source in external.glob('wrayth-*'):
        if source.is_file() and not source.suffix:
            relative = '.local/bin/' + source.name
            sources[relative] = ('link', str(home / '.config/quickshell/wrayth/external' / source.name), 0)
    for source in (ROOT / 'home/.config/quickshell/wrayth/assets/wallpapers').glob('*.png'):
        sources['Pictures/wallpapers/wrayth/' + source.name] = ('file', source.read_bytes(), source.stat().st_mode & 0o777)
    for source in (ROOT / 'home/.config/quickshell/wrayth/assets/fonts/chakra-petch').glob('*'):
        if source.is_file():
            sources['.local/share/fonts/chakra-petch/' + source.name] = ('file', source.read_bytes(), source.stat().st_mode & 0o777)
    return sources


def install(home, apply=False, hardware='generic'):
    home = home.expanduser().resolve()
    if hardware not in ('generic', 'zenbook', 'pc'):
        raise ValueError('Unknown hardware profile')
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup = home / '.local/state/dotfiles-backups' / stamp
    changes = []
    manifest = {'home': str(home), 'hardware': hardware, 'entries': []}
    for relative, (kind, data, mode) in sorted(desired_files(home, hardware).items()):
        dest = home / relative
        exists = dest.exists() or dest.is_symlink()
        if exists and relative in STATE_FILES:
            continue
        if kind == 'link' and dest.is_symlink() and os.readlink(dest) == data:
            continue
        if kind == 'file' and dest.is_file() and not dest.is_symlink() and dest.read_bytes() == data and stat.S_IMODE(dest.stat().st_mode) == mode:
            continue
        if exists and dest.is_dir() and not dest.is_symlink():
            raise ValueError(f'Refusing to replace a directory: {dest}')
        # Refuse writes through an unexpected symlinked ancestor.
        if not dest.parent.resolve().is_relative_to(home):
            raise ValueError(f'Destination escapes target home: {dest}')
        changes.append(relative)
        if not apply:
            continue
        backup.mkdir(parents=True, exist_ok=True, mode=0o700)
        if exists:
            old = backup / relative
            old.parent.mkdir(parents=True, exist_ok=True)
            if dest.is_symlink():
                old.symlink_to(os.readlink(dest))
            else:
                shutil.copy2(dest, old)
        manifest['entries'].append({'path': relative, 'existed': exists})
        # Persist the recovery record before each write, even if interrupted.
        (backup / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        dest.parent.mkdir(parents=True, exist_ok=True)
        if kind == 'link':
            fd, name = tempfile.mkstemp(dir=dest.parent, prefix='.dotfiles-')
            os.close(fd)
            Path(name).unlink()
            Path(name).symlink_to(data)
        else:
            fd, name = tempfile.mkstemp(dir=dest.parent, prefix='.dotfiles-')
            with os.fdopen(fd, 'wb') as output:
                output.write(data)
            Path(name).chmod(mode)
        Path(name).replace(dest)
    if apply and changes:
        for relative in ['.config/wrayth', '.local/state/wrayth', '.cache/wrayth',
                         'Pictures/Screenshots', 'Videos/Screencasts', 'Phone/Transfers', 'Phone/Models']:
            (home / relative).mkdir(parents=True, exist_ok=True)
        if home == Path.home().resolve():
            subprocess.run(['fc-cache', '-f'], check=False)
            subprocess.run(['systemctl', '--user', 'daemon-reload'], check=False)
    return {'apply': apply, 'hardware': hardware, 'changed': changes, 'backup': str(backup)}


def restore(backup, home):
    backup = backup.expanduser().resolve()
    home = home.expanduser().resolve()
    manifest = json.loads((backup / 'manifest.json').read_text())
    if manifest['home'] != str(home) or not backup.is_relative_to(home / '.local/state/dotfiles-backups'):
        raise ValueError('Backup does not belong to the selected target home')
    for entry in reversed(manifest['entries']):
        if entry['path'] in STATE_FILES and not entry['existed']:
            continue
        relative = Path(entry['path'])
        if relative.is_absolute() or '..' in relative.parts:
            raise ValueError('Unsafe backup path')
        dest = home / relative
        if not dest.parent.resolve().is_relative_to(home):
            raise ValueError('Restore destination escapes target home')
        if dest.exists() or dest.is_symlink():
            if dest.is_dir() and not dest.is_symlink():
                raise ValueError(f'Refusing to remove a directory: {dest}')
            dest.unlink()
        if entry['existed']:
            old = backup / relative
            dest.parent.mkdir(parents=True, exist_ok=True)
            if old.is_symlink():
                dest.symlink_to(os.readlink(old))
            else:
                shutil.copy2(old, dest)
    return {'restored': str(backup), 'home': str(home)}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--target-home', type=Path, default=Path.home())
    parser.add_argument('--hardware', choices=['generic', 'zenbook', 'pc'], default='generic')
    parser.add_argument('--restore', type=Path)
    args = parser.parse_args()
    if os.geteuid() == 0:
        parser.error('Run as your desktop user, not root.')
    if args.restore and args.apply:
        parser.error('--restore and --apply are mutually exclusive')
    print(json.dumps(restore(args.restore, args.target_home) if args.restore else
                     install(args.target_home, args.apply, args.hardware), indent=2))
