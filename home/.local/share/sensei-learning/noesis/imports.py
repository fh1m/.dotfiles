"""Versioned CSL projections. Learner analysis is never replaced."""
from datetime import date
import hashlib
import json
import re
import uuid
from .persistence import checksum, contained, lock, notes, parse, publish, render


def aliases(item):
    result = []
    if item.get('id'):result.append('csl:' + str(item['id']))
    if item.get('DOI'):result.append('doi:' + str(item['DOI']).strip().lower().removeprefix('https://doi.org/'))
    if item.get('URL'):result.append('url:' + str(item['URL']))
    return result


def import_csl(root, source, meta, resource_key, dry=False):
    items = json.loads(source.read_text())
    if not isinstance(items, list) or any(not isinstance(i, dict) or not i.get('title') for i in items):
        raise ValueError('Expected a CSL JSON array with titled items')
    created, existing = [], []
    with lock(root):
        records, by_alias = {}, {}
        for path in notes(root):
            text = path.read_text()
            props, body = parse(text)
            if not props.get('source_id'):continue
            key = props['source_id']
            if key in records:raise ValueError('Duplicate imported source identity')
            records[key] = (path, props, body, text)
            for alias in props.get('external_aliases', []):
                if alias in by_alias and by_alias[alias] != key:raise ValueError('Conflicting external alias')
                by_alias[alias] = key
        for item in items:
            key = resource_key(item)
            candidates = {by_alias[a] for a in aliases(item) if a in by_alias}
            if key in records:candidates.add(key)
            if len(candidates) > 1:raise ValueError('Ambiguous resource aliases; review duplicates')
            key = next(iter(candidates), key)
            if key in records:
                path, props, body, text = records[key]
                existing.append(str(path.relative_to(root)))
            else:
                title = re.sub(r'[\\/\n\r\x00-\x1f]', ' ', str(item['title'])).strip()[:130] or 'Paper'
                path = contained(root, meta['types'].get('paper', 'Notes') + '/' + title + ' [' + key[:8] + '].md')
                props = {'id': str(uuid.uuid4()), 'source_id': key, 'type': 'paper', 'status': 'queued', 'created': date.today().isoformat()}
                body = '\n# ' + str(item['title']) + '\n\n## Why this paper?\n\n## Claims / model / assumptions\n\n## My reconstruction\n\n## Implementation and evidence\n\n## Questions / limitations / connections\n'
                text = None
                created.append(str(path.relative_to(root)))
            raw = json.dumps(item, sort_keys=True, ensure_ascii=False)
            digest = hashlib.sha256(raw.encode()).hexdigest()
            projection = contained(root, 'Imports/' + props['id'] + '/bibliography/' + digest + '.md')
            updated = dict(props, noesis_schema=2, source_kind='paper', source=item.get('URL', ''), doi=item.get('DOI', ''),
                external_aliases=sorted(set(props.get('external_aliases', []) + aliases(item))), bibliography_projection=str(projection.relative_to(root)))
            match = re.search(r'/items/([A-Z0-9]{8})$', str(item.get('id', '')))
            if match:updated['zotero_uri'] = 'zotero://select/library/items/' + match[1]
            if not dry:
                # A projection may survive interruption; its source/resource identity
                # makes retry explainable and safe before publishing the pointer.
                if not projection.exists():
                    publish(projection, render({'id': str(uuid.uuid4()), 'noesis_schema': 2, 'type': 'imported-bibliography', 'resource_id': props['id'], 'source_sha256': digest}, '\n```json\n' + raw + '\n```\n'))
                if updated != props or text is None:
                    publish(path, render(updated, body), checksum(text) if text is not None else None)
            records[key] = (path, updated, body, render(updated, body))
            for alias in updated['external_aliases']:by_alias[alias] = key
    return {'created': created, 'existing': existing, 'dry_run': dry}
