#!/usr/bin/env python3
"""Synthetic, disposable rebuild and actual NDJSON round-trip measurements."""
import argparse
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'home/.local/share/sensei-learning'))
from noesis.index import Index


def benchmark(count, units=False):
    with tempfile.TemporaryDirectory(prefix='noesis-bench-') as temporary:
        home = Path(temporary)
        root = home / 'vault'
        (root / 'System').mkdir(parents=True)
        vault_id=str(uuid.uuid4());parent=str(uuid.uuid4())
        (root / 'System/System.json').write_text(json.dumps({'noesis_schema': 2, 'vault_id': vault_id, 'directories': [], 'types': {}}))
        if units:(root/'course.md').write_text('---\nid: '+parent+'\nnoesis_schema: 2\ntype: resource\nsource_kind: course\n---\nSynthetic course.')
        for i in range(count):
            extra='parent_ref: '+json.dumps({'vault_id':vault_id,'record_id':parent,'relation':'contains','order':i})+'\n' if units else ''
            (root / ('record-' + str(i) + '.md')).write_text('---\nid: ' + str(uuid.uuid4()) + '\nnoesis_schema: 2\ntype: '+('unit' if units else 'concept')+'\n'+extra+'---\nSynthetic reconstruction and numerical evidence ' + str(i) + '\n')
        index = Index(root, home / '.cache/noesis')
        start = time.perf_counter()
        health = index.reconcile()
        rebuild = time.perf_counter() - start
        assert not health['errors']
        index.close()
        env = dict(os.environ, HOME=str(home))
        worker = subprocess.Popen([sys.executable, str(ROOT / 'home/.local/bin/sensei-learn'), 'serve', '--stdio'],
                                  env=env, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        def query(number, action='query'):
            request = {'version': 1, 'request_id': number, 'vault': str(root), 'action': action, 'query': 'reconstruction'}
            start = time.perf_counter()
            worker.stdin.write(json.dumps(request) + '\n');worker.stdin.flush()
            raw = worker.stdout.readline();response = json.loads(raw)
            assert response['request_id'] == number and 'error' not in response, response
            return (time.perf_counter() - start) * 1000, len(raw.encode())
        query(0)
        samples = [query(i + 1) for i in range(50)]
        today_samples=[query(i+100,'today') for i in range(50)]
        worker.stdin.close();worker.wait(timeout=10)
        assert worker.returncode == 0, worker.stderr.read()
        capture = []
        for i in range(10):
            start = time.perf_counter()
            subprocess.run([sys.executable, str(ROOT / 'home/.local/bin/sensei-learn'), 'capture', '--vault', str(root), 'Synthetic unclassified capture'],
                           env=env, check=True, capture_output=True)
            capture.append((time.perf_counter() - start) * 1000)
        return {'records': count, 'fixture':'ordered course units' if units else 'concepts', 'cold_rebuild_seconds': round(rebuild, 3),
                'warm_worker_p95_ms': round(sorted(t for t, _ in samples)[47], 3),
                'max_response_bytes': max(size for _, size in samples),
                'warm_today_p95_ms':round(sorted(t for t,_ in today_samples)[47],3),
                'capture_cli_p95_ms': round(sorted(capture)[-1], 3)}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--counts', nargs='+', type=int, default=[100, 1000, 10000])
    parser.add_argument('--units',action='store_true')
    args = parser.parse_args()
    print(json.dumps([benchmark(count,args.units) for count in args.counts], indent=2))
