#!/usr/bin/env python3
"""Give Avahi announcement ownership; preserve DNS, DHCP and host-key policy."""
import argparse
import ipaddress
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import time


def command(args):
    return subprocess.run(args, capture_output=True, text=True, check=True, timeout=30)

def mdns_hosts(text):
    lines = text.splitlines(keepends=True)
    matches = [i for i, line in enumerate(lines) if line.startswith('hosts:')]
    if len(matches) != 1:
        raise ValueError('Ambiguous NSS hosts policy preserved')
    index = matches[0]
    body, marker, comment = lines[index].partition('#')
    tokens = body.split()[1:]
    if any(token.startswith('mdns') for token in tokens):
        return text
    position = next((i for i, token in enumerate(tokens) if token in ('resolve', 'dns')), 0)
    tokens[position:position] = ['mdns_minimal', '[NOTFOUND=return]']
    lines[index] = 'hosts: ' + ' '.join(tokens) + (' #' + comment.rstrip() if marker else '') + '\n'
    return ''.join(lines)



def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1] / 'pc/den/den-mdns-resolve.conf'
    target = Path('/etc/systemd/resolved.conf.d/90-den-mdns.conf')
    routes = json.loads(command(['ip', '-j', '-4', 'route', 'show', 'default']).stdout)
    interfaces = {row['dev'] for row in routes if row.get('dev') and row['dev'] != 'tailscale0'}
    addresses = json.loads(command(['ip', '-j', '-4', 'address']).stdout)
    networks = sorted({(row['ifname'], str(ipaddress.ip_network(f"{a['local']}/{a['prefixlen']}", strict=False)))
                       for row in addresses if row['ifname'] in interfaces
                       for a in row.get('addr_info', []) if a.get('family') == 'inet'
                       and ipaddress.ip_address(a['local']).is_private
                       and not ipaddress.ip_address(a['local']).is_loopback})
    plan = {'hostname': socket.gethostname().split('.')[0], 'target': str(target),
            'announcementOwner': 'Avahi', 'resolved': 'unicast DNS only', 'lanDiscovery': networks,
            'firewall': 'Add scoped UDP 5353 only when UFW is already active', 'apply': args.apply}
    if not args.apply:
        print(json.dumps(plan)); return
    if os.geteuid() != 0:
        raise PermissionError('Apply requires explicit sudo; preview needs none')
    if target.is_symlink() or (target.exists() and not target.is_file()):
        raise ValueError('Unexpected resolver override preserved')
    backup = Path('/var/lib/sensei-den/discovery-backups') / (time.strftime('%Y%m%d-%H%M%S') + '-' + str(os.getpid()))
    backup.mkdir(parents=True, mode=0o700)
    if target.exists(): shutil.copy2(target, backup / target.name)
    nss = Path('/etc/nsswitch.conf')
    if nss.is_symlink() or not Path('/usr/lib/libnss_mdns_minimal.so.2').is_file():
        raise ValueError('A regular NSS policy and installed nss-mdns are required')
    previous_nss = nss.read_text()
    next_nss = mdns_hosts(previous_nss)
    shutil.copy2(nss, backup / 'nsswitch.conf')
    if Path('/etc/ufw').is_dir(): shutil.copytree('/etc/ufw', backup / 'ufw', symlinks=True)
    changed = not target.exists() or target.read_bytes() != source.read_bytes()
    if changed:
        command(['install', '-D', '-m', '0644', str(source), str(target)])
    nss_changed = next_nss != previous_nss
    if nss_changed:
        stage = backup / 'nsswitch.next'
        stage.write_text(next_nss)
        command(['install', '-m', '0644', str(stage), str(nss)])
    rules = []
    if shutil.which('ufw') and command(['ufw', 'status']).stdout.startswith('Status: active'):
        for interface, network in networks:
            command(['ufw', 'allow', 'in', 'on', interface, 'from', network, 'to', 'any',
                     'port', '5353', 'proto', 'udp', 'comment', 'Den link-local discovery'])
            rules.append({'interface': interface, 'network': network})
    if changed or nss_changed:
        command(['systemctl', 'restart', 'systemd-resolved.service'])
        command(['systemctl', 'restart', 'avahi-daemon.service'])
    plan.update(changed=changed, nssChanged=nss_changed, firewallRules=rules, backup=str(backup))
    print(json.dumps(plan))


if __name__ == '__main__':
    main()
