import importlib.machinery
import importlib.util
import ipaddress
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('den_direct_connector', str(ROOT / 'home/.local/bin/den-peer-connect'))
spec = importlib.util.spec_from_loader(loader.name, loader)
peer = importlib.util.module_from_spec(spec)
loader.exec_module(peer)


def test_native_endpoint_must_belong_to_expected_node_and_connected_lan():
    node = {'TailscaleIPs': ['100.64.0.2']}
    ping = {'NodeName': 'homie', 'NodeIP': '100.64.0.2', 'Endpoint': '192.168.9.12:41641', 'Err': ''}
    networks = [ipaddress.ip_network('192.168.9.0/24')]
    assert peer.direct_endpoint(node, ping, 'homie', networks) == '192.168.9.12'
    for changed in [dict(NodeName='other-host'), dict(NodeIP='100.64.0.3'),
                    dict(Endpoint='203.0.113.12:41641'), dict(Endpoint='192.168.8.12:41641'),
                    dict(Endpoint='127.0.0.1:41641'), dict(Err='peer unavailable')]:
        assert peer.direct_endpoint(node, dict(ping, **changed), 'homie', networks) is None


def test_overlay_and_container_networks_are_not_direct_lan_candidates():
    def interface(name, address, flags=('UP',)):
        return {'ifname': name, 'flags': flags, 'addr_info': [
            {'family': 'inet', 'local': address, 'prefixlen': 24},
        ]}
    networks = peer.local_networks([
        interface('wlan0', '192.168.9.10'), interface('tailscale0', '100.64.0.1'),
        interface('docker0', '172.17.0.1'), interface('enp5s0', '192.168.8.10', ()),
    ])
    assert networks == [ipaddress.ip_network('192.168.9.0/24')]


def test_ambiguous_peer_names_do_not_select_an_arbitrary_node():
    row = {'HostName': 'homie', 'TailscaleIPs': ['100.64.0.2']}
    assert peer.peer_node({'Peer': {'a': row, 'b': dict(row)}}, 'homie') is None
    named = dict(row, DNSName='homie.private.example.')
    assert peer.peer_node({'Peer': {'a': named, 'b': dict(row, DNSName='homie-1.private.example.')}}, 'homie') == named
