"""Read-only host diagnostics and explicitly confirmed, bounded private-LAN probes."""
import ipaddress,json,subprocess,shutil,xml.etree.ElementTree as ET
PRIVATE=[ipaddress.ip_network(s) for s in ('10.0.0.0/8','172.16.0.0/12','192.168.0.0/16')]
def command(argv,timeout=5):
 r=subprocess.run(argv,capture_output=True,text=True,timeout=timeout)
 if r.returncode:raise ValueError('Network tool failed: '+argv[0])
 return r.stdout

def scope(interface,addresses=None):
 addresses=addresses if addresses is not None else json.loads(command(['ip','-j','address','show']))
 row=next((r for r in addresses if r.get('ifname')==interface and r.get('operstate')=='UP'),None)
 if not row:raise ValueError('Choose an active local interface')
 for item in row.get('addr_info',[]):
  if item.get('family')!='inet':continue
  addr=ipaddress.ip_address(item['local'])
  if not any(addr in net for net in PRIVATE):continue
  prefix=max(24,int(item['prefixlen']))
  network=ipaddress.ip_network(str(addr)+'/'+str(prefix),strict=False)
  return str(network)
 raise ValueError('No RFC1918 private IPv4 scope on this interface')
def target(interface,address,addresses=None):
 network=ipaddress.ip_network(scope(interface,addresses));addr=ipaddress.ip_address(address)
 if addr.version!=4 or addr not in network or addr in (network.network_address,network.broadcast_address):raise ValueError('Target must be a host in the selected private LAN segment')
 return str(addr)
def inventory():
 dns=''
 if shutil.which('resolvectl'):
  try:dns=command(['resolvectl','status'])[-12000:]
  except (ValueError,subprocess.SubprocessError):dns='Resolver status unavailable'
 return {'interfaces':json.loads(command(['ip','-j','address','show'])),'routes':json.loads(command(['ip','-j','route','show'])),'neighbors':json.loads(command(['ip','-j','neigh','show'])),'sockets':command(['ss','-tunap'])[-16000:],'dns':dns,'note':'Neighbor cache is observed evidence, not a complete router client list. Scans never run during refresh.'}
def scan(interface,address=None):
 cidr=scope(interface);host=target(interface,address) if address else None
 argv=['nmap','-n','--max-retries','1','--host-timeout','12s','-oX','-']
 argv+=['-sT','-Pn','--top-ports','50',host] if host else ['-sn',cidr]
 try:root=ET.fromstring(command(argv,timeout=18))
 except ET.ParseError as error:raise ValueError('Network tool returned an incomplete report; no result was saved') from error
 hosts=[]
 for row in root.findall('host'):
  status=row.find('status')
  if status is None or status.get('state')!='up':continue
  hosts.append({'addresses':[{k:v for k,v in a.attrib.items() if k in ('addr','addrtype','vendor')} for a in row.findall('address')], 'ports':[{'port':p.get('portid'),'protocol':p.get('protocol'),'state':p.find('state').get('state'),'service':p.find('service').get('name') if p.find('service') is not None else None} for p in row.findall('ports/port')]})
 return {'scope':cidr,'target':host,'hosts':hosts,'note':'Bounded unprivileged scan. No scripts, exploitation, packet capture or password testing.'}
