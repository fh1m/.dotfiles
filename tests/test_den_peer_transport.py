import importlib.machinery
import importlib.util
import json
from pathlib import Path
import subprocess

import pytest

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('den_peer_runtime', str(ROOT / 'home/.local/bin/sensei-den'))
spec = importlib.util.spec_from_loader(loader.name, loader)
den = importlib.util.module_from_spec(spec)
loader.exec_module(den)


@pytest.fixture
def peer(tmp_path, monkeypatch):
    script = tmp_path / 'ssh-fixture'
    behavior = tmp_path / 'behavior.json'
    receipts = tmp_path / 'receipts.jsonl'
    script.write_text('''#!/usr/bin/env python3
import json,os,pathlib,shlex,subprocess,sys
root=pathlib.Path(__file__).parent
state=json.loads((root/'behavior.json').read_text())
args=sys.argv[1:]
alias=next(a for a in args if a in ('homie','homie-remote','arete-den-control','arete-remote'))
operation=args[-1]
words=shlex.split(operation)
probe=operation=='hostname' or (len(words)==2 and pathlib.Path(words[0]).name=='den-control' and words[1]=='ping')
fresh='-S' in args and args[args.index('-S')+1]=='none'
with (root/'receipts.jsonl').open('a') as stream:stream.write(json.dumps({'alias':alias,'probe':probe,'operation':operation})+'\\n')
if probe:
 if fresh and not state.get(alias,False):raise SystemExit(255)
 if state.get('executeProbe'):
  result=subprocess.run(['/bin/sh','-c',operation],env=dict(os.environ,PATH='/usr/bin:/bin'))
  raise SystemExit(result.returncode)
 name=state.get('identity','homie')
 print(json.dumps({'host':name,'serverAddress':state.get('serverAddress')}) if 'den-control' in operation or args[-2:]==['den-control','ping'] else name)
else:
 with (root/'effects').open('a') as stream:stream.write(operation+'\\n')
 raise SystemExit(state.get('operationExit',0))
''')
    script.chmod(0o700)
    behavior.write_text(json.dumps({'homie': False, 'homie-remote': True}))
    monkeypatch.setattr(den, 'CONFIG', tmp_path / 'config')
    monkeypatch.setattr(den, 'STATE', tmp_path / 'state')
    monkeypatch.setattr(den, 'PRIVATE', tmp_path / 'private')
    monkeypatch.setattr(den, 'host', lambda: 'arete')
    den.write(den.CONFIG / 'access.json', {'privateAlias': 'homie-remote'})
    def execute(args, timeout=10, **kwargs):
        return subprocess.run([str(script), *args[1:]], capture_output=True, text=True, timeout=timeout, **kwargs)
    monkeypatch.setattr(den, 'run', execute)
    return tmp_path, behavior, receipts


def test_authenticated_private_route_survives_lan_discovery_failure(peer):
    root, _, receipts = peer
    assert den.connectivity()
    den.remote(['record', 'literal $HOME and spaces'])
    rows = [json.loads(line) for line in receipts.read_text().splitlines()]
    operations = [row for row in rows if not row['probe']]
    assert len(operations) == 1
    assert operations[0]['alias'] == 'homie-remote'
    assert (root / 'effects').read_text() == "record 'literal $HOME and spaces'\n"


def test_failed_command_is_not_replayed_after_its_effect(peer):
    root, behavior, _ = peer
    behavior.write_text(json.dumps({'homie': True, 'homie-remote': True, 'operationExit': 255}))
    with pytest.raises(ValueError):
        den.remote(['record', 'one effect only'])
    assert (root / 'effects').read_text().splitlines() == ["record 'one effect only'"]


def test_fresh_health_does_not_accept_a_cached_connection(peer):
    _, behavior, receipts = peer
    assert den.connectivity()
    behavior.write_text(json.dumps({'homie': False, 'homie-remote': False}))
    assert not den.connectivity()


def test_wrong_host_never_receives_the_requested_operation(peer):
    root, behavior, _ = peer
    behavior.write_text(json.dumps({'homie': True, 'homie-remote': True, 'identity': 'unrelated-host'}))
    with pytest.raises(ValueError):
        den.remote(['record', 'must not execute'])
    assert not (root / 'effects').exists()


def test_private_reachability_does_not_enable_away_laptop_capture(peer):
    assert den.connectivity()
    assert den.current_mode(True)['effective'] == 'away'


def test_only_fresh_lan_receipt_enables_automatic_together_mode(peer):
    import time
    den.write(den.STATE / 'peer-route.json', {
        'peer': 'homie', 'available': True, 'at': time.time(), 'lanAddress': '192.168.9.12',
    })
    assert den.current_mode(True)['effective'] == 'together'
    den.write(den.STATE / 'peer-route.json', {
        'peer': 'homie', 'available': True, 'at': time.time() - 90, 'lanAddress': '192.168.9.12',
    })
    assert den.current_mode(True)['effective'] == 'away'


def test_noninteractive_peer_shell_needs_no_user_path_setup(peer, monkeypatch):
    root, behavior, _ = peer
    home = root / 'paired home'
    helper = home / '.local/bin/den-control'
    helper.parent.mkdir(parents=True)
    source = ROOT / 'home/.local/bin/den-control'
    helper.write_text('#!/usr/bin/python3\n'
                      'import importlib.machinery,importlib.util\n'
                      f'loader=importlib.machinery.SourceFileLoader("peer_control",{str(source)!r})\n'
                      'spec=importlib.util.spec_from_loader(loader.name,loader)\n'
                      'control=importlib.util.module_from_spec(spec);loader.exec_module(control)\n'
                      'control.socket.gethostname=lambda:"homie"\n'
                      'control.main()\n')
    helper.chmod(0o700)
    monkeypatch.setattr(den, 'HOME', home)
    behavior.write_text(json.dumps({'homie': True, 'homie-remote': True, 'executeProbe': True}))
    assert den.connectivity()
    assert not (root / 'effects').exists()


def test_presence_ignores_transient_and_unknown_links_then_reports_one_transition():
    step = den.presentation_presence
    state = step(True, {}, 0)
    state = step(False, state, 15)
    state = step(None, state, 30)
    assert state == {'joined': True}
    state = step(False, state, 45)
    assert step(False, state, 60)['joined']
    state = step(False, state, 76)
    assert state == {'joined': False, 'eventAt': 76}
    assert step(False, state, 90) == state
    assert step(True, step(True, state, 105), 136) == {'joined': True, 'eventAt': 136}
