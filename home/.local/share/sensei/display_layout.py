"""Validated Hyprland monitor transactions with an independent rollback worker."""
import json,os,re,subprocess,time,uuid
from pathlib import Path
from engineering import locked,read,save,state,home

def ctl(*args):
 p=subprocess.run(['hyprctl','-i','0',*args],capture_output=True,text=True,timeout=8)
 if p.returncode or p.stdout.strip().lower().startswith(('error','err','failed')):raise ValueError(p.stderr.strip() or p.stdout.strip())
 return p.stdout

def outputs():return json.loads(ctl('monitors','all','-j'))

def snapshot(rows):
 return [dict(name=m['name'],enabled=not m.get('disabled',False),x=m.get('x',0),y=m.get('y',0),scale=m.get('scale',1),transform=m.get('transform',0),mode=f"{m['width']}x{m['height']}@{m.get('refreshRate',60):.2f}",mirror=m.get('mirrorOf','none') or 'none') for m in rows]

def validate(plan, actual):
 if not isinstance(plan,list) or not plan or len(plan)>16:raise ValueError('Expected a bounded display layout')
 lookup={m['name']:m for m in actual};seen=set();enabled=[]
 for row in plan:
  if not isinstance(row,dict) or set(row)-{'name','enabled','x','y','scale','transform','mode','mirror','primary'}:raise ValueError('Unknown display settings')
  name=row.get('name')
  if name not in lookup or name in seen:raise ValueError('Display missing or duplicated')
  seen.add(name)
  if not isinstance(row.get('enabled'),bool):raise ValueError('Enabled must be boolean')
  if not row['enabled']:continue
  enabled.append(name)
  for key in ('x','y'):
   if isinstance(row.get(key),bool) or not isinstance(row.get(key),int) or abs(row[key])>50000:raise ValueError('Invalid display position')
  scale=row.get('scale')
  if isinstance(scale,bool) or not isinstance(scale,(int,float)) or not .5<=scale<=4:raise ValueError('Scale must be between 0.5 and 4')
  if type(row.get('transform')) is not int or row['transform'] not in range(8):raise ValueError('Invalid orientation')
  mode=row.get('mode')
  available=[x.removesuffix('Hz') for x in lookup[name].get('availableModes',[])]
  current=snapshot([lookup[name]])[0]['mode']
  if mode not in available+[current,'preferred']:raise ValueError('Mode is not advertised by this display')
 for row in plan:
  mirror=row.get('mirror','none')
  if mirror not in ('none','') and (mirror not in enabled or mirror==row['name']):raise ValueError('Invalid mirror target')
 if not enabled:raise ValueError('Cannot disable every display')
 mains=[row for row in plan if row.get('primary')]
 if len(mains)>1 or any(not row['enabled'] for row in mains):raise ValueError('Choose one enabled primary display')
 if seen!=set(lookup):raise ValueError('Connected display set changed; refresh the layout')
 return plan

def expression(row):
 name=json.dumps(row['name'])
 if not row['enabled']:return 'hl.monitor({output='+name+',disabled=true})'
 fields=['output='+name,'mode='+json.dumps(row['mode']),'position='+json.dumps(str(row['x'])+'x'+str(row['y'])),'scale='+str(row['scale']),'transform='+str(row['transform'])]
 if row.get('mirror','none') not in ('none',''):fields.append('mirror='+json.dumps(row['mirror']))
 return 'hl.monitor({'+','.join(fields)+'})'

def apply_rows(rows):
 for row in sorted(rows,key=lambda r:not r['enabled']):ctl('eval',expression(row))

def begin(plan, helper):
 with locked(state()/'display.lock'):
  current=read(state()/'display-pending.json')
  if current and current.get('expires',0)>time.time():raise ValueError('Another display confirmation is pending')
  actual=outputs();validate(plan,actual);token=uuid.uuid4().hex
  previous=home()/'.config/hypr/monitors-user.lua'
  pending=dict(token=token,expires=time.time()+20,before=snapshot(actual),after=plan,previous=previous.read_text() if previous.exists() else None)
  save(state()/'display-pending.json',pending)
  # Arm a worker independent of QML before touching any output.
  p=subprocess.run(['systemd-run','--user','--quiet','--collect','--unit=sensei-display-rollback-'+token,'--',str(helper),'watchdog',token],capture_output=True,text=True,timeout=5)
  if p.returncode:
   (state()/'display-pending.json').unlink(missing_ok=True);raise ValueError('Could not arm rollback; no layout applied')
  try:apply_rows(plan)
  except Exception:
   apply_rows(pending['before']);(state()/'display-pending.json').unlink(missing_ok=True);raise
  return dict(token=token,expires=pending['expires'])

def confirm(token):
 with locked(state()/'display.lock'):
  p=read(state()/'display-pending.json')
  if p.get('token')!=token or time.time()>=p['expires']:raise ValueError('Display confirmation expired')
  # Persist only a confirmed, still-connected arrangement.
  validate(p['after'],outputs())
  target=home()/'.config/hypr/monitors-user.lua';target.parent.mkdir(parents=True,exist_ok=True)
  backup=state()/'display-history';backup.mkdir(parents=True,exist_ok=True,mode=0o700)
  save(backup/(token+'.json'),p)
  identities={m['name']:edid(m['name']) for m in outputs()}
  lua=durable_lua(p['after'],identities)
  temp=target.with_suffix('.lua.new');temp.write_text(lua);temp.replace(target)
  save(target.with_suffix('.json'),dict(version=1,edids=identities,primary=next((r['name'] for r in p['after'] if r.get('primary')),p['after'][0]['name'])))
  (state()/'display-pending.json').unlink();return {'kept':True}

def rollback(token):
 with locked(state()/'display.lock'):
  p=read(state()/'display-pending.json')
  if p.get('token')!=token:return {'rolledBack':False}
  present={m['name'] for m in outputs()}
  rows=[r for r in p['before'] if r['name'] in present]
  if not any(r['enabled'] for r in rows):
   rows=snapshot(outputs())
   if not rows:
    (state()/'display-pending.json').unlink();return {'rolledBack':False,'reason':'No outputs remain; automatic routing will handle reconnection'}
   rows[0].update(enabled=True,mode='preferred',scale=1,x=0,y=0)
  apply_rows(rows);(state()/'display-pending.json').unlink();return {'rolledBack':True}


def edid(output):
 if not re.fullmatch(r'[A-Za-z0-9_-]+',output):return ''
 for p in Path('/sys/class/drm').glob('card*-'+output+'/edid'):
  try:
   value=p.read_bytes()
   if value:return value.hex()
  except OSError:pass
 return ''


def profile_matches(actual):
 try:profile=read(home()/'.config/hypr/monitors-user.json')
 except (OSError,ValueError):return False
 if not profile:return True  # Preserve manually maintained/nwg-displays overrides.
 expected=profile.get('edids',{})
 return set(expected)=={m['name'] for m in actual} and all(edid(name)==value and value for name,value in expected.items())


def durable_lua(rows,identities):
 # Direct file reads only: calling hyprctl while config is loading can deadlock.
 code=['-- Confirmed display profile; only apply to the same connected hardware.','local matched=true']
 for name,value in identities.items():
  if not value:raise ValueError('Display EDID unavailable; cannot persist a safe hardware-specific profile')
  code += ['do local found=false', 'for card=0,31 do', 'local f=io.open("/sys/class/drm/card"..card..'+json.dumps('-'+name+'/edid')+',"rb")', 'if f then local b=f:read("*a");f:close();local h=b:gsub(".",function(c)return string.format("%02x",string.byte(c))end);if h=='+json.dumps(value)+' then found=true end end','end','matched=matched and found end']
 return '\n'.join(code)+'\nif matched then\n'+'\n'.join(expression(row) for row in rows)+'\nend\n'
