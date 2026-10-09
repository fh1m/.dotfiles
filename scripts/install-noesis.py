#!/usr/bin/env python3
"""Scoped Noesis deployment and hash-checked rollback; dry run by default."""
import argparse,datetime,hashlib,importlib.util,json,os,shutil,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('installer',ROOT/'scripts/install.py');installer=importlib.util.module_from_spec(spec);spec.loader.exec_module(installer)
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() and not path.is_symlink() else None
def files(bridge=False):
 prefixes=['.config/quickshell/noesis','.local/share/sensei-learning/ui','.local/share/sensei-learning/noesis']
 exact=['.local/bin/sensei-learn','.local/bin/noesis','.local/share/applications/org.fh1m.Noesis.desktop','.local/share/icons/hicolor/scalable/apps/org.fh1m.Noesis.svg']
 if bridge:
  prefixes+=['.config/quickshell/wrayth/modules/learning']
  exact+=['.config/quickshell/wrayth/services/Oasis.qml','.config/quickshell/wrayth/services/NoesisBridge.qml','.config/quickshell/wrayth/shell.qml','.config/quickshell/wrayth/modules/bar/ArchiveButton.qml','.config/quickshell/wrayth/modules/bar/BottomBar.qml','.config/hypr/oasis.lua','.config/quickshell/wrayth/services/Spaces.qml','.config/quickshell/wrayth/services/WindowDesk.qml','.config/quickshell/wrayth/modules/navigation/NavigationOverlay.qml','.config/quickshell/wrayth/modules/navigation/WorkspacePreview.qml']
 return sorted(p for p in (ROOT/'home').rglob('*') if p.is_file() and '__pycache__' not in p.parts and p.suffix!='.pyc' and (str(p.relative_to(ROOT/'home')) in exact or any(str(p.relative_to(ROOT/'home')).startswith(prefix+'/') for prefix in prefixes)))
def install(home,apply=False,bridge=False):
 home=home.resolve();backup=home/'.local/state/noesis-deployments'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f');entries=[]
 targets=[(str(p.relative_to(ROOT/'home')),installer.render(p.read_bytes(),home,'zenbook'),p.stat().st_mode&0o777,None) for p in files(bridge)]
 targets.append(('.config/quickshell/noesis/ui',None,None,'../../../.local/share/sensei-learning/ui'))
 if bridge:targets.append(('.config/quickshell/wrayth/noesis-ui',None,None,'../../../.local/share/sensei-learning/ui'))
 revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
 hashes={relative:hashlib.sha256(data).hexdigest() for relative,data,mode,link in targets if data is not None}
 build={'version':1,'commit':revision,'files':hashes,'source_dirty':bool(subprocess.check_output(['git','status','--porcelain','--','home','scripts/install-noesis.py'],cwd=ROOT,text=True).strip())}
 targets.append(('.local/share/sensei-learning/build.json',(json.dumps(build,sort_keys=True,indent=2)+'\n').encode(),0o644,None))
 # Install shared dependencies before the live shell entry can reload them.
 def phase(target):
  path=target[0]
  if path=='.config/quickshell/wrayth/shell.qml':return 4
  if target[3]:return 2
  if path.startswith('.config/quickshell/wrayth/'):return 3
  if path.startswith('.local/share/sensei-learning/noesis/'):return 0
  return 1
 targets.sort(key=phase)
 for relative,data,mode,link in targets:
  dest=home/relative
  if link and dest.is_symlink() and os.readlink(dest)==link:continue
  if data is not None and dest.is_file() and not dest.is_symlink() and dest.read_bytes()==data:continue
  if dest.is_dir() and not dest.is_symlink():raise ValueError('Refusing to replace directory: '+str(dest))
  entry={'path':relative,'before':'symlink' if dest.is_symlink() else 'file' if dest.exists() else 'absent','after_link':link,'after_sha256':hashlib.sha256(data).hexdigest() if data is not None else None};entries.append(entry)
  if not apply:continue
  old=backup/'files'/relative;old.parent.mkdir(parents=True,exist_ok=True)
  if dest.is_symlink():old.symlink_to(os.readlink(dest))
  elif dest.exists():shutil.copy2(dest,old)
  dest.parent.mkdir(parents=True,exist_ok=True);temp=dest.with_name(dest.name+'.noesis-new')
  if temp.exists() or temp.is_symlink():raise ValueError('Existing staging file: '+str(temp))
  if link:temp.symlink_to(link,target_is_directory=True)
  else:temp.write_bytes(data);temp.chmod(mode)
  temp.replace(dest)
  backup.mkdir(parents=True,exist_ok=True);backup.chmod(0o700)
  (backup/'manifest.json').write_text(json.dumps({'version':1,'home':str(home),'entries':entries},indent=2))
 return {'apply':apply,'bridge':bridge,'changed':[e['path'] for e in entries],'manifest':str(backup/'manifest.json') if entries else None}
def rollback(manifest,apply=False):
 value=json.loads(manifest.read_text());home=Path(value['home']);entries=value['entries']
 # Check the entire set before reverting anything changed after installation.
 for entry in entries:
  dest=home/entry['path']
  matches=dest.is_symlink() and os.readlink(dest)==entry['after_link'] if entry['after_link'] else digest(dest)==entry['after_sha256']
  if not matches:raise ValueError('Changed since deployment; refusing rollback: '+str(dest))
 if apply:
  for entry in reversed(entries):
   dest=home/entry['path'];old=manifest.parent/'files'/entry['path']
   if entry['before']=='absent':dest.unlink()
   elif entry['before']=='symlink':
    temp=dest.with_name(dest.name+'.noesis-rollback');temp.symlink_to(os.readlink(old));temp.replace(dest)
   else:shutil.copy2(old,dest.with_name(dest.name+'.noesis-rollback'));dest.with_name(dest.name+'.noesis-rollback').replace(dest)
 return {'apply':apply,'restored':[e['path'] for e in entries]}
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--target-home',type=Path,default=Path.home());p.add_argument('--apply',action='store_true');p.add_argument('--bridge',action='store_true');p.add_argument('--rollback',type=Path);args=p.parse_args()
 print(json.dumps(rollback(args.rollback,args.apply) if args.rollback else install(args.target_home,args.apply,args.bridge),indent=2))
