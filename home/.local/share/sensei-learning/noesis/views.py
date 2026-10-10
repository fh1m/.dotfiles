"""Context projections keep consumption, assessment and learner decisions distinct."""
import json
from pathlib import Path
from .presentation import display_title
from .index import local_relationship


def overview(index, identity):
    root=index.record(identity)
    kind=root['props'].get('type')
    if kind=='paper' or kind=='resource' and root['props'].get('source_kind')=='paper':
        from .sources import annotations, bibliography
        result={'kind':'paper','annotations':[], 'bibliography':root['props'].get('bibliography_projection'),
                'summary':'Source annotations and learner analysis remain separate'}
        try:result.update(annotations(index,identity))
        except (ValueError,OSError,TypeError) as error:
            result.update(projection_unavailable=True,projection_error=str(error))
        try:result['bibliographic_summary']=bibliography(index,root)
        except (ValueError,OSError,TypeError) as error:result['bibliography_error']=str(error)
        result['annotations_truncated']=bool(result.get('cursor'))
        return result
    if kind in ('task','problem'):
        import re
        statement=re.search(r'(?ms)^## Problem statement\r?\n(.*?)(?=^## |\Z)',root.get('body',''))
        return {'kind':'practice','statement':statement.group(1).strip() if statement else None,'source_role':'learner-declared problem statement; reference and history remain separate'}
    if kind in ('experiment','project','lab'):
        from .experiments import context
        return context(index,root)
    if kind=='capability':
        from .frontier import claim_page
        return dict(claim_page(index, identity), kind='capability', criteria=root['props'].get('criteria',[]),
                    summary='Complete-history reduction; scoped learner decisions, no mastery percentage')
    if kind not in ('path','course') and not (kind=='unit' and root['props'].get('unit_kind')=='module') and not (kind=='resource' and (root['props'].get('source_kind') or root['props'].get('medium')) in ('course','book','playlist')):return None
    rows=index.db.execute('''WITH RECURSIVE members(id) AS (
        SELECT ? UNION SELECT r.target FROM relationships r JOIN members m ON r.source=m.id
        JOIN records target ON target.id=r.target
        WHERE (r.relation IN ('contains','orders','assigns','pursues','investigates')
        OR (r.relation='references' AND target.kind='project')) AND '''+local_relationship('r')+''')
        SELECT records.id,records.kind,records.props FROM records JOIN members ON members.id=records.id
        WHERE records.id!=? AND kind IN ('unit','stage','task','problem','project') LIMIT 1001''',(identity,index.manifest['vault_id'],index.manifest['vault_id'],identity)).fetchall()
    counts={bucket:{'total':0,'consumed':0,'reported_success':0,'independent_reported_success':0} for bucket in ('lectures','readings','assignments','projects','other_units')}
    for record_id,record_kind,raw in rows[:1000]:
        props=json.loads(raw)
        if record_kind=='unit' and props.get('unit_kind')=='module':continue
        bucket='assignments' if record_kind in ('task','problem') else 'projects' if record_kind=='project' else {'lecture':'lectures','video':'lectures','reading':'readings','assignment':'assignments'}.get(props.get('unit_kind'),'other_units')
        counts[bucket]['total']+=1
        record=index.record(record_id)
        if record['state'].get('status') in ('read','extracted','complete'):counts[bucket]['consumed']+=1
        attempts=[event for event in index.timeline(record_id) if event.get('event') in ('attempt','review')]
        if any(a.get('outcome')=='succeeded' for a in attempts):counts[bucket]['reported_success']+=1
        if any(a.get('outcome')=='succeeded' and a.get('assistance')==['none'] for a in attempts):counts[bucket]['independent_reported_success']+=1
    return {'kind':'course' if kind in ('resource','course','unit') else 'path','counts':counts,'truncated':len(rows)>1000,
            'summary':'Consumption and reported assessment are separate; no competence is awarded'}


def today(index, context_id=None, path_id=None, quiet=False):
    from .policies import next_actions
    resume=None
    identities=[context_id] if context_id else []
    identities.extend(row[0] for row in index.db.execute("SELECT target FROM activities WHERE json_extract(props,'$.event')!='outline-order' ORDER BY timestamp DESC LIMIT 20"))
    for identity in identities:
        try:
            record=index.record(identity)
        except (ValueError,TypeError):continue
        if record['state'].get('conflict') or record['props'].get('type') in ('activity','relationship') or record['state'].get('status') in ('retired','abandoned','parked','read','extracted','complete','passed','skipped'):continue
        events=[event for event in index.timeline(identity) if event.get('event')!='outline-order']
        resume={'id':identity,'path':record['path'],'title':display_title(record['props'],record['path']),
                'type':record['props'].get('type','note'),'position':(record['state'].get('locator') or {}).get('value') or record['state'].get('position') or '',
                'last_worked':events[-1].get('timestamp') if events else None,'unfinished_attempt':bool(record['attempt']),
                'source_kind':record['props'].get('source_kind'),'local_file':record['props'].get('local_file'),'zotero_uri':record['props'].get('zotero_uri')}
        break
    record_count=index.db.execute("SELECT count(*) FROM records WHERE kind NOT IN ('activity','relationship','home','frontier','daily','protocol')").fetchone()[0]
    actions=next_actions(index,quiet,path_id)[:5]
    paths=[row for row in index.query(kind=['path','course','resource'],resource_kinds=['course','book','playlist'],limit=50)['records'] if row.get('status') not in ('parked','abandoned','retired','complete')][:6]
    return {'continue':resume,'records':actions,'paths':paths,'record_count':record_count,
            'availability':'ready','empty_reason':'no-records' if not record_count else 'no-active-work' if not resume and not actions else 'nothing-due' if not actions else None,'generation':index.generation,
            'message':'Resume when you are ready. Suggestions are optional, and age is not a competence estimate.'}
