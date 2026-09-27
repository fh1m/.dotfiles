#!/usr/bin/env python3
"""Render audited user dotfiles. Default: dry run; no packages or root edits."""
import argparse, datetime, json, os, re, shutil, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def render(data, home, hardware):
    try:
        text = data.decode().replace('@HOME@', str(home))
    except UnicodeError:
        return data
    if hardware == 'generic' and text.startswith('-- Personal setup layered'):
        # Do not install a dual-panel laptop's output rules on another machine.
        text = re.sub(r'hl\.monitor\(\{.*?\}\)\n', '', text, flags=re.S)
        text = re.sub(r'hl\.workspace_rule\(\{ workspace = "[16]", monitor = .*?\}\)\n', '', text)
        text = text.replace(', monitor = id == 6 and "DP-2" or "eDP-1"', '')
    if hardware == 'generic' and 'readonly property var bottomBarScreens: screens.filter' in text:
        text = text.replace('readonly property var bottomBarScreens: screens.filter(s => s.name === "DP-2")', 'readonly property var bottomBarScreens: { const secondary=screens.find(s=>s.name==="DP-2"); return secondary?[secondary]:barScreens; }')
    return text.encode()

def install(home, apply=False, hardware='generic'):
    home = home.resolve()
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup = home / '.local/state/dotfiles-backups' / stamp
    changes = []
    for source in sorted((ROOT / 'home').rglob('*')):
        if not source.is_file() or source.name.endswith('.example'):
            continue
        relative = source.relative_to(ROOT / 'home')
        dest = home / relative
        data = render(source.read_bytes(), home, hardware)
        if dest.is_file() and not dest.is_symlink() and dest.read_bytes() == data:
            continue
        changes.append(str(relative))
        if not apply:
            continue
        if dest.exists() or dest.is_symlink():
            old = backup / relative
            old.parent.mkdir(parents=True, exist_ok=True)
            if dest.is_symlink():
                old.symlink_to(os.readlink(dest))
            else:
                shutil.copy2(dest, old)
        dest.parent.mkdir(parents=True, exist_ok=True)
        temp = dest.with_name(dest.name + '.dotfiles-new')
        temp.write_bytes(data)
        temp.chmod(source.stat().st_mode & 0o777)
        temp.replace(dest)
    if apply:
        # Wrayth's helpers remain linked to their retained upstream sources.
        bindir = home / '.local/bin'
        for source in (home / '.config/quickshell/wrayth/external').glob('wrayth-*'):
            if not source.is_file() or source.suffix:
                continue
            dest = bindir / source.name
            if dest.exists() or dest.is_symlink():
                if dest.is_symlink() and dest.resolve() == source.resolve():
                    continue
                old = backup / '.local/bin' / source.name
                old.parent.mkdir(parents=True, exist_ok=True)
                if dest.is_symlink(): old.symlink_to(os.readlink(dest))
                else: shutil.copy2(dest, old)
                dest.unlink()
            dest.symlink_to(source)
        for relative in ['.config/wrayth', '.local/state/wrayth', '.cache/wrayth',
                         'Pictures/wallpapers/wrayth', 'Pictures/Screenshots',
                         'Videos/Screencasts', 'Phone/Transfers', 'Phone/Models']:
            (home / relative).mkdir(parents=True, exist_ok=True)
        wallpapers = home / '.config/quickshell/wrayth/assets/wallpapers'
        for source in wallpapers.glob('*.png'):
            dest = home / 'Pictures/wallpapers/wrayth' / source.name
            if not dest.exists(): shutil.copy2(source, dest)
        fontdir = home / '.local/share/fonts/chakra-petch'
        shutil.copytree(home / '.config/quickshell/wrayth/assets/fonts/chakra-petch', fontdir, dirs_exist_ok=True)
        if home == Path.home().resolve():
            subprocess.run(['fc-cache', '-f'], check=False)
            subprocess.run(['systemctl', '--user', 'daemon-reload'], check=False)
    return {'apply': apply, 'hardware': hardware, 'changed': changes, 'backup': str(backup)}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--target-home', type=Path, default=Path.home())
    parser.add_argument('--hardware', choices=['generic', 'zenbook'], default='generic')
    args = parser.parse_args()
    if os.geteuid() == 0: parser.error('Run as your desktop user, not root.')
    print(json.dumps(install(args.target_home, args.apply, args.hardware), indent=2))
