#!/usr/bin/env python3
"""Reload companion code without restarting native input or losing visual focus."""
import datetime
import json
from pathlib import Path
import shutil
import subprocess
import time
h=Path.home();root=Path(__file__).resolve().parents[2];source=root/'pc/den/cursor-ui/shell.qml';dest=h/'.local/state/homie-control/cursor-ui/shell.qml'
cmd=['qs','ipc','--any-display','-p',str(dest.parent),'call','den-cursor']
def call(*args):return subprocess.check_output([*cmd,*args],text=True,stderr=subprocess.DEVNULL,timeout=4)
state=json.loads(call('state'));changed=dest.read_bytes()!=source.read_bytes()
if changed:
 backup=h/'.local/state/dotfiles-backups'/('cursor-ui-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
 backup.mkdir(parents=True,exist_ok=True,mode=0o700);shutil.copy2(dest,backup/'shell.qml')
 # Quickshell watches this inode; replacing it atomically detaches that watch.
 with dest.open('wb') as file:file.write(source.read_bytes());file.flush()
ready=False
for _ in range(40):
 time.sleep(.15)
 try:json.loads(call('state'));ready=True;break
 except (ValueError,subprocess.SubprocessError):pass
if not ready:raise SystemExit('Cursor renderer did not become ready; native input was not restarted')
call('focus',state['focusedOutput']);call('reloadCompanion')
print(json.dumps({'changed':changed,'visualFocusRestored':state['focusedOutput'],'nativeInputRestarted':False}))
