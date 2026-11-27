#!/usr/bin/python3 -I
"""Read one root-enrolled SDK directory; no arbitrary paths, commands or writes."""
import hashlib
import json
import os
from pathlib import Path
import resource
import signal
import stat
import sys

CONFIG = Path('/etc/sensei-den/protected-rootfs.json')


def open_root(config):
    fd = os.open(config['source'], os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    actual = os.fstat(fd)
    if (actual.st_dev, actual.st_ino) != (config['device'], config['inode']):
        os.close(fd)
        raise ValueError('Enrolled root filesystem was replaced; explicit re-enrollment required')
    return fd


def describe(config, fd):
    digest = hashlib.sha256()
    count = total = 0
    device = os.fstat(fd).st_dev
    for directory, dirs, files, current in os.fwalk('.', dir_fd=fd, follow_symlinks=False):
        for name in ['.', *sorted(dirs + files)]:
            value = os.stat(name, dir_fd=current, follow_symlinks=False)
            relative = directory + '/' + name
            metadata = (relative, value.st_dev, value.st_ino, value.st_mode,
                        value.st_uid, value.st_gid, value.st_size,
                        value.st_mtime_ns, value.st_ctime_ns)
            digest.update(json.dumps(metadata, ensure_ascii=True).encode() + b'\n')
            count += 1
            if stat.S_ISREG(value.st_mode):
                total += value.st_size
        dirs[:] = sorted(name for name in dirs
                         if os.stat(name, dir_fd=current, follow_symlinks=False).st_dev == device)
    return {'source': config['source'], 'device': device, 'inode': config['inode'],
            'fingerprint': digest.hexdigest(), 'entries': count, 'apparentBytes': total}


def read_config():
    fd = os.open(CONFIG, os.O_RDONLY | os.O_NOFOLLOW)
    with os.fdopen(fd) as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_uid != 0 or info.st_mode & 0o022 or info.st_size > 65536:
            raise ValueError('Enrollment must be a bounded, root-owned, non-writable regular file')
        return json.load(stream)


def main():
    if os.geteuid() != 0 or len(sys.argv) != 2 or sys.argv[1] not in ('inspect', 'export'):
        raise ValueError('Use the approved inspect or export operation through sudo')
    config = read_config()
    if config.get('schema') != 1 or int(os.environ.get('SUDO_UID', '-1')) not in (0, config['uid']):
        raise ValueError('Caller is not the enrolled desktop user')
    # Keep effective root only for the approved reads, but let the enrolled user
    # terminate a stalled reader through its real UID. No command/path is taken
    # from the caller; effective/saved root still prevent unprivileged tracing.
    os.setresuid(config['uid'], 0, 0)
    os.setpriority(os.PRIO_PROCESS, 0, 19)
    resource.setrlimit(resource.RLIMIT_CPU, (600, 620))
    signal.alarm(110 if sys.argv[1] == 'inspect' else 1800)
    fd = open_root(config)
    try:
        if sys.argv[1] == 'inspect':
            print(json.dumps(describe(config, fd)))
            return
        os.fchdir(fd)
        resource.setrlimit(resource.RLIMIT_FSIZE, (8 * 1024 ** 3, 8 * 1024 ** 3))
        # No inherited TAR_OPTIONS, compression settings, shell input or network.
        environment = {'PATH': '/usr/bin:/bin', 'LC_ALL': 'C'}
        arguments = ['/usr/bin/tar', '--create', '--format=pax', '--numeric-owner',
                     '--acls', '--xattrs', '--xattrs-include=*', '--sparse', '--one-file-system', '--sort=name',
                     '--pax-option=delete=atime,delete=ctime',
                     '--use-compress-program=/usr/bin/zstd -q -T1 -3', '--file=-', '--', '.']
        os.execve(arguments[0], arguments, environment)
    finally:
        os.close(fd)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError) as error:
        print('Protected rootfs reader: ' + str(error), file=sys.stderr)
        raise SystemExit(1)
