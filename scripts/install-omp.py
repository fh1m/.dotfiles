#!/usr/bin/env python3
"""Scoped OMP integration deployment, with hash-checked rollback. Dry run by default."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import os
import shutil

ROOT=Path(__file__).resolve().parents[1]
PREFIXES=['.local/share/omp-den','.local/share/omp-unified']
EXACT=['.local/bin/omp-work','.local/bin/omp-unified','.omp/agent/extensions/sensei-unified.ts','.omp/agent/extensions/den-desktop.ts','.omp/agent/lsp.json']


def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def install(home,apply=False):
    backup=home/'.local/state/omp-deployments'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    entries=[]
    for source in sorted((ROOT/'home').rglob('*')):
        relative=str(source.relative_to(ROOT/'home'))
        if not source.is_file() or '__pycache__' in source.parts or source.suffix=='.pyc':continue
        if relative not in EXACT and not any(relative.startswith(x+'/') for x in PREFIXES):continue
        data=source.read_text().replace('@HOME@',str(home)).replace('/home/fh1m',str(home)).encode()
        dest=home/relative
        if dest.is_file() and not dest.is_symlink() and dest.read_bytes()==data:continue
        if dest.is_symlink() or dest.is_dir():raise ValueError('Refusing to overwrite symlink/directory: '+str(dest))
        entry={'path':relative,'before':dest.exists(),'sha256':hashlib.sha256(data).hexdigest()};entries.append(entry)
        if not apply:continue
        backup.mkdir(parents=True,exist_ok=True,mode=0o700)
        if dest.exists():
            old=backup/'files'/relative;old.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest,old)
        dest.parent.mkdir(parents=True,exist_ok=True)
        temp=dest.with_name(dest.name+'.omp-new')
        with temp.open('xb') as f:f.write(data)
        temp.chmod(0o755 if relative.startswith('.local/bin/') or source.stat().st_mode&0o111 else 0o644)
        temp.replace(dest)
        (backup/'manifest.json').write_text(json.dumps({'home':str(home),'entries':entries},indent=2))
    return {'apply':apply,'changed':[e['path'] for e in entries],'manifest':str(backup/'manifest.json') if apply and entries else None}


def rollback(manifest,apply=False):
    data=json.loads(manifest.read_text());home=Path(data['home'])
    for e in data['entries']:
        p=home/e['path']
        if p.is_symlink() or not p.is_file() or digest(p)!=e['sha256']:raise ValueError('Changed since deployment: '+str(p))
    if apply:
        for e in reversed(data['entries']):
            p=home/e['path']
            if e['before']:shutil.copy2(manifest.parent/'files'/e['path'],p)
            else:p.unlink()
    return {'apply':apply,'restored':[e['path'] for e in data['entries']]}

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--home',type=Path,default=Path.home());p.add_argument('--apply',action='store_true');p.add_argument('--rollback',type=Path);a=p.parse_args()
    print(json.dumps(rollback(a.rollback,a.apply) if a.rollback else install(a.home.resolve(),a.apply),indent=2))
