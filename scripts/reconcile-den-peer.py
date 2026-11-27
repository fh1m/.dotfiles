#!/usr/bin/env python3
"""Update only the existing Den peer firewall set after pinned SSH verification."""
import argparse,ipaddress,json,os,pwd,socket,subprocess,tempfile
from pathlib import Path

CONFIG=Path('/etc/sensei-den/peer.json')
PEERS=Path('/etc/nftables.d/den-peers-local.nft')

class PeerUnavailable(Exception):pass

def run(command):
 return subprocess.run(command,stdin=subprocess.DEVNULL,capture_output=True,text=True,timeout=5)

def atomic(path,data):
 path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
 fd,name=tempfile.mkstemp(prefix='.den-peer-',dir=path.parent)
 try:
  with os.fdopen(fd,'w') as stream:
   os.fchmod(stream.fileno(),0o600);stream.write(data);stream.flush();os.fsync(stream.fileno())
  os.replace(name,path)
 finally:
  if os.path.exists(name):os.unlink(name)

def reconcile(cfg,runner=run,resolver=socket.getaddrinfo,apply=False,peers=PEERS):
 network=ipaddress.IPv4Network(cfg['network']);username=cfg['user'];pwd.getpwnam(username)
 try:candidates=sorted({str(ipaddress.IPv4Address(row[4][0])) for row in resolver(cfg['hostname'],22,socket.AF_INET,socket.SOCK_STREAM) if ipaddress.IPv4Address(row[4][0]) in network})
 except socket.gaierror:raise PeerUnavailable()
 if not candidates:raise PeerUnavailable()
 current=runner(['nft','-j','list','set','inet','sensei_fw','den_peers4'])
 if current.returncode:raise ValueError('Existing Den firewall set unavailable; no policy was changed')
 sets=[item['set'] for item in json.loads(current.stdout)['nftables'] if 'set' in item]
 previous=sets[0].get('elem',[]) if sets else []
 if len(previous)==1 and previous[0] in candidates:return {'state':'unchanged','verifiedChange':False}
 for address in candidates:
  try:probe=runner(['runuser','-u',username,'--','ssh','-4','-n','-F','/dev/null','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','UpdateHostKeys=no','-o','UserKnownHostsFile='+cfg['knownHostsFile'],'-o','HostKeyAlias='+cfg['hostKeyAlias'],'-o','ConnectTimeout=2','-o','ConnectionAttempts=1','-i',cfg['identityFile'],username+'@'+address,'hostname'])
  except subprocess.TimeoutExpired:continue
  if probe.returncode or probe.stdout.strip().split('.')[0]!=cfg['expectedHost']:continue
  if not apply:return {'state':'verified-change','verifiedChange':True}
  old=peers.read_text() if peers.exists() else ''
  transaction='flush set inet sensei_fw den_peers4\nadd element inet sensei_fw den_peers4 { '+address+' }\n'
  # nft consumes one atomic transaction. No other chain/table is replaced.
  with tempfile.NamedTemporaryFile(mode='w',prefix='den-peer-',delete=True) as staged:
   staged.write(transaction);staged.flush()
   checked=runner(['nft','-c','-f',staged.name])
   if checked.returncode:raise ValueError('Peer rule validation failed; original policy retained')
   atomic(peers,'add element inet sensei_fw den_peers4 { '+address+' }\n')
   changed=runner(['nft','-f',staged.name])
   if changed.returncode:
    atomic(peers,old);raise ValueError('Peer rule update failed; original persistent policy restored')
  return {'state':'updated','verifiedChange':True}
 raise PeerUnavailable()

def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--apply',action='store_true');args=parser.parse_args()
 if os.geteuid()!=0:raise ValueError('Run through the installed root-owned service')
 cfg=json.loads(CONFIG.read_text())
 for path in (CONFIG,Path(cfg['knownHostsFile'])):
  st=path.stat()
  if st.st_uid!=0 or st.st_mode&0o022:raise ValueError('Pairing policy must be root-owned and not writable by other users')
 print(json.dumps(reconcile(cfg,apply=args.apply)))
if __name__=='__main__':
 try:main()
 except PeerUnavailable:
  print(json.dumps({'state':'peer-unverified','changed':False,'reason':'Peer unavailable or identity unverified; existing policy retained'}))
 except (OSError,ValueError,KeyError,subprocess.SubprocessError):
  print(json.dumps({'state':'unverified','changed':False,'reason':'Peer discovery or authentication unavailable; existing policy retained'}));raise SystemExit(1)
