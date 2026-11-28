import importlib.util
from pathlib import Path
import tomllib

import pytest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('den_input_config', ROOT / 'home/.local/share/sensei/den_input_config.py')
configurator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(configurator)

SOURCE = '''# My paired devices stay named, never replaced by an anonymous IP.
port = 4242
authorized_fingerprints = ["paired-device-fingerprint"]
[[clients]]
hostname = "homie.local"
position = "top"
[[clients]]
hostname = "homie.local"
position = "right"
[[clients]]
hostname = "another-device.local"
ips = ["192.168.9.99"]
position = "left"
'''


def test_refresh_preserves_pairing_and_user_settings_while_address_changes(tmp_path):
    path = tmp_path / 'config.toml'
    path.write_text(SOURCE)
    result = configurator.refresh(path, home=tmp_path,
                                  resolve=lambda *args: '192.168.9.12', verify=lambda *args: True)
    data = tomllib.loads(path.read_text())
    assert [row['ips'] for row in data['clients']] == [['192.168.9.12'], ['192.168.9.12'], ['192.168.9.99']]
    assert [row['hostname'] for row in data['clients']] == ['homie.local', 'homie.local', 'another-device.local']
    assert data['authorized_fingerprints'] == ['paired-device-fingerprint']
    assert data['port'] == 4242
    assert path.read_text().startswith('# My paired devices stay named')
    assert Path(result['backup']).read_text() == SOURCE
    repeated = configurator.refresh(path, home=tmp_path,
                                    resolve=lambda *args: '192.168.9.12', verify=lambda *args: True)
    assert not repeated['changed']


def test_unverified_identity_never_changes_input_destinations(tmp_path):
    path = tmp_path / 'config.toml'
    path.write_text(SOURCE)
    with pytest.raises(ValueError, match='identity is unverified'):
        configurator.refresh(path, home=tmp_path,
                             resolve=lambda *args: '192.168.9.12', verify=lambda *args: False)
    assert path.read_text() == SOURCE


def test_edit_during_network_verification_is_not_overwritten(tmp_path):
    path = tmp_path / 'config.toml'
    path.write_text(SOURCE)
    user_edit = SOURCE.replace('port = 4242', 'port = 4343')
    def verify(*args):
        path.write_text(user_edit)
        return True
    with pytest.raises(ValueError, match='user edits preserved'):
        configurator.refresh(path, home=tmp_path,
                             resolve=lambda *args: '192.168.9.12', verify=verify)
    assert path.read_text() == user_edit


def test_server_only_configuration_needs_no_peer_discovery(tmp_path):
    path = tmp_path / 'config.toml'
    path.write_text('port = 4242\n')
    def unexpected(*args):
        raise AssertionError('Server-only startup attempted an outbound connection')
    assert configurator.refresh(path, home=tmp_path, resolve=unexpected, verify=unexpected)['clients'] == 0


def test_writable_policy_receipt_cannot_authorize_capture(tmp_path, monkeypatch):
    import json
    import time
    managed = tmp_path / 'managed-policy.json'
    managed.write_text('{}')
    forged = tmp_path / 'peer-status.json'
    forged.write_text(json.dumps({'peer': 'homie', 'address': '192.168.9.12',
                                 'ready': True, 'at': time.time()}))
    forged.chmod(0o666)
    monkeypatch.setattr(configurator, 'POLICY_CONFIG', managed)
    monkeypatch.setattr(configurator, 'POLICY_STATUS', forged)
    with pytest.raises(ValueError, match='capture was not started'):
        configurator.confirm_peer_policy(tmp_path, 'homie', '192.168.9.12', timeout=0.02)
