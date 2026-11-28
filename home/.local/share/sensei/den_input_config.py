"""Resolve paired input clients before capture; preserve user TOML and credentials."""
import ipaddress
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import time

import tomlkit

POLICY_CONFIG = Path('/etc/sensei-den/peer.json')
POLICY_STATUS = Path('/run/sensei-den/peer-status.json')



def resolve_peer(home, peer):
    result = subprocess.run([str(home / '.local/bin/den-peer-connect'), peer, '22', '--resolve'],
                            capture_output=True, text=True, check=True, timeout=8)
    return result.stdout.strip()


def verify_peer(home, peer, address):
    result = subprocess.run(['ssh', '-4', '-S', 'none', '-n', '-F',
                             str(home / '.local/state/homie-control/client.conf'),
                             '-o', 'ProxyCommand=none', '-o', 'ProxyJump=none',
                             '-o', 'HostName=' + address, '-o', 'StrictHostKeyChecking=yes',
                             peer, 'hostname'], capture_output=True, text=True, timeout=8)
    return result.returncode == 0 and result.stdout.strip().split('.')[0] == peer

def confirm_peer_policy(home, peer, address, timeout=8):
    try:
        POLICY_CONFIG.stat()
    except FileNotFoundError:
        return  # An unmanaged firewall is not this paired Den policy.
    hint = home / '.local/state/sensei-den/peer-address.json'
    hint.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, name = tempfile.mkstemp(prefix='.peer-hint-', dir=hint.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            os.fchmod(stream.fileno(), 0o600)
            json.dump({'hostname': peer + '.local', 'addresses': [address],
                       'verifiedAt': time.time()}, stream)
        os.replace(name, hint)
    finally:
        if os.path.exists(name):
            os.unlink(name)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            metadata = POLICY_STATUS.lstat()
            if metadata.st_uid == 0 and stat.S_ISREG(metadata.st_mode) and not metadata.st_mode & 0o022:
                result = json.loads(POLICY_STATUS.read_text())
                if not isinstance(result, dict):
                    raise ValueError('Invalid firewall acknowledgement')
                measured = result.get('at', 0)
                if (result.get('ready') is True and result.get('peer') == peer
                        and result.get('address') == address
                        and isinstance(measured, (int, float)) and 0 <= time.time() - measured <= 30):
                    return
        except (OSError, ValueError, TypeError):
            pass
        time.sleep(min(0.05, max(0, deadline - time.monotonic())))
    raise ValueError('Den peer firewall is not confirmed; capture was not started')



def refresh(config, *, home=None, peer='homie', resolve=None, verify=None, require_policy=False):
    config = Path(config)
    home = Path.home() if home is None else Path(home)
    if config.is_symlink() or not config.is_file() or config.stat().st_uid != os.getuid():
        raise ValueError('Input configuration must be an owner-controlled regular file')
    original = config.read_bytes()
    document = tomlkit.parse(original.decode())
    clients = [row for row in document.get('clients', [])
               if row.get('hostname') in (peer, peer + '.local')]
    if not clients:
        return {'changed': False, 'clients': 0}
    address = str(ipaddress.IPv4Address((resolve or resolve_peer)(home, peer)))
    parsed = ipaddress.ip_address(address)
    if not parsed.is_private or parsed.is_loopback or parsed.is_link_local:
        raise ValueError('Input peer must be on the discovered private LAN')
    if not (verify or verify_peer)(home, peer, address):
        raise ValueError('Input peer identity is unverified; capture was not started')
    if require_policy:
        confirm_peer_policy(home, peer, address)
    for client in clients:
        client['ips'] = [address]
    rendered = tomlkit.dumps(document).encode()
    if config.read_bytes() != original:
        raise ValueError('Input configuration changed during discovery; user edits preserved')
    if rendered == original:
        return {'changed': False, 'clients': len(clients), 'address': address}
    backups = config.parent / 'backups'
    backups.mkdir(exist_ok=True, mode=0o700)
    backup = backups / ('config-before-discovery-' + str(time.time_ns()) + '.toml')
    with backup.open('xb') as stream:
        os.fchmod(stream.fileno(), 0o600)
        stream.write(original)
        stream.flush()
        os.fsync(stream.fileno())
    fd, name = tempfile.mkstemp(prefix='.input-config-', dir=config.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            os.fchmod(stream.fileno(), 0o600)
            stream.write(rendered)
            stream.flush()
            os.fsync(stream.fileno())
        if config.read_bytes() != original:
            raise ValueError('Input configuration changed before activation; user edits preserved')
        os.replace(name, config)
        directory = os.open(config.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(name):
            os.unlink(name)
    return {'changed': True, 'clients': len(clients), 'address': address, 'backup': str(backup)}
