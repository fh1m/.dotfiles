"""Explicit, streaming external-artifact inspection; no file relocation."""
import hashlib
from pathlib import Path
from .index import Index
from .persistence import contained
from .activities import record_activity


def inspect(root, identity, operation_id=None):
    index=Index(root)
    try:
        health=index.reconcile()
        if health['errors']:raise ValueError(str(health['errors']))
        record=index.record(identity)
        props=record['props']
        if props.get('type')!='artifact':raise ValueError('Choose an artifact record')
        location=props.get('location') or props.get('local_file')
        if not location:raise ValueError('Artifact location is unknown')
        file=Path(location).expanduser()
        if not file.is_absolute():file=contained(root,str(file))
        fields={'location':str(file),'expected_sha256':props.get('sha256'),'availability':'artifact unavailable'}
        if file.is_file():
            before=file.stat()
            with file.open('rb') as stream:actual=hashlib.file_digest(stream,'sha256').hexdigest()
            after=file.stat()
            if (before.st_mtime_ns,before.st_size,before.st_ino)!=(after.st_mtime_ns,after.st_size,after.st_ino):raise ValueError('Artifact changed during inspection; no verification recorded')
            fields.update(availability='available',observed_sha256=actual,size=before.st_size,
                          integrity='matches expected checksum' if props.get('sha256')==actual else 'checksum mismatch' if props.get('sha256') else 'observed checksum; no expected checksum')
        relative=record['path']
    finally:index.close()
    return record_activity(root,relative,'artifact-check','Streaming file inspection; availability is separate from knowledge.',operation_id,expected_id=identity,**fields)
