#!/usr/bin/env python3
"""Build the pinned lightweight music backend and preserve existing local login."""
import argparse,base64,json,os,shutil,subprocess,tomllib
from pathlib import Path
PIN='bd3fa7407eb1ab595295446e1be50cb9663e69cb'
ROOT=Path(__file__).resolve().parents[1];HOME=Path.home()
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--build',action='store_true');p.add_argument('--apply',action='store_true');p.add_argument('--catalog',action='store_true');a=p.parse_args()
source=HOME/'.cache/sensei-build/go-librespot';binary=HOME/'.local/opt/go-librespot/go-librespot';config=HOME/'.config/sensei-go-spotify'
if a.build:
 source.parent.mkdir(parents=True,exist_ok=True)
 if not source.exists():subprocess.run(['git','clone','https://github.com/devgianlu/go-librespot.git',str(source)],check=True)
 head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=source,text=True).strip()
 if head!=PIN:
  if subprocess.check_output(['git','status','--porcelain'],cwd=source).strip():raise SystemExit('Build checkout has changes; preserved. Use a separate clean checkout.')
  subprocess.run(['git','fetch','origin',PIN],cwd=source,check=True);subprocess.run(['git','checkout','--detach',PIN],cwd=source,check=True)
 for filename in ('queue-status.patch','id-overflow.patch'):
  patch=ROOT/'patches/go-librespot'/filename
  check=subprocess.run(['git','apply','--reverse','--check',str(patch)],cwd=source,capture_output=True)
  if check.returncode:subprocess.run(['git','apply','--check',str(patch)],cwd=source,check=True);subprocess.run(['git','apply',str(patch)],cwd=source,check=True)
 binary.parent.mkdir(parents=True,exist_ok=True)
 env=dict(os.environ,GOMAXPROCS='2')
 subprocess.run(['nice','-n','10','go','build','-o',str(binary)+'.next','./cmd/daemon'],cwd=source,env=env,check=True)
 if binary.exists():shutil.copy2(binary,binary.with_suffix('.previous'))
 Path(str(binary)+'.next').replace(binary)
 shutil.copy2(source/'LICENSE',binary.parent/'LICENSE')
if a.catalog:
 import hashlib,io,tarfile,urllib.request
 version='0.46.0';expected='9c69f581eb5ced5010ae44daf668629f1eaf3eb77bd54271d88a998b68929b1d'
 if os.uname().machine!='x86_64':raise SystemExit('Catalogue release installer currently supports x86_64 only.')
 url='https://github.com/LargeModGames/spotatui/releases/download/v'+version+'/spotatui-linux-x86_64.tar.gz'
 with urllib.request.urlopen(url,timeout=60) as response:data=response.read(100*1024*1024)
 if hashlib.sha256(data).hexdigest()!=expected:raise SystemExit('Catalogue checksum mismatch; nothing installed.')
 dest=HOME/'.local/opt/spotatui-catalog/spotatui';dest.parent.mkdir(parents=True,exist_ok=True)
 with tarfile.open(fileobj=io.BytesIO(data),mode='r:gz') as archive:
  member=next(m for m in archive.getmembers() if m.isfile() and Path(m.name).name=='spotatui')
  with archive.extractfile(member) as source_file:payload=source_file.read()
 temp=dest.with_suffix('.next');temp.write_bytes(payload);temp.chmod(0o755);temp.replace(dest)
 root=HOME/'.local/share/sensei-spotify/catalog-helper'
 for folder in ('config/spotatui','cache/spotatui/streaming_cache','state'):(root/folder).mkdir(parents=True,exist_ok=True,mode=0o700)
 settings=root/'config/spotatui/config.yml'
 settings.write_text('behavior:\n  enable_streaming: false\n  disable_auto_update: true\n  enable_discord_rpc: false\n  startup_behavior: pause\n');settings.chmod(0o600)
 old=HOME/'.cache/spotify-player/credentials.json';login=root/'cache/spotatui/streaming_cache/credentials.json'
 if old.exists() and not login.exists():shutil.copy2(old,login);login.chmod(0o600)
if a.apply:
 config.mkdir(parents=True,exist_ok=True,mode=0o700);config.chmod(0o700)
 destination=config/'config.yml'
 if not destination.exists():
  name='Den · '+os.uname().nodename.title()
  destination.write_text('device_name: '+json.dumps(name)+'\naudio_backend: pulseaudio\nbitrate: 320\nvolume_steps: 100\nmpris_enabled: true\nzeroconf_enabled: false\ncredentials:\n  type: device_auth\nserver:\n  enabled: true\n  address: 127.0.0.1\n  port: 3678\nmetadata:\n  enabled: true\n  context_sweep: false\n  max_tracks: 2000\ncache:\n  enabled: true\n  size_limit: 256MB\n');destination.chmod(0o600)
 state=config/'state.json';old=HOME/'.cache/spotify-player/credentials.json'
 if not state.exists() and old.exists():
  c=json.loads(old.read_text())
  if c.get('auth_type')!=1:raise SystemExit('Existing credentials use a different login type; use device pairing instead.')
  base64.b64decode(c['auth_data'],validate=True)
  state.write_text(json.dumps({'credentials':{'username':c['username'],'data':c['auth_data']}}));state.chmod(0o600);old.chmod(0o600)
 print('Configuration prepared; existing credentials remain local. Select Use lightweight player in Account.')
print(json.dumps({'binary':binary.is_file(),'config':(config/'config.yml').is_file(),'credentials':(config/'state.json').is_file(),'revision':PIN}))
