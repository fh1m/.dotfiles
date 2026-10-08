"""Versioned NDJSON read-only worker; EOF closes its database."""
import json
import sys
import sqlite3
from .index import Index
from .policies import next_actions
from .views import overview, today


def serve(resolve):
    indexes = {}
    def get_index(root,reconcile=False):
        key=str(root)
        if key not in indexes:
            indexes[key]=Index(root)
            reconcile=True
        if reconcile:
            health=indexes[key].reconcile()
            if health.get('errors'):raise ValueError('Vault index has invalid records; inspect Doctor')
        return indexes[key]
    try:
        for line in sys.stdin:
            request = {}
            try:
                request = json.loads(line)
                if not isinstance(request, dict):raise ValueError('Request must be an object')
                if request.get('version') != 1:
                    raise ValueError('Expected protocol version 1')
                root = resolve(request['vault'])
                key = str(root)
                action = request.get('action', 'query')
                index = None if action in ('collection-today','collection-query') else get_index(root)
                if action in ('collection-today','collection-query'):
                    from .collection import project
                    result=project(request,get_index)
                elif action == 'reconcile':
                    result = index.reconcile(request.get('paths'))
                elif action == 'query':
                    result = index.query(request.get('query', ''), request.get('kind'), request.get('cursor') or 0,resource_kinds=request.get('resource_kinds'))
                elif action == 'record':
                    result = index.record(request['record_id'])
                    result['overview'] = overview(index, request['record_id'])
                    from .presentation import preview
                    result['preview']=preview(result['body'],result['display_title'])
                    result['body_truncated'] = len(result['body']) > 32000
                    result['body'] = result['body'][:32000]
                elif action == 'timeline':
                    result = {'activities': index.timeline(request['record_id'])[-50:]}
                elif action == 'relations':
                    result = {'relationships': index.relations(request['record_id'])}
                elif action == 'today':
                    result = today(index, request.get('context_id'), request.get('path_id'), request.get('quiet', False))
                elif action == 'next':
                    result = {'records': next_actions(index, request.get('quiet', False), request.get('path_id'))}
                else:
                    raise ValueError('Unknown read action')
                response = {'version': 1, 'request_id': request.get('request_id'), 'vault': key, 'result': result}
            except (ValueError, KeyError, OSError, TypeError, sqlite3.Error) as error:
                if not isinstance(request, dict):request = {}
                response = {'version': 1, 'request_id': request.get('request_id'), 'vault': request.get('vault'), 'error': str(error)}
            print(json.dumps(response, default=str), flush=True)
    finally:
        for index in indexes.values():
            index.close()
