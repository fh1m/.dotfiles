#!/usr/bin/env python3
"""Scoped Noesis deployment and hash-checked rollback; dry run by default."""
import argparse,datetime,hashlib,importlib.util,json,os,shutil,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('installer',ROOT/'scripts/install.py');installer=importlib.util.module_from_spec(spec);spec.loader.exec_module(installer)
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() and not path.is_symlink() else None
def files(bridge=False):
 prefixes=['.local/share/sensei-learning/catalogs','.config/quickshell/noesis','.local/share/sensei-learning/ui','.local/share/sensei-learning/noesis','.local/share/sensei-learning/examples']
 exact=['.config/quickshell/sensei/services/NoesisBridge.qml','.config/quickshell/sensei/modules/bar/ArchiveButton.qml','.config/quickshell/sensei/services/CalendarDesk.qml','.config/systemd/user/sensei-noesis-sources.service','.config/systemd/user/sensei-noesis-sources.timer','.local/bin/sensei-calendar','.local/share/sensei/agenda.py','.local/bin/sensei-learning-backup','.local/bin/sensei-draw','.local/share/sensei/drawing.py','.local/bin/sensei-learn','.local/bin/noesis','.local/share/applications/org.fh1m.Noesis.desktop','.local/share/icons/hicolor/scalable/apps/org.fh1m.Noesis.svg']
 if bridge:
  prefixes+=['.config/quickshell/sensei/modules/learning']
  exact+=['.config/quickshell/sensei/services/Oasis.qml','.config/quickshell/sensei/services/NoesisBridge.qml','.config/quickshell/sensei/shell.qml','.config/quickshell/sensei/modules/bar/ArchiveButton.qml','.config/quickshell/sensei/modules/bar/BottomBar.qml','.config/hypr/oasis.lua','.config/quickshell/sensei/services/Spaces.qml','.config/quickshell/sensei/services/WindowDesk.qml','.config/quickshell/sensei/modules/navigation/NavigationOverlay.qml','.config/quickshell/sensei/modules/navigation/WorkspacePreview.qml']
 return sorted(p for p in (ROOT/'home').rglob('*') if p.is_file() and '__pycache__' not in p.parts and p.suffix!='.pyc' and (str(p.relative_to(ROOT/'home')) in exact or any(str(p.relative_to(ROOT/'home')).startswith(prefix+'/') for prefix in prefixes)))

def relative(value):
 if not isinstance(value,str):raise ValueError('Invalid manifest path')
 p=Path(value)
 if p.is_absolute() or not p.parts or any(x in ('','.','..') for x in p.parts) or p.as_posix()!=value:raise ValueError('Invalid manifest path')
 return p
def safe_parents(home,rel):
 cur=home
 for part in rel.parts[:-1]:
  cur=cur/part
  if cur.is_symlink():raise ValueError('Symlink parent: '+str(cur))
def trusted_home(home):
 if not home.is_absolute() or home==Path('/') or home!=home.resolve() or home.stat().st_uid!=os.getuid():raise ValueError('Untrusted home')
def write_manifest(path,value):
 temp=path.with_name(path.name+'.tmp')
 if temp.exists() or temp.is_symlink():raise ValueError('Existing manifest staging file')
 with temp.open('x') as stream:
  stream.write(json.dumps(value,indent=2));stream.flush();os.fsync(stream.fileno())
 temp.chmod(0o600);temp.replace(path)
def rollback_data(manifest,expected_home):
 if Path(manifest).is_symlink():raise ValueError('Symlink manifest')
 manifest=Path(manifest).resolve();value=json.loads(manifest.read_text())
 if not isinstance(value,dict) or set(value)!={'version','home','entries'} or type(value['version']) is not int or value['version']!=1 or not isinstance(value['home'],str) or not isinstance(value['entries'],list):raise ValueError('Invalid rollback manifest')
 home=Path(value['home']);trusted_home(home)
 if home!=expected_home.resolve():raise ValueError('Manifest home does not match selected home')
 if manifest.stat().st_uid!=os.getuid():raise ValueError('Untrusted manifest owner')
 safe_parents(home,Path('.local/state/noesis-deployments/placeholder/manifest.json'))
 backup_root=home/'.local/state/noesis-deployments'
 if not manifest.is_relative_to(backup_root.resolve()) or manifest.name!='manifest.json':raise ValueError('Manifest outside deployment backup')
 safe_parents(home,manifest.relative_to(home));validated=[];seen=set()
 for e in value['entries']:
  base_keys={'path','before','after_link','after_sha256'}
  optional={'before_sha256','before_link'}
  if not isinstance(e,dict) or set(e)-base_keys-optional or not base_keys<=set(e) or e['before'] not in ('absent','file','symlink') or (e['after_link'] is not None and not isinstance(e['after_link'],str)) or (e['after_sha256'] is not None and (not isinstance(e['after_sha256'],str) or len(e['after_sha256'])!=64)) or ((e['after_link'] is None)==(e['after_sha256'] is None)):raise ValueError('Invalid manifest entry')
  rel=relative(e['path'])
  if e['path'] in seen:raise ValueError('Duplicate manifest path')
  seen.add(e['path']);safe_parents(home,rel);dest=home/rel;old=manifest.parent/'files'/rel
  safe_parents(home,Path('.local/state/noesis-deployments/'+manifest.parent.name+'/files').joinpath(rel))
  if e['before']=='file' and (old.is_symlink() or not old.is_file()):raise ValueError('Missing file backup')
  if e['before']=='symlink' and not old.is_symlink():raise ValueError('Missing symlink backup')
  prior_hash=digest(old) if e['before']=='file' else None
  prior_link=os.readlink(old) if e['before']=='symlink' else None
  if e.get('before_sha256') is not None and e['before_sha256']!=prior_hash:raise ValueError('Preimage backup hash mismatch')
  if e.get('before_link') is not None and e['before_link']!=prior_link:raise ValueError('Preimage backup link mismatch')
  if 'before_sha256' in e and ((e['before']=='file') != (e['before_sha256'] is not None)):raise ValueError('Invalid preimage hash field')
  if 'before_link' in e and ((e['before']=='symlink') != (e['before_link'] is not None)):raise ValueError('Invalid preimage link field')
  prior=(e['before']=='absent' and not dest.exists() and not dest.is_symlink()) or (e['before']=='file' and dest.is_file() and not dest.is_symlink() and digest(dest)==prior_hash) or (e['before']=='symlink' and dest.is_symlink() and os.readlink(dest)==prior_link)
  installed=dest.is_symlink() and e['after_link'] is not None and os.readlink(dest)==e['after_link'] or not dest.is_symlink() and e['after_link'] is None and digest(dest)==e['after_sha256']
  if prior:state='before'
  elif installed:state='installed'
  else:raise ValueError('Target is neither preimage nor installed state: '+str(dest))
  validated.append((e,dest,old,state))
 return home,validated
def install(home,apply=False,bridge=False):
 if os.geteuid()==0:raise PermissionError('Refusing deployment as root')
 home=home.resolve();trusted_home(home)
 backup=home/'.local/state/noesis-deployments'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
 targets=[(str(p.relative_to(ROOT/'home')),installer.render(p.read_bytes(),home,'zenbook'),p.stat().st_mode&0o777,None) for p in files(bridge)]
 targets.append(('.config/quickshell/noesis/ui',None,None,'../../../.local/share/sensei-learning/ui'))
 if bridge:targets.append(('.config/quickshell/sensei/noesis-ui',None,None,'../../../.local/share/sensei-learning/ui'))
 revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
 hashes={name:hashlib.sha256(data).hexdigest() for name,data,mode,link in targets if data is not None}
 build={'version':1,'commit':revision,'files':hashes,'source_dirty':bool(subprocess.check_output(['git','status','--porcelain','--','home','scripts/install-noesis.py'],cwd=ROOT,text=True).strip())}
 targets.append(('.local/share/sensei-learning/build.json',(json.dumps(build,sort_keys=True,indent=2)+'\n').encode(),0o644,None))
 def phase(target):
  path=target[0]
  if path=='.config/quickshell/sensei/shell.qml':return 4
  if target[3]:return 2
  if path.startswith('.config/quickshell/sensei/'):return 3
  if path.startswith('.local/share/sensei-learning/noesis/'):return 0
  return 1
 targets.sort(key=phase);changes=[]
 for name,data,mode,link in targets:
  rel=relative(name);dest=home/rel;safe_parents(home,rel)
  if link and dest.is_symlink() and os.readlink(dest)==link:continue
  if data is not None and dest.is_file() and not dest.is_symlink() and dest.read_bytes()==data:continue
  if dest.is_dir() and not dest.is_symlink():raise ValueError('Refusing to replace directory: '+str(dest))
  if dest.is_symlink() and not (link is not None or dest.is_file()):raise ValueError('Refusing unsupported symlink target: '+str(dest))
  before='symlink' if dest.is_symlink() else 'file' if dest.is_file() else 'absent'
  entry={'path':name,'before':before,'before_sha256':digest(dest) if before=='file' else None,'before_link':os.readlink(dest) if before=='symlink' else None,'after_link':link,'after_sha256':hashlib.sha256(data).hexdigest() if data is not None else None}
  changes.append((entry,rel,dest,data,mode,link))
 if not apply:return {'apply':False,'bridge':bridge,'changed':[e['path'] for e,*_ in changes],'manifest':None}
 if not changes:return {'apply':True,'bridge':bridge,'changed':[],'manifest':None}
 safe_parents(home,Path('.local/state/noesis-deployments/'+backup.name+'/manifest.json'))
 for entry,rel,dest,data,mode,link in changes:
  temp=dest.with_name(dest.name+'.noesis-new')
  if temp.exists() or temp.is_symlink():raise ValueError('Existing staging file: '+str(temp))
 backup.mkdir(parents=True,exist_ok=False,mode=0o700)
 for entry,rel,dest,data,mode,link in changes:
  old=backup/'files'/rel;old.parent.mkdir(parents=True,exist_ok=True)
  if entry['before']=='symlink':
   old.symlink_to(entry['before_link'])
   if not dest.is_symlink() or os.readlink(dest)!=entry['before_link']:raise ValueError('Target changed while preparing backup: '+str(dest))
  elif entry['before']=='file':
   shutil.copy2(dest,old)
   if digest(old)!=entry['before_sha256']:raise ValueError('Target changed while preparing backup: '+str(dest))
  elif dest.exists() or dest.is_symlink():raise ValueError('Target appeared while preparing backup: '+str(dest))
 write_manifest(backup/'manifest.json',{'version':1,'home':str(home),'entries':[e for e,*_ in changes]})
 for entry,rel,dest,data,mode,link in changes:
  before=entry['before']
  if before=='file' and (dest.is_symlink() or not dest.is_file() or digest(dest)!=entry['before_sha256']):raise ValueError('Target changed during deployment: '+str(dest))
  if before=='symlink' and (not dest.is_symlink() or os.readlink(dest)!=entry['before_link']):raise ValueError('Target changed during deployment: '+str(dest))
  if before=='absent' and (dest.exists() or dest.is_symlink()):raise ValueError('Target appeared during deployment: '+str(dest))
  dest.parent.mkdir(parents=True,exist_ok=True);safe_parents(home,rel);temp=dest.with_name(dest.name+'.noesis-new')
  if link:temp.symlink_to(link,target_is_directory=True)
  else:temp.write_bytes(data);temp.chmod(mode)
  temp.replace(dest)
 backup.chmod(0o700)
 return {'apply':True,'bridge':bridge,'changed':[e['path'] for e,*_ in changes],'manifest':str(backup/'manifest.json')}
def rollback(manifest,apply=False,expected_home=None):
 if os.geteuid()==0:raise PermissionError('Refusing rollback as root')
 expected_home=Path.home() if expected_home is None else Path(expected_home)
 home,validated=rollback_data(manifest,expected_home)
 if apply:
  for entry,dest,old,state in validated:
   temp=dest.with_name(dest.name+'.noesis-rollback')
   if temp.exists() or temp.is_symlink():raise ValueError('Existing rollback staging file: '+str(temp))
 if apply:
  for entry,dest,old,state in reversed(validated):
   if state=='before':continue
   if entry['before']=='absent':dest.unlink()
   elif entry['before']=='symlink':
    temp=dest.with_name(dest.name+'.noesis-rollback');temp.symlink_to(os.readlink(old));temp.replace(dest)
   else:
    temp=dest.with_name(dest.name+'.noesis-rollback');shutil.copy2(old,temp);temp.replace(dest)
 return {'apply':apply,'restored':[e['path'] for e,_,_,_ in validated]}
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--target-home',type=Path,default=Path.home());p.add_argument('--apply',action='store_true');p.add_argument('--bridge',action='store_true');p.add_argument('--rollback',type=Path);args=p.parse_args()
 print(json.dumps(rollback(args.rollback,args.apply,args.target_home.resolve()) if args.rollback else install(args.target_home,args.apply,args.bridge),indent=2))
