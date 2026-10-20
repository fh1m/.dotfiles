"""Pen profiles, bounded driver control and durable local drawing captures."""
import copy,datetime,gzip,json,os,shutil,subprocess,tempfile,time,uuid
from pathlib import Path
import engineering as e
from den_layout import roles
MODEL='XP-Pen Star G960S Plus'
DEVICE='opentabletdriver-virtual-artist-tablet'
DEFAULT={'version':1,'output':'upper','aspect':True,'rotation':0,'threshold':1,'profile':'writing','buttons':['undo','redo','eraser','pan']}

def config():return e.home()/'.config/sensei-drawing/profile.json'
def prefs():return dict(DEFAULT,**e.read(config(),{}))
def call(argv,timeout=10):
 r=subprocess.run(argv,capture_output=True,text=True,timeout=timeout,env=e.session_environment())
 if r.returncode:raise ValueError((r.stderr or r.stdout or 'Tool unavailable')[-800:])
 return r.stdout

def monitors():return json.loads(call(['hyprctl','-i','0','monitors','-j']))
def connected():
 for p in Path('/sys/bus/usb/devices').glob('*'):
  try:
   if (p/'idVendor').read_text().strip()=='28bd' and (p/'idProduct').read_text().strip()=='0918':return True
  except OSError:pass
 return False

def validate(value):
 if not isinstance(value,dict) or set(value)-set(DEFAULT):raise ValueError('Unknown tablet preference')
 p=dict(DEFAULT,**value)
 if p['output'] not in ('upper','main','lower','screenpad','current'):raise ValueError('Select a display role')
 if type(p['aspect']) is not bool or p['rotation'] not in (0,90,180,270):raise ValueError('Invalid area or rotation')
 if type(p['threshold']) not in (int,float) or not 0<=p['threshold']<=20:raise ValueError('Pressure threshold must be 0–20%')
 if p['profile'] not in ('writing','diagram','art'):raise ValueError('Unknown pen profile')
 if not isinstance(p['buttons'],list) or len(p['buttons'])!=4 or any(x not in ('undo','redo','eraser','pan','none') for x in p['buttons']):raise ValueError('Choose four supported button actions')
 return p

def area(p,m):
 width,height=228.6,152.4
 if p['aspect']:
  ratio=m['width']/m['height']
  if p['rotation'] in (90,270):ratio=1/ratio
  if width/height>ratio:width=height*ratio
  else:height=width/ratio
 return {'Width':round(width,4),'Height':round(height,4),'X':114.3,'Y':76.2,'Rotation':float(p['rotation'])}

def target(p,rows):
 mapped=roles(rows)
 if p['output']=='current':return next((m for m in rows if m.get('focused')),mapped['main']),False
 return mapped.get(p['output'],mapped['main']),p['output'] not in mapped

def status():
 p=validate(prefs());rows=monitors();m,fallback=target(p,rows)
 try:active=call(['systemctl','--user','is-active','opentabletdriver.service']).strip()=='active'
 except ValueError:active=False
 return {'version':1,'model':MODEL,'connected':connected(),'driver':active,'profile':p,'mappedOutput':m['name'],'fallback':fallback,'displays':[{'role':r,'output':v['name']} for r,v in roles(rows).items()],'area':area(p,m),'capabilities':{'pressure':True,'tilt':True,'eraser':True,'buttons':4,'globalPressureCurve':False},'note':'Pressure curves belong to the drawing app; driver threshold is shown separately. Physical pen feel requires a real stroke.'}

def binding(action,app):
 # Never emit editing shortcuts into terminals or other unrelated applications.
 if app not in ('com.github.xournalpp.xournalpp','xournalpp','org.kde.krita','krita','obsidian'):return None
 keys={'undo':'Control+Z','redo':'Control+Shift+Z','eraser':'E','pan':'Space'}
 if app in ('com.github.xournalpp.xournalpp','xournalpp'):keys['eraser']='Shift+Control+E'
 key=keys.get(action)
 if not key:return None
 return {'Path':'OpenTabletDriver.Desktop.Binding.MultiKeyBinding','Settings':[{'Property':'Keys','Value':key}],'Enable':True}

def driver_settings(source,p,rows,app):
 data=copy.deepcopy(source);profile=next((x for x in data['Profiles'] if x['Tablet']==MODEL),None)
 if profile is None:raise ValueError('Driver has not detected this tablet')
 m,_=target(p,rows);bounds={'Width':max(x['x']+x['width']/x['scale'] for x in rows)-min(x['x'] for x in rows),'Height':max(x['y']+x['height']/x['scale'] for x in rows)-min(x['y'] for x in rows)}
 profile['OutputMode']={'Path':'OpenTabletDriver.Desktop.Output.LinuxArtistMode','Settings':[],'Enable':True}
 mode=profile['AbsoluteModeSettings'];mode['Display']={**bounds,'X':bounds['Width']/2,'Y':bounds['Height']/2,'Rotation':0};mode['Tablet']=area(p,m);mode['LockAspectRatio']=False
 b=profile['Bindings'];b['DisablePressure']=False;b['DisableTilt']=False;b['TipActivationThreshold']=p['threshold'];b['EraserActivationThreshold']=p['threshold'];b['AuxButtons']=[binding(x,app) for x in p['buttons']]
 return data,m

def canvas_view():
 """Read only the owned scratch window's accessible viewport, never other app text."""
 try:
  active=json.loads(call(['hyprctl','-i','0','activewindow','-j']))
  saved=e.read(e.home()/'.local/state/sensei-drawing/current.json',{})
  if 'xournal' not in active.get('class','').lower() or Path(saved.get('path','/missing')).name not in active.get('title',''):return None
  import gi
  gi.require_version('Atspi','2.0')
  from gi.repository import Atspi
  Atspi.set_timeout(300,500)
  desktop=Atspi.get_desktop(0);views=[];zooms=[]
  def walk(n,depth=0):
   if depth>12:return
   role=n.get_role_name()
   if role=='viewport':
    r=n.get_component_iface().get_extents(Atspi.CoordType.WINDOW)
    if r.width>300 and r.height>200 and r.x>=0 and r.y>=0:views.append([r.x,r.y,r.width,r.height])
   if role=='slider':
    try:zooms.append(n.get_value_iface().get_current_value())
    except Exception:pass
   for i in range(n.get_child_count()):
    try:walk(n.get_child_at_index(i),depth+1)
    except Exception:pass
  for i in range(desktop.get_child_count()):
   app=desktop.get_child_at_index(i)
   if app.get_name()=='com.github.xournalpp.xournalpp' and app.get_process_id()==active.get('pid'):walk(app)
  if not views:return None
  return {'viewport':max(views,key=lambda r:r[2]*r[3]),'at':active['at'],'size':active['size'],'address':active['address'],'monitor':active.get('monitor'),'zoom':zooms}
 except (ImportError,ValueError,OSError,subprocess.SubprocessError):return None

def paper_bounds(image):
 """Find white paper within the accessible canvas; no image or ink is retained."""
 from PIL import Image
 # Downsample only for geometry recognition, not for displayed artwork.
 small=image.convert('RGB');small.thumbnail((640,400));w,h=small.size
 counts_x=[0]*w;counts_y=[0]*h
 for y in range(h):
  for x in range(w):
   r,g,b=small.getpixel((x,y))
   if min(r,g,b)>=244 and max(r,g,b)-min(r,g,b)<10:counts_x[x]+=1;counts_y[y]+=1
 xs=[i for i,v in enumerate(counts_x) if v>h*.25]
 ys=[i for i,v in enumerate(counts_y) if v>w*.25]
 if not xs or not ys:return None
 left,right=min(xs)*image.width/w,(max(xs)+1)*image.width/w
 top,bottom=min(ys)*image.height/h,(max(ys)+1)*image.height/h
 if right-left<160 or bottom-top<120:return None
 return [round(left+8),round(top+8),round(right-left-16),round(bottom-top-16)]

def drawable_region(m):
 view=canvas_view()
 if not view or view.get('monitor')!=m.get('id'):return None
 import io
 from PIL import Image
 x,y,w,h=view['viewport'];ax,ay=view['at']
 # GTK Wayland accessibility coordinates are window-local on this installation.
 capture=subprocess.run(['grim','-g',f'{ax+x},{ay+y} {w}x{h}','-'],capture_output=True,timeout=5,env=e.session_environment())
 if capture.returncode:return None
 with Image.open(io.BytesIO(capture.stdout)) as image:
  paper=paper_bounds(image);sx=image.width/w;sy=image.height/h
 if not paper:return None
 px,py,pw,ph=[round(v/(sx if i%2==0 else sy)) for i,v in enumerate(paper)]
 return {'x':ax+x+px-m['x'],'y':ay+y+py-m['y'],'width':pw,'height':ph,'kind':'scratch-paper'}

def reconcile():
 if not connected():return status()
 p=validate(prefs());rows=monitors()
 try:app=json.loads(call(['hyprctl','-i','0','activewindow','-j'])).get('class','').lower()
 except ValueError:app=''
 state=e.home()/'.local/state/sensei-drawing';state.mkdir(parents=True,exist_ok=True,mode=0o700)
 with e.locked(state/'driver.lock'):
  with tempfile.TemporaryDirectory(prefix='pen-',dir=state) as d:
   path=Path(d)/'settings.json';call(['otd','savesettings',str(path)]);source=json.loads(path.read_text())
   backup=state/'before-otd.json'
   if not backup.exists():e.save(backup,source)
   data,m=driver_settings(source,p,rows,app)
   region=drawable_region(m) if 'xournal' in app else None
   if region:
    profile=next(x for x in data['Profiles'] if x['Tablet']==MODEL)
    profile['AbsoluteModeSettings']['Tablet']=area(p,region)
   region=region or {'x':0,'y':0,'width':m['width']/m['scale'],'height':m['height']/m['scale'],'kind':'display'}
   if data!=source:
    e.save(path,data);call(['otd','loadsettings',str(path)]);call(['otd','savedefaultsettings'])
   # Loading an output profile can recreate uinput devices. Resolve them after it.
   name='';devices={}
   for _ in range(10):
    devices=json.loads(call(['hyprctl','-i','0','devices','-j']))
    name=next((x.get('name') for x in devices.get('tablets',[]) if 'opentabletdriver' in x.get('name','')),'')
    if name:break
    time.sleep(.1)
   if not name:raise ValueError('Artist Mode virtual pen is not present')
   # Older compositor sessions may retain native interfaces from before the OTD
   # udev ignore rule was installed. Never let those fight the virtual artist pen.
   for kind in ('mice','keyboards','tablets'):
    for raw in devices.get(kind,[]):
     raw_name=raw.get('name','')
     if raw_name.startswith('ugtablet-9-inch-pentablet'):
      call(['hyprctl','-i','0','eval','hl.device({name='+json.dumps(raw_name)+',enabled=false})'])
   # JSON quoting is a safe Lua string for these driver-owned device/output names.
   call(['hyprctl','-i','0','eval','hl.device({name='+json.dumps(name)+',output='+json.dumps(m['name'])+',region_position={'+str(region['x'])+','+str(region['y'])+'},region_size={'+str(region['width'])+','+str(region['height'])+'},active_area_position={0,0},active_area_size={0,0},transform=0,relative_input=false})'])
   e.save(state/'mapped.json',{'output':m['name'],'device':name,'at':time.time(),'profile':p,'region':region})
 return status()

def update(changes):
 p=validate(dict(prefs(),**changes));old=e.read(config(),{})
 with e.locked(config().with_suffix('.lock')):
  e.save(config(),p)
  try:return reconcile()
  except Exception:
   e.save(config(),old);raise

def scratch_root():return e.home()/'Study/Scratchpad'
def recent():
 folder=scratch_root();rows=[]
 for p in sorted(folder.glob('*.xopp'),key=lambda p:p.stat().st_mtime,reverse=True)[:20]:rows.append({'path':str(p),'name':p.stem,'modified':p.stat().st_mtime})
 return {'version':1,'drawings':rows}

def place(app,filename=None):
 # Match only the launched specialist, never move an unrelated active window.
 for _ in range(40):
  clients=json.loads(call(['hyprctl','-i','0','clients','-j']))
  matches=[x for x in clients if app in x.get('class','').lower() and (not filename or filename in x.get('title',''))]
  if matches:
   rows=monitors();m,_=target(prefs(),rows);address=matches[-1]['address']
   call(['hyprctl','-i','0','dispatch','hl.dsp.window.move({window='+json.dumps('address:'+address)+',workspace='+json.dumps(str(m['activeWorkspace']['id']))+',follow=false})']);call(['hyprctl','-i','0','dispatch','hl.dsp.focus({window='+json.dumps('address:'+address)+'})']);return
  time.sleep(.15)

def focus_ink():
 saved=e.read(e.home()/'.local/state/sensei-drawing/current.json',{})
 name=Path(saved.get('path','/missing')).name
 clients=json.loads(call(['hyprctl','-i','0','clients','-j']))
 for c in clients:
  if 'xournal' in c.get('class','').lower() and name in c.get('title',''):
   call(['hyprctl','-i','0','dispatch','hl.dsp.send_shortcut({mods="",key="F11",window='+json.dumps('address:'+c['address'])+'})'])
   return {'focusMode':not bool(c.get('fullscreen'))}
 raise ValueError('Open the scratchpad first')

def tool(name):
 if name not in ('pen','eraser'):raise ValueError('Choose Pen or Eraser')
 saved=e.read(e.home()/'.local/state/sensei-drawing/current.json',{})
 filename=Path(saved.get('path','/missing')).name
 for c in json.loads(call(['hyprctl','-i','0','clients','-j'])):
  if 'xournal' in c.get('class','').lower() and filename in c.get('title',''):
   key='P' if name=='pen' else 'E'
   call(['hyprctl','-i','0','dispatch','hl.dsp.send_shortcut({mods="CTRL|SHIFT",key='+json.dumps(key)+',window='+json.dumps('address:'+c['address'])+'})'])
   return {'tool':name}
 raise ValueError('Open the scratchpad first')


def quick(new=False):
 with e.locked(e.home()/'.local/state/sensei-drawing/scratch.lock'):return _quick(new)

def _quick(new=False):
 folder=scratch_root();folder.mkdir(parents=True,exist_ok=True,mode=0o700);saved=e.read(e.home()/'.local/state/sensei-drawing/current.json',{})
 path=Path(saved.get('path','/missing'))
 if new or not path.is_file() or path.parent!=folder:
  stamp=datetime.datetime.now().strftime('%Y-%m-%d %H-%M-%S');path=folder/f'Den Ink {stamp}-{uuid.uuid4().hex[:4]}.xopp'
  with gzip.open(path,'wb') as f:f.write(b'<?xml version="1.0" standalone="no"?><xournal creator="Xournal++" fileversion="4"><title>Den Ink</title><page width="842" height="595"><background type="solid" color="#ffffffff" style="plain"/><layer/></page></xournal>')
  path.chmod(0o600);e.save(e.home()/'.local/state/sensei-drawing/current.json',{'path':str(path)})
 clients=json.loads(call(['hyprctl','-i','0','clients','-j']))
 if any('xournal' in x.get('class','').lower() and path.name in x.get('title','') for x in clients):
  place('xournal',path.name);return {'path':str(path),'editable':True,'resumed':True}
 subprocess.Popen(['xournalpp',str(path)],env=e.session_environment(),stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True);place('xournal',path.name);return {'path':str(path),'editable':True}

def learning():
 projection=e.read(e.home()/'.local/state/sensei-learning/companion.json',{});ctx=projection.get('context',{})
 root=ctx.get('vault') or e.read(e.home()/'.config/sensei-learning/config.json',{}).get('active_vault')
 if not root:raise ValueError('Choose a learning vault in Noesis first')
 binary=str(e.home()/'.local/bin/noesis');identity=ctx.get('id')
 if not identity:
  row=json.loads(call([binary,'record','question','Quick learning sketch','--vault',root,'--body','A spontaneous diagram; not an assessment.']))
  identity=row.get('id')
 if not identity:raise ValueError('Open the learning record you want to draw about')
 row=json.loads(call([binary,'drawing-create',identity,'--vault',root,'--title','Sketch '+datetime.datetime.now().strftime('%Y-%m-%d %H-%M'),'--mode','freehand','--operation-id',str(uuid.uuid4())],30))
 call([binary,'artifact-open',row['id'],'--vault',root],30);place('obsidian');return row

def export(path):
 p=Path(path).expanduser().resolve();folder=scratch_root().resolve()
 if p.parent!=folder or p.suffix!='.xopp' or not p.is_file():raise ValueError('Choose a saved scratch sheet')
 out=p.with_suffix('.pdf');call(['xournalpp','-p',str(out),str(p)],30)
 if not out.is_file():raise ValueError('Preview export was not confirmed')
 out.chmod(0o600)
 return {'editable':str(p),'preview':str(out)}

def attach():
 saved=e.read(e.home()/'.local/state/sensei-drawing/current.json',{});result=export(saved.get('path',''))
 root=e.read(e.home()/'.config/sensei-learning/config.json',{}).get('active_vault')
 if not root:raise ValueError('Choose a learning vault; the scratch is safely saved')
 # Durable artifact links the one editable source; no second editable copy.
 row=json.loads(call([str(e.home()/'.local/bin/noesis'),'record','artifact',Path(result['editable']).stem,'--vault',root,'--operation-id',str(uuid.uuid5(uuid.NAMESPACE_URL,str(root)+result['editable'])),'--body','Native handwriting scratch. Editable source: '+result['editable']+'\n\nPreview: '+result['preview'],'--data',json.dumps({'location':result['editable'],'artifact_kind':'drawing','drawing_format':'xopp'})],30))
 return dict(result,record=row)
