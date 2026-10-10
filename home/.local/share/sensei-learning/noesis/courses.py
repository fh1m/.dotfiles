"""Bounded educational outlines and immutable changes to their sequence."""
import json
from .activities import record_activity,progress_state
from .index import Index,local_relationship


def is_outline(props):
    return props.get('type') in ('path','course') or props.get('type')=='unit' and props.get('unit_kind')=='module' or props.get('type')=='resource' and (props.get('source_kind') or props.get('medium')) in ('course','book','playlist')


def outline(index,parent,cursor=0,limit=50):
    record=index.record(parent,include_body=False,include_attempt=False)
    if not is_outline(record['props']):return {'records':[],'cursor':None,'available':False}
    if type(cursor) is not int or cursor<0:raise ValueError('Invalid outline cursor')
    limit=min(50,max(1,limit))
    ordering=record['state'].get('unit_order') or []
    rows=index.db.execute('''SELECT child.path,child.id,child.kind,child.title,state.status,
        json_extract(child.props,'$.unit_kind'),json_extract(state.state,'$.position'),
        MIN(COALESCE(sequence.key,100000+COALESCE(json_extract(edge.props,'$.order'),10000))) AS rank
        FROM relationships edge JOIN records child ON child.id=edge.target
        LEFT JOIN states state ON state.id=child.id
        LEFT JOIN json_each(?) sequence ON sequence.value=child.id
        WHERE edge.source=? AND edge.relation IN ('contains','orders','assigns','pursues')
        AND '''+local_relationship('edge')+'''
        GROUP BY child.id ORDER BY rank,child.path LIMIT ? OFFSET ?''',(json.dumps(ordering),parent,index.manifest['vault_id'],index.manifest['vault_id'],limit+1,cursor)).fetchall()
    records=[dict(zip(('path','id','type','title','status','unit_kind','position'),row[:7])) for row in rows[:limit]]
    return {'records':records,'cursor':cursor+len(records) if len(rows)>limit else None,'available':True,'generation':index.generation,'parent_id':parent}


def order_ids(index,parent):
    rows=[];cursor=0
    while True:
        page=outline(index,parent,cursor)
        if not page['available']:raise ValueError('Choose a course, book, path or module outline')
        rows.extend(row['id'] for row in page['records'])
        if len(rows)>1000:raise ValueError('Outline exceeds 1,000 direct members')
        if page['cursor'] is None:return rows
        cursor=page['cursor']


def move(root,parent,child,direction,operation_id=None):
    if direction not in ('up','down'):raise ValueError('Move up or down within this outline')
    index=Index(root)
    try:
        health=index.reconcile()
        if health['errors']:raise ValueError('Resolve index errors before arranging an outline')
        if operation_id:
            for path,raw in index.db.execute("SELECT path,props FROM activities WHERE json_extract(props,'$.operation_id')=?",(operation_id,)):
                old=json.loads(raw)
                if old.get('event')!='outline-order' or old.get('target',{}).get('record_id')!=parent or old.get('move_child')!=child or old.get('move_direction')!=direction:raise ValueError('Operation ID reused for another outline change')
                return dict(old,path=path)
        record=index.record(parent,include_body=False,include_attempt=False)
        identities=order_ids(index,parent)
        if child not in identities:raise ValueError('Selected item does not belong to this outline')
        current=identities.index(child);destination=current+(-1 if direction=='up' else 1)
        if destination<0 or destination>=len(identities):return {'message':'The item is already at the edge of this outline.'}
        identities[current],identities[destination]=identities[destination],identities[current]
        return record_activity(root,record['path'],'outline-order','Moved one outline item '+direction,
            operation_id=operation_id,expected_id=parent,expected_head=progress_state(record['props'],index.timeline(parent))[1],move_child=child,move_direction=direction,state={'unit_order':identities})
    finally:index.close()


def learning_context(index,identity):
    """Bounded lesson navigation; assessment is reported evidence, never competence."""
    record=index.record(identity,include_body=False,include_attempt=False)
    props=record['props']
    if props.get('type') not in ('unit','stage','task','problem','concept','prerequisite','question','capability'):
        return None
    owner=index.manifest['vault_id']
    def summary(identity):
        item=index.record(identity,include_body=False,include_attempt=False)
        fields=item['props'];state=item['state']
        latest_row=index.db.execute("SELECT props FROM activities WHERE target=? AND json_extract(props,'$.event') IN ('attempt','review') ORDER BY timestamp DESC,path DESC LIMIT 1",(identity,)).fetchone()
        latest=json.loads(latest_row[0]) if latest_row else None
        return {'id':identity,'path':item['path'],'title':item['display_title'],
                'type':fields.get('type'),'unit_kind':fields.get('unit_kind'),
                'status':state.get('status'),'position':state.get('position'),
                'assessment':{'outcome':latest.get('outcome','unknown'),
                              'assistance':latest.get('assistance',['unknown']),
                              'timestamp':latest.get('timestamp')} if latest else None,
                'vault':str(index.root),'vault_id':owner}
    relations=index.db.execute("SELECT props FROM relationships r WHERE (source=? OR target=?) AND "+local_relationship('r')+" ORDER BY path LIMIT 51",(identity,identity,owner,owner)).fetchall()
    parents=[];prerequisites=[];assignments=[];unavailable=[]
    for raw, in relations[:50]:
        edge=json.loads(raw)
        try:
            if edge['target']==identity and edge['relation'] in ('contains','orders','assigns'):
                item=summary(edge['source'])
                if item['id'] not in {r['id'] for r in parents}:parents.append(item)
            if edge['source']==identity and edge['relation']=='assigns':assignments.append(summary(edge['target']))
            if edge['source']==identity and edge['relation']=='prerequisite':
                item=summary(edge.get('exit_task') or edge['target'])
                item.update(role=edge.get('role'),reason=edge.get('reason'),relationship_id=edge['id'],
                            relationship_path=index.record(edge['id'],include_body=False,include_attempt=False)['path'],
                            readiness=index.record(edge['id'],include_body=False,include_attempt=False)['state'].get('status'))
                prerequisites.append(item)
        except ValueError as error:unavailable.append(str(error))
    next_lesson=None
    for parent in parents:
        if not is_outline(index.record(parent['id'],include_body=False,include_attempt=False)['props']):continue
        ordering=index.record(parent['id'],include_body=False,include_attempt=False)['state'].get('unit_order') or []
        next_row=index.db.execute("""WITH members AS (
            SELECT child.id,child.path,child.kind,state.status,json_extract(child.props,'$.unit_kind') AS unit_kind,
              MIN(COALESCE(sequence.key,100000+COALESCE(json_extract(edge.props,'$.order'),10000))) AS rank
            FROM relationships edge JOIN records child ON child.id=edge.target
            LEFT JOIN states state ON state.id=child.id
            LEFT JOIN json_each(?) sequence ON sequence.value=child.id
            WHERE edge.source=? AND edge.relation IN ('contains','orders','assigns','pursues')
            AND """+local_relationship('edge')+""" GROUP BY child.id)
            SELECT following.id FROM members following JOIN members current ON current.id=?
            WHERE (following.rank>current.rank OR (following.rank=current.rank AND following.path>current.path))
            AND following.kind IN ('unit','stage') AND COALESCE(following.unit_kind,'')!='module'
            AND COALESCE(following.status,'') NOT IN ('read','extracted','complete','passed','skipped','parked','retired','abandoned')
            ORDER BY following.rank,following.path LIMIT 1""",(json.dumps(ordering),parent['id'],owner,owner,identity)).fetchone()
        if next_row:next_lesson=summary(next_row[0]);break
    return {'parents':parents,'prerequisites':prerequisites,'assignments':assignments,
            'next_lesson':next_lesson,'truncated':len(relations)>50,'unavailable':unavailable}
