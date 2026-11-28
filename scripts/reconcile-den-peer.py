#!/usr/bin/env python3
"""Update only the existing Den peer firewall set after pinned SSH verification."""
import argparse,ipaddress,json,os,pwd,socket,stat,subprocess,tempfile,time
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

def hint_candidates(cfg,network):
 path=cfg.get('hintFile')
 if not path:return []
 try:
  fd=os.open(path,os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK)
  with os.fdopen(fd,'rb') as stream:
   if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):return []
   raw=stream.read(4097)
  if len(raw)>4096:return []
  hint=json.loads(raw)
  if not isinstance(hint,dict) or hint.get('hostname')!=cfg['hostname']:return []
  measured=hint.get('verifiedAt')
  if not isinstance(measured,(int,float)) or not 0<=time.time()-measured<=120:return []
  addresses=hint.get('addresses')
  if not isinstance(addresses,list) or len(addresses)>8:return []
  return sorted({str(ipaddress.IPv4Address(value)) for value in addresses if ipaddress.IPv4Address(value) in network})
 except (OSError,ValueError,TypeError):return []


def reconcile(cfg,runner=run,resolver=socket.getaddrinfo,apply=False,peers=PEERS):
 network=ipaddress.IPv4Network(cfg['network']);username=cfg['user'];pwd.getpwnam(username)
 candidates=hint_candidates(cfg,network)
 if not candidates:
  try:candidates=sorted({str(ipaddress.IPv4Address(row[4][0])) for row in resolver(cfg['hostname'],22,socket.AF_INET,socket.SOCK_STREAM) if ipaddress.IPv4Address(row[4][0]) in network})
  except socket.gaierror:raise PeerUnavailable()
 if not candidates:raise PeerUnavailable()
 current=runner(['nft','-j','list','set','inet','sensei_fw','den_peers4'])
 if current.returncode:raise ValueError('Existing Den firewall set unavailable; no policy was changed')
 sets=[item['set'] for item in json.loads(current.stdout)['nftables'] if 'set' in item]
 previous=sets[0].get('elem',[]) if sets else []
 for address in candidates:
  try:probe=runner(['runuser','-u',username,'--','ssh','-4','-n','-F','/dev/null','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','UpdateHostKeys=no','-o','UserKnownHostsFile='+cfg['knownHostsFile'],'-o','HostKeyAlias='+cfg['hostKeyAlias'],'-o','ConnectTimeout=2','-o','ConnectionAttempts=1','-i',cfg['identityFile'],username+'@'+address,'hostname'])
  except subprocess.TimeoutExpired:continue
  if probe.returncode or probe.stdout.strip().split('.')[0]!=cfg['expectedHost']:continue
  if len(previous)==1 and previous[0]==address:
   return {'state':'unchanged','verifiedChange':False,'identityVerified':True,'address':address}
  if not apply:return {'state':'verified-change','verifiedChange':True,'identityVerified':True,'address':address}
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
  return {'state':'updated','verifiedChange':True,'identityVerified':True,'address':address}
 raise PeerUnavailable()

def publish_status(cfg,result):
 directory=Path('/run/sensei-den')
 if directory.is_symlink():raise ValueError('Unexpected runtime status directory')
 directory.mkdir(mode=0o755,exist_ok=True)
 metadata=directory.stat()
 if metadata.st_uid!=0 or metadata.st_mode&0o022:raise ValueError('Runtime status directory must be root-owned')
 path=directory/'peer-status.json'
 if path.is_symlink():raise ValueError('Unexpected runtime status link')
 data={'peer':cfg['expectedHost'],'address':result.get('address'),'ready':result.get('identityVerified') is True and result['state'] in ('unchanged','updated'),
       'state':result['state'],'at':time.time()}
 atomic(path,json.dumps(data)+'\n');path.chmod(0o644)


def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--apply',action='store_true');args=parser.parse_args()
 if os.geteuid()!=0:raise ValueError('Run through the installed root-owned service')
 cfg=json.loads(CONFIG.read_text())
 for path in (CONFIG,Path(cfg['knownHostsFile'])):
  st=path.stat()
  if st.st_uid!=0 or st.st_mode&0o022:raise ValueError('Pairing policy must be root-owned and not writable by other users')
 try:result=reconcile(cfg,apply=args.apply)
 except PeerUnavailable:result={'state':'peer-unverified','changed':False,'reason':'Peer unavailable or identity unverified; existing policy retained'}
 publish_status(cfg,result)
 print(json.dumps(result))
if __name__=='__main__':
 try:main()
 except (OSError,ValueError,KeyError,subprocess.SubprocessError):
  print(json.dumps({'state':'unverified','changed':False,'reason':'Peer discovery or authentication unavailable; existing policy retained'}));raise SystemExit(1)
