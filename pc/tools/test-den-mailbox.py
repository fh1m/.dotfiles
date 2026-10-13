#!/usr/bin/env python3
"""Exercise message boundaries and reconnect-safe delivery in a scratch home."""
import datetime
import importlib.util
import json
from pathlib import Path
import tempfile
spec=importlib.util.spec_from_file_location('mailbox',Path(__file__).with_name('den-mailbox.py'))
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
msg=dict(id='test-001',sender='arete',recipient='homie',timestamp=datetime.datetime.now(datetime.timezone.utc).isoformat(),task='fixture',commits=['5dba0dd'],proposed_changes='',observed_results='',tests='fixture',requested_response='ack')
raw=json.dumps(msg).encode();m.validate(raw,'homie')
with tempfile.TemporaryDirectory() as tmp:
 base=m.directory(Path(tmp)/'inbox');dest=base/'test-001.json'
 assert m.put(dest,raw)=='stored'
 assert m.put(dest,raw)=='duplicate'
 assert m.read(dest)==raw
 try:m.put(dest,b'changed')
 except ValueError:pass
 else:raise AssertionError('conflicting ID accepted')
 (base/'link.json').symlink_to(dest)
 try:m.read(base/'link.json')
 except OSError:pass
 else:raise AssertionError('symlink accepted')
for bad in [dict(msg,id='../escape'),dict(msg,sender='homie'),dict(msg,commits=['not-a-commit']),dict(msg,timestamp='2026-10-13'),dict(msg,extra='unknown')]:
 try:m.validate(json.dumps(bad).encode(),'homie')
 except (ValueError,TypeError):pass
 else:raise AssertionError('invalid schema accepted')
try:m.validate(b'x'*65537)
except ValueError:pass
else:raise AssertionError('oversized input accepted')
print('PASS: schema, identities, timestamp, size, traversal, symlinks, conflict and identical reconnect delivery')
