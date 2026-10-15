"""Resolve explicit vault/record references without treating a path as identity."""
from pathlib import Path
import uuid
from .scopes import locations,identity
from .index import Index


def resolve(reference):
    if not isinstance(reference,dict):raise ValueError('Reference needs vault and record identities')
    vault_id=str(uuid.UUID(reference['vault_id']));record_id=str(uuid.UUID(reference['record_id']))
    roots=[]
    for root in locations():
        if root.name in ('Downloads','Archives'):continue
        try:
            if identity(root)==vault_id:roots.append(root)
        except (ValueError,OSError):continue
    if len(roots)!=1:raise ValueError('Referenced vault is unavailable or registered more than once')
    index=Index(roots[0])
    try:
        health=index.reconcile()
        if health['errors']:raise ValueError('Referenced vault has index errors')
        record=index.record(record_id,include_body=False,include_attempt=False)
        return {'vault':str(roots[0]),'vault_id':vault_id,'record_id':record_id,
                'path':record['path'],'title':record['display_title'],'type':record['props'].get('type'),
                'status':record['state'].get('status')}
    finally:index.close()


def link(root,source,target,relation,target_vault,reason='',operation_id=None):
    # Cross-vault contextual gates need a global deadlock policy; do not flatten them.
    if relation not in ('references','supports','exercises','pursues'):raise ValueError('Cross-vault links currently support references, supports, exercises and pursues')
    root=Path(root).resolve();target_vault=Path(target_vault).expanduser().resolve()
    other_id=identity(target_vault)
    resolved=resolve({'vault_id':other_id,'record_id':target})
    if Path(resolved['vault'])!=target_vault:raise ValueError('Target vault location changed')
    index=Index(root)
    try:index.reconcile();index.record(source,include_body=False,include_attempt=False);own_id=index.manifest['vault_id']
    finally:index.close()
    from .models import create
    return create(root,'relationship',relation+' '+source[:8]+' to '+target[:8],reason,fields={
        'source':source,'target':target,'source_ref':{'vault_id':own_id,'record_id':source},
        'target_ref':{'vault_id':other_id,'record_id':target},'relation':relation,'reason':reason},operation_id=operation_id)
