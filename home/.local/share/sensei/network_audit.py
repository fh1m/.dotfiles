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

def interface_name(name):
 import re
 if not re.fullmatch(r'[A-Za-z0-9_.:-]{1,32}',name or '') or not ( __import__('pathlib').Path('/sys/class/net')/name).exists():raise ValueError('Choose an existing interface')
 return name

def hostname(value):
 import re
 if not value or len(value)>253 or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.:-]*',value):raise ValueError('Use a hostname or IP address, without a URL or command flags')
 return value

def diagnostic(action,interface=None,host=None):
 import socket,urllib.request,time
 if action=='public':
  with urllib.request.urlopen('https://ipinfo.io/json',timeout=7) as response:
   raw=response.read(131073)
   if len(raw)>131072:raise ValueError('Provider response exceeded the bounded limit')
   data=json.loads(raw)
   if not isinstance(data,dict):raise ValueError('Provider response was not an object')
  return {'kind':'Public egress / ASN','data':{k:data.get(k) for k in ['ip','hostname','city','region','country','org','timezone']},'note':'Requested from ipinfo.io. Organization is the observed egress network; VPNs and carrier NAT can differ from your billing ISP.'}
 if action=='resolve':
  name=hostname(host or 'example.com');start=time.monotonic()
  text=command(['getent','ahosts',name],timeout=6)
  return {'kind':'System DNS','host':name,'addresses':sorted({line.split()[0] for line in text.splitlines()})[:30],'elapsedMs':round((time.monotonic()-start)*1000),'note':'Uses the same system resolver as ordinary applications.'}
 if action=='trace':
  name=hostname(host or '1.1.1.1')
  if not shutil.which('tracepath'):raise ValueError('tracepath is unavailable; install iputils')
  r=subprocess.run(['tracepath','-n','-m','12',name],capture_output=True,text=True,timeout=15)
  return {'kind':'Route path','host':name,'result':r.stdout[-10000:] or r.stderr[-1000:],'note':'Routers can suppress replies; missing hops do not prove the internet is down.'}
 if action=='link':
  name=interface_name(interface);data=json.loads(command(['ip','-s','-j','link','show','dev',name]))
  details=''
  if shutil.which('ethtool'):
   r=subprocess.run(['ethtool',name],capture_output=True,text=True,timeout=4);details=r.stdout[-10000:] or r.stderr[-1000:]
  return {'kind':'Link / driver counters','interface':name,'links':data,'physical':details,'note':'Counters are since interface creation, not current traffic rate. Unsupported driver fields remain unavailable.'}
 if action=='health':
  name=interface_name(interface);routes=json.loads(command(['ip','-j','route','show','dev',name]));gateway=next((r.get('gateway') for r in routes if r.get('dst')=='default'),None);checks=[]
  for label,address in [('Gateway',gateway),('Public IP','1.1.1.1')]:
   if not address:checks.append({'name':label,'state':'unavailable','detail':'No IPv4 gateway on this interface'});continue
   r=subprocess.run(['ping','-n','-I',name,'-c','3','-W','1',address],capture_output=True,text=True,timeout=6)
   checks.append({'name':label,'state':'reply' if r.returncode==0 else 'no reply','detail':r.stdout[-2200:] or r.stderr[-1000:]})
  try:checks.append({'name':'DNS','state':'resolved','detail':diagnostic('resolve',host='example.com')})
  except (OSError,ValueError,subprocess.SubprocessError) as error:checks.append({'name':'DNS','state':'failed','detail':str(error)})
  return {'kind':'Connectivity checks','interface':name,'checks':checks,'note':'ICMP can be blocked. A missing reply alone is not proof of lost connectivity; DNS follows the system route.'}
 raise ValueError('Unknown network diagnostic')
