from datetime import datetime, timezone
import json
import uuid
from .index import Index
from .persistence import checksum, contained, lock, manifest_path, parse, publish, render


def validate_progress(current=None, total=None):
    if current is not None and (type(current) is not int or current < 0):
        raise ValueError('Current must be a nonnegative integer')
    if total is not None and (type(total) is not int or total <= 0):
        raise ValueError('Total must be a positive integer or unknown')
    if current is not None and total is not None and current > total:
        raise ValueError('Progress exceeds total')


def progress_state(props, timeline):
    baseline = {k: props.get(k) for k in ('progress_current', 'progress_total', 'position', 'status')}
    states, heads = {}, set()
    for event in timeline:
        if event.get('event') not in ('study', 'resolution'):
            continue
        previous = event.get('previous')
        if previous is not None and previous not in states:
            raise ValueError('Missing study predecessor')
        state = dict(states[previous] if previous else baseline)
        if event['event'] == 'resolution':
            if set(event.get('resolves', [])) != heads or previous not in heads:
                raise ValueError('Resolution must name all conflicting heads and selected predecessor')
            heads.clear()
        state.update(event['state'])
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
    if event not in ('study', 'resolution', 'attempt-start', 'attempt', 'review', 'assistance', 'comparison', 'correction', 'capability-decision', 'session-state', 'disposition'):
        raise ValueError('Unknown activity event')
    with lock(root):
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
            if event == 'study':
                state, previous = progress_state(props, index.timeline(identity))
                update = fields.pop('state')
                if not isinstance(update, dict) or set(update) - {'progress_current', 'progress_total', 'position', 'status', 'reading_pass', 'locator'}:
                    raise ValueError('Invalid study state fields')
                state.update(update)
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
                operation_id=operation_id or str(uuid.uuid4()), provenance='learner-reported', request_hash=request_hash)
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
