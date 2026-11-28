import importlib.machinery
import importlib.util
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


setup = load('den_sync_setup', ROOT / 'scripts/setup-den-sync.py')
den = load('den_sync_status', ROOT / 'home/.local/bin/sensei-den')


def test_explicit_data_disk_placement_survives_reconfiguration():
    folder = {'id': 'den-videos'}
    registered = [{'id': 'den-videos', 'path': '/mounted/data/Den/Videos'}]
    assert setup.peer_folder_path(folder, registered) == '/mounted/data/Den/Videos'
    with pytest.raises(ValueError):
        setup.peer_folder_path(folder, registered + registered)


@pytest.mark.parametrize('state,errors,needed,healthy', [
    ('idle', 0, 0, True),
    ('idle', 58, 0, False),
    ('idle', 0, 12, False),
    ('error', 0, 0, False),
    (None, 0, None, False),
])
def test_sync_health_requires_known_complete_error_free_state(tmp_path, monkeypatch, state, errors, needed, healthy):
    monkeypatch.setattr(den, 'read', lambda path: {'folders': [
        {'id': 'learning', 'label': 'Learning', 'path': str(tmp_path), 'floorGiB': 20},
    ]})
    monkeypatch.setattr(den, 'service', lambda name: 'active')
    monkeypatch.setattr(den, 'sync_api', lambda *args: {
        'state': state, 'pullErrors': errors, 'needFiles': needed,
    })
    result = den.sync_status()
    assert result['healthy'] is healthy
    assert result['completion'][0]['pullErrors'] == errors
