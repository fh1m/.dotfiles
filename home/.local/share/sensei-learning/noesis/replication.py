"""Inspect existing private Syncthing replicas; do not sync caches or credentials."""
import json,re,urllib.request,urllib.parse,xml.etree.ElementTree as ET
from pathlib import Path
IGNORE=['.git','(?d).obsidian/plugins/*/data.json','(?d).obsidian/workspace*.json','(?d).obsidian/cache','(?d).noesis-*','(?d).creating-*','(?d).ink-*','(?d).preview-*','(?d).preview.json','node_modules','__pycache__']
def api(method,path,body=None):
 p=Path.home()/'.local/state/syncthing/config.xml';tree=ET.parse(p).getroot();address=tree.findtext('gui/address');key=tree.findtext('gui/apikey')
 if not address or not re.fullmatch(r'127\.0\.0\.1:\d+',address):raise ValueError('Syncthing API must remain loopback-only')
 request=urllib.request.Request('http://'+address+'/rest/'+path,data=json.dumps(body).encode() if body is not None else None,headers={'X-API-Key':key,'Content-Type':'application/json'},method=method)
 with urllib.request.urlopen(request,timeout=4) as response:return json.load(response)
def conflicts(root):
 root=Path(root);result=[]
 for p in root.rglob('*sync-conflict*'):
  if not any(x in p.parts for x in ('.git','.stversions')):result.append(str(p.relative_to(root)))
 return sorted(result)
def status():
 folders=[]
 try:
  config=api('GET','config/folders')
  for f in config:
   if not f['id'].startswith('den-vault-'):continue
   s=api('GET','db/status?'+urllib.parse.urlencode({'folder':f['id']}));root=Path(f['path'])
   folders.append({'folder_id':f['id'],'path':str(root),'exists':root.is_dir(),'state':s.get('state'),'pending_files':s.get('needFiles'),'pending_bytes':s.get('needBytes'),'last_scan':s.get('lastScan'),'versioning':f.get('versioning',{}).get('type'),'conflicts':conflicts(root)})
  return {'available':True,'folders':folders,'backup_warning':'Sync is not backup; independent restore-tested snapshots are required'}
 except (OSError,ValueError,ET.ParseError):return {'available':False,'folders':folders,'message':'Syncthing is unavailable; local records remain usable'}
def protect(folder_id):
 folders=api('GET','config/folders');folder=next((f for f in folders if f['id']==folder_id),None)
 if not folder or not folder_id.startswith('den-vault-'):raise ValueError('Choose a known Noesis replica')
 old=api('GET','db/ignores?'+urllib.parse.urlencode({'folder':folder_id}));lines=old.get('ignore',[])
 merged=list(dict.fromkeys(lines+IGNORE));api('POST','db/ignores?'+urllib.parse.urlencode({'folder':folder_id}),{'ignore':merged})
 return {'folder_id':folder_id,'protected':True,'new_patterns':len(merged)-len(lines)}
