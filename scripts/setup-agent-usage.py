#!/usr/bin/env python3
"""Install the pinned, on-demand CodexBar CLI. No account login or credential transfer."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import tarfile
import tempfile
import urllib.request

VERSION='0.85.0'
SHA256='adaa5c7b4e09e26b135e5b958705a746189b289ade7fc3c26b1d0538259572a5'
ASSET=f'CodexBarCLI-v{VERSION}-linux-x86_64.tar.gz'
URL=f'https://github.com/steipete/CodexBar/releases/download/v{VERSION}/{ASSET}'
LICENSE='''MIT License

Copyright (c) 2026 Peter Steinberger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'''


def digest(path):
    with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()


def install(home,archive=None,apply=False):
    if os.geteuid()==0:raise PermissionError('Run this user-owned installer without sudo')
    if platform.system()!='Linux' or platform.machine()!='x86_64':
        raise ValueError('This reviewed release pin supports Linux x86_64 only')
    home=home.expanduser().resolve()
    prefix=home/'.local/opt/codexbar'/VERSION
    launcher=home/'.local/bin/codexbar'
    if launcher.exists() or launcher.is_symlink():
        if not launcher.is_symlink() or not launcher.resolve().is_relative_to(home/'.local/opt/codexbar'):
            raise ValueError('Existing unrelated codexbar launcher is preserved; review it before installation')
    record={'version':VERSION,'archiveSha256':SHA256,'source':URL,'prefix':str(prefix),'apply':apply}
    if not apply:return record
    prefix.parent.mkdir(parents=True,exist_ok=True)
    if prefix.exists():
        saved=json.loads((prefix/'installation.json').read_text())
        if saved.get('archiveSha256')!=SHA256 or saved.get('binarySha256')!=digest(prefix/'CodexBarCLI'):
            raise ValueError('Existing installation changed; preserve and inspect it rather than overwriting it')
    else:
        with tempfile.TemporaryDirectory(prefix='.install-',dir=prefix.parent) as temporary:
            root=Path(temporary)
            source=archive
            if source is None:
                source=root/ASSET
                with urllib.request.urlopen(URL,timeout=60) as response,source.open('xb') as target:
                    while chunk:=response.read(1024*1024):target.write(chunk)
            if digest(source)!=SHA256:raise ValueError('Release checksum mismatch; no installation was changed')
            stage=root/'release';stage.mkdir()
            with tarfile.open(source) as package:package.extractall(stage,filter='data')
            binary=stage/'CodexBarCLI'
            version=subprocess.run([str(binary),'--version'],capture_output=True,text=True,timeout=10,check=True)
            if version.stdout.strip()!=f'CodexBar {VERSION}':raise ValueError('Unexpected CLI release identity')
            (stage/'LICENSE').write_text(LICENSE)
            record['binarySha256']=digest(binary)
            (stage/'installation.json').write_text(json.dumps(record,indent=2)+'\n')
            stage.replace(prefix)
    launcher.parent.mkdir(parents=True,exist_ok=True)
    if not launcher.is_symlink() or launcher.resolve()!=(prefix/'CodexBarCLI').resolve():
        temporary=launcher.with_name('codexbar.new')
        if temporary.exists() or temporary.is_symlink():raise ValueError('Existing launcher staging file is preserved')
        temporary.symlink_to(prefix/'CodexBarCLI');temporary.replace(launcher)
    return record


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply',action='store_true')
    parser.add_argument('--archive',type=Path)
    parser.add_argument('--home',type=Path,default=Path.home())
    args=parser.parse_args()
    print(json.dumps(install(args.home,args.archive,args.apply),indent=2))
