"""Reviewable course outlines; retryable publication uses existing creation receipts."""
import json
from pathlib import Path
import uuid
from .models import create
from .persistence import checksum,contained,lock,publish,manifest_path


def plan(source):
    source=Path(source).expanduser()
    if source.stat().st_size>512*1024:raise ValueError('Course outline too large')
    raw=source.read_text();document=json.loads(raw)
    if not isinstance(document,dict) or document.get('version')!=1:raise ValueError('Expected outline version 1')
    title=document.get('title');entries=document.get('entries')
    def valid_title(value):return isinstance(value,str) and value.strip() and len(value)<=100 and not any(c in value for c in '/\\\r\n\0')
    if not valid_title(title):raise ValueError('Course needs a title, not a path')
    if not isinstance(entries,list) or not 1<=len(entries)<=300:raise ValueError('Outline needs one to 300 entries')
    known={'course'};review=[]
    for number,entry in enumerate(entries):
        if not isinstance(entry,dict) or not isinstance(entry.get('key'),str) or not entry['key'] or len(entry['key'])>80 or entry['key'] in known:raise ValueError('Outline keys must be short and unique')
        if entry.get('kind') not in ('unit','task','project','concept','capability'):raise ValueError('Choose unit, task, project, concept or capability')
        if not valid_title(entry.get('title')):raise ValueError('Entry needs a title, not a path')
        parent=entry.get('parent','course')
        if parent not in known:raise ValueError('Parents must precede their children')
        fields=entry.get('fields',{})
        allowed={'unit_kind','source','local_file','source_kind','criteria','hypothesis'}
        if not isinstance(fields,dict) or set(fields)-allowed:raise ValueError('Unsupported outline fields')
        if not isinstance(entry.get('body',''),str):raise ValueError('Entry body must be text')
        if any(not isinstance(v,str) for k,v in fields.items() if k!='criteria'):raise ValueError('Outline fields must be text')
        if 'criteria' in fields and (not isinstance(fields['criteria'],list) or any(not isinstance(v,str) for v in fields['criteria'])):raise ValueError('Criteria must be text items')
        review.append(dict(entry,parent=parent,order=number));known.add(entry['key'])
    return {'title':title,'source':str(source),'digest':checksum(raw),'entries':review,'count':len(review),'status':'review'}


def apply(root,source,operation_id,expected_digest=None,course_id=None):
    reviewed=plan(source)
    if expected_digest and reviewed['digest']!=expected_digest:raise ValueError('Outline changed since review; review again')
    namespace=uuid.UUID(operation_id)
    manifest=json.loads(manifest_path(root).read_text())
    if manifest.get("noesis_schema")!=2:raise ValueError("Migrate the vault before importing an outline")
    course=None
    if course_id:
        from .index import Index
        from .courses import is_outline
        index=Index(root)
        try:
            health=index.reconcile()
            if health['errors']:raise ValueError('Resolve index errors before importing an outline')
            record=index.record(course_id,include_body=False,include_attempt=False)
            if not is_outline(record['props']):raise ValueError('Choose an existing course, book, path or module')
            course={'id':record['props']['id'],'path':record['path'],'type':record['props']['type'],'title':record['display_title']}
        finally:index.close()
    # Persist the namespace before publication; reopening the dialog can retry safely.
    journal=contained(root,'.Noesis/Outlines/'+reviewed['digest']+('-'+course_id if course_id else '')+'.json')
    if course_id:
        original_journal=contained(root,'.Noesis/Outlines/'+reviewed['digest']+'.json')
        if original_journal.exists():
            prior=json.loads(original_journal.read_text())
            if prior.get('course_id')==course_id or record['props'].get('operation_id')==str(uuid.uuid5(uuid.UUID(prior['operation_id']),'course')):
                journal=original_journal
    with lock(root):
        from .scopes import assert_unique
        assert_unique(root)
        if journal.exists():namespace=uuid.UUID(json.loads(journal.read_text())['operation_id'])
        else:publish(journal,json.dumps({'operation_id':str(namespace),'digest':reviewed['digest'],'status':'preparing'}))
    course=course or create(root,'resource',reviewed['title'],fields={'source_kind':'course','outline_sha256':reviewed['digest']},operation_id=str(uuid.uuid5(namespace,'course')))
    records={'course':course}
    for entry in reviewed['entries']:
        kind=entry['kind'];fields=entry.get('fields',{})
        records[entry['key']]=create(root,kind,entry['title'],entry.get('body',''),fields=fields,
                parent_id=records[entry['parent']]['id'],relation='assigns' if kind=='task' else 'pursues' if kind=='capability' else 'contains',
                order=entry['order'],operation_id=str(uuid.uuid5(namespace,entry['key'])))
    with lock(root):
        original=journal.read_text();state=json.loads(original);state.update(status='committed',course_id=course['id'])
        publish(journal,json.dumps(state),checksum(original))
    return {'status':'committed','course':course,'count':len(reviewed['entries']),'operation_id':str(namespace)}
