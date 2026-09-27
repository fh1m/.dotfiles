#!/usr/bin/python3
"""Socket-activated root reader. No input, commands, resets, or filesystem writes.
Only reports processes with open handles to USB nodes or USB-mounted volumes.
The installed root-owned copy is used, never this editable source at runtime.
"""
import json, os, pwd, subprocess
from pathlib import Path
import pyudev

def read(p):
    try:return Path(p).read_text().strip()
    except (OSError,UnicodeError):return ''
ctx=pyudev.Context();ports={}
for d in ctx.list_devices(subsystem='usb',DEVTYPE='usb_device'):
    ports[d.sys_name]={'nodes':set([d.device_node]) if d.device_node else set(),'mounts':[],'processes':[]}
for d in ctx.list_devices():
    if not d.device_node:continue
    u=d.find_parent('usb','usb_device')
    if u is not None and u.sys_name in ports:ports[u.sys_name]['nodes'].add(d.device_node)
j=json.loads(subprocess.run(['/usr/bin/lsblk','-J','-o','PATH,MOUNTPOINTS'],capture_output=True,text=True,timeout=3).stdout)
def mount(nodes):
    for n in nodes:
        for p in ports.values():
            if n['path'] in p['nodes']:p['mounts'].extend(m for m in n.get('mountpoints',[]) or [] if m and m!='/')
        mount(n.get('children',[]))
mount(j.get('blockdevices',[]));denied=0
for proc in Path('/proc').iterdir():
    if not proc.name.isdigit():continue
    try:fds=list((proc/'fd').iterdir())
    except OSError:denied+=1;continue
    matches={}
    for fd in fds:
        try:target=os.readlink(fd)
        except OSError:continue
        for key,p in ports.items():
            if target in p['nodes'] or any(target==m or target.startswith(m.rstrip('/')+'/') for m in p['mounts']):
                flags=next((s.split(':',1)[1].strip() for s in read(proc/'fdinfo'/fd.name).splitlines() if s.startswith('flags:')),'0')
                mode={0:'read',1:'write',2:'read/write'}.get(int(flags,8)&3,'unknown')
                matches.setdefault(key,[]).append({'path':target,'access':mode})
    if not matches:continue
    io={s.split(':')[0]:int(s.split(':')[1]) for s in read(proc/'io').splitlines() if ':' in s}
    try:user=pwd.getpwuid(proc.stat().st_uid).pw_name
    except (OSError,KeyError):user='unknown'
    for key,handles in matches.items():ports[key]['processes'].append({'pid':int(proc.name),'name':read(proc/'comm'),'user':user,'handles':handles,'io':io})
print(json.dumps({'ports':{key:p['processes'] for key,p in ports.items()},'restricted':denied}),flush=True)
