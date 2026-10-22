"""Root-only isolated kernel ARP regression; no live interfaces or routes modified."""
import subprocess,uuid,re
suffix=uuid.uuid4().hex[:7];h='denh'+suffix;p='denp'+suffix
names=[]
def run(*args):
 r=subprocess.run(args,capture_output=True,text=True)
 if r.returncode:raise RuntimeError(str(args)+': '+r.stdout+r.stderr)
 return r.stdout
try:
 for n in [h,p]:run('ip','netns','add',n);names.append(n)
 run('ip','-n',p,'link','add','name','denbr0','type','bridge');run('ip','-n',p,'addr','add','192.0.2.1/24','dev','denbr0');run('ip','-n',p,'link','set','denbr0','up')
 for a,b,addr in [('ha0','pa','192.0.2.10/24'),('hb0','pb','192.0.2.11/24')]:
  run('ip','-n',h,'link','add','name',a,'type','veth','peer','name',b);run('ip','-n',h,'link','set',b,'netns',p);run('ip','-n',p,'link','set',b,'master','denbr0');run('ip','-n',p,'link','set',b,'up');run('ip','-n',h,'addr','add',addr,'dev',a);run('ip','-n',h,'link','set',a,'up')
 def probe():
  r=run('ip','netns','exec',p,'arping','-b','-I','denbr0','-c','2','-w','3','192.0.2.11');return set(re.findall(r'\[([0-9A-F:]{17})\]',r))
 before=probe()
 for n in ['ha0','hb0']:
  for key,value in [('arp_ignore','1'),('arp_announce','2')]:run('ip','netns','exec',h,'sysctl','-qw','net.ipv4.conf.'+n+'.'+key+'='+value)
 after=probe();print('Isolated ARP regression: responding MACs before',len(before),'after',len(after));assert len(before)==2 and len(after)==1
finally:
 for n in names:subprocess.run(['ip','netns','delete',n],check=False)
