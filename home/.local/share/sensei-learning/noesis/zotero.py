"""Bounded read-only local Zotero adapter. Bibliographic/annotation authority stays there."""
import json
import re
import tempfile
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, build_opener, ProxyHandler, HTTPRedirectHandler
from urllib.parse import urlencode
from .imports import import_csl
from .persistence import read_content
from .persistence import contained, lock, manifest_path, parse, publish, render, checksum
import uuid


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ValueError('Unexpected Zotero redirect')


class LocalAPI:
    def __init__(self, server_id=None, opener=None):
        self.server_id = server_id
        self.api_version = None
        self.library_version = None
        self.opener = opener or build_opener(ProxyHandler({}), NoRedirect())

    def get(self, endpoint=''):
        if not re.fullmatch(r'[A-Za-z0-9/?=&%+._-]*', endpoint):raise ValueError('Invalid local API endpoint')
        headers = {'Zotero-API-Version': '3'}
        if self.server_id:headers['Zotero-Server-ID'] = self.server_id
        try:
            with self.opener.open(Request('http://127.0.0.1:23119/api/' + endpoint, headers=headers), timeout=3) as response:
                version = response.headers.get('Zotero-API-Version')
                server = response.headers.get('Zotero-Server-ID')
                if version != '3':raise ValueError('Unsupported Zotero local API version; use export import')
                if self.server_id and server != self.server_id:raise ValueError('Zotero instance changed; no import committed')
                if not server:raise ValueError('Zotero instance identity unavailable; use export import')
                self.server_id, self.api_version = server, version
                self.library_version = response.headers.get('Last-Modified-Version')
                raw = response.read(4 * 1024 * 1024 + 1)
                if len(raw) > 4 * 1024 * 1024:raise ValueError('Zotero response too large; reduce query')
                # The installed Zotero 10 root returns a plain-text probe body.
                return json.loads(raw) if raw and endpoint else None
        except HTTPError as error:
            messages = {403: 'Enable the local API in Zotero settings, or import its export', 412: 'Zotero instance changed; no import committed'}
            message = messages.get(error.code, 'Zotero local API refused request: ' + str(error.code))
            error.close()
            raise ValueError(message) from error
        except (URLError, TimeoutError) as error:
            raise ValueError('Zotero local API unavailable; capture offline or import CSL/Markdown exports') from error

    def probe(self):
        self.get()
        return {'api_version': self.api_version, 'server_id': self.server_id, 'access': 'read-only', 'write_authorization': 'not requested'}

    def search(self, query='', start=0):
        if not isinstance(query,str) or len(query)>256:raise ValueError('Use a short Zotero search query')
        if type(start) is not int or start<0:raise ValueError('Invalid Zotero cursor')
        self.probe()
        items=self.get('users/0/items/top?'+urlencode({'q':query,'qmode':'everything','limit':50,'start':start}))
        if not isinstance(items,list):raise ValueError('Invalid Zotero search response')
        return {'server_id':self.server_id,'records':[{'key':item['key'],'title':item.get('data',{}).get('title','Untitled item'),
                'type':item.get('data',{}).get('itemType'),'version':item.get('version')} for item in items],
                'cursor':start+len(items) if len(items)==50 else None}

    def item(self, key):
        if not re.fullmatch(r'[A-Z0-9]{8}', key):raise ValueError('Expected Zotero item key')
        self.probe()
        item = self.get('users/0/items/' + key)
        library_version = self.library_version
        children = self.children(key)
        for child in list(children):
            if child.get('data',{}).get('itemType') == 'attachment':children.extend(self.children(child['key']))
        if len(children)>1000:raise ValueError('Too many child records; use export')
        if library_version and self.library_version != library_version:raise ValueError('Zotero library changed during read; retry import')
        return item, children

    def children(self,key):
        children, start = [], 0
        for _ in range(20):
            page = self.get('users/0/items/' + key + '/children?' + urlencode({'limit':50,'start':start}))
            if not isinstance(page,list):raise ValueError('Invalid Zotero child response')
            children.extend(page)
            if len(page) < 50:break
            start += 50
        else:raise ValueError('Too many item children; use explicit export')
        return children


def import_item(root, key, api=None):
    api = api or LocalAPI()
    item, children = api.item(key)
    data = item['data']
    if not data.get('title'):raise ValueError('Choose a titled bibliography item')
    csl = {'id': 'zotero:' + api.server_id + ':' + key, 'title': data['title'], 'DOI': data.get('DOI',''),
           'URL': data.get('url',''), 'author': [{'family': c.get('lastName',c.get('name','')), 'given':c.get('firstName','')} for c in data.get('creators',[])]}
    meta = json.loads(manifest_path(root).read_text())
    with tempfile.TemporaryDirectory() as folder:
        source = Path(folder)/'item.json';source.write_text(json.dumps([csl]))
        result = import_csl(root,source,meta,lambda entry: checksum(entry['id'])[:16])
    relative = (result['created'] + result['existing'])[0]
    with lock(root):
        path = contained(root,relative);text=read_content(path);props,body=parse(text)
        raw = json.dumps({'item':item,'children':children,'server_id':api.server_id},sort_keys=True)
        digest=checksum(raw)
        projection=contained(root,'Imports/'+props['id']+'/zotero/'+digest+'.md')
        if not projection.exists():publish(projection,render({'id':str(uuid.uuid4()),'noesis_schema':2,'type':'imported-zotero','resource_id':props['id'],'zotero_server_id':api.server_id,'zotero_key':key,'source_version':item.get('version'),'source_sha256':digest},'\n```json\n'+raw+'\n```\n'))
        updated=dict(props,zotero_server_id=api.server_id,zotero_key=key,zotero_uri='zotero://select/library/items/'+key,zotero_projection=str(projection.relative_to(root)),zotero_version=item.get('version'))
        pdfs=[child['key'] for child in children if child.get('data',{}).get('itemType')=='attachment' and child.get('data',{}).get('contentType')=='application/pdf']
        if len(pdfs)==1:updated['zotero_attachment_key']=pdfs[0]
        else:updated.pop('zotero_attachment_key',None)
        if updated!=props:publish(path,render(updated,body),checksum(text))
    return dict(result,resource_id=props['id'],projection=str(projection.relative_to(root)),server_id=api.server_id,access='read-only')
