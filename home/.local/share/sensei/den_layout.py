"""Resolve private physical-display roles without treating PC DP-2 as a ScreenPad."""
import json
import os
from pathlib import Path
import socket

PATH = Path(os.environ.get('DEN_LAYOUT_PATH', str(Path.home()/'.config/sensei-den/layout.json')))


def settings():
    try:
        d=json.loads(PATH.read_text())
        if d.get('schema') != 1 or not isinstance(d.get('hosts'),dict):raise ValueError('Unsupported Den layout')
        return d
    except FileNotFoundError:return {'schema':1,'hosts':{}}


def roles(monitors, host=None, profile=None):
    host=host or socket.gethostname().split('.')[0]
    configured=settings().get('hosts',{}).get(host,{})
    result={}; used=set()
    for role, rule in configured.get('displays',{}).items():
        if role not in {'main','screenpad','upper','lower'} or not isinstance(rule,dict):continue
        # A recorded identity never falls through to a different monitor on its old port.
        identity=rule.get('description')
        found=next((m for m in monitors if m['name'] not in used and
                    (m.get('description')==identity if identity else m['name']==rule.get('connector'))),None)
        if found:result[role]=found;used.add(found['name'])
    laptop=profile=='zenbook' or any(m['name'].startswith('eDP-') for m in monitors)
    if 'main' not in result:
        candidates=[m for m in monitors if m['name'] not in used]
        found=next((m for m in candidates if m['name'].startswith('eDP-')),None) if laptop else None
        found=found or next((m for m in candidates if m.get('focused')),None) or next(iter(candidates),None)
        if found:result['main']=found;used.add(found['name'])
    if laptop and 'screenpad' not in result:
        found=next((m for m in monitors if m['name'] not in used and
                    (m.get('model')=='0x085F' or (m['name']=='DP-2' and m.get('height') in (550,1100)))),None)
        if found:result['screenpad']=found;used.add(found['name'])
    # Preserve configured spatial choices; unregistered displays use safe deterministic slots.
    remaining=sorted((m for m in monitors if m['name'] not in used),key=lambda m:(m['name']!='HDMI-A-1',m['name']))
    for role in ('lower','upper'):
        if role not in result and remaining:result[role]=remaining.pop(0)
    return result


def role_for(output, monitors, **kwargs):
    return next((role for role,m in roles(monitors,**kwargs).items() if m['name']==output),'external')
