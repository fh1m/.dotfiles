#!/usr/bin/env python3
"""Seed private Git history beside the personal Work mirror, without checkout.

Preview by default. Repeating --apply archives new bundles/WIP but never resets
an existing Homie repository. Working files travel through Syncthing separately.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import time

HOME=Path.home();ROOT=HOME/'Work';PRIVATE=HOME/'.local/state/homie-control'
SSH=['ssh','-F',str(PRIVATE/'client.conf'),'homie']


def discover(root):
    result=[]
    for directory,dirs,files in os.walk(root):
        path=Path(directory)
        if '.git' in dirs or '.git' in files:
            if subprocess.run(['git','-C',str(path),'rev-parse','--verify','HEAD'],capture_output=True).returncode==0:result.append(path)
            dirs[:]=[]
        else:dirs[:]=[d for d in dirs if d not in {'node_modules','.venv','venv','build','install','log','target','__pycache__'}]
    return result


def seed_repository(handoff,root):
    meta=json.loads((handoff/'record.json').read_text());path=root/meta['relative']
    if not path.resolve().is_relative_to(root.resolve()):raise ValueError('Project escapes mirror')
    path.mkdir(parents=True,exist_ok=True)
    def git(*args):return subprocess.run(['git','-C',str(path),*args],capture_output=True,check=True)
    valid=subprocess.run(['git','-C',str(path),'rev-parse','--verify','HEAD'],capture_output=True).returncode==0
    if valid:return {'seeded':False,'head':git('rev-parse','HEAD').stdout.decode().strip()}
    # A mirror may have created only directory placeholders before ignores settled.
    # Preserve that incomplete metadata before initializing, never touch work files.
    metadata=path/'.git'
    if metadata.exists():shutil.move(str(metadata),str(handoff/('incomplete-git-'+str(time.time_ns()))))
    git('init','-q')
    git('fetch','-q','--update-head-ok',str(handoff/'history.bundle'),'+refs/heads/*:refs/heads/*','+refs/tags/*:refs/tags/*')
    git('fetch','-q',str(handoff/'history.bundle'),'HEAD')
    branch=meta['branch'] or 'den-handoff'
    git('update-ref','refs/heads/'+branch,meta['head'])
    git('symbolic-ref','HEAD','refs/heads/'+branch)
    git('read-tree',meta['head'])
    if (handoff/'index.patch').stat().st_size:git('apply','--cached',str(handoff/'index.patch'))
    git('fsck','--connectivity-only','--no-dangling')
    return {'seeded':True,'head':meta['head']}


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');p.add_argument('--receive',type=Path);args=p.parse_args()
    if args.receive:
        if not args.receive.resolve().is_relative_to((HOME/'.local/state/den/project-handoffs').resolve()):raise ValueError('Unowned handoff')
        print(json.dumps(seed_repository(args.receive,HOME/'Den/Mirror/arete/den-work')));return
    projects=discover(ROOT)
    if not args.apply:print(json.dumps({'repositories':len(projects),'policy':'bundle + WIP; no checkout, reset, force or automatic publication'}));return
    records=[]
    receiver=str(PRIVATE/'setup-den-projects.py')
    subprocess.run(['scp','-q','-F',str(PRIVATE/'client.conf'),str(Path(__file__).resolve()),'homie:'+receiver],check=True)
    with tempfile.TemporaryDirectory(prefix='den-projects-') as tmp:
        for path in projects:
            rel=str(path.relative_to(ROOT));ident=hashlib.sha256(rel.encode()).hexdigest()[:16]
            stamp=time.strftime('%Y%m%dT%H%M%S');local=Path(tmp)/ident;local.mkdir()
            def git(*cmd):return subprocess.check_output(['git','-C',str(path),*cmd])
            (local/'history.bundle').write_bytes(git('bundle','create','-','--all','HEAD'))
            (local/'working.patch').write_bytes(git('diff','HEAD','--binary'))
            (local/'index.patch').write_bytes(git('diff','--cached','--binary'))
            branch=subprocess.run(['git','-C',str(path),'symbolic-ref','--quiet','--short','HEAD'],capture_output=True,text=True).stdout.strip()
            meta={'relative':rel,'head':git('rev-parse','HEAD').decode().strip(),'branch':branch,'captured':stamp}
            (local/'record.json').write_text(json.dumps(meta,indent=2))
            remote_dir=str(HOME/'.local/state/den/project-handoffs'/ident/stamp)
            subprocess.run([*SSH,'mkdir -p '+shlex.quote(remote_dir)],check=True)
            subprocess.run(['scp','-q','-F',str(PRIVATE/'client.conf'),*[str(x) for x in local.iterdir()],'homie:'+remote_dir+'/'],check=True)
            r=subprocess.run([*SSH,shlex.join(['python3',receiver,'--receive',remote_dir])],capture_output=True,text=True,check=True)
            records.append({'id':ident,**json.loads(r.stdout)})
    out=PRIVATE/'project-handoffs.json';out.write_text(json.dumps(records,indent=2));out.chmod(0o600)
    print(json.dumps({'repositories':len(records),'seeded':sum(x['seeded'] for x in records),'existingRepositoriesReset':0}))


if __name__=='__main__':os.umask(0o077);main()
