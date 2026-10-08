"""Explicit restore replacement and copy-on-publish forks; originals stay untouched."""
import fcntl
import json
import os
from pathlib import Path
import shutil
import tempfile
import uuid
from .persistence import checksum,lock,manifest_path,notes,parse,publish,read_content,render
from .scopes import identity,locations,registry_path


def replace_location(restored,original):
    restored=Path(restored).resolve();original=Path(original).resolve()
    if restored==original or not restored.is_dir():raise ValueError('Choose a distinct restored vault directory')
    value=identity(restored)
    if not value or identity(original)!=value:raise ValueError('Replacement requires matching vault identities')
    path=registry_path();path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    with open(path.with_suffix('.lock'),'a') as stream:
        os.chmod(stream.name,0o600);fcntl.flock(stream,fcntl.LOCK_EX)
        if original not in locations():raise ValueError('Original location is not registered')
        others={p for p in locations()-{original,restored} if identity(p)==value}
        if others:raise ValueError('Additional duplicate locations require explicit resolution')
        text=read_content(path) if path.exists() else None
        data=json.loads(text) if text else {'version':1,'locations':[]}
        if data.get('version')!=1:raise ValueError('Unsupported location registry')
        data['locations']=sorted((set(data.get('locations',[]))-{str(original)})|{str(restored)})
        data.setdefault('replacements',{})[str(original)]={'path':str(restored),'vault_id':value}
        # The prior local registry is retained for rollback; native registry is untouched.
        backup=path.parent/'recovery'/str(uuid.uuid4());backup.mkdir(parents=True,mode=0o700)
        (backup/'locations.json').write_text(text or '{}');(backup/'locations.json').chmod(0o600)
        publish(path,json.dumps(data,indent=2)+'\n',checksum(text) if text else None)
    return {'path':str(restored),'vault_id':value,'replaces':str(original),'registry_backup':str(backup),'original_content_unchanged':True}


def fork(source,destination):
    source=Path(source).resolve();destination=Path(destination).expanduser().resolve()
    if destination.exists() or source==destination or source in destination.parents:
        raise ValueError('Fork destination must be a new directory outside the source vault')
    original_id=identity(source)
    if not original_id:raise ValueError('Fork requires a managed vault identity')
    destination.parent.mkdir(parents=True,exist_ok=True)
    stage=Path(tempfile.mkdtemp(prefix='.noesis-fork-',dir=destination.parent))
    try:
        with lock(source):
            # Explicit fork copies data, not reader/editor runtime or local operation receipts.
            for path in source.rglob('*'):
                relative=path.relative_to(source)
                if any(part in ('.git','.obsidian','.Noesis','.cache','__pycache__') for part in relative.parts):continue
                if path.is_symlink():raise ValueError('Fork refuses symlinks; keep external artifacts as explicit references')
                target=stage/relative
                if path.is_dir():target.mkdir(parents=True,exist_ok=True)
                elif path.is_file():target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(path,target);target.chmod(0o600)
            mappings={original_id:str(uuid.uuid4())};parsed=[]
            for path in notes(stage):
                props,body=parse(read_content(path))
                from .persistence import supported_schema
                supported_schema(props,legacy=True)
                if props.get('id'):
                    if props['id'] in mappings:raise ValueError('Duplicate record identity; repair before forking')
                    mappings[props['id']]=str(uuid.uuid4())
                parsed.append((path,props,body))
            def remap(value):
                if isinstance(value,dict):
                    if value.get('vault_id') and value['vault_id']!=original_id:return dict(value)
                    return {key:remap(item) for key,item in value.items()}
                if isinstance(value,list):return [remap(item) for item in value]
                return mappings.get(value,value) if isinstance(value,str) else value
            for path,props,body in parsed:
                updated=remap(props)
                for endpoint in ('source','target'):
                    reference=props.get(endpoint+'_ref') or {}
                    if reference.get('vault_id') and reference['vault_id']!=original_id:updated[endpoint]=props.get(endpoint)
                if props.get('id'):updated['forked_from']={'vault_id':original_id,'record_id':props['id']}
                updated.pop('operation_id',None);updated.pop('request_hash',None)
                path.write_text(render(updated,body))
            manifest=manifest_path(stage);meta=json.loads(manifest.read_text());meta=remap(meta)
            meta['forked_from']={'vault_id':original_id,'location':str(source)}
            manifest.write_text(json.dumps(meta,indent=2)+'\n')
            from .index import Index
            index=Index(stage)
            try:
                health=index.reconcile()
                if health['errors']:raise ValueError('Fork validation failed: '+str(health['errors']))
            finally:index.close()
            os.rename(stage,destination)
        return {'path':str(destination),'vault_id':mappings[original_id],'records':len(parsed),
                'source_unchanged':True,'registration':'Register this explicit fork when ready; source remains registered'}
    finally:
        if stage.exists():shutil.rmtree(stage)
