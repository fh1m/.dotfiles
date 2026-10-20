#!/usr/bin/env python3
"""Enable login-password keyring unlock for greetd without weakening PAM auth."""
import argparse
from datetime import datetime
import os
from pathlib import Path
import shutil


def configured(text):
    lines = text.splitlines()
    additions = [('auth', 'auth       optional     pam_gnome_keyring.so'),
                 ('session', 'session    optional     pam_gnome_keyring.so auto_start')]
    for phase, addition in additions:
        if any(not s.lstrip().startswith('#') and s.split()[:1] == [phase]
               and 'pam_gnome_keyring.so' in s for s in lines):
            continue
        positions = [i for i, s in enumerate(lines) if s.split()[:1] == [phase]]
        lines.insert(positions[-1] + 1 if positions else len(lines), addition)
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    target = Path('/etc/pam.d/greetd')
    if not Path('/usr/lib/security/pam_gnome_keyring.so').exists():
        parser.error('Install gnome-keyring before enabling its PAM module')
    before = target.read_text()
    after = configured(before)
    if after == before:
        print('greetd keyring integration already present')
        return
    if not args.apply:
        print(after, end='')
        print('Preview only; use sudo python3 scripts/setup-keyring-login.py --apply')
        return
    if os.geteuid() != 0:
        parser.error('--apply requires root')
    backup = target.with_name(target.name + '.before-keyring-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
    shutil.copy2(target, backup)
    staged = target.with_name(target.name + '.keyring-staging')
    with staged.open('x') as stream:
        stream.write(after)
        stream.flush()
        os.fsync(stream.fileno())
    shutil.copystat(target, staged)
    staged.replace(target)
    print('Enabled optional keyring unlock; backup:', backup)


if __name__ == '__main__':
    main()
