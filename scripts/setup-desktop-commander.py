#!/usr/bin/env python3
"""Install a pinned local remote agent; never copy or print account credentials."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess

VERSION='0.3.0'


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--apply',action='store_true')
    a=p.parse_args()
    home=Path.home();prefix=home/'.local/opt/sensei-desktop-commander'
    manifest=prefix/'node_modules/@wonderwhy-er/desktop-commander/package.json'
    if not a.apply:
        print(f'Install Desktop Commander {VERSION} at {prefix}; reuse this host’s saved pairing.')
        print('Then deploy home/ with scripts/install.py and enable the user service.')
        print('For boot before login, explicitly enable user lingering once with loginctl.')
        return
    for tool in ('node','npm'):
        if not shutil.which(tool):p.error(tool+' is required')
    current=json.loads(manifest.read_text()).get('version') if manifest.exists() else None
    marker=prefix/'.sensei-install-version'
    complete=marker.read_text().strip() if marker.exists() else None
    if current!=VERSION or complete!=VERSION:
        prefix.mkdir(parents=True,exist_ok=True)
        subprocess.run(['npm','install','--prefix',str(prefix),'--omit=dev','--no-audit',
                        '--no-fund',f'@wonderwhy-er/desktop-commander@{VERSION}'],check=True)
    subprocess.run([shutil.which('node'),str(manifest.parent/'dist/index.js'),'remote','--help'],
                   check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=20)
    marker.write_text(VERSION+'\n')
    private=home/'.desktop-commander-device'
    if private.exists():private.chmod(0o700)
    credential=private/'device.json'
    if credential.exists():credential.chmod(0o600)
    print('Local agent ready:',VERSION)
    if not credential.exists():print('Pair explicitly with the official remote command before starting the service.')


if __name__=='__main__':main()
