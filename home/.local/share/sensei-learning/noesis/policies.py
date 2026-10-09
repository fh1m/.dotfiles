"""Transparent recommendations; no inferred competence or forgetting."""
from datetime import datetime, timezone
import json
from .presentation import display_title
from .index import local_relationship


def path_scope(index, path_id):
    """Follow explicit educational containment, never arbitrary concept associations."""
    root = index.record(path_id)
    if root['props'].get('type') != 'path':raise ValueError('Recommendation scope must name a path')
    return {row[0] for row in index.db.execute("""WITH RECURSIVE scope(id) AS (
        SELECT ? UNION SELECT target FROM relationships r WHERE context=? AND """+local_relationship('r')+"""
        UNION SELECT edges.target FROM relationships edges JOIN scope ON edges.source=scope.id
        WHERE edges.relation IN ('contains','orders','assigns','pursues','investigates') AND """+local_relationship('edges')+""") SELECT id FROM scope""",(path_id,path_id,*([index.manifest['vault_id']]*4)))}



def parked_contexts(index):
    """Suppress owned descendants; reusable records with an active parent remain available."""
    blocked={row[0] for row in index.db.execute("SELECT id FROM states WHERE status IN ('parked','abandoned','retired','skipped') OR json_extract(state,'$.manual_priority')='quiet'")}
    if not blocked:return blocked
    parents={};children={}
    for source,target in index.db.execute("SELECT source,target FROM relationships r WHERE relation IN ('contains','orders','assigns','investigates') AND "+local_relationship('r'),(index.manifest['vault_id'],index.manifest['vault_id'])):
        parents.setdefault(target,set()).add(source);children.setdefault(source,set()).add(target)
    remaining={target:len(values) for target,values in parents.items()}
    queue=list(blocked)
    for source in queue:
        for target in children.get(source,()):
            if target in blocked:continue
            remaining[target]-=1
            if remaining[target]==0:blocked.add(target);queue.append(target)
    return blocked


def next_actions(index, quiet=False, path_id=None):
    if quiet:return []
    scope = path_scope(index, path_id) if path_id else None
    inactive=('parked','abandoned','retired','skipped','passed','complete')
    if path_id and index.record(path_id)['state'].get('status') in inactive:return []
    blocked=parked_contexts(index)
    cache={}
    def record(identity):
        if identity not in cache:cache[identity]=index.record(identity,include_body=False,include_attempt=False)
        return cache[identity]
    grouped={}
    ordered=set()
    for source,target,raw,status,parent_status in index.db.execute("""SELECT r.source,r.target,r.props,s.status,parent_state.status
        FROM relationships r JOIN records child ON child.id=r.target AND child.kind='unit'
        JOIN records parent ON parent.id=r.source LEFT JOIN states s ON s.id=r.target
        LEFT JOIN states parent_state ON parent_state.id=r.source WHERE r.relation IN ('orders','contains') AND """+local_relationship('r'),(index.manifest['vault_id'],index.manifest['vault_id'])):
        edge=json.loads(raw)
        if type(edge.get('order')) is not int:continue
        ordered.add(target)
        if parent_status in inactive:continue
        sequence=record(source)['state'].get('unit_order') or []
        rank=sequence.index(target) if target in sequence else len(sequence)+edge['order']
        grouped.setdefault(source,[]).append((rank,target,status))
    next_units=set()
    for steps in grouped.values():
        for _,target,status in sorted(steps):
            if status not in inactive+('read','extracted','succeeded'):
                next_units.add(target);break
    from .activities import review_heads
    plans={};assessed_plans=set()
    for target, in index.db.execute("SELECT DISTINCT target FROM activities WHERE json_extract(props,'$.event')='review-plan'"):
        timeline=index.timeline(target)
        assessed_plans.update(event.get('review_plan_id') for event in timeline if event.get('event') in ('attempt','review') and event.get('outcome') in ('failed','partial','succeeded'))
        try:plans[target]=review_heads(timeline)
        except ValueError:plans[target]=[]
    plan_ids={head[0]['id'] for head in plans.values() if len(head)==1 and head[0]['id'] not in assessed_plans}
    candidates = []
    now = datetime.now(timezone.utc).isoformat()
    for path, identity, kind, raw, derived_raw, pinned in index.db.execute("""SELECT r.path,r.id,r.kind,r.props,s.state,COALESCE(json_extract(s.state,'$.pin'),json_extract(r.props,'$.pin')) FROM records r
        LEFT JOIN states s ON s.id=r.id WHERE (r.kind IN ('session','practice-session','relationship','unit','experiment')
        AND COALESCE(s.status,'active') NOT IN ('parked','abandoned','retired','skipped','passed','complete','read','extracted','succeeded'))
        OR (r.kind='activity' AND (json_extract(r.props,'$.retry_requested')=1 OR json_extract(r.props,'$.due')<=? OR json_extract(r.props,'$.event')='review-plan'))
        OR COALESCE(json_extract(s.state,'$.pin'),json_extract(r.props,'$.pin'))=1
        OR COALESCE(json_extract(s.state,'$.manual_priority'),json_extract(r.props,'$.manual_priority'))='high'
        ORDER BY CASE WHEN COALESCE(json_extract(s.state,'$.pin'),json_extract(r.props,'$.pin'))=1 THEN 0
        WHEN COALESCE(json_extract(s.state,'$.manual_priority'),json_extract(r.props,'$.manual_priority'))='high' THEN 1 WHEN r.kind IN ('session','practice-session') THEN 2
        WHEN r.kind='relationship' THEN 3 WHEN json_extract(r.props,'$.retry_requested')=1 THEN 4 WHEN r.kind='activity' THEN 5 ELSE 6 END,r.path""",(now,)):
        if kind=='unit' and identity in ordered and identity not in next_units and not pinned:continue
        if identity in blocked and not pinned:continue
        props = json.loads(raw)
        target_id = props.get('target', {}).get('record_id') if kind == 'activity' else None
        if kind == 'relationship':target_id = props.get('exit_task') or props.get('target')
        if target_id in blocked and not pinned:continue
        if kind=='activity' and props.get('event')=='review-plan' and (identity not in plan_ids or props.get('action')=='retire'):continue
        if kind=='activity' and props.get('event')!='review-plan' and target_id in plans:continue
        if scope is not None and identity not in scope and target_id not in scope and props.get('context') != path_id:
            continue
        if identity:
            derived = json.loads(derived_raw) if derived_raw else record(identity)['state']
            if derived.get('conflict'):continue
            if derived.get('status') is not None:props['status'] = derived['status']
            for field in ('pin','manual_priority'):
                if derived.get(field) is not None:props[field]=derived[field]
        if props.get('status') in inactive+('read','extracted','succeeded'):continue
        if props.get('manual_priority')=='quiet':continue
        reason, priority = None, 99
        if props.get('pin'):
            priority, reason = 0, 'Manually pinned'
        elif props.get('manual_priority')=='high':
            priority, reason = 1, 'Learner-selected high priority'
        elif kind in ('session', 'practice-session') and props.get('status') == 'active':
            priority, reason = 2, 'Unfinished active session'
        elif kind == 'relationship' and props.get('relation') == 'prerequisite' and props.get('role') == 'gate':
            priority, reason = 3, 'Gate has no learner-recorded completion'
        elif kind == 'activity' and props.get('retry_requested'):
            priority, reason = 4, 'Independent retry explicitly requested'
        elif kind == 'activity' and props.get('due') and props['due'] <= now:
            priority, reason = 5, 'Learner-selected check is due; age is not a competence estimate'
        elif kind in ('unit', 'experiment') and props.get('status', 'active') not in ('complete', 'succeeded', 'read', 'extracted'):
            if kind=='unit' and identity in ordered and identity not in next_units:continue
            priority, reason = 6, 'Incomplete unit or explicit experiment'
        if reason:
            evidence = identity
            target = props.get('target', {}).get('record_id') if kind == 'activity' else None
            if kind == 'relationship':target = props.get('exit_task') or props.get('target')
            title = props.get('title')
            if target:
                try:
                    target_record = record(target)
                except ValueError:continue
                if target_record['state'].get('status') in inactive:continue
                identity, path, kind = target, target_record['path'], target_record['props'].get('type', 'note')
                title = display_title(target_record['props'],path)
            candidates.append({'id': identity, 'path': path, 'title': display_title({'title':title,'type':kind},path), 'type': kind, 'reason': reason, 'priority': priority, 'evidence_id': evidence})
            if len({row['id'] for row in candidates})>=50:break
    unique = {}
    for row in sorted(candidates, key=lambda row: (row['priority'], row['path'])):
        unique.setdefault(row['id'], row)
    return list(unique.values())[:50]


def agent_context(index, identity, role='tutor'):
    if role not in ('tutor', 'examiner', 'researcher', 'reviewer', 'archivist'):raise ValueError('Unknown agent role')
    record = index.record(identity)
    return {'role': role, 'target': {'id': identity, 'path': record['path'], 'metadata': record['props']},
            'rules': ['Agent output is unverified material.', 'Declare assistance; preserve predictions and failed attempts.',
                      'Only the learner can accept evidence against capability criteria.',
                      'Examiner: request reconstruction before revealing reference material.'],
            'activities': index.timeline(identity)[-10:]}
