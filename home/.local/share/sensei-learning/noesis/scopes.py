"""Machine-local vault locations; Obsidian registration remains Obsidian-owned."""
import fcntl
import json
import os
from pathlib import Path
import uuid
from .persistence import read_content
from .persistence import checksum,manifest_path,publish


def registry_path():return Path.home()/'.local/state/noesis/vaults.json'


def locations():
    result=set()
    native=Path.home()/'.config/obsidian/obsidian.json'
    if native.exists():
        try:
            app=json.loads(native.read_text())
            entries=app.get('vaults',{}) if isinstance(app,dict) else {}
            if isinstance(entries,dict):
                result.update(Path(value['path']).expanduser().resolve() for value in entries.values() if isinstance(value,dict) and isinstance(value.get('path'),str))
        except (ValueError,KeyError,TypeError,OSError):pass
    path=registry_path()
    if path.exists():
        data=json.loads(path.read_text())
        values=data.get('locations',[]) if isinstance(data,dict) else None
        if not isinstance(values,list) or any(not isinstance(value,str) or not Path(value).is_absolute() for value in values):raise ValueError('Malformed Noesis location registry; preserve it and recover the registered paths')
        result.update(Path(value).resolve() for value in values)
    configuration=Path.home()/'.config/sensei-learning/config.json'
    if configuration.exists():
        try:
            active=json.loads(configuration.read_text()).get('active_vault')
            if active:result.add(Path(active).expanduser().resolve())
        except (ValueError,TypeError):pass
    return {path for path in result if path.is_dir()}


def identity(root):
    try:meta=json.loads(manifest_path(root).read_text())
    except FileNotFoundError:return None
    value=meta.get('vault_id')
    return str(uuid.UUID(value)) if value else None


def conflicts(root):
    root=Path(root).resolve();value=identity(root)
    if not value:return []
    duplicates=[]
    for other in locations()-{root}:
        try:
            if identity(other)==value:duplicates.append(str(other))
        except (ValueError,OSError):continue
    return sorted(duplicates)


def assert_unique(root):
    duplicates=conflicts(root)
    if duplicates:raise ValueError('Vault identity is registered at another location. A restored copy needs an explicit replacement or fork before mutation: '+', '.join(duplicates))


def register(root):
    root=Path(root).resolve()
    if not root.is_dir():raise ValueError('Vault directory unavailable')
    path=registry_path();path.parent.mkdir(parents=True,exist_ok=True,mode=0o700);path.parent.chmod(0o700)
    fd=os.open(path.with_suffix('.lock'),os.O_CREAT|os.O_RDWR,0o600)
    with os.fdopen(fd,'a') as stream:
        fcntl.flock(stream,fcntl.LOCK_EX)
        assert_unique(root)
        original=read_content(path) if path.exists() else None
        data=json.loads(original) if original else {'version':1,'locations':[]}
        if data.get('version')!=1:raise ValueError('Unsupported Noesis location registry version; nothing changed')
        data['locations']=sorted(set(data.get('locations',[]))|{str(root)})
        text=json.dumps(data,indent=2)+'\n'
        if text!=original:publish(path,text,checksum(original) if original else None)
        return {'path':str(root),'vault_id':identity(root),'noesis_registered':True,
                'obsidian_registration':'Open this folder as a vault in Obsidian when needed; its registry was not changed.'}
