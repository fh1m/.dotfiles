#!/usr/bin/env python3
"""Install pinned official readers in ~/.local/opt, never upgrade the OS."""
import argparse,hashlib,json,os,shutil,subprocess,tarfile,tempfile,urllib.request,zipfile
from pathlib import Path
HOME=Path.home()
RELEASES={
 'zotero':('10.0.6','https://download.zotero.org/client/release/10.0.6/Zotero-10.0.6_linux-x86_64.tar.xz','Zotero-10.0.6.tar.xz','246c2574a9ac526abeaf3027ffd22fc45536a5ab25f227bb1df932fca9cedd63'),
 'sioyek':('2.0.0','https://github.com/ahrm/sioyek/releases/download/v2.0.0/sioyek-release-linux-portable.zip','sioyek-2.0.0.zip','3f90659c1f29705de680b3607ae247582eab8860015c208d364a0f3fc15d3222')}
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');args=p.parse_args()
 if not args.apply:print(json.dumps(RELEASES,indent=2));return
 if os.geteuid()==0:raise SystemExit('Run as the desktop user, not root')
 cache=HOME/'.cache/noesis-install';cache.mkdir(parents=True,exist_ok=True)
 opt=HOME/'.local/opt';opt.mkdir(parents=True,exist_ok=True)
 records=[]
 for name,(version,url,filename,expected) in RELEASES.items():
  dest=opt/(name+'-'+version);file=cache/filename
  if not file.exists():
   temporary=file.with_suffix('.part');urllib.request.urlretrieve(url,temporary);temporary.rename(file)
  sha=hashlib.sha256(file.read_bytes()).hexdigest()
  if sha!=expected:raise SystemExit('Download checksum differs from the inspected release: '+str(file))
  if not dest.exists():
   with tempfile.TemporaryDirectory(dir=opt) as temporary:
    stage=Path(temporary)
    if name=='zotero':
     with tarfile.open(file) as tar:tar.extractall(stage,filter='data')
     (stage/'Zotero_linux-x86_64').rename(dest)
    else:
     with zipfile.ZipFile(file) as archive:
      member='Sioyek-x86_64.AppImage'
      (stage/member).write_bytes(archive.read(member));(stage/member).chmod(0o755)
     subprocess.run([str(stage/member),'--appimage-extract'],cwd=stage,check=True,stdout=subprocess.DEVNULL)
     (stage/'squashfs-root').rename(dest)
  records.append({'name':name,'version':version,'url':url,'download_sha256':sha,'path':str(dest)})
 state=HOME/'.local/state/sensei-learning/readers.json';state.parent.mkdir(parents=True,exist_ok=True);state.write_text(json.dumps(records,indent=2)+'\n')
 print(state)
if __name__=='__main__':main()
