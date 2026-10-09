"""Versioned lesson sources; learner prose and previous positions remain intact."""
from pathlib import Path
from urllib.parse import urlsplit
from .persistence import contained

SOURCE_KEYS=('source','source_kind','local_file','zotero_uri','zotero_attachment_key')


def validate(material,root=None):
    if not isinstance(material,dict) or set(material)-{'source','local_file','source_kind'}:
        raise ValueError('Choose a source URL or local document for the lesson')
    if material.get('source_kind') not in ('video','pdf','article','documentation','book'):
        raise ValueError('Choose video, PDF, article, documentation or book')
    if bool(material.get('source'))==bool(material.get('local_file')):
        raise ValueError('Choose exactly one source URL or local document')
    for key in ('source','local_file'):
        value=material.get(key)
        if value is not None and (not isinstance(value,str) or len(value)>8192 or any(c in value for c in '\n\r\0')):
            raise ValueError('Invalid lesson source')
    if material.get('source'):
        url=urlsplit(material['source'])
        if url.scheme not in ('https','http') or not url.hostname or url.username or url.password:
            raise ValueError('Use an HTTP(S) source without embedded credentials')
    if root is not None and material.get('local_file'):
        path=Path(material['local_file']).expanduser()
        if not path.is_absolute():path=contained(root,material['local_file'])
        if not path.is_file():raise ValueError('Replacement document unavailable; no change was committed')
    return dict(material)


def effective_props(props,state):
    material=state.get('material')
    if material is None:return dict(props)
    material=validate(material)
    result={key:value for key,value in props.items() if key not in SOURCE_KEYS}
    result.update(material)
    return result


def source_snapshot(index,identity):
    """Declared source/version and owning identity, without copying learner prose."""
    from .readers import resource_props
    props=resource_props(index,identity)
    keys=SOURCE_KEYS+('doi','arxiv','revision','edition','sha256','zotero_version','zotero_projection','bibliography_projection')
    snapshot={key:props[key] for key in keys if props.get(key)}
    if snapshot:snapshot['record_ref']={'vault_id':index.manifest['vault_id'],'record_id':props['id']}
    return snapshot
