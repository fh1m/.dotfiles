"""Evidence-backed read projections. No scores, inferred competence or document writes."""
import base64
import json
import uuid
from .index import local_relationship

DIMENSIONS = ('encountered', 'use', 'explain', 'derive', 'implement', 'predict-debug', 'transfer', 'retained')
DEPTHS = ('quick', 'normal', 'deep', 'research-grade')
EVIDENCE_KINDS = ('explanation', 'derivation', 'unit-test', 'software-run', 'simulation',
                  'bench-test', 'sensor-measurement', 'in-water-test', 'external-verdict')


def evidence_record(index, reference):
    if not isinstance(reference, dict) or set(reference) != {'vault_id', 'record_id'}:
        raise ValueError('Evidence needs exact vault and record identities')
    owner = str(uuid.UUID(reference['vault_id']))
    identity = str(uuid.UUID(reference['record_id']))
    if owner == index.manifest['vault_id']:
        return index.record(identity, include_body=False, include_attempt=False)
    from .references import resolve
    from .persistence import contained, parse
    resolved = resolve(reference)
    props, _ = parse(contained(resolved['vault'], resolved['path']).read_text())
    return {'props': props, 'path': resolved['path'], 'display_title': resolved['title']}


def references(index, decision):
    return decision.get('evidence_refs') or ([{'vault_id': index.manifest['vault_id'],
                                             'record_id': decision['evidence_id']}]
                                           if decision.get('evidence_id') else [])


def unaided_basis(index, record):
    props = record['props']
    if props.get('event') not in ('attempt', 'review') or props.get('outcome') != 'succeeded':
        return False
    if props.get('assistance') != ['none']:
        return False
    # Reinspect exposure, including later/imported exposure. Never trust a copied badge.
    target = props.get('target', {})
    if target.get('vault_id') != index.manifest['vault_id']:
        return False  # Foreign assessments remain evidence, not certified local unaided claims.
    attempt = props.get('attempt_id')
    if not attempt:
        return False  # Legacy assessments did not necessarily preserve a protected start.
    for event in index.timeline(target['record_id']):
        if event.get('attempt_id') == attempt and event.get('event') == 'assistance':
            if event.get('assistance') != ['none']:
                return False
    start = index.record(attempt, include_body=False, include_attempt=False)['props']
    return (start.get('event') == 'attempt-start' and start.get('target') == target
            and start.get('assistance', ['none']) == ['none'])


def validate_claim(index, target, fields):
    """Additional validation for new dimensional claims; legacy callers stay compatible."""
    dimension = fields.get('dimension')
    if dimension is None:
        return
    if dimension not in DIMENSIONS:
        raise ValueError('Choose a supported understanding dimension')
    if fields.get('confidence', 'unknown') not in ('unknown', 'low', 'medium', 'high'):
        raise ValueError('Confidence is a separate self-report: unknown, low, medium or high')
    if not isinstance(fields.get('scope'), str) or not 1 <= len(fields['scope'].strip()) <= 1000:
        raise ValueError('Describe the scope of this understanding claim')
    if fields.get('evidence_kind') not in EVIDENCE_KINDS:
        raise ValueError('Describe the kind of evidence, not merely successful execution')
    refs = references(index, fields)
    if not isinstance(refs, list) or not 1 <= len(refs) <= 8:
        raise ValueError('Attach between one and eight owned evidence references')
    records = [evidence_record(index, ref) for ref in refs]
    if any(record['props'].get('event') == 'capability-decision' for record in records):
        raise ValueError('A claim cannot serve as its own evidence; attach the underlying work')
    if type(fields.get('independent', False)) is not bool:
        raise ValueError('Independent must be an explicit learner decision')
    if fields.get('independent') and not all(unaided_basis(index, record) for record in records):
        raise ValueError('Unaided claims need successful protected assessments without recorded exposure')
    if dimension == 'retained' and fields.get('decision') == 'accept':
        from datetime import datetime, timedelta
        earlier = index.record(fields.get('retained_from', ''), include_body=False, include_attempt=False)['props']
        days = fields.get('interval_days')
        if (earlier.get('event') != 'capability-decision' or earlier.get('decision') != 'accept'
                or earlier.get('dimension') not in DIMENSIONS[:-1]
                or earlier.get('target', {}).get('record_id') != target
                or earlier.get('criterion') != fields.get('criterion')
                or earlier.get('scope') != fields.get('scope')
                or type(days) is not int or not 1 <= days <= 3650):
            raise ValueError('Retention needs an earlier scoped ability and a learner-chosen interval')
        current = next((row for row in claims(index, target)
                        if row.get('decision_id') == earlier['id'] and row.get('decision') == 'accept'), None)
        if current is None:
            raise ValueError('Retention needs an established, unwithdrawn earlier scoped ability')
        threshold = datetime.fromisoformat(earlier['timestamp']) + timedelta(days=days)
        for record in records:
            props = record['props']
            if (props.get('event') not in ('attempt', 'review') or props.get('outcome') != 'succeeded'
                    or not props.get('timestamp') or datetime.fromisoformat(props['timestamp']) < threshold):
                raise ValueError('A scheduled check is not retention; attach a successful later assessment')
    previous = fields.get('supersedes')
    if previous:
        old = index.record(previous, include_body=False, include_attempt=False)['props']
        if (old.get('event') != 'capability-decision' or old.get('target', {}).get('record_id') != target
                or old.get('criterion') != fields.get('criterion') or old.get('dimension') != dimension
                or old.get('scope', '') != fields.get('scope', '')):
            raise ValueError('A replacement must name a decision for the same criterion, dimension and scope')
    resolutions = fields.get('resolves')
    if resolutions is not None:
        if not isinstance(resolutions, list) or len(resolutions) > 50:
            raise ValueError('Claim resolution needs a bounded list of conflicting decisions')
        group = [event for event in index.timeline(target) if event.get('event') == 'capability-decision'
                 and (event.get('criterion'), event.get('dimension'), event.get('scope', '')) ==
                     (fields.get('criterion'), dimension, fields.get('scope', ''))]
        replaced = {event.get('supersedes') for event in group}
        for event in group:
            replaced.update(event.get('resolves') or [])
        heads = {event['id'] for event in group if event['id'] not in replaced}
        if len(heads) < 2 or set(resolutions) != heads:
            raise ValueError('Reload and explicitly resolve all current conflicting claim heads')


def claims(index, identity):
    """Reduce every decision, not the last presentation page. Competing heads are visible."""
    groups = {}
    for event in index.timeline(identity):
        if event.get('event') == 'capability-decision':
            scope = event.get('scope')
            if scope is None:
                scope = ''
            elif not isinstance(scope, str):
                scope = json.dumps(scope, sort_keys=True, default=str)
            key = (str(event.get('criterion') or ''), event.get('dimension'), scope)
            groups.setdefault(key, []).append(event)
    result = []
    for (criterion, dimension, scope), events in groups.items():
        replaced = {event.get('supersedes') for event in events}
        for event in events:
            replaced.update(event.get('resolves') or [])
        heads = [event for event in events if event['id'] not in replaced]
        if not heads:
            result.append({'criterion': criterion[:200], 'dimension': dimension, 'decision': 'conflict',
                           'scope': scope[:1000], 'availability': 'Cyclic or invalid claim history'})
            continue
        head = heads[-1]
        row = {'criterion': criterion[:200], 'dimension': dimension, 'scope': scope[:1000],
               'decision': head.get('decision') if len(heads) == 1 else 'conflict',
               'decision_id': head['id'], 'head_ids': [event['id'] for event in heads][:50],
               'decision_count': len(events), 'confidence': head.get('confidence', 'unknown'),
               'evidence_kind': head.get('evidence_kind', 'not recorded'), 'independent': False,
               'checked': head.get('timestamp'), 'evidence_refs': references(index, head),
               'provenance': 'learner-reported', 'legacy': dimension is None}
        try:
            supporting = [evidence_record(index, ref) for ref in row['evidence_refs']]
            row['independent'] = bool(len(heads) == 1 and head.get('decision') == 'accept' and head.get('independent') is True and head.get('actor') == 'learner' and dimension in DIMENSIONS
                                      and supporting and all(unaided_basis(index, record) for record in supporting))
            if supporting:
                row.update(evidence_id=supporting[0]['props']['id'], path=supporting[0]['path'],
                           outcome=supporting[0]['props'].get('outcome', 'unknown'),
                           assistance=supporting[0]['props'].get('assistance', ['unknown']))
        except (ValueError, OSError, KeyError, TypeError) as error:
            row['availability'] = str(error)
        result.append(row)
    return result


def frontier(index, identity, cursor=None):
    """One-hop page bound to owner, record, cache and index generation."""
    record = index.record(identity, include_body=False, include_attempt=False)
    scope = {'version': 1, 'owner': index.manifest['vault_id'], 'record': identity,
             'cache': index.cache_identity, 'generation': index.generation}
    offset = 0
    if cursor:
        try:
            value = json.loads(base64.b64decode(cursor, validate=True))
            if any(value.get(key) != expected for key, expected in scope.items()):
                raise ValueError('Frontier changed or belongs to another context; reload')
            offset = value['offset']
            if type(offset) is not int or offset < 0 or offset % 50:
                raise ValueError('Invalid frontier cursor')
        except (TypeError, KeyError, AttributeError, UnicodeError, json.JSONDecodeError, base64.binascii.Error) as error:
            raise ValueError('Invalid frontier cursor') from error
    rows = index.db.execute('''SELECT DISTINCT r.id FROM records r WHERE r.id=? OR r.id IN (
        SELECT CASE WHEN r.source=? THEN r.target ELSE r.source END FROM relationships r
        WHERE (r.source=? OR r.target=?) AND ''' + local_relationship('r') + ''')
        ORDER BY r.id LIMIT 51 OFFSET ?''',
        (identity, identity, identity, identity, index.manifest['vault_id'], index.manifest['vault_id'], offset)).fetchall()
    items = []
    for (related_id,) in rows[:50]:
        related = index.record(related_id, include_body=False, include_attempt=False)
        props = related['props']
        if props.get('type') in ('activity', 'relationship'):
            continue
        item = {'id': related_id, 'vault': str(index.root), 'vault_id': scope['owner'],
                'title': related['display_title'][:240], 'type': props.get('type'), 'path': related['path'],
                'status': related['state'].get('status') or props.get('status') or 'unknown',
                'depth': related['state'].get('depth') or (props['investigation'].get('depth') if isinstance(props.get('investigation'), dict) else None) or 'normal'}
        if props.get('type') == 'capability':
            reduced = claims(index, related_id)
            compact = [{key: str(value)[:240] if key in ('criterion', 'scope') else value
                        for key, value in row.items() if key in
                        ('criterion', 'dimension', 'scope', 'decision', 'independent', 'availability')}
                       for row in reduced[:1]]
            item.update(claims=compact, claim_count=len(reduced), claims_truncated=len(reduced) > 1)
        items.append(item)
    encode = lambda position: base64.b64encode(json.dumps(dict(scope, offset=position), separators=(',', ':')).encode()).decode()
    parent = record['props'].get('parent_ref')
    return {'owner': scope['owner'], 'record_id': identity, 'generation': index.generation,
            'items': items, 'cursor': encode(offset + 50) if len(rows) > 50 else None,
            'newer_cursor': encode(offset - 50) if offset else None, 'parent_ref': parent,
            'summary': 'Evidence, confidence and unanswered mechanisms remain separate.'}


def claim_page(index, identity, cursor=None):
    """Ten fully reduced criteria per page; older decisions participate in every reduction."""
    scope = {'version': 1, 'owner': index.manifest['vault_id'], 'record': identity,
             'cache': index.cache_identity, 'generation': index.generation, 'kind': 'claims'}
    offset = 0
    if cursor:
        try:
            value = json.loads(base64.b64decode(cursor, validate=True))
            if any(value.get(key) != expected for key, expected in scope.items()):
                raise ValueError('Claim history changed or belongs to another context; reload')
            offset = value['offset']
            if type(offset) is not int or offset < 0 or offset % 10:
                raise ValueError('Invalid claim cursor')
        except (TypeError, KeyError, AttributeError, UnicodeError, json.JSONDecodeError, base64.binascii.Error) as error:
            raise ValueError('Invalid claim cursor') from error
    reduced = claims(index, identity)
    encode = lambda position: base64.b64encode(json.dumps(dict(scope, offset=position), separators=(',', ':')).encode()).decode()
    return {'evidence': reduced[offset:offset + 10], 'claim_count': len(reduced),
            'claim_cursor': encode(offset + 10) if offset + 10 < len(reduced) else None,
            'claim_newer_cursor': encode(offset - 10) if offset else None}
