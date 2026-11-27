#!/usr/bin/env python3
"""Install root-owned, pinned-identity Den DHCP reconciliation; no new ports or keys."""
import argparse,ipaddress,json,os,pwd,shutil,socket,subprocess,time
from pathlib import Path

def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--user',default=os.environ.get('SUDO_USER'));parser.add_argument('--apply',action='store_true');args=parser.parse_args()
 if os.geteuid()!=0 or socket.gethostname().split('.')[0]!='arete':parser.error('Run as root on Arete')
 if not args.user or args.user=='root':parser.error('Specify the desktop user')
 home=Path(pwd.getpwnam(args.user).pw_dir);repo=Path(__file__).resolve().parents[1]
 known=home/'.local/state/homie-control/known_hosts'
 pins=[line for line in known.read_text().splitlines() if line.split() and 'homie-den' in line.split()[0].split(',')]
 if not pins:raise ValueError('Existing verified homie-den host-key pin is required')
 address=ipaddress.IPv4Address(socket.gethostbyname('homie.local'))
 routes=json.loads(subprocess.check_output(['ip','-j','-4','route','show','scope','link'],text=True))
 networks=[ipaddress.IPv4Network(row['dst']) for row in routes if row.get('dst') and row['dst']!='default' and address in ipaddress.IPv4Network(row['dst'])]
 if not networks:raise ValueError('The paired hostname has no directly connected LAN route')
 network=max(networks,key=lambda n:n.prefixlen)
 cfg={'hostname':'homie.local','expectedHost':'homie','network':str(network),'user':args.user,'identityFile':str(home/'.local/state/homie-control/operator_ed25519'),'hostKeyAlias':'homie-den','knownHostsFile':'/usr/local/share/sensei-den/known_hosts'}
 if not args.apply:print(json.dumps({'ready':True,'peer':cfg['hostname'],'scope':'Existing Den set only; host-key verified DHCP updates'}));return
 backup=Path('/var/backups/sensei-den-peer')/str(time.time_ns());backup.mkdir(parents=True,mode=0o700)
 def install(target,data,mode):
  target=Path(target)
  if target.exists():
   saved=backup/str(target).lstrip('/');saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,saved)
  fresh=not target.parent.exists()
  target.parent.mkdir(parents=True,exist_ok=True)
  if fresh:target.parent.chmod(0o755)
  target.write_bytes(data);target.chmod(mode)
 install('/usr/local/share/sensei-den/known_hosts',('\n'.join(pins)+'\n').encode(),0o644)
 install('/etc/sensei-den/peer.json',json.dumps(cfg,indent=2).encode(),0o600)
 install('/usr/local/libexec/den-peer-firewall.py',(repo/'scripts/reconcile-den-peer.py').read_bytes(),0o755)
 for suffix in ('service','path','timer'):
  name='den-peer-firewall.'+suffix;data=(repo/'system/etc/systemd/system'/name).read_text().replace('@HOME@',str(home)).encode()
  install('/etc/systemd/system/'+name,data,0o644)
 subprocess.run(['systemctl','daemon-reload'],check=True)
 subprocess.run(['systemctl','enable','--now','den-peer-firewall.path','den-peer-firewall.timer'],check=True)
 subprocess.run(['systemctl','start','den-peer-firewall.service'],check=True)
 print(json.dumps({'installed':True,'peer':'homie.local','backup':str(backup)}))
if __name__=='__main__':main()
