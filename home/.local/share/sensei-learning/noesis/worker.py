"""Versioned NDJSON read-only worker; EOF closes its database."""
import json
import sys
import sqlite3
from .index import Index
from .policies import next_actions


def serve(resolve):
    indexes = {}
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
                if key not in indexes:
                    indexes[key] = Index(root)
                    indexes[key].reconcile()
                index = indexes[key]
                action = request.get('action', 'query')
                if action == 'reconcile':
                    result = index.reconcile(request.get('paths'))
                elif action == 'query':
                    result = index.query(request.get('query', ''), request.get('kind'), request.get('cursor') or 0)
                elif action == 'record':
                    result = index.record(request['record_id'])
                    result['body_truncated'] = len(result['body']) > 32000
                    result['body'] = result['body'][:32000]
                elif action == 'timeline':
                    result = {'activities': index.timeline(request['record_id'])[-50:]}
                elif action == 'relations':
                    result = {'relationships': index.relations(request['record_id'])}
                elif action == 'next':
                    result = {'records': next_actions(index, request.get('quiet', False))}
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
