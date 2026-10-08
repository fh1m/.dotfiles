"""Validated native handoffs; reader state remains owned by the reader."""
from pathlib import Path
from urllib.parse import urlsplit,urlunsplit,parse_qsl,urlencode
from .persistence import contained

def command(root, props, state, reader='sioyek'):
    locator=state.get('locator') or {}
    page=locator.get('value') if locator.get('kind')=='page' else None
    if page is not None and (type(page) is not int or page<1):raise ValueError('Invalid saved page')
    if reader=='zotero' or not props.get('local_file') and not props.get('source') and props.get('zotero_uri'):
        key=props.get('zotero_attachment_key')
        if key:
            import re
            if not re.fullmatch('[A-Z0-9]{8}',str(key)):raise ValueError('Invalid Zotero attachment key')
            uri='zotero://open-pdf/library/items/'+key
            return ['xdg-open',uri+('?page='+str(page) if page else '')]
        uri=props.get('zotero_uri','')
        if uri and str(uri).startswith('zotero://select/'):return ['xdg-open',str(uri)]
        return [str(Path.home()/'.local/bin/zotero') if (Path.home()/'.local/bin/zotero').exists() else 'zotero']
    local=props.get('local_file')
    if local:
        path=Path(str(local)).expanduser()
        if not path.is_absolute():path=contained(root,str(local))
        if not path.is_file():raise ValueError('Linked artifact unavailable; its learning record is preserved')
        if reader=='sioyek' and path.suffix.lower()=='.pdf':
            binary=Path.home()/'.local/bin/sioyek'
            return [str(binary) if binary.exists() else 'sioyek']+(['--page',str(page)] if page else [])+[str(path)]
        return ['xdg-open',str(path)]
    source=str(props.get('source') or '')
    url=urlsplit(source)
    if url.scheme not in ('https','http'):raise ValueError('Link a document or supported source URL first')
    if locator.get('kind')=='timestamp' and url.hostname in ('youtube.com','www.youtube.com','m.youtube.com','youtu.be'):
        seconds=locator.get('seconds')
        if type(seconds) not in (int,float) or seconds<0:raise ValueError('Invalid saved timestamp')
        query=dict(parse_qsl(url.query));query['t']=str(int(seconds))+'s'
        source=urlunsplit((url.scheme,url.netloc,url.path,urlencode(query),url.fragment))
    return ['xdg-open',source]


def resource_props(index, identity):
    """A chapter can reuse its containing book's document without copying metadata."""
    seen=set();current=identity
    for _ in range(20):
        if current in seen:raise ValueError('Cyclic resource containment')
        seen.add(current)
        props=index.record(current,include_body=False,include_attempt=False)['props']
        if any(props.get(key) for key in ('local_file','source','zotero_uri')):return props
        parents=list(index.db.execute("SELECT source FROM relationships WHERE target=? AND relation IN ('contains','orders')",(current,)))
        if len(parents)!=1:return props
        current=parents[0][0]
    raise ValueError('Resource containment is too deep; open its source explicitly')
