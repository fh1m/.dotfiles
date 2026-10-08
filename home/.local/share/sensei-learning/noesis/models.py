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


def create(root, kind, title, body='', fields=None, parent_id=None, relation='contains', order=None):
    if kind not in KINDS:raise ValueError('Unsupported creation kind')
    if not title.strip() or any(c in title for c in '/\\\n\r\0'):raise ValueError('Use a title, not a path')
    with lock(root):
        from .scopes import assert_unique
        assert_unique(root)
        fields=dict(fields or {})
        if parent_id:
            if relation not in ('contains','assigns','references','investigates'):raise ValueError('Unsupported parent relationship')
            index=Index(root)
            try:
                health=index.reconcile()
                if health['errors']:raise ValueError(str(health['errors']))
                index.record(parent_id)
                meta=json.loads(manifest_path(root).read_text())
                if kind=='unit' and order is None:
                    existing=[json.loads(raw).get('order') for raw, in index.db.execute('SELECT props FROM relationships WHERE source=?',(parent_id,))]
                    order=max([n for n in existing if type(n) is int],default=-1)+1
                fields['parent_ref']={'vault_id':meta['vault_id'],'record_id':parent_id,'relation':relation,'order':order}
            finally:index.close()
        return _create(root,kind,title,body,fields)


def _create(root, kind, title, body='', fields=None):
    meta = json.loads(manifest_path(root).read_text())
    if meta.get('noesis_schema') != 2:raise ValueError('Migrate the vault first')
    uuid.UUID(str(meta.get('vault_id')))
    props = dict(fields or {})
    props.update(id=str(uuid.uuid4()), noesis_schema=2, type=kind, title=title, created=datetime.now(timezone.utc).isoformat())
    path = contained(root, 'Records/' + kind + '/' + title[:100] + ' [' + props['id'][:8] + '].md')
    publish(path, render(props, '\n# ' + title + '\n\n' + body + '\n'))
    return dict(props, path=str(path.relative_to(root)))

def relationship(root, source, target, relation, role=None, reason='', exit_task=None, context=None, order=None):
    with lock(root):
        from .scopes import assert_unique
        assert_unique(root)
        return _relationship(root,source,target,relation,role,reason,exit_task,context,order)


def _relationship(root, source, target, relation, role=None, reason='', exit_task=None, context=None, order=None):
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
        return _create(root, 'relationship', relation + ' ' + source[:8] + ' to ' + target[:8], reason, fields)
    finally:index.close()
