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

def canonical_relative(value):
    p=Path(value)
    if not isinstance(value,str) or p.is_absolute() or not p.parts or any(x in ('','.','..') for x in p.parts) or p.as_posix()!=value:raise ValueError('Invalid manifest path')
    return p

def contained(base,path):
    return path.resolve(strict=False).is_relative_to(base.resolve())

def safe_parents(home,rel):
    current=home
    for part in rel.parts[:-1]:
        current=current/part
        if current.is_symlink():raise ValueError('Symlink parent: '+str(current))

def rollback_data(manifest):
    manifest=manifest.resolve()
    data=json.loads(manifest.read_text())
    if not isinstance(data,dict) or set(data)!={'home','entries'} or not isinstance(data['home'],str) or not isinstance(data['entries'],list):raise ValueError('Invalid rollback manifest')
    home=Path(data['home'])
    if not home.is_absolute() or home==Path('/') or home!=home.resolve():raise ValueError('Untrusted home')
    safe_parents(home,Path('.local/state/omp-deployments/placeholder/manifest.json'))
    base=home/'.local/state/omp-deployments'
    if not contained(base,manifest) or manifest.name!='manifest.json':raise ValueError('Manifest outside deployment backup')
    seen=set();validated=[]
    for e in data['entries']:
        if not isinstance(e,dict) or set(e)!={'path','before','sha256'} or type(e['before']) is not bool or not isinstance(e['sha256'],str) or len(e['sha256'])!=64:raise ValueError('Invalid manifest entry')
        rel=canonical_relative(e['path'])
        if e['path'] in seen:raise ValueError('Duplicate manifest path')
        seen.add(e['path']);safe_parents(home,rel);p=home/rel
        if p.is_symlink() or not p.is_file() or digest(p)!=e['sha256']:raise ValueError('Changed since deployment: '+str(p))
        old=manifest.parent/'files'/rel
        if e['before'] and (not contained(manifest.parent/'files',old) or old.is_symlink() or not old.is_file()):raise ValueError('Missing or unsafe backup: '+str(old))
        validated.append((e,p,old))
    return home,validated


def install(home,apply=False):
    home=home.resolve()
    if apply and os.geteuid()==0:raise PermissionError('Refusing deployment as root')
    backup=home/'.local/state/omp-deployments'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    entries=[];updates=[]
    for source in sorted((ROOT/'home').rglob('*')):
        relative=str(source.relative_to(ROOT/'home'))
        if not source.is_file() or '__pycache__' in source.parts or source.suffix=='.pyc':continue
        if relative not in EXACT and not any(relative.startswith(x+'/') for x in PREFIXES):continue
        rel=canonical_relative(relative);data=source.read_text().replace('@HOME@',str(home)).replace('/home/fh1m',str(home)).encode()
        dest=home/rel;safe_parents(home,rel)
        if dest.is_file() and not dest.is_symlink() and dest.read_bytes()==data:continue
        if dest.is_symlink() or dest.is_dir():raise ValueError('Refusing to overwrite symlink/directory: '+str(dest))
        entry={'path':relative,'before':dest.exists(),'sha256':hashlib.sha256(data).hexdigest()};entries.append(entry);updates.append((source,rel,data,dest))
    if not apply:return {'apply':False,'changed':[e['path'] for e in entries],'manifest':None}
    if not entries:return {'apply':True,'changed':[],'manifest':None}
    safe_parents(home,Path('.local/state/omp-deployments/'+backup.name+'/manifest.json'))
    backup.mkdir(parents=True,exist_ok=False,mode=0o700)
    for entry,(_,rel,_,dest) in zip(entries,updates):
        if entry['before']:
            old=backup/'files'/rel;old.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest,old)
    for _,rel,data,dest in updates:
        dest.parent.mkdir(parents=True,exist_ok=True);safe_parents(home,rel)
        temp=dest.with_name(dest.name+'.omp-new')
        with temp.open('xb') as f:f.write(data)
        temp.chmod(0o755 if str(rel).startswith('.local/bin/') else 0o644);temp.replace(dest)
    (backup/'manifest.json').write_text(json.dumps({'home':str(home),'entries':entries},indent=2))
    return {'apply':True,'changed':[e['path'] for e in entries],'manifest':str(backup/'manifest.json')}


def rollback(manifest,apply=False):
    if apply and os.geteuid()==0:raise PermissionError('Refusing rollback as root')
    home,validated=rollback_data(manifest)
    if apply:
        for entry,dest,old in reversed(validated):
            if entry['before']:shutil.copy2(old,dest)
            else:dest.unlink()
    return {'apply':apply,'restored':[e['path'] for e,_,_ in validated]}

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--home',type=Path,default=Path.home());p.add_argument('--apply',action='store_true');p.add_argument('--rollback',type=Path);a=p.parse_args()
    print(json.dumps(rollback(a.rollback,a.apply) if a.rollback else install(a.home.resolve(),a.apply),indent=2))
