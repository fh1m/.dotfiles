#!/usr/bin/env python3
"""Persist Arete's paired-peer rules in its existing nftables firewall only."""
import argparse
import ipaddress
import json
import os
from pathlib import Path
import pwd
import shutil
import socket
import subprocess
import time
import sys


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');args=p.parse_args()
    if os.geteuid()!=0 or socket.gethostname().split('.')[0]!='arete':raise SystemExit('Run as root on Arete only')
    home=Path(pwd.getpwnam('fh1m').pw_dir);cfg=json.loads((home/'.config/sensei-den/access.json').read_text())
    hostname=cfg.get('lanHost','homie.local')
    address=ipaddress.IPv4Address(socket.gethostbyname(hostname))
    if not address.is_private or address.is_unspecified or address.is_loopback:raise SystemExit('Expected a private peer address')
    probe=subprocess.run(['runuser','-u','fh1m','--','ssh','-S','none','-n','-F',str(home/'.local/state/homie-control/client.conf'),'-o','HostName='+str(address),'homie','hostname'],capture_output=True,text=True,timeout=8)
    if probe.returncode or probe.stdout.strip().split('.')[0]!='homie':raise SystemExit('Named peer failed pinned SSH verification; firewall unchanged')
    if not args.apply:print('Pair one private peer: SSH, authenticated input, isolated ROS domain 83; preserve Docker tables');return
    source=Path(__file__).resolve().parents[1]/'system/etc/nftables.conf';dest=Path('/etc/nftables.conf')
    backup=home/'.local/state/homie-control/backups'/('firewall-'+str(int(time.time())));backup.mkdir(parents=True,mode=0o700)
    shutil.copy2(dest,backup/'nftables.conf')
    old=subprocess.check_output(['nft','list','table','inet','sensei_fw'])
    rollback=backup/'runtime.nft';rollback.write_bytes(b'add table inet sensei_fw\ndelete table inet sensei_fw\n'+old)
    peers=Path('/etc/nftables.d/den-peers-local.nft');peers.parent.mkdir(exist_ok=True)
    previous=peers.read_bytes() if peers.exists() else None
    peers.write_text('add element inet sensei_fw den_peers4 { '+str(address)+' }\n');peers.chmod(0o600)
    dropin=Path('/etc/systemd/system/nftables.service.d/den-no-global-flush.conf')
    old_dropin=dropin.read_bytes() if dropin.exists() else None
    try:
        subprocess.run(['nft','-c','-f',str(source)],check=True)
        shutil.copy2(source,dest)
        # Keep this oneshot active. Without RemainAfterExit, ExecStop would run
        # immediately after loading the rules on distributions whose unit omits it.
        dropin.parent.mkdir(parents=True,exist_ok=True)
        dropin.write_text('[Service]\nRemainAfterExit=yes\nExecStop=\nExecStop=/usr/bin/nft delete table inet sensei_fw\n')
        subprocess.run(['systemctl','daemon-reload'],check=True)
        subprocess.run(['nft','-f',str(dest)],check=True)
        # Existing Docker state must remain readable through the operator account.
        subprocess.run(['runuser','-u','fh1m','--','docker','info','--format','{{.ServerVersion}}'],check=True,stdout=subprocess.DEVNULL)
        subprocess.run(['systemctl','enable','--now','nftables'],check=True)
    except BaseException:
        shutil.copy2(backup/'nftables.conf',dest)
        if previous is None:peers.unlink(missing_ok=True)
        else:peers.write_bytes(previous)
        if old_dropin is None:dropin.unlink(missing_ok=True)
        else:dropin.write_bytes(old_dropin)
        subprocess.run(['systemctl','daemon-reload'],check=False)
        subprocess.run(['nft','-f',str(rollback)],check=False)
        raise
    print('Paired-peer firewall persisted; Docker tables preserved; nftables enabled for next boot')
    subprocess.run([sys.executable,str(Path(__file__).with_name('install-den-peer-reconcile.py')),'--apply','--user','fh1m'],check=True)


if __name__=='__main__':main()
