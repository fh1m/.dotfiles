"""Shared extensible records and explicit relationships."""
from datetime import datetime, timezone
import json
import uuid
from .index import Index
from .persistence import read_content
from .persistence import checksum, contained, lock, manifest_path, parse, publish, render

KINDS = ('path', 'capability', 'concept', 'resource', 'unit', 'task', 'project', 'experiment',
         'question', 'misconception', 'branch', 'artifact', 'relationship', 'session')


def promote(root, relative, kind, expected_id=None):
    if kind not in KINDS:raise ValueError('Unknown promotion kind')
    with lock(root):
        from .scopes import assert_unique
        assert_unique(root)
        path = contained(root, relative)
        text = read_content(path)
        props, body = parse(text)
        from .persistence import supported_schema
        supported_schema(props,legacy=True)
        if not props.get('id') or expected_id and props['id'] != expected_id:
            raise ValueError('Target identity missing or changed')
        index = Index(root)
        try:
            health = index.reconcile()
            if health['errors']:raise ValueError(str(health['errors']))
            index.record(props['id'])
        finally:index.close()
        original = props.get('type', 'note')
        if original != kind:
            props.update(type=kind, promoted_from=original, promoted_at=datetime.now(timezone.utc).isoformat())
            publish(path, render(props, body), checksum(text))
        return dict(props, path=str(path.relative_to(root)))


def create(root, kind, title, body='', fields=None, parent_id=None, relation='contains', order=None, operation_id=None):
    if kind not in KINDS:raise ValueError('Unsupported creation kind')
    if not title.strip() or any(c in title for c in '/\\\n\r\0'):raise ValueError('Use a title, not a path')
    if operation_id:uuid.UUID(operation_id)
    request_hash=checksum(json.dumps(dict(kind=kind,title=title,body=body,fields=fields or {},parent_id=parent_id,relation=relation,order=order),sort_keys=True))
    with lock(root):
        from .scopes import assert_unique
        assert_unique(root)
        fields=dict(fields or {})
        if operation_id:
            receipt=contained(root,'.Noesis/Operations/'+operation_id+'.json')
            if receipt.exists():
                journal=json.loads(read_content(receipt))
                index=Index(root)
                try:
                    index.reconcile()
                    exists=index.db.execute("SELECT 1 FROM records WHERE json_extract(props,'$.operation_id')=? LIMIT 1",(operation_id,)).fetchone()
                finally:index.close()
                # An acknowledged creation is independent of current tool/storage availability.
                if exists or journal.get('status')=='committed':
                    return _create(root,kind,title,body,fields,operation_id,request_hash)
        if parent_id:
            if relation not in ('contains','assigns','references','investigates','pursues'):raise ValueError('Unsupported parent relationship')
            index=Index(root)
            try:
                health=index.reconcile()
                if health['errors']:raise ValueError(str(health['errors']))
                parent=index.record(parent_id,include_body=False,include_attempt=False)['props']
                repository=parent.get('repository') or (parent.get('code_snapshot') or {}).get('repository')
                if kind=='experiment' and repository:
                    from .development import snapshot
                    try:fields['code_snapshot']=snapshot(repository)
                    except (ValueError,OSError):fields['code_snapshot']={'repository':repository,'availability':'unavailable'}
                meta=json.loads(manifest_path(root).read_text())
                if kind=='unit' and order is None:
                    existing=[json.loads(raw).get('order') for raw, in index.db.execute('SELECT props FROM relationships WHERE source=?',(parent_id,))]
                    order=max([n for n in existing if type(n) is int],default=-1)+1
                fields['parent_ref']={'vault_id':meta['vault_id'],'record_id':parent_id,'relation':relation,'order':order}
            finally:index.close()
        if kind=='question' and fields.get('evidence_refs') is not None:
            from .frontier import evidence_record
            refs=fields['evidence_refs']
            if not isinstance(refs,list) or not 1<=len(refs)<=8 or not parent_id:
                raise ValueError('An attempt-linked question needs its original context and bounded evidence references')
            index=Index(root)
            try:
                index.reconcile()
                for ref in refs:
                    evidence=evidence_record(index,ref)['props']
                    if (ref['vault_id']!=index.manifest['vault_id'] or evidence.get('event') not in ('attempt','review')
                            or evidence.get('target')!={'vault_id':index.manifest['vault_id'],'record_id':parent_id}):
                        raise ValueError('Question evidence must be an assessment of its exact owning context')
            finally:index.close()
        if kind=='project' and fields.get('repository'):
            from .development import snapshot
            fields['code_snapshot']=snapshot(fields['repository'])
            fields['repository']=fields['code_snapshot']['repository']
        return _create(root,kind,title,body,fields,operation_id,request_hash)


def _create(root, kind, title, body='', fields=None, operation_id=None, request_hash=None):
    meta = json.loads(manifest_path(root).read_text())
    if meta.get('noesis_schema') != 2:raise ValueError('Migrate the vault first')
    uuid.UUID(str(meta.get('vault_id')))
    journal_path=contained(root,'.Noesis/Operations/'+operation_id+'.json') if operation_id else None
    original=read_content(journal_path) if journal_path and journal_path.exists() else None
    journal=json.loads(original) if original else None
    if journal:
        if journal.get('request_hash')!=request_hash or journal.get('vault_id')!=meta['vault_id']:
            raise ValueError('Operation ID reused with changed record content or vault identity')
        index=Index(root)
        try:
            health=index.reconcile()
            if health['errors']:raise ValueError('Could not verify previous creation: '+str(health['errors']))
            rows=list(index.db.execute("SELECT path,props FROM records WHERE json_extract(props,'$.operation_id')=?",(operation_id,)))
            if len(rows)==1:
                if journal.get('status')!='committed':
                    journal['status']='committed';publish(journal_path,json.dumps(journal,indent=2),checksum(original))
                return dict(json.loads(rows[0][1]),path=rows[0][0])
            if rows or journal.get('status')=='committed':
                raise ValueError('Previous creation committed but is missing or duplicated; inspect recovery before retrying')
        finally:index.close()
    props = dict(fields or {})
    props.update(id=str(uuid.uuid4()), noesis_schema=2, type=kind, title=title, created=datetime.now(timezone.utc).isoformat())
    path = contained(root, 'Records/' + kind + '/' + title[:100] + ' [' + props['id'][:8] + '].md')
    if journal:
        props=journal['props'];path=contained(root,journal['path'])
    elif journal_path:
        props.update(operation_id=operation_id,request_hash=request_hash)
        journal=dict(status='preparing',vault_id=meta['vault_id'],operation_id=operation_id,request_hash=request_hash,props=props,path=str(path.relative_to(root)))
        original=json.dumps(journal,indent=2);publish(journal_path,original)
    publish(path, render(props, '\n# ' + title + '\n\n' + body + '\n'))
    if journal_path:
        journal['status']='committed';publish(journal_path,json.dumps(journal,indent=2),checksum(original))
    return dict(props, path=str(path.relative_to(root)))

def relationship(root, source, target, relation, role=None, reason='', exit_task=None, context=None, order=None, operation_id=None):
    with lock(root):
        from .scopes import assert_unique
        assert_unique(root)
        return _relationship(root,source,target,relation,role,reason,exit_task,context,order,operation_id)


def _relationship(root, source, target, relation, role=None, reason='', exit_task=None, context=None, order=None, operation_id=None):
    if operation_id:uuid.UUID(operation_id)
    if relation not in ('contains', 'orders', 'assigns', 'supports', 'exercises', 'pursues', 'prerequisite', 'investigates', 'produces', 'references'):
        raise ValueError('Unsupported relationship')
    if relation == 'prerequisite' and role not in ('gate', 'parallel', 'deep-descent'):
        raise ValueError('Prerequisite needs a contextual role')
    index = Index(root)
    try:
        health = index.reconcile()
        if health['errors']:raise ValueError(str(health['errors']))
        for identity in (source, target, exit_task, context):
            if identity:index.record(identity)
        if relation == 'prerequisite' and role == 'gate':
            graph = {}
            for _, raw in index.db.execute("SELECT path,props FROM records WHERE kind='relationship'"):
                props = json.loads(raw)
                if props.get('relation') == 'prerequisite' and props.get('role') == 'gate' and props.get('context') == context:
                    graph.setdefault(props['source'], []).append(props['target'])
            graph.setdefault(source, []).append(target)
            pending=[target];seen=set()
            while pending:
                node=pending.pop()
                if node==source:raise ValueError('Blocking prerequisite cycle')
                if node in seen:continue
                seen.add(node);pending.extend(graph.get(node,()))
        meta=json.loads(manifest_path(root).read_text())
        fields = dict(source=source, target=target, source_ref={'vault_id':meta['vault_id'],'record_id':source}, target_ref={'vault_id':meta['vault_id'],'record_id':target}, relation=relation, role=role, reason=reason,
                      exit_task=exit_task, context=context, order=order)
        request_hash=checksum(json.dumps(fields,sort_keys=True))
        return _create(root, 'relationship', relation + ' ' + source[:8] + ' to ' + target[:8], reason, fields,operation_id,request_hash)
    finally:index.close()
