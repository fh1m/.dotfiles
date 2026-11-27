#!/usr/bin/env python3
"""Compare maintained desktop files with deployment; emit hashes, never file contents."""
import argparse,hashlib,json,subprocess
from pathlib import Path

def runtime():
 processes=[]
 for directory in Path('/proc').iterdir():
  if not directory.name.isdigit():continue
  try:
   if (directory/'comm').read_text().strip() not in ('qs','quickshell'):continue
   executable=(directory/'exe').resolve();args=(directory/'cmdline').read_bytes().split(b'\0')
   env=dict(v.split(b'=',1) for v in (directory/'environ').read_bytes().split(b'\0') if b'=' in v)
   processes.append({'pid':int(directory.name),'role':'main' if b'-c' in args and b'sensei' in args else 'overlay','executable':str(executable),'binarySha256':hashlib.sha256(executable.read_bytes()).hexdigest(),'renderer':{k:env[k.encode()].decode(errors='replace') for k in ('QSG_RHI_BACKEND','QT_DISABLE_HW_TEXTURES_CONVERSION','QT_QPA_PLATFORM') if k.encode() in env}})
  except (OSError,ValueError):continue
 packages=subprocess.run(['pacman','-Q','quickshell','noctalia-qs','qt6-base','qt6-declarative','mesa','nvidia-utils'],capture_output=True,text=True,timeout=5)
 return {'processes':processes,'packages':packages.stdout.splitlines()}

def receipt(source,home):
 source=Path(source);home=Path(home);rows=[]
 roots=['.config/quickshell/sensei','.config/systemd/user','.local/bin','.local/share/sensei','.local/share/sensei-companion']
 for root in roots:
  for path in sorted((source/'home'/root).rglob('*')):
   if not path.is_file() or '__pycache__' in path.parts:continue
   relative=path.relative_to(source/'home');target=home/relative
   data=path.read_bytes().replace(b'@HOME@',str(home).encode())
   expected=hashlib.sha256(data).hexdigest()
   try:actual=hashlib.sha256(target.read_bytes()).hexdigest()
   except OSError:actual=None
   rows.append({'file':str(relative),'sourceSha256':expected,'deployedSha256':actual,'state':'matching' if expected==actual else 'missing' if actual is None else 'different'})
 revision=subprocess.run(['git','rev-parse','HEAD'],cwd=source,capture_output=True,text=True)
 return {'schema':1,'revision':revision.stdout.strip() if revision.returncode==0 else None,'runtime':runtime(),'files':rows,'matching':sum(r['state']=='matching' for r in rows),'different':sum(r['state']=='different' for r in rows),'missing':sum(r['state']=='missing' for r in rows),'scope':'Hash comparison against the current source tree, including uncommitted changes; not a claim of a clean Git revision'}

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--home',type=Path,default=Path.home());a=p.parse_args()
 print(json.dumps(receipt(Path(__file__).resolve().parents[1],a.home),indent=2))
if __name__=='__main__':main()
