#!/usr/bin/env python3
"""Pair existing local Syncthing instances without exporting their API keys.

Only personal content folders are shared. No credentials, Git internals, runtimes
or existing archive disks. Default is a private inventory/preview.
"""
import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import time
import urllib.request
import xml.etree.ElementTree as E

HOME=Path.home();PRIVATE=HOME/'.local/state/homie-control'
REMOTE='''import json,urllib.request,xml.etree.ElementTree as E,sys
from pathlib import Path
r=E.parse(Path.home()/'.local/state/syncthing/config.xml').getroot();q=json.load(sys.stdin)
a=r.findtext('gui/address');assert a.startswith('127.0.0.1:')
req=urllib.request.Request('http://'+a+'/rest/'+q['path'],method=q['method'],headers={'X-API-Key':r.findtext('gui/apikey'),'Content-Type':'application/json'},data=json.dumps(q['body']).encode() if q.get('body') is not None else None)
with urllib.request.urlopen(req,timeout=20) as v:
 b=v.read();print(b.decode() if b else '{}')
'''


def peer(args,**kw):
    return subprocess.run(['ssh','-F',str(PRIVATE/'client.conf'),'homie',shlex.join(args)],check=True,capture_output=True,**kw)


def api(method,path,body=None,remote=False):
    q={'method':method,'path':path,'body':body}
    if remote:return json.loads(peer(['python3','-c',REMOTE],input=json.dumps(q),text=True).stdout)
    r=E.parse(HOME/'.local/state/syncthing/config.xml').getroot();a=r.findtext('gui/address')
    if not a.startswith('127.0.0.1:'):raise ValueError('API must stay on loopback')
    req=urllib.request.Request('http://'+a+'/rest/'+path,method=method,headers={'X-API-Key':r.findtext('gui/apikey'),'Content-Type':'application/json'},data=json.dumps(body).encode() if body is not None else None)
    with urllib.request.urlopen(req,timeout=20) as v:
        b=v.read();return json.loads(b) if b else {}


def write(path,value):
    path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    p=path.with_suffix('.tmp');p.write_text(json.dumps(value,indent=2));p.chmod(0o600);p.replace(path)


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');a=p.parse_args()
    folders=[{'label':n,'path':str(HOME/n),'id':'den-'+n.lower()} for n in ['Documents','Pictures','Music','Videos','Downloads','Work'] if (HOME/n).is_dir()]
    # Existing registered vaults are additional folders only when not already inside a shared tree.
    reg=HOME/'.config/obsidian/obsidian.json'
    try:vaults=json.loads(reg.read_text()).get('vaults',{}).values()
    except (OSError,ValueError):vaults=[]
    import hashlib
    for v in vaults:
        path=Path(v.get('path','')).resolve()
        if not path.is_dir() or not (path/'.obsidian').is_dir() or any(path.is_relative_to(Path(f['path'])) for f in folders):continue
        # Ignore disposable showcase vaults and temporary/test homes.
        if path.is_relative_to(HOME/'.local/state') or str(path).startswith('/tmp/'):continue
        folders.append({'label':path.name,'path':str(path),'id':'den-vault-'+hashlib.sha256(str(path).encode()).hexdigest()[:12]})
    inventory={'folders':folders,'policy':'Broad personal mirror; existing paths preserved; archives and runtime state excluded','floorGiB':80}
    if not a.apply:print(json.dumps(inventory,indent=2));return
    if shutil.disk_usage(HOME).free<80*2**30:raise ValueError('Laptop reserve below 80 GiB')
    peer(['systemctl','--user','enable','--now','syncthing'])
    for _ in range(40):
        try:remote_id=api('GET','system/status',remote=True)['myID'];break
        except (OSError,ValueError,subprocess.CalledProcessError):time.sleep(.5)
    else:raise ValueError('Homie Syncthing did not start')
    local_id=api('GET','system/status')['myID'];cfgs=[api('GET','config'),api('GET','config',remote=True)]
    # Syncthing verifies peer device certificates; transport is encrypted natively.
    for index,cfg in enumerate(cfgs):
        ident=remote_id if index==0 else local_id
        device=next((d for d in cfg['devices'] if d['deviceID']==ident),None)
        if device is None:device=dict(cfg['defaults']['device']);device['deviceID']=ident;cfg['devices'].append(device)
        device.update(name='Homie' if index==0 else 'Arete',addresses=['tcp://homie.local:22000'] if index==0 else ['dynamic'],autoAcceptFolders=False)
        for f in folders:
            target=f['path'] if index==0 else str(HOME/'Den/Mirror/arete'/f['id'])
            existing=next((x for x in cfg['folders'] if x['id']==f['id']),None)
            if existing and existing['path']!=target:raise ValueError('Existing folder ID maps elsewhere; preserved')
            if existing is None:existing=dict(cfg['defaults']['folder']);existing.update(id=f['id'],path=target,label=f['label']);cfg['folders'].append(existing)
            ids={d['deviceID'] for d in existing.get('devices',[])}
            existing['devices']=[{'deviceID':d} for d in sorted(ids|{local_id,remote_id})]
            existing.update(type='sendreceive',paused=False,fsWatcherEnabled=True,rescanIntervalS=3600,
                minDiskFree={'value':80 if index==0 else 60,'unit':'GiB'},ignorePerms=True)
            existing['versioning']={'type':'staggered','params':{'maxAge':'2592000','cleanInterval':'3600'},'cleanupIntervalS':3600,'fsPath':'','fsType':'basic'}
        # These are private snapshots containing Syncthing configuration/API keys.
        if index==0:write(PRIVATE/('backups/syncthing-'+time.strftime('%Y%m%dT%H%M%S')+'.json'),api('GET','config'))
        else:peer(['python3','-c',"from pathlib import Path;import shutil,datetime;p=Path.home()/'.local/state/syncthing/config.xml';d=Path.home()/'.local/state/homie-control/backups';d.mkdir(parents=True,exist_ok=True);shutil.copy2(p,d/('syncthing-'+datetime.datetime.now().strftime('%Y%m%dT%H%M%S')+'.xml'))"])
        api('PUT','config',cfg,remote=index==1)
    ignores=['.git','.obsidian/workspace*','.obsidian/cache','node_modules','__pycache__','.venv','venv','.Trash-*','*.tmp','*.crdownload','.DS_Store']
    for f in folders:
        for remote in (False,True):
            prior=api('GET','db/ignores?folder='+f['id'],remote=remote).get('ignore',[])
            api('POST','db/ignores?folder='+f['id'],{'ignore':list(dict.fromkeys([*prior,*ignores]))},remote=remote)
    write(HOME/'.config/sensei-den/sync.json',{'schema':1,'folders':[dict(f,floorGiB=80) for f in folders]})
    data={'schema':1,'folders':[dict(f,path=str(HOME/'Den/Mirror/arete'/f['id']),floorGiB=60) for f in folders]}
    peer(['python3','-c',"import sys,json,os;from pathlib import Path;p=Path.home()/'.config/sensei-den/sync.json';p.parent.mkdir(parents=True,exist_ok=True);p.write_text(sys.stdin.read());p.chmod(0o600)"],input=json.dumps(data),text=True)
    # Friendly entry points never replace existing folders or merge unrelated vaults.
    peer(['python3','-c',"import sys,json;from pathlib import Path;d=json.load(sys.stdin);root=Path.home()/'Den/Shared';root.mkdir(parents=True,exist_ok=True);[(root/f['id']).symlink_to(f['path'],target_is_directory=True) for f in d['folders'] if not (root/f['id']).exists() and not (root/f['id']).is_symlink()];p=Path.home()/'Work/Arete';p.parent.mkdir(exist_ok=True);t=next((f['path'] for f in d['folders'] if f['id']=='den-work'),None);p.symlink_to(t,target_is_directory=True) if t and not p.exists() and not p.is_symlink() else None"],input=json.dumps(data),text=True)
    print(json.dumps({'paired':True,'folders':len(folders),'transport':'Syncthing native TLS with pinned device identity; LAN-only listener rule','localFreeGiB':round(shutil.disk_usage(HOME).free/2**30,1)}))


if __name__=='__main__':
    os.umask(0o077)
    try:main()
    except (OSError,ValueError,subprocess.CalledProcessError) as e:
        print('Setup did not complete; existing data preserved. Inspect private service diagnostics.',file=sys.stderr);sys.exit(1)
