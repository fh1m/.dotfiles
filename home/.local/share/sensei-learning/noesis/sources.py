"""Read-only, owner-checked bibliography and annotation snapshot projections."""
import base64
import json
from .persistence import checksum, contained, parse


def projection(index, record, path, kind):
    source=contained(index.root,path)
    if source.stat().st_size>10*1024*1024:
        raise ValueError('Source snapshot exceeds the native preview limit; inspect the preserved source')
    props, body = parse(source.read_text())
    if props.get('type') != kind or props.get('resource_id') != record['props']['id']:
        raise ValueError('Source projection belongs to another paper')
    try:
        raw = body.split('```json\n', 1)[1].split('\n```', 1)[0]
        payload = json.loads(raw)
    except (ValueError, IndexError) as error:
        raise ValueError('Source projection is unreadable') from error
    if not isinstance(payload, dict) or checksum(raw) != props.get('source_sha256'):
        raise ValueError('Source projection checksum changed; inspect the preserved import')
    return props, payload


def annotations(index, identity, cursor=None, projection_path=None):
    record = index.record(identity)
    props = record['props']
    path = projection_path or props.get('zotero_projection')
    if not path:
        if cursor:raise ValueError('Annotation source is no longer available; reload the paper')
        return {'annotations': [], 'annotation_count': 0, 'cursor': None, 'newer_cursor': None}
    metadata, payload = projection(index, record, path, 'imported-zotero')
    if not props.get('zotero_server_id') or not props.get('zotero_key'):
        raise ValueError('Paper is missing its Zotero library or item identity')
    item = payload.get('item', {})
    if not isinstance(item, dict):raise ValueError('Invalid paper snapshot')
    if (not props.get('zotero_server_id') or not props.get('zotero_key') or metadata.get('zotero_key') != props.get('zotero_key') or metadata.get('zotero_server_id') != props.get('zotero_server_id') or
        payload.get('server_id') != props.get('zotero_server_id') or
        metadata.get('zotero_key') != props.get('zotero_key') or
        item.get('key') != props.get('zotero_key')):
        raise ValueError('Annotation snapshot does not match this paper and Zotero library')
    children = payload.get('children', [])
    if not isinstance(children, list) or any(not isinstance(child, dict) or not isinstance(child.get('data'),dict) for child in children):
        raise ValueError('Invalid annotation snapshot')
    attachments = {child.get('key') for child in children
                   if child.get('data', {}).get('itemType') == 'attachment' and
                   child.get('data', {}).get('parentItem') == item.get('key')}
    rows = []
    for child in children:
        data = child.get('data', {})
        if data.get('itemType') != 'annotation':continue
        parent = data.get('parentItem')
        rows.append({'native_id': child.get('key'), 'source_version': child.get('version'),
                     'text': data.get('annotationText', ''), 'comment': data.get('annotationComment', ''),
                     'page_label': data.get('annotationPageLabel', ''), 'position': data.get('annotationPosition'),
                     'attachment_key': parent if parent in attachments else None,
                     'availability': 'imported snapshot; live reader state not checked' if parent in attachments else 'attachment unavailable in this paper snapshot',
                     'authority': 'Zotero; imported snapshot', 'projection': path})
    scope = {'version': 1, 'owner': index.manifest.get('vault_id'), 'record': identity,
             'cache': index.cache_identity, 'generation': index.generation,
             'projection': path, 'digest': metadata['source_sha256']}
    offset = 0
    if cursor:
        try:
            value = json.loads(base64.b64decode(cursor, validate=True))
            if not isinstance(value, dict) or any(value.get(key) != expected for key, expected in scope.items()):
                raise ValueError('Annotation source changed or belongs to another context; reload annotations')
            offset = value['offset']
            if type(offset) is not int or not 0 <= offset < 2**63 or offset % 50:
                raise ValueError('Invalid annotation cursor')
        except (TypeError, KeyError, UnicodeError, json.JSONDecodeError, base64.binascii.Error) as error:
            raise ValueError('Invalid annotation cursor') from error
    def encode(start):
        return base64.b64encode(json.dumps(dict(scope, offset=start), separators=(',', ':')).encode()).decode()
    return {'annotations': rows[offset:offset+50], 'annotation_count': len(rows),
            'cursor': encode(offset+50) if len(rows) > offset+50 else None,
            'newer_cursor': encode(max(0, offset-50)) if offset else None,
            'projection': path, 'source_version': item.get('version'), 'generation': index.generation,
            'historical_snapshot':path != props.get('zotero_projection')}


def annotation_revisions(index, identity, cursor=None):
    record=index.record(identity)
    scope={'version':1,'owner':index.manifest.get('vault_id'),'record':identity,
           'cache':index.cache_identity,'generation':index.generation}
    offset=0
    if cursor:
        try:
            value=json.loads(base64.b64decode(cursor,validate=True))
            if not isinstance(value,dict) or any(value.get(key)!=expected for key,expected in scope.items()):
                raise ValueError('Source revisions changed or belong to another context; reload revisions')
            offset=value['offset']
            if type(offset) is not int or not 0<=offset<2**63 or offset%50:raise ValueError('Invalid revision cursor')
        except (TypeError,KeyError,UnicodeError,json.JSONDecodeError,base64.binascii.Error) as error:
            raise ValueError('Invalid revision cursor') from error
    rows=list(index.db.execute('''SELECT path,props FROM records WHERE kind='imported-zotero'
        AND json_extract(props,'$.resource_id')=?
        ORDER BY CAST(json_extract(props,'$.source_version') AS INTEGER) DESC,path LIMIT 51 OFFSET ?''',
        (record['props']['id'],offset)))
    def encode(start):return base64.b64encode(json.dumps(dict(scope,offset=start),separators=(',',':')).encode()).decode()
    return {'revisions':[{'path':path,'source_version':json.loads(raw).get('source_version'),
                         'current':path==record['props'].get('zotero_projection')} for path,raw in rows[:50]],
            'cursor':encode(offset+50) if len(rows)>50 else None,
            'newer_cursor':encode(max(0,offset-50)) if offset else None}


def bibliography(index, record):
    props = record['props']
    path = props.get('bibliography_projection')
    if not path:return None
    _, item = projection(index, record, path, 'imported-bibliography')
    result={key:item.get(key) for key in ('title','DOI','URL','container-title','publisher','type')}
    if any(value is not None and not isinstance(value,str) for value in result.values()):
        raise ValueError('Bibliography contains an invalid display field; inspect its preserved source')
    authors=item.get('author',[])
    if not isinstance(authors,list) or any(not isinstance(author,dict) for author in authors):
        raise ValueError('Bibliography has invalid authors; inspect its preserved source')
    result['author']=[{key:value for key,value in author.items() if key in ('literal','given','family') and isinstance(value,str)} for author in authors[:100]]
    issued=item.get('issued',{})
    parts=issued.get('date-parts') if isinstance(issued,dict) else None
    result['issued']={'date-parts':parts} if isinstance(parts,list) and all(isinstance(part,list) and all(type(value) is int for value in part) for part in parts) else None
    return result


def annotation_command(index, identity, annotation_key, projection_path=None, api=None):
    """Resolve an owned imported annotation against the currently connected reader.

    Old/deleted annotation text stays authoritative as preserved source history;
    navigation falls back to its physical page rather than pretending selection.
    """
    import re
    from urllib.parse import urlencode
    from .zotero import LocalAPI
    record = index.record(identity, include_body=False, include_attempt=False)
    props = record['props']
    if not re.fullmatch('[A-Z0-9]{8}', annotation_key): raise ValueError('Invalid annotation identity')
    path = projection_path or props.get('zotero_projection')
    metadata, payload = projection(index, record, path, 'imported-zotero')
    if (not props.get('zotero_server_id') or not props.get('zotero_key') or metadata.get('zotero_key') != props.get('zotero_key') or metadata.get('zotero_server_id') != props.get('zotero_server_id') or
        payload.get('server_id') != props.get('zotero_server_id') or
        payload.get('item', {}).get('key') != props.get('zotero_key')):
        raise ValueError('Annotation belongs to a different paper or Zotero instance')
    children = payload.get('children', [])
    matches = [row for row in children if row.get('key') == annotation_key and row.get('data', {}).get('itemType') == 'annotation']
    if len(matches) != 1: raise ValueError('Annotation is not in this owned source revision')
    annotation = matches[0]; attachment = annotation['data'].get('parentItem')
    if not re.fullmatch('[A-Z0-9]{8}', str(attachment)): raise ValueError('Invalid attachment identity')
    if not any(row.get('key') == attachment and row.get('data', {}).get('itemType') == 'attachment' and row['data'].get('parentItem') == props.get('zotero_key') for row in children):
        raise ValueError('Annotation attachment is outside this paper')
    api = api or LocalAPI(server_id=props.get('zotero_server_id'))
    live_item, live_children = api.item(props['zotero_key'])
    if live_item.get('key') != props['zotero_key']:raise ValueError('Live paper identity changed')
    if not any(row.get('key') == attachment and row.get('data', {}).get('parentItem') == props['zotero_key'] for row in live_children):
        raise ValueError('Source attachment is unavailable in Zotero; preserved annotation remains readable')
    try: position = json.loads(annotation['data'].get('annotationPosition') or '{}')
    except (TypeError, ValueError): position = {}
    params = {}
    page = position.get('pageIndex')
    if type(page) is int and page >= 0: params['page'] = page + 1
    exact = path == props.get('zotero_projection') and any(row.get('key') == annotation_key and row.get('version') == annotation.get('version') and row.get('data', {}).get('parentItem') == attachment for row in live_children)
    if exact: params['annotation'] = annotation_key
    uri = 'zotero://open-pdf/library/items/' + attachment + ('?' + urlencode(params) if params else '')
    return {'command': ['xdg-open', uri], 'mode': 'annotation' if exact else 'preserved-page' if params else 'attachment',
            'message': 'Annotation navigation requested; Zotero owns selection.' if exact else 'Historical or changed annotation: opening the current PDF at its recorded page; page content may differ and old annotation selection is unavailable.'}


def annotation_reference(index, identity, key, path):
    """A durable source pointer, not a second copy of annotation text."""
    record=index.record(identity,include_body=False,include_attempt=False)
    props=record['props'];metadata,payload=projection(index,record,path,'imported-zotero')
    if (metadata.get('zotero_server_id')!=props.get('zotero_server_id') or
        metadata.get('zotero_key')!=props.get('zotero_key') or
        payload.get('server_id')!=props.get('zotero_server_id') or
        payload.get('item',{}).get('key')!=props.get('zotero_key')):
        raise ValueError('Annotation belongs to another source library')
    rows=[row for row in payload.get('children',[]) if row.get('key')==key and row.get('data',{}).get('itemType')=='annotation']
    if len(rows)!=1:raise ValueError('Annotation is absent from this owned source revision')
    row=rows[0];attachment=row['data'].get('parentItem')
    if not any(child.get('key')==attachment and child.get('data',{}).get('itemType')=='attachment' and child['data'].get('parentItem')==props.get('zotero_key') for child in payload.get('children',[])):
        raise ValueError('Annotation attachment is outside this paper')
    return {'vault_id':index.manifest['vault_id'],'record_id':identity,'server_id':props['zotero_server_id'],
            'item_key':props['zotero_key'],'attachment_key':attachment,'annotation_key':key,
            'source_version':row.get('version'),'projection':path,'projection_sha256':metadata['source_sha256']}
