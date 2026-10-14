"""Encrypted local deduplicated backups; never prune the sole verified copy."""
import hashlib
import json
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import tempfile
from .persistence import contained, lock, manifest_path, publish


def digest(path):
    with path.open('rb') as stream:return hashlib.file_digest(stream, 'sha256').hexdigest()


def command(state, *args, cwd=None):
    executable = shutil.which('restic')
    if not executable:raise ValueError('Restic unavailable; install packages/learning.txt requirement')
    return subprocess.run([executable, '-r', str(state / 'repository'), '--password-file', str(state / 'password'), *args],
                          cwd=cwd, text=True, capture_output=True, check=True).stdout


def backup(root, state=None, reader_snapshots=None):
    root = Path(root).resolve()
    manifest_path(root)
    state = Path(state) if state else Path.home() / '.local/state/sensei-learning/restic'
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    with lock(state), lock(root):
        password = state / 'password'
        if not password.exists():
            publish(password, secrets.token_urlsafe(48) + '\n')
            password.chmod(0o600)
        if not (state / 'repository/config').exists():command(state, 'init')
        with tempfile.TemporaryDirectory(dir=state) as temporary:
            stage = Path(temporary) / 'vault'
            stage.mkdir(mode=0o700)
            files, external = {}, {}
            reader_states=[]
            for folder, dirs, names in os.walk(root, followlinks=False):
                dirs[:] = [d for d in dirs if d not in {'plugins', 'themes', '.cache', 'node_modules', 'build','RecoveredReaderState'} and not (Path(folder) / d).is_symlink()]
                for name in names:
                    source = Path(folder) / name
                    if source.is_symlink() or name=='.noesis-recovery.json' or name.startswith(('.env', 'workspace', 'credentials')) or 'token' in name.lower() or source.suffix in {'.sqlite', '.db', '.log'}:continue
                    relative = str(source.relative_to(root))
                    before = source.stat()
                    if before.st_size > 25 * 1024 * 1024 or source.suffix.lower() in {'.mcap', '.bag', '.mp4', '.mkv'}:
                        external[relative] = {'location': str(source), 'size': before.st_size, 'availability': 'external; not backed up here'}
                        continue
                    target = contained(stage, relative)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(source, target)
                    after = source.stat()
                    if (before.st_mtime_ns, before.st_size, before.st_ino) != (after.st_mtime_ns, after.st_size, after.st_ino):
                        raise ValueError('File changed while staging backup: ' + relative)
                    files[relative] = digest(target)
            snapshots=[]
            previous=root/'.noesis-recovery.json'
            if previous.exists():
                recovered=json.loads(previous.read_text())
                for reader in recovered.get('reader_states',[]):
                    relative=reader['path']
                    if not isinstance(relative,str) or not relative.startswith('RecoveredReaderState/'):raise ValueError('Invalid recovered reader-state reference')
                    snapshots.append(contained(root,relative))
            supplied=reader_snapshots or []
            if not isinstance(supplied,list):raise ValueError('Reader snapshots must be a list')
            snapshots.extend(supplied)
            owned={}
            for snapshot in snapshots:
                snapshot=Path(snapshot).expanduser().resolve();metadata_file=snapshot/'manifest.json'
                if metadata_file.stat().st_size>4*1024*1024:raise ValueError('Reader manifest too large')
                metadata=json.loads(metadata_file.read_text())
                source=metadata.get('source')
                if not isinstance(source,str) or not source:raise ValueError('Reader snapshot needs an owning source')
                owned[source]=snapshot
            snapshots=list(owned.values())
            if len(snapshots)>4:raise ValueError('Select at most four verified reader snapshots')
            for number,snapshot in enumerate(snapshots):
                snapshot=Path(snapshot).expanduser().resolve()
                metadata_file=snapshot/'manifest.json'
                if metadata_file.stat().st_size>4*1024*1024:raise ValueError('Reader manifest too large')
                metadata=json.loads(metadata_file.read_text())
                entries=metadata.get('files')
                if not isinstance(entries,dict) or len(entries)>10000 or not isinstance(metadata.get('database_sources'),dict):raise ValueError('Expected a verified reader snapshot manifest')
                prefix='RecoveredReaderState/'+str(number)
                for name,expected in entries.items():
                    source=contained(snapshot,name)
                    if (snapshot/name).is_symlink() or not source.is_file() or digest(source)!=expected:raise ValueError('Reader snapshot missing, unsafe or changed: '+name)
                    relative=prefix+'/'+name;target=contained(stage,relative);target.parent.mkdir(parents=True,exist_ok=True)
                    shutil.copyfile(source,target)
                    if digest(target)!=expected:raise ValueError('Reader snapshot changed during backup: '+name)
                    files[relative]=expected
                target=contained(stage,prefix+'/manifest.json');publish(target,json.dumps(metadata))
                files[prefix+'/manifest.json']=digest(target)
                reader_states.append({'path':prefix,'source':metadata.get('source'),'database_sources':metadata['database_sources'],'external':metadata.get('external',{})})
            publish(stage / '.noesis-recovery.json', json.dumps({'source': str(root), 'files': files, 'external': external,'reader_states':reader_states}))
            output = command(state, 'backup', '--json', '--tag', 'noesis', 'vault', cwd=stage.parent)
            summary = next(json.loads(line) for line in reversed(output.splitlines()) if json.loads(line).get('message_type') == 'summary')
            command(state, 'check')
            return {'snapshot_id': summary['snapshot_id'], 'repository': str(state / 'repository'), 'external': external,
                    'off_device': False, 'password_file': str(password),'reader_states':reader_states}


def restore(snapshot, destination, state=None):
    state = Path(state) if state else Path.home() / '.local/state/sensei-learning/restic'
    destination = Path(destination)
    if destination.exists() or destination.is_symlink():raise ValueError('Restore destination exists')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with lock(state), tempfile.TemporaryDirectory(dir=destination.parent) as temporary:
        stage = Path(temporary)
        command(state, 'restore', snapshot, '--target', str(stage))
        manifests = list(stage.rglob('.noesis-recovery.json'))
        if len(manifests) != 1:raise ValueError('Expected one Noesis recovery manifest')
        root = manifests[0].parent
        manifest = json.loads(manifests[0].read_text())
        for name, expected in manifest['files'].items():
            if digest(contained(root, name)) != expected:raise ValueError('Restored checksum mismatch: ' + name)
        root.rename(destination)
    return {'destination': str(destination), 'verified_files': len(manifest['files']), 'external': manifest['external'],'reader_states':[dict(reader,path=str(contained(destination,reader['path']))) for reader in manifest.get('reader_states',[])]}
