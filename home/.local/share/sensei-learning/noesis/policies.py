"""Transparent recommendations; no inferred competence or forgetting."""
from datetime import datetime, timezone
import json


def next_actions(index, quiet=False):
    if quiet:return []
    candidates = []
    now = datetime.now(timezone.utc).isoformat()
    for path, identity, kind, raw in index.db.execute('''SELECT path,id,kind,props FROM records
        WHERE kind IN ('session','practice-session','relationship','unit','experiment')
        OR (kind='activity' AND (json_extract(props,'$.retry_requested')=1 OR json_extract(props,'$.due') IS NOT NULL))
        OR json_extract(props,'$.pin')=1 ORDER BY path'''):
        props = json.loads(raw)
        if identity:
            derived = index.record(identity)['state']
            if derived.get('conflict'):continue
            if derived.get('status') is not None:props['status'] = derived['status']
        if props.get('status') in ('parked', 'abandoned', 'retired', 'skipped', 'passed', 'complete'):continue
        reason, priority = None, 99
        if props.get('pin'):
            priority, reason = 1, 'Manually pinned'
        elif kind in ('session', 'practice-session') and props.get('status') == 'active':
            priority, reason = 2, 'Unfinished active session'
        elif kind == 'relationship' and props.get('relation') == 'prerequisite' and props.get('role') == 'gate':
            priority, reason = 3, 'Gate has no learner-recorded completion'
        elif kind == 'activity' and props.get('retry_requested'):
            priority, reason = 4, 'Independent retry explicitly requested'
        elif kind == 'activity' and props.get('due') and props['due'] <= now:
            priority, reason = 5, 'Learner-selected check is due; age is not a competence estimate'
        elif kind in ('unit', 'experiment') and props.get('status', 'active') not in ('complete', 'succeeded'):
            priority, reason = 6, 'Incomplete unit or explicit experiment'
        if reason:
            evidence = identity
            target = props.get('target', {}).get('record_id') if kind == 'activity' else None
            if kind == 'relationship':target = props.get('exit_task') or props.get('target')
            title = props.get('title')
            if target:
                try:
                    record = index.record(target)
                except ValueError:continue
                if record['state'].get('status') in ('parked', 'abandoned', 'retired', 'skipped', 'passed', 'complete'):continue
                identity, path, kind = target, record['path'], record['props'].get('type', 'note')
                title = record['props'].get('title') or path
            candidates.append({'id': identity, 'path': path, 'title': title, 'type': kind, 'reason': reason, 'priority': priority, 'evidence_id': evidence})
    return sorted(candidates, key=lambda row: (row['priority'], row['path']))[:50]


def agent_context(index, identity, role='tutor'):
    if role not in ('tutor', 'examiner', 'researcher', 'reviewer', 'archivist'):raise ValueError('Unknown agent role')
    record = index.record(identity)
    return {'role': role, 'target': {'id': identity, 'path': record['path'], 'metadata': record['props']},
            'rules': ['Agent output is unverified material.', 'Declare assistance; preserve predictions and failed attempts.',
                      'Only the learner can accept evidence against capability criteria.',
                      'Examiner: request reconstruction before revealing reference material.'],
            'activities': index.timeline(identity)[-10:]}
