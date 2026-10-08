from datetime import datetime, timezone, timedelta
import json
import uuid
from .locators import normalize as normalize_locator
from .index import Index
from .persistence import checksum, contained, lock, manifest_path, parse, publish, render


def validate_progress(current=None, total=None):
    if current is not None and (type(current) is not int or current < 0):
        raise ValueError('Current must be a nonnegative integer')
    if total is not None and (type(total) is not int or total <= 0):
        raise ValueError('Total must be a positive integer or unknown')
    if current is not None and total is not None and current > total:
        raise ValueError('Progress exceeds total')


def operation_status(root, operation_id):
    """Wait for writers, then report durable publication rather than process exit."""
    uuid.UUID(operation_id)
    with lock(root):
        index = Index(root)
        try:
            health = index.reconcile()
            rows = [dict(json.loads(raw), path=path) for path, raw in index.db.execute(
                "SELECT path,props FROM records WHERE json_extract(props,'$.operation_id')=?",
                (operation_id,))]
            if health['errors'] or len(rows) > 1:
                return {'operation_id': operation_id, 'status': 'uncertain', 'errors': health['errors'], 'records': rows}
            witness=contained(root,'.Noesis/Operations/'+operation_id+'.json')
            witness_state=json.loads(witness.read_text()).get('status') if witness.exists() else None
            committed=witness_state=='committed'
            return {'operation_id': operation_id, 'status': 'committed' if rows or committed else 'uncertain' if witness_state=='preparing' else 'not-committed', 'records': rows, 'record_unavailable':bool(committed and not rows)}
        finally:index.close()


def unfinished_attempts(timeline):
    finalized = {event.get('attempt_id') for event in timeline if event.get('event') == 'attempt'}
    return [event for event in timeline if event.get('event') == 'attempt-start' and event['id'] not in finalized]


def causal_order(events, predecessor, resolutions):
    import heapq
    nodes={event['id']:event for event in events}
    if len(nodes)!=len(events):raise ValueError('Duplicate activity identity')
    node_ids=set(nodes)
    incoming={};children={};ready=[]
    for identity,event in nodes.items():
        dependencies=set(event.get(resolutions,[]) or [])
        if event.get(predecessor):dependencies.add(event[predecessor])
        if dependencies-node_ids:raise ValueError('Missing activity predecessor')
        incoming[identity]=len(dependencies)
        for previous in dependencies:children.setdefault(previous,[]).append(identity)
        if not dependencies:heapq.heappush(ready,(str(event.get('timestamp','')),identity))
    ordered=[]
    while ready:
        _,identity=heapq.heappop(ready);ordered.append(nodes[identity])
        for following in children.get(identity,()):
            incoming[following]-=1
            if incoming[following]==0:heapq.heappush(ready,(str(nodes[following].get('timestamp','')),following))
    if len(ordered)!=len(nodes):raise ValueError('Cyclic activity history')
    return ordered


def review_heads(timeline):
    plans=causal_order([event for event in timeline if event.get('event')=='review-plan'],'previous_plan','resolves_plans')
    referenced=set()
    for plan in plans:
        referenced.update(plan.get('resolves_plans',[]))
        if plan.get('previous_plan'):referenced.add(plan['previous_plan'])
    return [plan for plan in plans if plan['id'] not in referenced]


def progress_state(props, timeline):
    baseline = {k: props.get(k) for k in ('progress_current', 'progress_total', 'position', 'status')}
    states, heads = {}, set()
    events=[event for event in timeline if event.get('event') in ('study', 'session-state', 'disposition', 'resolution')]
    for event in causal_order(events,'previous','resolves'):
        previous = event.get('previous')
        if previous is not None and previous not in states:
            raise ValueError('Missing study predecessor')
        state = dict(states[previous] if previous else baseline)
        if event['event'] == 'resolution':
            if set(event.get('resolves', [])) != heads or previous not in heads:
                raise ValueError('Resolution must name all conflicting heads and selected predecessor')
            heads.clear()
        update = event['state'] if isinstance(event['state'], dict) else {'status': event['state']}
        state.update(update)
        states[event['id']] = state
        heads.discard(previous)
        heads.add(event['id'])
    if len(heads) > 1:
        raise ValueError('Divergent study history; explicit resolution required: ' + ', '.join(sorted(heads)))
    head = next(iter(heads), None)
    return states[head] if head else baseline, head


def record_activity(root, relative, event, evidence='', operation_id=None, **fields):
    expected_id = fields.pop('expected_id', None)
    request_hash = checksum(json.dumps({'target': expected_id or relative, 'event': event, 'evidence': evidence, 'fields': fields}, sort_keys=True, default=str))
    if any(key in fields for key in ('id', 'type', 'noesis_schema', 'target', 'timestamp', 'provenance', 'path')):
        raise ValueError('Reserved activity metadata cannot be supplied')
    if event not in ('study', 'resolution', 'attempt-start', 'attempt', 'review', 'review-plan', 'assistance', 'comparison', 'correction', 'capability-decision', 'session-state', 'disposition', 'artifact-check'):
        raise ValueError('Unknown activity event')
    with lock(root):
        from .scopes import assert_unique
        assert_unique(root)
        meta = json.loads(manifest_path(root).read_text())
        if meta.get('noesis_schema') != 2 or not meta.get('vault_id'):
            raise ValueError('Run migrate --apply after reviewing its dry-run')
        uuid.UUID(str(meta['vault_id']))
        path = contained(root, relative)
        props, _ = parse(path.read_text())
        identity = props.get('id')
        if expected_id and identity != expected_id:
            raise ValueError('Target identity changed; refusing stale mutation')
        if not identity:
            raise ValueError('Target needs stable identity; run migration')
        uuid.UUID(str(identity))
        index = Index(root)
        try:
            status = index.reconcile()
            if status['errors']:
                raise ValueError('Index validation errors: ' + str(status['errors']))
            from .persistence import supported_schema
            supported_schema(props,legacy=True)
            index.record(identity)
            if operation_id:
                uuid.UUID(operation_id)
                for _, raw in index.db.execute("SELECT path,props FROM records WHERE kind='activity'"):
                    old = json.loads(raw)
                    if old.get('operation_id') == operation_id:
                        if old['target']['record_id'] != identity or old['event'] != event:
                            raise ValueError('Operation ID reused for a different request')
                        if old.get('request_hash') != request_hash:
                            raise ValueError('Operation ID reused with changed content')
                        return old
            if event == 'attempt-start' and unfinished_attempts(index.timeline(identity)):
                raise ValueError('Resume or finalize the durable unfinished attempt before starting another')
            if event=='review-plan':
                if not evidence.strip():raise ValueError('Check planning needs a purpose or learner decision')
                if fields.get('action') not in ('schedule','snooze','retire'):raise ValueError('Choose schedule, snooze or retire')
                stage=fields.get('stage','retry')
                if stage not in ('retry','later','maintenance'):raise ValueError('Choose retry, later or maintenance')
                days=fields.get('days',meta.get('review_intervals',{}).get(stage,{'retry':1,'later':7,'maintenance':30}[stage]))
                if type(days) is not int or not 1<=days<=3650:raise ValueError('Check interval must be 1–3650 days')
                heads=review_heads(index.timeline(identity))
                if len(heads)>1:
                    if set(fields.get('resolves_plans',[]))!={head['id'] for head in heads}:raise ValueError('Divergent check plans need an explicit resolution naming all heads')
                elif fields.get('resolves_plans'):raise ValueError('Only conflicting check plans can be resolved')
                fields['previous_plan']=heads[0]['id'] if len(heads)==1 else None
                fields['interval_days']=days
                fields['due']=(datetime.now(timezone.utc)+timedelta(days=days)).isoformat() if fields['action']!='retire' else None
            if fields.get('attempt_id'):
                started = index.record(fields['attempt_id'])['props']
                if started.get('event') != 'attempt-start' or started.get('target', {}).get('record_id') != identity:
                    raise ValueError('Attempt reference must name a start for this target')
                if event == 'attempt':
                    if any(e.get('event') == 'attempt' and e.get('attempt_id') == fields['attempt_id'] for e in index.timeline(identity)):
                        raise ValueError('Attempt already finalized; start an independent retry')
                    exposures = set(fields.get('assistance', ['unknown']))
                    for entry in index.timeline(identity):
                        if entry.get('attempt_id') == fields['attempt_id'] and entry.get('event') == 'assistance':
                            exposures.update(entry.get('assistance', ['unknown']))
                    if len(exposures) > 1:exposures.discard('none')
                    fields['assistance'] = sorted(exposures)
            for key in ('supersedes', 'evidence_id', 'artifact_id'):
                if fields.get(key):index.record(fields[key])
            if event == 'capability-decision':
                if fields.get('actor') != 'learner':
                    raise ValueError('Capability acceptance requires an explicit learner decision')
                if props.get('type') != 'capability' or not fields.get('criterion') or not fields.get('evidence_id') or not evidence.strip():
                    raise ValueError('Learner capability decision needs capability, criterion, evidence ID and explanation')
                if fields.get('decision') not in ('accept', 'reject', 'withdraw'):
                    raise ValueError('Explicit accept, reject or withdraw decision required')
            if fields.get('session'):
                session = index.record(fields['session'])
                if session['props'].get('type') not in ('session', 'practice-session'):
                    raise ValueError('Session reference must target a session')
            if event in ('study', 'session-state', 'disposition'):
                state, previous = progress_state(props, index.timeline(identity))
                update = fields.pop('state')
                if event in ('session-state', 'disposition') and isinstance(update, str):update = {'status': update}
                if not isinstance(update, dict) or set(update) - {'progress_current', 'progress_total', 'position', 'status', 'reading_pass', 'locator'}:
                    raise ValueError('Invalid study state fields')
                if update.get('locator') is not None:
                    update['locator'],update['position']=normalize_locator(update['locator'])
                if update.get('reading_pass') is not None and update['reading_pass'] not in ('survey','detail','reconstruct','verify'):
                    raise ValueError('Unsupported reading pass')
                if 'position' in update and 'locator' not in update:update['locator']=None
                state.update(update)
                source={key:props[key] for key in ('bibliography_projection','zotero_projection','zotero_version','zotero_attachment_key','local_file','source','source_kind','doi','arxiv','revision','edition') if props.get(key)}
                if source:fields['source_snapshot']=source
                validate_progress(state.get('progress_current'), state.get('progress_total'))
                fields.update(state=state, previous=previous)
            elif event in ('attempt', 'review'):
                if not evidence.strip():
                    raise ValueError('Assessment needs actual evidence')
                if fields.get('outcome', 'unknown') not in ('unknown', 'incomplete', 'failed', 'partial', 'succeeded'):
                    raise ValueError('Unsupported assessment outcome')
            now = datetime.now(timezone.utc)
            record = dict(fields, id=str(uuid.uuid4()), noesis_schema=2, type='activity', event=event,
                target={'vault_id': meta['vault_id'], 'record_id': identity}, timestamp=now.isoformat(),
                operation_id=operation_id or str(uuid.uuid4()), provenance='noesis-file-inspection' if event=='artifact-check' else 'learner-reported', request_hash=request_hash)
            if event == 'resolution':
                if not evidence.strip():raise ValueError('Resolution needs a learner explanation')
                state, _ = progress_state(props, index.timeline(identity) + [record])
                validate_progress(state.get('progress_current'), state.get('progress_total'))
            folder = contained(root, meta.get('activity', 'Activity')) / now.strftime('%Y/%m')
            dest = folder / (record['id'] + '.md')
            publish(dest, render(record, '\n# ' + event.title() + '\n\n' + evidence + '\n'))
            return dict(record, path=str(dest.relative_to(root)))
        finally:
            index.close()
