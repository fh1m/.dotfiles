#!/usr/bin/env python3
"""Back up recoverable OMP work without exporting provider credentials."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import sqlite3
import tarfile
import tempfile


def backup(home):
    root=home/'.omp/agent'
    dest=home/'Envs/backups/omp'
    dest.mkdir(parents=True,exist_ok=True,mode=0o700)
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    final=dest/(stamp+'.tar.gz');partial=dest/(stamp+'.partial')
    os.umask(0o077)
    with tempfile.TemporaryDirectory(prefix='omp-backup-') as tmp:
        stage=Path(tmp); hashes={}
        # Canonical sessions/blobs preserve tool evidence and multimodal history.
        for folder in ['sessions','blobs','memories','extensions','managed-skills','skills','rules','agents','prompts']:
            source=root/folder
            if not source.exists():continue
            for p in source.rglob('*'):
                if not p.is_file() or p.is_symlink():continue
                rel=p.relative_to(root);target=stage/'agent'/rel;target.parent.mkdir(parents=True,exist_ok=True)
                for attempt in range(3):
                    before=p.stat();shutil.copyfile(p,target);after=p.stat()
                    if (before.st_mtime_ns,before.st_size)==(after.st_mtime_ns,after.st_size):break
                else:raise RuntimeError('Session is changing continuously; retry backup when idle: '+str(rel))
        (stage/'agent').mkdir(exist_ok=True)
        for name in ['config.yml','lsp.json']:
            if (root/name).exists():shutil.copyfile(root/name,stage/'agent'/name)
        # history.db has title/recap metadata; backup API includes committed WAL data.
        source=root/'history.db'
        if source.exists():
            with sqlite3.connect(source.as_uri()+'?mode=ro',uri=True) as src, sqlite3.connect(stage/'agent/history.db') as dst:src.backup(dst)
        hub=home/'.local/share/omp-unified'
        for name in ['imports.json','nested-subagents.json']:
            if (hub/name).exists():
                (stage/'omp-unified').mkdir(exist_ok=True);shutil.copyfile(hub/name,stage/'omp-unified'/name)
        # New foreign continuations may postdate the original archive backup.
        revisions=hub/'revisions'
        if revisions.exists():shutil.copytree(revisions,stage/'omp-unified/revisions',symlinks=False)
        # Include configuration/provenance hashes and all immutable revision copies.
        for p in stage.rglob('*'):
            if p.is_file():hashes[str(p.relative_to(stage))]=hashlib.sha256(p.read_bytes()).hexdigest()
        manifest={'version':2,'created':stamp,'sha256':hashes,'credentials_included':False,
                  'note':'agent.db contains OAuth credentials and is deliberately excluded; reauthenticate after machine loss. Original foreign archives are backed up separately.'}
        (stage/'manifest.json').write_text(json.dumps(manifest,indent=2))
        with tarfile.open(partial,'w:gz',compresslevel=3) as archive:
            for p in stage.iterdir():archive.add(p,arcname=p.name)
        # Restore into disposable storage, check every content hash before publishing.
        restore=stage/'restore';restore.mkdir()
        with tarfile.open(partial) as archive:archive.extractall(restore,filter='data')
        for relative,expected in hashes.items():
            if hashlib.sha256((restore/relative).read_bytes()).hexdigest()!=expected:raise RuntimeError('Restore mismatch: '+relative)
        partial.replace(final);final.chmod(0o600)
    return {'archive':str(final),'verified_files':len(hashes),'restore_verified':True,'credentials_included':False,
            'off_device':False}

if __name__=='__main__':print(json.dumps(backup(Path('@HOME@')),indent=2))
