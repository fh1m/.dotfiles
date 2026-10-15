#!/usr/bin/env python3
"""Prepare encrypted local Den backups without formatting or touching old archives."""
import json
import os
from pathlib import Path
import secrets
import shlex
import subprocess

HOME=Path.home();PRIVATE=HOME/'.local/state/homie-control';SSH=['ssh','-F',str(PRIVATE/'client.conf'),'homie']


def remote(code,data=None):
    return subprocess.run([*SSH,'python3 -c '+shlex.quote(code)],input=data,capture_output=True,check=True).stdout


def write(path,value):
    path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    if path.exists():raise ValueError('Existing backup configuration preserved; review before replacing')
    path.write_text(json.dumps(value,indent=2));path.chmod(0o600)


def key(path):
    path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    if not path.exists():path.write_text(secrets.token_hex(32)+'\n');path.chmod(0o600)
    return path.read_bytes()


def main():
    config=HOME/'.config/sensei-den';config.mkdir(parents=True,exist_ok=True,mode=0o700)
    remote("import os;from pathlib import Path;p=Path('/mnt/homie/Datasets');assert os.path.ismount(p);d=p/'Den-backups';d.mkdir(exist_ok=True);(Path.home()/'.config/sensei-den').mkdir(parents=True,exist_ok=True)")
    subprocess.run(['scp','-q','-F',str(PRIVATE/'client.conf'),str(HOME/'.local/bin/restic'),'homie:.local/bin/restic'],check=True)
    remote("from pathlib import Path;(Path.home()/'.local/bin/restic').chmod(0o755)")
    akey=config/'arete-backup.key';hkey=config/'homie-backup.key'
    for name,path in [('arete-backup.key',akey),('homie-backup.key',hkey)]:
        remote("import sys;from pathlib import Path;p=Path.home()/'.config/sensei-den'/"+repr(name)+";data=sys.stdin.buffer.read();assert not p.exists() or p.read_bytes()==data;p.write_bytes(data);p.chmod(0o600)",key(path))
    sync=json.loads((config/'sync.json').read_text())
    paths=[f['path'] for f in sync['folders'] if Path(f['path']).name!='Downloads']
    paths += [str(HOME/p) for p in ['Work','.config/sensei-den','.ssh','.codex/config.toml','.codex/auth.json','.claude/settings.json','.claude/.credentials.json','.local/state/homie-control/input'] if (HOME/p).exists()]
    exclude=['**/node_modules','**/__pycache__','**/.venv','**/venv','**/.git','**/build','**/install','**/log','**/target','**/.obsidian/workspace*','**/.obsidian/cache','**/.stversions','*.iso','*.AppImage','*.crdownload','*.zip','*.tar','*.tar.gz','*.tgz','*.mkv','*.mp4','*.avi','*.webm','*.bag','*.mcap','*.npy','*.pt','*.pth','*.onnx']
    cfg={'schema':1,'repository':'sftp:homie:/mnt/homie/Datasets/Den-backups/arete','passwordFile':str(akey),
        'sftpCommand':shlex.join(['ssh','-F',str(PRIVATE/'client.conf'),'homie','-s','sftp']),
        'paths':paths,'exclude':exclude,'remoteMinimumFreeGiB':20,'remoteTarget':'/mnt/homie/Datasets/Den-backups/arete',
        'requiredMount':'/mnt/homie/Datasets','scope':'local machines only'}
    if not (config/'backup.json').exists():write(config/'backup.json',cfg)
    hcfg={'schema':1,'repository':'/mnt/homie/Datasets/Den-backups/homie','passwordFile':str(hkey),
        'paths':[str(HOME/p) for p in ['.config/sensei-den','.ssh','.codex/config.toml','.codex/auth.json','.claude/settings.json','.claude/.credentials.json','Work','.local/state/homie-control/input']],
        'exclude':exclude,'minimumFreeGiB':20,'requiredMount':'/mnt/homie/Datasets','scope':'local machines only'}
    remote("import sys,json;from pathlib import Path;p=Path.home()/'.config/sensei-den/backup.json';data=sys.stdin.read();assert not p.exists() or json.loads(p.read_text())==json.loads(data);p.write_text(data);p.chmod(0o600)",json.dumps(hcfg).encode())
    base=[str(HOME/'.local/bin/restic'),'-o','sftp.command='+cfg['sftpCommand']]
    env=dict(os.environ,RESTIC_REPOSITORY=cfg['repository'],RESTIC_PASSWORD_FILE=str(akey))
    check=subprocess.run([*base,'snapshots','--json'],capture_output=True,env=env)
    if check.returncode:
        # init refuses an existing repository; never overwrites a wrong-key repository.
        subprocess.run([*base,'init'],check=True,env=env,stdout=subprocess.DEVNULL)
    remote("import os,subprocess,json;from pathlib import Path;c=json.loads((Path.home()/'.config/sensei-den/backup.json').read_text());e=dict(os.environ,RESTIC_REPOSITORY=c['repository'],RESTIC_PASSWORD_FILE=c['passwordFile']);b=str(Path.home()/'.local/bin/restic');r=subprocess.run([b,'snapshots','--json'],capture_output=True,env=e);subprocess.run([b,'init'],check=True,env=e,stdout=subprocess.DEVNULL) if r.returncode else None")
    print(json.dumps({'repositoriesPrepared':2,'scope':'local only','keysOnBothHosts':True,'oldArchivesUntouched':True}))


if __name__=='__main__':os.umask(0o077);main()
