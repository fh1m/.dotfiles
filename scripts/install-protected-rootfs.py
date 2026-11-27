#!/usr/bin/env python3
"""Enroll one approved SDK rootfs for read-only export; preserve rollback files."""
import argparse
import json
import os
from pathlib import Path
import pwd
import shutil
import subprocess
import tempfile
import time


def atomic(target, data, mode):
    target.parent.mkdir(parents=True, exist_ok=True, mode=0o755)
    fd, temporary = tempfile.mkstemp(dir=target.parent, prefix='.' + target.name)
    try:
        with os.fdopen(fd, 'wb') as stream:
            os.fchmod(stream.fileno(), mode)
            os.fchown(stream.fileno(), 0, 0)
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, target)
    finally:
        Path(temporary).unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--user', default=os.environ.get('SUDO_USER'))
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    if os.geteuid() != 0 or not args.user or args.user == 'root':
        parser.error('Run through sudo for the enrolled desktop user')
    account = pwd.getpwnam(args.user)
    if not args.user.replace('_', '').replace('-', '').isalnum():
        parser.error('Invalid desktop account name')
    source = args.source.resolve(strict=True)
    if source.name != 'rootfs' or not source.is_dir() or not source.is_relative_to(account.pw_dir):
        parser.error('Enroll one SDK rootfs directory inside the desktop home')
    if any(character in str(source) for character in '*?[]'):
        parser.error('Source cannot contain backup-pattern metacharacters')
    for command in ('/usr/bin/tar', '/usr/bin/zstd', '/usr/bin/visudo'):
        if not Path(command).is_file():
            parser.error('Required native tool missing: ' + command)
    info = source.stat()
    policy = {'schema': 1, 'source': str(source), 'device': info.st_dev,
              'inode': info.st_ino, 'uid': account.pw_uid}
    helper = Path('/usr/local/libexec/den-rootfs-export')
    sudoers = (f'{args.user} ALL=(root) NOPASSWD: {helper} inspect, {helper} export\n').encode()
    with tempfile.NamedTemporaryFile() as check:
        check.write(sudoers)
        check.flush()
        subprocess.run(['/usr/bin/visudo', '-cf', check.name], check=True, stdout=subprocess.DEVNULL)
    if not args.apply:
        print(json.dumps({'ready': True, 'scope': 'One inode-enrolled SDK; inspect/export only'}))
        return
    repo = Path(__file__).resolve().parents[1]
    targets = [(helper, (repo / 'scripts/protected-rootfs-reader.py').read_bytes(), 0o755),
               (Path('/etc/sensei-den/protected-rootfs.json'), json.dumps(policy).encode(), 0o600),
               (Path('/etc/sudoers.d/den-protected-rootfs'), sudoers, 0o440)]
    backup = Path('/var/backups/sensei-protected-rootfs') / str(time.time_ns())
    backup.mkdir(parents=True, mode=0o700)
    previous = {}
    for target, _, _ in targets:
        if target.is_symlink():
            raise ValueError('Refusing symlink deployment target')
        previous[str(target)] = target.exists()
        if target.exists():
            saved = backup / str(target).lstrip('/')
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, saved)
    (backup / 'manifest.json').write_text(json.dumps(previous))
    try:
        for target, data, mode in targets:
            atomic(target, data, mode)
        subprocess.run(['/usr/bin/visudo', '-cf', '/etc/sudoers'], check=True,
                       stdout=subprocess.DEVNULL)
    except Exception:
        for target, _, _ in targets:
            if previous[str(target)]:
                shutil.copy2(backup / str(target).lstrip('/'), target)
            else:
                target.unlink(missing_ok=True)
        raise
    print(json.dumps({'installed': True, 'backup': str(backup),
                      'scope': 'Read-only; no general sudo, file permission changes or network access'}))


if __name__ == '__main__':
    main()
