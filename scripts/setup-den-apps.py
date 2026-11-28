#!/usr/bin/env python3
"""Transfer allowlisted Spotify presentation preferences; sign in natively."""
import argparse
import io
import json
import os
from pathlib import Path
import shlex
import subprocess
import tarfile
import tomllib

HOME=Path.home();SSH=['ssh','-F',str(HOME/'.local/state/homie-control/client.conf'),'homie']
PREFERENCES={'theme','playback_format','playback_metadata_fields','notify_timeout_in_secs','notify_transient','tracks_playback_limit','page_size_in_rows','play_icon','pause_icon','liked_icon','explicit_icon','border_type','progress_bar_type','progress_bar_position','genre_num','cover_img_length','cover_img_width','cover_img_scale','enable_media_control','enable_audio_visualization','enable_notify','enable_cover_image_cache','notify_streaming_only','seek_duration_secs','sort_artist_albums_by_type','volume_scroll_step','enable_mouse_scroll_volume','pause_on_startup','custom_queue'}


def peer(code,data=None):
    p=subprocess.run([*SSH,'python3 -c '+shlex.quote(code)],input=data,capture_output=True,check=True)
    return p.stdout


def config_payload(home):
    source=home/'.config/spotify-player/app.toml'
    if not source.is_file():return {}
    values=tomllib.loads(source.read_text())
    safe={key:value for key,value in values.items() if key in PREFERENCES and (isinstance(value,(str,int,float,bool)) or isinstance(value,list) and all(isinstance(item,(str,int,float,bool)) for item in value))}
    if not safe:return {}
    data=''.join(f'{key} = {json.dumps(value,ensure_ascii=False)}\n' for key,value in sorted(safe.items()))
    return {'.config/spotify-player/app.toml':data.encode()}


def receiver_code():
    return '''from pathlib import Path
import sys,tarfile,io,os,json
os.umask(0o077);home=Path.home();changed=[];allowed={'.config/spotify-player/app.toml'}
with tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode='r:gz') as tar:
 members=tar.getmembers();seen=set()
 for member in members:
  rel=Path(member.name)
  if member.issym() or member.islnk() or not member.isfile() or rel.is_absolute() or '..' in rel.parts or rel.as_posix() not in allowed or rel.as_posix() in seen:raise ValueError('Unexpected configuration archive member')
  seen.add(rel.as_posix());current=home
  for part in rel.parts[:-1]:
   current=current/part
   if current.is_symlink():raise ValueError('Symlink parent is not allowed')
 for member in members:
  rel=Path(member.name);dest=home/rel
  if dest.exists() or dest.is_symlink():continue
  dest.parent.mkdir(parents=True,exist_ok=True,mode=0o700);dest.write_bytes(tar.extractfile(member).read());dest.chmod(0o600);changed.append(member.name)
print(json.dumps({'installedMissingFiles':len(changed),'existingFilesPreserved':True,'credentialsCopied':False,'nativeSignInRequired':True}))
'''


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');a=p.parse_args()
    config=config_payload(HOME)
    if not a.apply:
        print(json.dumps({'files':len(config),'policy':'allowlisted Spotify preferences only; destination files preserved; native sign-in required; no credentials, skills, or approval settings copied'}));return
    stream=io.BytesIO()
    with tarfile.open(fileobj=stream,mode='w:gz') as tar:
        for name,data in config.items():
            info=tarfile.TarInfo(name);info.size=len(data);tar.addfile(info,io.BytesIO(data))
    print(peer(receiver_code(),stream.getvalue()).decode().strip())


if __name__=='__main__':
    os.umask(0o077);main()
