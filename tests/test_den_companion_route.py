"""Lease behavior across two disposable Den records, without desktop control."""
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'home/.local/share/sensei'))


def desktop(tmp_path, name, monkeypatch):
    loader = importlib.machinery.SourceFileLoader('companion_' + name, str(ROOT / 'home/.local/bin/sensei-den'))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    module.HOME = tmp_path / name
    module.CONFIG = module.HOME / 'config'
    module.STATE = module.HOME / 'state'
    monkeypatch.setattr(module, 'host', lambda: name)
    monkeypatch.setattr(module, 'companion_available', lambda: [name + '-display'])
    monkeypatch.setattr(module, 'run', lambda *args, **kwargs: subprocess.CompletedProcess(
        [], 0, json.dumps([{'name': name + '-display', 'focused': True}]), ''))
    return module


@pytest.mark.parametrize('action,value', [('roam', 'on'), ('tour', None), ('hide-seek', None)])
def test_location_controls_preserve_reduced_motion(tmp_path, monkeypatch, action, value):
    owner = desktop(tmp_path, 'arete', monkeypatch)
    owner.write(owner.CONFIG / 'companion.json', {'enabled': True, 'reducedMotion': True})
    monkeypatch.setattr(owner, 'companion_tick', lambda *args: None)
    result = owner.companion(action, value)
    assert result['roaming'] is True
    assert result['reducedMotion'] is True


@pytest.mark.parametrize('quiet,suspended', [(False, False), (True, False), (False, True)])
def test_reduced_motion_peer_can_receive_one_exclusive_static_lease(tmp_path, monkeypatch, quiet, suspended):
    owner = desktop(tmp_path, 'arete', monkeypatch)
    peer = desktop(tmp_path, 'homie', monkeypatch)
    owner.write(owner.CONFIG / 'companion.json', {'enabled': True, 'roaming': True})
    peer.write(peer.CONFIG / 'companion.json', {'enabled': True, 'quiet': quiet,
                                             'suspended': suspended, 'reducedMotion': True})
    owner.write(owner.STATE / 'companion-route.json', {'destination': ['arete', 'arete-display'], 'next': 0})

    def remote(argv, **kwargs):
        action, value = argv[2], argv[3] if len(argv) > 3 else None
        if action == 'grant':
            # Authoritative local lease must hide before a remote writer can show.
            assert owner.read(owner.STATE / 'companion-travel.json')['output'] == ''
        return json.dumps(peer.companion(action, value))

    monkeypatch.setattr(owner, 'remote', remote)
    owner.companion_tick(True)
    route = owner.read(owner.STATE / 'companion-route.json')
    if quiet or suspended:
        assert route['destination'] == ['arete', 'arete-display']
        assert not peer.read(peer.STATE / 'companion-travel.json')
    else:
        assert route['destination'] == ['homie', 'homie-display']
        assert peer.read(peer.STATE / 'companion-travel.json')['output'] == 'homie-display'
        assert owner.read(owner.STATE / 'companion-travel.json')['output'] == ''
    assert peer.read(peer.CONFIG / 'companion.json')['reducedMotion'] is True
