#!/usr/bin/env python3
"""Explicit, bounded coordination messages; never execute message contents."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import socket
import sys
import tempfile

LIMIT = 65536
ID = re.compile(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,95}\Z')
FIELDS = {'id', 'sender', 'recipient', 'timestamp', 'task', 'commits',
          'proposed_changes', 'observed_results', 'tests', 'requested_response'}

def validate(raw, recipient=None):
    if len(raw) > LIMIT:
        raise ValueError('message exceeds 64 KiB')
    msg = json.loads(raw)
    if not isinstance(msg, dict) or set(msg) != FIELDS:
        raise ValueError('unexpected message fields')
    if not isinstance(msg['id'], str) or not ID.fullmatch(msg['id']):
        raise ValueError('invalid message ID')
    for field in FIELDS - {'commits'}:
        if not isinstance(msg[field], str) or len(msg[field]) > 16384:
            raise ValueError('invalid text field: ' + field)
    if msg['sender'] not in {'homie', 'arete'} or msg['recipient'] not in {'homie', 'arete'} or msg['sender'] == msg['recipient']:
        raise ValueError('invalid machine identities')
    if recipient and (msg['recipient'] != recipient or msg['sender'] != ('arete' if recipient == 'homie' else 'homie')):
        raise ValueError('unexpected sender/recipient')
    dt = datetime.datetime.fromisoformat(msg['timestamp'].replace('Z', '+00:00'))
    if dt.tzinfo is None:
        raise ValueError('timestamp needs timezone')
    if not isinstance(msg['commits'], list) or len(msg['commits']) > 16 or not all(isinstance(c,str) and re.fullmatch(r'[0-9a-f]{7,40}',c) for c in msg['commits']):
        raise ValueError('invalid commit identities')
    return msg

def directory(path):
    if path.is_symlink():
        raise ValueError('mailbox directory must not be a symlink')
    path.mkdir(parents=True, exist_ok=True, mode=0o700)
    if path.stat().st_uid != os.getuid() or path.stat().st_mode & 0o077:
        raise ValueError('mailbox directory needs private ownership/mode')
    return path

def read(path):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    with os.fdopen(fd, 'rb') as stream:
        return stream.read(LIMIT + 1)

def put(path, raw):
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
        name = stream.name
        stream.write(raw)
        stream.flush()
        os.fsync(stream.fileno())
    try:
        try:
            os.link(name, path, follow_symlinks=False)
        except FileExistsError:
            if read(path) != raw:
                raise ValueError('ID already exists with different content')
            return 'duplicate'
        return 'stored'
    finally:
        os.unlink(name)

def main():
    os.umask(0o077)
    host = socket.gethostname().split('.')[0].lower()
    if host not in {'homie', 'arete'}:
        raise ValueError('unknown host')
    base = directory(Path.home()/'.local/state/den/coordination')
    inbox = directory(base/'inbox')
    outbox = directory(base/'outbox')
    remote = sys.argv[1:] == ['--serve']
    args = shlex.split(os.environ.get('SSH_ORIGINAL_COMMAND','')) if remote else sys.argv[1:]
    if remote:
        if not args or args.pop(0) != 'den-mailbox':
            raise ValueError('only den-mailbox requests are accepted')
    if args == ['ping']:
        print(json.dumps({'host':host,'protocol':1,'timestamp':datetime.datetime.now(datetime.timezone.utc).isoformat(),'automatic_execution':False}))
    elif args == ['put'] or (not remote and args == ['publish']):
        raw = sys.stdin.buffer.read(LIMIT+1)
        msg = validate(raw, host if args == ['put'] else ('arete' if host == 'homie' else 'homie'))
        target = inbox if args == ['put'] else outbox
        state = put(target/(msg['id']+'.json'),raw)
        print(json.dumps({'id':msg['id'],'sha256':hashlib.sha256(raw).hexdigest(),'state':state}))
    elif args == ['list'] or (not remote and args == ['inbox']):
        target = inbox if args == ['inbox'] else outbox
        print(json.dumps(sorted(p.stem for p in target.glob('*.json') if ID.fullmatch(p.stem))))
    elif len(args) == 2 and args[0] in ({'get'} if remote else {'get','read'}) and ID.fullmatch(args[1]):
        raw = read((inbox if args[0]=='read' else outbox)/(args[1]+'.json'))
        validate(raw)
        sys.stdout.buffer.write(raw)
    else:
        raise ValueError('unsupported operation')

if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, TypeError) as exc:
        print('den-mailbox: '+str(exc),file=sys.stderr)
        raise SystemExit(2)
