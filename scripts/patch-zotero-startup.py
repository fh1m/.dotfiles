#!/usr/bin/env python3
"""Guarded Zotero 10.0.6 LocalAPI initialization compatibility fix.

Dry run by default. Changes application code only, never reader profiles/data.
"""
import argparse,datetime,hashlib,json,os,tempfile
from pathlib import Path
from zipfile import ZipFile
ENTRY='chrome/content/zotero/xpcom/server/server_localAPI.js'
NEEDLE=b'  async _initInternal(requestData) {\n'
ADDITION=b'    // Noesis compatibility: wait for creator initialization before library item loading.\n    await Zotero.initializationPromise;\n'
def digest(data):return hashlib.sha256(data).hexdigest()
def running(application):
 for path in Path('/proc').iterdir():
  if not path.name.isdigit():continue
  try:
   parts=(path/'cmdline').read_bytes().split(b'\0')
   if parts and parts[0] and Path(os.fsdecode(parts[0])).is_relative_to(application):return True
  except (OSError,ValueError):pass
 return False
def apply(application,write=False):
 application=application.resolve();archive=application/'app/omni.ja'
 if running(application):raise ValueError('Zotero is running from this application; leave it untouched until it is closed')
 if 'Version=10.0.6' not in (application/'app/application.ini').read_text():raise ValueError('Only the inspected Zotero 10.0.6 build is supported')
 original=archive.read_bytes()
 with ZipFile(archive) as source:
  data=source.read(ENTRY)
  if ADDITION in data:return {'status':'already-patched','application':str(application),'sha256':digest(original)}
  # Pin the exact inspected entry; never patch an unfamiliar vendor build.
  expected='c1198c52070fc8bf7b6ac014e76283972c48e533ff2f38adbbc4c039d65fb994'
  if digest(data)!=expected:raise ValueError('Application source differs from the inspected build; refusing patch')
  if NEEDLE not in data or b'await Zotero.Creators.init()' not in source.read('chrome/content/zotero/xpcom/zotero.js'):raise ValueError('Expected initialization contracts are absent')
  if not write:return {'status':'dry-run','application':str(application),'original_sha256':digest(original),'change':'Await Zotero initialization before LocalAPI item loading'}
  backup=Path.home()/'.local/state/noesis-zotero-compat'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f');backup.mkdir(parents=True,mode=0o700)
  saved=backup/'omni.ja';saved.write_bytes(original);saved.chmod(0o600)
  fd,name=tempfile.mkstemp(prefix='.noesis-compat-',dir=archive.parent);os.close(fd);replacement=Path(name)
  try:
   with ZipFile(replacement,'w') as output:
    for entry in source.infolist():
     payload=source.read(entry)
     if entry.filename==ENTRY:payload=payload.replace(NEEDLE,NEEDLE+ADDITION,1)
     output.writestr(entry,payload)
   replacement.chmod(archive.stat().st_mode&0o777)
   with replacement.open('rb') as content:os.fsync(content.fileno())
   patched=digest(replacement.read_bytes());os.replace(replacement,archive)
  finally:replacement.unlink(missing_ok=True)
 manifest={'version':1,'application':str(application),'archive':str(archive),'backup':str(saved),'original_sha256':digest(original),'patched_sha256':patched,'entry':ENTRY,'change':'Await Zotero initialization before LocalAPI library item loading'}
 target=backup/'manifest.json';target.write_text(json.dumps(manifest,indent=2)+'\n');target.chmod(0o600)
 return dict(manifest,status='patched',manifest=str(target))
def rollback(path):
 manifest=json.loads(path.read_text());archive=Path(manifest['archive']);application=Path(manifest['application'])
 if running(application):raise ValueError('Zotero is active; refusing rollback')
 if digest(archive.read_bytes())!=manifest['patched_sha256']:raise ValueError('Application has changed since the patch; refusing overwrite')
 original=Path(manifest['backup']).read_bytes()
 if digest(original)!=manifest['original_sha256']:raise ValueError('Backup hash mismatch')
 fd,name=tempfile.mkstemp(prefix='.noesis-rollback-',dir=archive.parent);os.close(fd);replacement=Path(name)
 try:replacement.write_bytes(original);replacement.chmod(archive.stat().st_mode&0o777);os.replace(replacement,archive)
 finally:replacement.unlink(missing_ok=True)
 return {'status':'rolled-back','sha256':digest(original)}
if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--application',type=Path,default=Path.home()/'.local/opt/zotero-10.0.6');parser.add_argument('--apply',action='store_true');parser.add_argument('--rollback',type=Path);args=parser.parse_args()
 try:print(json.dumps(rollback(args.rollback) if args.rollback else apply(args.application,args.apply),indent=2))
 except (ValueError,OSError) as error:parser.exit(1,str(error)+'\n')
