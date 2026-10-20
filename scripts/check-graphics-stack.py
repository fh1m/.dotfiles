#!/usr/bin/env python3
"""Read-only graphics ABI check. Exit 1: broken dependencies; 2: reboot needed."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess


def run(*args):
    env = dict(os.environ)
    # A session recovery must not disguise broken system libraries.
    env.pop('LD_LIBRARY_PATH', None)
    env.pop('LD_PRELOAD', None)
    return subprocess.run(args, env=env, capture_output=True, text=True, timeout=15)


def inspect():
    report = {'errors': [], 'warnings': [], 'libraries': {}, 'nvidia': {}}
    for name in ('libEGL_mesa.so.0', 'libGLX_mesa.so.0'):
        path = Path('/usr/lib') / name
        if not path.exists():
            report['errors'].append(f'{path} is missing')
            continue
        result = run('ldd', str(path))
        missing = [s.strip() for s in result.stdout.splitlines() if 'not found' in s]
        report['libraries'][name] = {'missing': missing}
        if result.returncode or missing:
            report['errors'].append(f'{name}: unresolved dependencies: {missing}')
    conf = Path('/etc/pacman.conf').read_text()
    for line in conf.splitlines():
        if re.match(r'^\s*IgnorePkg\s*=', line):
            held = set(line.split('=', 1)[1].split('#', 1)[0].split())
            if held & {'mesa', 'lib32-mesa'}:
                report['warnings'].append('Mesa is held; an LLVM update can break its ABI.')
    version_file = Path('/proc/driver/nvidia/version')
    if version_file.exists():
        match = re.search(r'Kernel Module.*?\s(\d+\.\d+(?:\.\d+)?)\s', version_file.read_text())
        package = run('pacman', '-Q', 'nvidia-utils')
        if match and package.returncode == 0:
            loaded = match.group(1)
            installed = package.stdout.split()[1].split(':')[-1].rsplit('-', 1)[0]
            report['nvidia'] = {'loaded': loaded, 'installed': installed,
                                'rebootRequired': loaded != installed}
    report['rebootRequired'] = report['nvidia'].get('rebootRequired', False)
    report['status'] = 'broken' if report['errors'] else 'reboot-required' if report['rebootRequired'] else 'ok'
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    result = inspect()
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print('Graphics stack:', result['status'])
        for message in result['errors'] + result['warnings']:
            print(' -', message)
        if result['rebootRequired']:
            print(' - NVIDIA loaded/installed:', result['nvidia']['loaded'], '/', result['nvidia']['installed'])
            print(' - Save your work and reboot normally; do not unload the in-use GPU driver.')
    return 1 if result['errors'] else 2 if result['rebootRequired'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
