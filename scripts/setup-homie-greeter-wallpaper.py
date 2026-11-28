#!/usr/bin/env python3
"""Set Homie's pre-login background without replacing its greeter config."""
import argparse
import datetime
import os
import stat
import tempfile
import tomllib
from pathlib import Path


TARGET = Path('/var/lib/noctalia-greeter/greeter.toml')
SETTINGS = '[appearance.wallpaper]\npath = "color:#000000"\nfill_color = "#000000"\n'


def render(text):
    current = tomllib.loads(text)
    appearance = current.get('appearance', {})
    if 'wallpapers' in appearance:
        raise ValueError('Preserving explicit per-display greeter wallpapers; remove them intentionally first.')
    if 'wallpaper' in appearance:
        if appearance['wallpaper'] == tomllib.loads(SETTINGS)['appearance']['wallpaper']:
            return text
        raise ValueError('Preserving an existing administrator-controlled wallpaper.')
    return text.rstrip() + '\n\n' + SETTINGS


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true', help='Back up and update the existing Homie greeter config')
    args = parser.parse_args()
    if os.uname().nodename.split('.')[0].lower() != 'homie':
        parser.error('This setup is scoped to Homie.')
    if TARGET.is_symlink() or not TARGET.is_file():
        parser.error('No regular administrator-controlled greeter.toml; leaving login configuration unchanged.')
    before = TARGET.read_text()
    after = render(before)
    if before == after:
        print('Homie greeter already uses a black background.')
        return
    if not args.apply:
        print('Would add a black background under [appearance.wallpaper].')
        return
    if os.geteuid() != 0:
        parser.error('--apply requires root; no files changed.')
    original = TARGET.stat()
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup = TARGET.with_name(f'{TARGET.name}.bak-{stamp}')
    with backup.open('x') as stream:
        os.fchmod(stream.fileno(), 0o600)
        stream.write(before)
    with tempfile.NamedTemporaryFile(dir=TARGET.parent, mode='w', delete=False) as stream:
        replacement = Path(stream.name)
        os.fchown(stream.fileno(), original.st_uid, original.st_gid)
        os.fchmod(stream.fileno(), stat.S_IMODE(original.st_mode))
        stream.write(after)
        stream.flush()
        os.fsync(stream.fileno())
    try:
        if TARGET.read_text() != before:
            raise RuntimeError('Greeter config changed while preparing the replacement.')
        replacement.replace(TARGET)
    finally:
        replacement.unlink(missing_ok=True)
    print(f'Black greeter background scheduled for the next login. Backup: {backup}')


if __name__ == '__main__':
    main()
