#!/usr/bin/env python3
"""Private one-time application parity through the already pinned operator SSH.

Does not publish data or continuously synchronize refresh tokens. Existing Codex
credentials are preserved; Claude's cache is copied only when missing. Private
backups precede changes. Native binaries stay outside the public repository.
"""
import argparse
import io
import json
import os
from pathlib import Path
import shlex
import subprocess
import tarfile
import time

HOME=Path.home();SSH=['ssh','-F',str(HOME/'.local/state/homie-control/client.conf'),'homie']


def peer(code,data=None):
    p=subprocess.run([*SSH,'python3 -c '+shlex.quote(code)],input=data,capture_output=True,check=True)
    return p.stdout


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');a=p.parse_args()
    files=['.config/spotify-player/app.toml','.claude/settings.json','.claude/.credentials.json','.codex/AGENTS.md']
    for n in (HOME/'.cache/spotify-player').glob('*_token.json'):files.append(str(n.relative_to(HOME)))
    for n in ['.cache/spotify-player/credentials.json']:
        if (HOME/n).is_file():files.append(n)
    for root in ['.claude/skills','.codex/skills']:
        if (HOME/root).is_dir():
            files.extend(str(x.relative_to(HOME)) for x in (HOME/root).rglob('*') if x.is_file() and not x.is_symlink() and '__pycache__' not in x.parts)
    files=[n for n in files if (HOME/n).is_file()]
    if not a.apply:print(json.dumps({'files':len(files),'claudeVersion':'2.1.300','policy':'preserve existing auth; missing files only; distinct music device'}));return
    stream=io.BytesIO()
    with tarfile.open(fileobj=stream,mode='w:gz') as tar:
        for n in files:tar.add(HOME/n,arcname=n,recursive=False)
    code='''from pathlib import Path
import sys,tarfile,io,os,time,json,shutil
os.umask(0o077);home=Path.home();backup=home/'.local/state/homie-control/backups'/('apps-'+str(int(time.time())));backup.mkdir(parents=True,exist_ok=True)
changed=[]
with tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:gz') as tar:
 for member in tar.getmembers():
  rel=Path(member.name)
  if member.islnk() or member.issym() or not member.isfile() or rel.is_absolute() or '..' in rel.parts:raise ValueError('Unsafe archive')
  dest=home/rel
  if dest.exists():
   # A seeded Spotify config without its token is not a working destination account.
   if member.name=='.config/spotify-player/app.toml':
    import tomllib
    try:c=tomllib.loads(dest.read_text());ready=(home/'.cache/spotify-player'/(c.get('client_id','')+'_token.json')).is_file()
    except (ValueError,OSError):ready=True
    if ready:continue
    shutil.copy2(dest,backup/'spotify-before-client-alignment.toml')
   else:continue
  dest.parent.mkdir(parents=True,exist_ok=True,mode=0o700);dest.write_bytes(tar.extractfile(member).read());dest.chmod(0o600);changed.append(member.name)
# Device identity must never claim the laptop's name.
p=home/'.config/spotify-player/app.toml'
if p.exists():
 import re
 shutil.copy2(p,backup/'spotify-app.toml')
 s=p.read_text();s=re.sub(r'^default_device\\s*=.*$', 'default_device = "Homie · fh1m"',s,flags=re.M)
 s=re.sub(r'(\\[device\\][\\s\\S]*?^name\\s*=).*$',r'\\1 "Homie · fh1m"',s,count=1,flags=re.M)
 p.write_text(s);p.chmod(0o600)
print(json.dumps({'installedMissingFiles':len(changed),'existingCredentialsPreserved':True}))
'''
    print(peer(code,stream.getvalue()).decode().strip())
    # The CLI's native distribution is installed at its versioned user path.
    source=HOME/'.local/share/claude/versions/2.1.300'
    if source.is_file():
        target='.local/share/claude/versions/2.1.300'
        peer("from pathlib import Path;p=Path.home()/'.local/share/claude/versions';p.mkdir(parents=True,exist_ok=True)")
        subprocess.run(['scp','-q','-F',str(HOME/'.local/state/homie-control/client.conf'),str(source),'homie:'+target+'.next'],check=True)
        peer("from pathlib import Path;h=Path.home();p=h/'.local/share/claude/versions/2.1.300';n=p.with_name(p.name+'.next');n.chmod(0o755);n.replace(p);b=h/'.local/bin/claude';b.parent.mkdir(parents=True,exist_ok=True);b.symlink_to(p) if not b.exists() else None")


if __name__=='__main__':
    os.umask(0o077);main()
