#!/usr/bin/env python3
"""Render audited user dotfiles. Default: dry run; no packages or root edits."""
import argparse, datetime, json, os, re, shutil, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Machine state written by the desktop itself. Installed only when missing, so
# a live choice (a validated GPU record, a touchpad switch, a wallpaper pool)
# is never reset to the repository's default.
SEED_ONLY = {
    '.config/hypr/chrome-gpu.json',
    '.config/hypr/zenbook-controls.json',
    '.config/sensei/wallpapers.json',
    '.config/sensei/runner',
    '.config/sensei/profile',
}
# Caches and editor leftovers are never configuration.
SKIPPED_PARTS = {'__pycache__', '.DS_Store'}
SKIPPED_SUFFIXES = ('.pyc', '.tmp', '.bak', '.dotfiles-new')

def wanted(relative):
    return not (set(relative.parts) & SKIPPED_PARTS) and not relative.name.endswith(SKIPPED_SUFFIXES)

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
    # sensei helpers are linked from the checkout below, not copied. A tracked
    # copy in home/.local/bin would be replaced by that link on every run and
    # show up as a change each time, so it is skipped here.
    linked = {p.name for p in (ROOT / 'home/.config/quickshell/sensei/external').glob('sensei-*') if p.is_file() and not p.suffix}
    for source in sorted((ROOT / 'home').rglob('*')):
        if not source.is_file() or source.name.endswith('.example'):
            continue
        relative = source.relative_to(ROOT / 'home')
        if not wanted(relative):
            continue
        if relative.parts[:2] == ('.local', 'bin') and source.name in linked:
            continue
        dest = home / relative
        if relative.as_posix() in SEED_ONLY and (dest.exists() or dest.is_symlink()):
            continue
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
        # sensei helpers are linked from the checkout, so edits show up without a reinstall.
        bindir = home / '.local/bin'
        for source in (home / '.config/quickshell/sensei/external').glob('sensei-*'):
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
        for relative in ['.config/sensei', '.local/state/sensei', '.cache/sensei',
                         'Pictures/wallpapers/sensei', 'Pictures/Screenshots',
                         'Videos/Screencasts', 'Phone/Transfers', 'Phone/Models']:
            (home / relative).mkdir(parents=True, exist_ok=True)
        wallpapers = home / '.config/quickshell/sensei/assets/wallpapers'
        for source in wallpapers.glob('*.png'):
            dest = home / 'Pictures/wallpapers/sensei' / source.name
            if not dest.exists(): shutil.copy2(source, dest)
        fontdir = home / '.local/share/fonts/chakra-petch'
        shutil.copytree(home / '.config/quickshell/sensei/assets/fonts/chakra-petch', fontdir, dirs_exist_ok=True)
        if home == Path.home().resolve():
            subprocess.run(['fc-cache', '-f'], check=False)
            subprocess.run(['systemctl', '--user', 'daemon-reload'], check=False)
    return {'apply': apply, 'hardware': hardware, 'changed': changes, 'backup': str(backup)}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--target-home', type=Path, default=Path.home())
    # No default: a generic install strips the dual-panel monitor rules, so
    # applying it must be a deliberate choice, never an accident of the default.
    parser.add_argument('--hardware', choices=['generic', 'zenbook'], default=None)
    args = parser.parse_args()
    if args.hardware is None: args.hardware = 'generic' if not args.apply else None
    if os.geteuid() == 0: parser.error('Run as your desktop user, not root.')
    if args.apply and args.hardware is None: parser.error('--apply needs --hardware generic or --hardware zenbook.')
    print(json.dumps(install(args.target_home, args.apply, args.hardware), indent=2))
