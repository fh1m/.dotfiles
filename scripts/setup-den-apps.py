#!/usr/bin/env python3
"""Install non-secret app configuration; sign in natively on each device."""
import argparse
import io
import json
import os
from pathlib import Path
import shlex
import subprocess
import tarfile

HOME=Path.home();SSH=['ssh','-F',str(HOME/'.local/state/homie-control/client.conf'),'homie']


def peer(code,data=None):
    p=subprocess.run([*SSH,'python3 -c '+shlex.quote(code)],input=data,capture_output=True,check=True)
    return p.stdout


def config_files(home):
    files=['.config/spotify-player/app.toml','.claude/settings.json','.codex/AGENTS.md']
    for root in ['.claude/skills','.codex/skills']:
        if (home/root).is_dir():
            files.extend(str(x.relative_to(home)) for x in (home/root).rglob('*') if x.is_file() and not x.is_symlink() and '__pycache__' not in x.parts)
    return [n for n in files if (home/n).is_file()]


def receiver_code():
    return '''from pathlib import Path
import sys,tarfile,io,os,json
os.umask(0o077);home=Path.home();changed=[]
with tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:gz') as tar:
 members=tar.getmembers()
 for member in members:
  rel=Path(member.name)
  if member.issym() or member.islnk() or not member.isfile() or rel.is_absolute() or '..' in rel.parts:raise ValueError('Unsafe archive')
  if rel.as_posix() in ('.claude/.credentials.json','.codex/auth.json','.cache/spotify-player/credentials.json') or (rel.parent.as_posix()=='.cache/spotify-player' and rel.name.endswith('_token.json')):raise ValueError('Credential transfer is disabled')
  current=home
  for part in rel.parts[:-1]:
   current=current/part
   if current.is_symlink():raise ValueError('Symlink parent is not allowed')
 for member in members:
  rel=Path(member.name);dest=home/rel
  if dest.exists() or dest.is_symlink():continue
  dest.parent.mkdir(parents=True,exist_ok=True,mode=0o700);dest.write_bytes(tar.extractfile(member).read());dest.chmod(0o600);changed.append(member.name)
print(json.dumps({'installedMissingFiles':len(changed),'existingFilesPreserved':True,'credentialsCopied':False,'nativeSignInRequired':True}))
'''


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');a=p.parse_args()
    files=config_files(HOME)
    if not a.apply:
        print(json.dumps({'files':len(files),'policy':'configuration only; destination files preserved; sign in natively on each device; no credential copying'}));return
    stream=io.BytesIO()
    with tarfile.open(fileobj=stream,mode='w:gz') as tar:
        for n in files:tar.add(HOME/n,arcname=n,recursive=False)
    print(peer(receiver_code(),stream.getvalue()).decode().strip())


if __name__=='__main__':
    os.umask(0o077);main()
