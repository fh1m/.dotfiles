"""Transparent recommendations; no inferred competence or forgetting."""
from datetime import datetime, timezone
import json


def next_actions(index, quiet=False):
    if quiet:return []
    candidates = []
    now = datetime.now(timezone.utc).isoformat()
    for path, identity, kind, raw in index.db.execute('SELECT path,id,kind,props FROM records ORDER BY path'):
        props = json.loads(raw)
        if identity:
            for event in index.timeline(identity):
                if event.get('event') in ('disposition','session-state'):props['status'] = event.get('state', props.get('status'))
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
        if reason:candidates.append({'id': identity, 'path': path, 'type': kind, 'reason': reason, 'priority': priority})
    return sorted(candidates, key=lambda row: (row['priority'], row['path']))[:50]


def agent_context(index, identity, role='tutor'):
    if role not in ('tutor', 'examiner', 'researcher', 'reviewer', 'archivist'):raise ValueError('Unknown agent role')
    record = index.record(identity)
    return {'role': role, 'target': {'id': identity, 'path': record['path'], 'metadata': record['props']},
            'rules': ['Agent output is unverified material.', 'Declare assistance; preserve predictions and failed attempts.',
                      'Only the learner can accept evidence against capability criteria.',
                      'Examiner: request reconstruction before revealing reference material.'],
            'activities': index.timeline(identity)[-10:]}
