"""Context projections keep consumption, assessment and learner decisions distinct."""
import json
from pathlib import Path


def overview(index, identity):
    root=index.record(identity)
    kind=root['props'].get('type')
    if kind=='paper' or kind=='resource' and root['props'].get('source_kind')=='paper':
        annotations=[]
        projection=root['props'].get('zotero_projection')
        if projection:
            from .persistence import contained,parse
            try:
                _,body=parse(contained(index.root,projection).read_text())
                payload=json.loads(body.split('```json\n',1)[1].split('\n```',1)[0])
                for child in payload.get('children',[]):
                    data=child.get('data',{})
                    if data.get('itemType')!='annotation':continue
                    annotations.append({'native_id':child.get('key'),'source_version':child.get('version'),
                                        'text':data.get('annotationText',''),'comment':data.get('annotationComment',''),
                                        'page_label':data.get('annotationPageLabel',''),'position':data.get('annotationPosition'),
                                        'authority':'Zotero; imported snapshot'})
            except (ValueError,OSError,IndexError):return {'kind':'paper','annotations':[],'projection_unavailable':True}
        return {'kind':'paper','annotations':annotations[:50],'annotations_truncated':len(annotations)>50,
                'projection':projection,'bibliography':root['props'].get('bibliography_projection'),
                'summary':'Source annotations and learner analysis remain separate'}
    if kind in ('experiment','project','lab'):
        comparisons=[event for event in index.timeline(identity) if event.get('event')=='comparison']
        return {'kind':'project' if kind=='project' else 'experiment','hypothesis':root['props'].get('hypothesis'),'latest_comparison':comparisons[-1] if comparisons else None,'summary':'Prediction, reported observation and conclusion remain separate'}
    if kind=='capability':
        decisions=[event for event in index.timeline(identity) if event.get('event')=='capability-decision']
        evidence=[]
        for decision in decisions[-50:]:
            try:
                supporting=index.record(decision['evidence_id'])
                props=supporting['props']
                evidence.append({'criterion':decision.get('criterion'),'decision':decision.get('decision'),
                    'actor':decision.get('actor','unknown'),'decision_id':decision['id'],'evidence_id':decision['evidence_id'],
                    'outcome':props.get('outcome','unknown'),'assistance':props.get('assistance',['unknown']),
                    'scope':props.get('scope'), 'assessment':props.get('assessment','learner-reported'),
                    'checked':props.get('timestamp'),'path':supporting['path']})
            except ValueError:
                evidence.append({'decision_id':decision['id'],'availability':'evidence unavailable'})
        return {'kind':'capability','criteria':root['props'].get('criteria',[]),'evidence':evidence,'summary':'Scoped learner decisions; no mastery percentage'}
    if kind not in ('path','resource','course'):return None
    rows=index.db.execute('''WITH RECURSIVE members(id) AS (
        SELECT ? UNION SELECT r.target FROM relationships r JOIN members m ON r.source=m.id
        JOIN records target ON target.id=r.target
        WHERE r.relation IN ('contains','orders','assigns','pursues','investigates')
        OR (r.relation='references' AND target.kind='project'))
        SELECT records.id,records.kind,records.props FROM records JOIN members ON members.id=records.id
        WHERE records.id!=? AND kind IN ('unit','stage','task','problem','project') LIMIT 1001''',(identity,identity)).fetchall()
    counts={bucket:{'total':0,'consumed':0,'reported_success':0,'independent_reported_success':0} for bucket in ('lectures','readings','assignments','projects','other_units')}
    for record_id,record_kind,raw in rows[:1000]:
        props=json.loads(raw)
        bucket='assignments' if record_kind in ('task','problem') else 'projects' if record_kind=='project' else {'lecture':'lectures','reading':'readings','assignment':'assignments'}.get(props.get('unit_kind'),'other_units')
        counts[bucket]['total']+=1
        record=index.record(record_id)
        if record['state'].get('status') in ('read','extracted','complete'):counts[bucket]['consumed']+=1
        attempts=[event for event in index.timeline(record_id) if event.get('event') in ('attempt','review')]
        if any(a.get('outcome')=='succeeded' for a in attempts):counts[bucket]['reported_success']+=1
        if any(a.get('outcome')=='succeeded' and a.get('assistance')==['none'] for a in attempts):counts[bucket]['independent_reported_success']+=1
    return {'kind':'course' if kind in ('resource','course') else 'path','counts':counts,'truncated':len(rows)>1000,
            'summary':'Consumption and reported assessment are separate; no competence is awarded'}


def today(index, context_id=None, path_id=None, quiet=False):
    from .policies import next_actions
    resume=None
    identities=[context_id] if context_id else []
    identities.extend(row[0] for row in index.db.execute('SELECT target FROM activities ORDER BY timestamp DESC LIMIT 20'))
    for identity in identities:
        try:
            record=index.record(identity)
        except (ValueError,TypeError):continue
        if record['props'].get('type') in ('activity','relationship') or record['state'].get('status') in ('retired','abandoned'):continue
        events=index.timeline(identity)
        resume={'id':identity,'path':record['path'],'title':record['props'].get('title') or record['props'].get('imported_title') or Path(record['path']).stem,
                'type':record['props'].get('type','note'),'position':record['state'].get('position') or '',
                'last_worked':events[-1].get('timestamp') if events else None,'unfinished_attempt':bool(record['attempt']),
                'source_kind':record['props'].get('source_kind'),'local_file':record['props'].get('local_file'),'zotero_uri':record['props'].get('zotero_uri')}
        break
    return {'continue':resume,'records':next_actions(index,quiet,path_id)[:5],'generation':index.generation,
            'message':'Resume when you are ready. Suggestions are optional, and age is not a competence estimate.'}
