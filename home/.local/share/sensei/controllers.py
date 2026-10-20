"""Capability-based gamepad monitoring; never grabs devices or changes game input."""
import hashlib,json,os,select,time,math,shlex,subprocess,re,shutil
from pathlib import Path
import evdev
from evdev import ecodes as E
CONFIG=Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config')))/'sensei/controllers.json'
def profiles():
 try:data=json.loads(CONFIG.read_text())
 except (OSError,ValueError):return {}
 if not isinstance(data,dict):return {}
 result={}
 for key,p in data.items():
  if not isinstance(p,dict):continue
  zone=p.get('deadzone',.04)
  if not isinstance(zone,(int,float)) or not math.isfinite(zone) or not 0<=zone<=.4:zone=.04
  axes={}
  for code,a in (p.get('axes',{}) if isinstance(p.get('axes'),dict) else {}).items():
   if not isinstance(a,dict):continue
   lo,hi,center=(a.get(n) for n in ('min','max','center'))
   if all(isinstance(v,(int,float)) and math.isfinite(v) for v in (lo,hi,center)) and lo<hi and lo<=center<=hi:axes[code]={'min':lo,'max':hi,'center':center}
  r=p.get('ros',{}) if isinstance(p.get('ros'),dict) else {};rate=r.get('rate',20.0);dead=r.get('deadzone',.05)
  if not isinstance(rate,(int,float)) or not math.isfinite(rate) or not 0<=rate<=1000:rate=20.0
  if not isinstance(dead,(int,float)) or not math.isfinite(dead) or not 0<=dead<=.3:dead=.05
  result[key]={'deadzone':zone,'axes':axes,'enabled':p.get('enabled') is not False,'ros':{'rate':rate,'deadzone':dead,'node':r.get('node') if r.get('node') in ('joy_node','game_controller_node') else 'joy_node','sticky':r.get('sticky') is True,'coalesce':r.get('coalesce') if isinstance(r.get('coalesce'),int) and 0<=r['coalesce']<=1000 else 1,'controller_name':str(r.get('controller_name',''))[:200],'device_name':str(r.get('device_name',''))[:200],'environment':str(r.get('environment',''))[:64],'mapped':r.get('mapped') if isinstance(r.get('mapped'),bool) else None}}
 return result
def save(data):
 CONFIG.parent.mkdir(parents=True,exist_ok=True);p=CONFIG.with_suffix('.tmp');p.write_text(json.dumps(data,indent=2)+'\n');p.chmod(0o600);p.replace(CONFIG)
def normalized(value,low,high,center=None,trigger=False,deadzone=0):
 if high<=low:return 0
 if trigger:return round(max(0,min(1,(value-low)/(high-low))),4)
 center=(low+high)/2 if center is None else center
 width=(high-center) if value>=center else (center-low)
 result=max(-1,min(1,(value-center)/max(1,width)))
 return 0 if abs(result)<deadzone else round(result,4)
def gamepad(caps):
 buttons=caps.get(E.EV_KEY,[]);axes=caps.get(E.EV_ABS,[])
 return (E.BTN_GAMEPAD in buttons or E.BTN_JOYSTICK in buttons) and E.ABS_X in axes and E.ABS_Y in axes
def devices():
 result=[]
 for path in evdev.list_devices():
  try:
   d=evdev.InputDevice(path)
   if gamepad(d.capabilities(absinfo=False)):result.append(d)
   else:d.close()
  except (PermissionError,OSError):continue
 return result
def identity(d):return hashlib.sha256(f'{d.info.vendor}:{d.info.product}:{d.name}:{d.uniq or d.phys}'.encode()).hexdigest()[:20]
def label(code):
 names=E.ABS.get(code,E.BTN.get(code,str(code)))
 return names[0] if isinstance(names,list) else names
def layout(axes):
 sticks=[{'name':'Left stick','x':E.ABS_X,'y':E.ABS_Y}];triggers=[]
 if E.ABS_RX in axes and E.ABS_RY in axes:
  sticks.append({'name':'Right stick','x':E.ABS_RX,'y':E.ABS_RY});triggers=[c for c in (E.ABS_Z,E.ABS_RZ) if c in axes]
 elif E.ABS_Z in axes and E.ABS_RZ in axes:sticks.append({'name':'Right stick','x':E.ABS_Z,'y':E.ABS_RZ})
 triggers += [c for c in (E.ABS_GAS,E.ABS_BRAKE) if c in axes]
 return {'sticks':sticks,'triggers':triggers,'dpad':E.ABS_HAT0X in axes and E.ABS_HAT0Y in axes}
def button_label(code):
 names={E.BTN_SOUTH:'A',E.BTN_EAST:'B',E.BTN_NORTH:'X',E.BTN_WEST:'Y',E.BTN_TL:'LB',E.BTN_TR:'RB',E.BTN_TL2:'LT',E.BTN_TR2:'RT',E.BTN_SELECT:'Select',E.BTN_START:'Start',E.BTN_MODE:'Guide',E.BTN_THUMBL:'L3',E.BTN_THUMBR:'R3'}
 return names.get(code,'Button '+str(code-E.BTN_JOYSTICK+1) if E.BTN_JOYSTICK<=code<E.BTN_GAMEPAD else str(E.BTN.get(code,code)))
def snapshot(d,profile):
 caps=d.capabilities(absinfo=False);cal=profile.get('axes',{});axes=[];mapping=layout(caps.get(E.EV_ABS,[]))
 for code in caps.get(E.EV_ABS,[]) if profile.get('enabled',True) else []:
  a=d.absinfo(code);c=cal.get(str(code),{});trigger=code in mapping['triggers']
  axes.append({'code':code,'name':label(code),'raw':a.value,'min':a.min,'max':a.max,'flat':a.flat,'fuzz':a.fuzz,'trigger':trigger,'value':normalized(a.value,c.get('min',a.min),c.get('max',a.max),c.get('center'),trigger,profile.get('deadzone',.04))})
 return {'id':identity(d),'name':d.name.strip(),'rawName':d.name,'ros':profile.get('ros',{'rate':20.0,'deadzone':.05,'node':'joy_node','sticky':False,'coalesce':1}),'path':d.path,'layout':mapping,'connection':'Bluetooth' if d.info.bustype==5 else 'USB' if d.info.bustype==3 else 'Input','physical':d.phys,'serial':d.uniq or '', 'driver':Path('/sys/class/input/'+Path(d.path).name+'/device/device/driver').resolve().name if Path('/sys/class/input/'+Path(d.path).name+'/device/device/driver').exists() else 'kernel input','vendor':f'{d.info.vendor:04x}','product':f'{d.info.product:04x}','bus':d.info.bustype,'axes':axes,'pressed':[{'code':c,'name':button_label(c)} for c in (d.active_keys() if profile.get('enabled',True) else [])],'buttons':[{'code':c,'name':button_label(c)} for c in caps.get(E.EV_KEY,[])],'rumble':E.FF_RUMBLE in caps.get(E.EV_FF,[]),'calibrated':bool(cal),'monitoring':profile.get('enabled',True),'deadzone':profile.get('deadzone',.04)}
def inventory(opened=None):
 own=opened is None;opened=devices() if own else opened;p=profiles();rows=[]
 try:
  for d in opened:
   try:rows.append(snapshot(d,p.get(identity(d),{})))
   except OSError:continue
 finally:
  if own:
   for d in opened:d.close()
 return {'controllers':rows,'note':'Read-only evdev tester. Calibration/deadzone profiles affect this viewer, not Steam, SDL or game settings. No input is grabbed.'}
def watch():
 opened=[];refresh=0;last='';last_emit=0;history={}
 try:
  while True:
   if time.monotonic()>refresh:
    for d in opened:d.close()
    opened=devices();refresh=time.monotonic()+2
   if time.monotonic()-last_emit>=1/30:
    packet=inventory(opened)
    for row in packet['controllers']:row['events']=history.get(row['id'],[]) if row['monitoring'] else []
    text=json.dumps(packet)
    if text!=last:print(text,flush=True);last=text
    last_emit=time.monotonic()
   ready,_,_=select.select(opened,[],[],.033) if opened else ([],[],[])
   for d in ready:
    try:
     for event in d.read():
      if event.type in (E.EV_KEY,E.EV_ABS):
       key=identity(d);history[key]=(history.get(key,[])+[{'name':label(event.code) if event.type==E.EV_ABS else button_label(event.code),'value':event.value,'type':'axis' if event.type==E.EV_ABS else 'button'}])[-8:]
    except OSError:refresh=0
   if not opened:time.sleep(.25)
 finally:
  for d in opened:d.close()
def find(key):
 found=None
 for d in devices():
  if identity(d)==key and found is None:found=d
  else:d.close()
 if found is None:raise ValueError('Controller disconnected or identity changed; refresh first')
 return found
def setting(key,name,value):
 if name=='deadzone':
  value=float(value)
  if not math.isfinite(value) or not 0<=value<=.4:raise ValueError('Deadzone must be between 0 and 0.4')
 elif name=='enabled':
  if value not in ('on','off'):raise ValueError('Use on or off')
  value=value=='on'
 elif name=='reset':name='axes';value={}
 elif name in ('ros-rate','ros-deadzone','ros-coalesce'):
  value=float(value)
  if not math.isfinite(value) or not ((0<=value<=1000) if name in ('ros-rate','ros-coalesce') else (0<=value<=.3)):raise ValueError('ROS rate/coalescing must be 0–1000; ROS deadzone must be 0–0.3')
  if name=='ros-coalesce':
   if value!=int(value):raise ValueError('Coalescing interval must be whole milliseconds')
   value=int(value)
 elif name=='ros-node':
  if value not in ('joy_node','game_controller_node'):raise ValueError('Choose joy_node or game_controller_node')
 elif name=='ros-sticky':
  if value not in ('on','off'):raise ValueError('Use on or off')
  value=value=='on'
 else:raise ValueError('Unsupported setting')
 d=find(key);d.close();p=profiles();profile=p.setdefault(key,{})
 if name.startswith('ros-'):profile.setdefault('ros',{})[{'ros-rate':'rate','ros-deadzone':'deadzone','ros-node':'node','ros-sticky':'sticky','ros-coalesce':'coalesce'}[name]]=value
 else:profile[name]=value
 save(p);return {'saved':name,'id':key}
def rumble(key):
 from evdev import ff
 d=find(key)
 try:
  if E.FF_RUMBLE not in d.capabilities(absinfo=False).get(E.EV_FF,[]):raise ValueError('This controller does not report rumble support')
  effect=ff.Effect(E.FF_RUMBLE,-1,0,ff.Trigger(0,0),ff.Replay(350,0),ff.EffectType(ff_rumble_effect=ff.Rumble(strong_magnitude=12000,weak_magnitude=6000)))
  number=d.upload_effect(effect)
  try:d.write(E.EV_FF,number,1);time.sleep(.4)
  finally:d.erase_effect(number)
 finally:d.close()
 return {'note':'350 ms rumble test completed'}
def calibrate(key):
 d=find(key);samples={};start=time.monotonic()
 try:
  while time.monotonic()-start<12:
   age=time.monotonic()-start
   for code in d.capabilities(absinfo=False).get(E.EV_ABS,[]):
    a=d.absinfo(code);s=samples.setdefault(str(code),{'min':a.value,'max':a.value,'neutral':[]})
    s['min']=min(s['min'],a.value);s['max']=max(s['max'],a.value)
    if age<2:s['neutral'].append(a.value)
   print(json.dumps({'phase':'Keep sticks released' if age<2 else 'Rotate sticks fully; sweep triggers','remaining':round(12-age)}),flush=True);time.sleep(.1)
  axes={k:{'min':s['min'],'max':s['max'],'center':sum(s['neutral'])/len(s['neutral'])} for k,s in samples.items() if s['max']-s['min']>10 and s['neutral']}
  if not axes:raise ValueError('No sufficient axis movement observed; calibration was not changed')
  p=profiles();p.setdefault(key,{})['axes']=axes;save(p)
  return {'note':'Viewer calibration saved. Game calibration is separate; reset is available.','axes':len(axes)}
 finally:d.close()

def export_ros(key):
 d=find(key)
 try:row=snapshot(d,profiles().get(key,{}))
 finally:d.close()
 r=row['ros'];folder=Path(os.environ.get('XDG_DATA_HOME',str(Path.home()/'.local/share')))/'sensei-controllers/exports'/key/str(time.time_ns());folder.mkdir(parents=True,exist_ok=False,mode=0o700)
 params={'device_name':(r.get('controller_name') if r['node']=='game_controller_node' else r.get('device_name')) or row['rawName'],'deadzone':float(r['deadzone']),'autorepeat_rate':float(r['rate']),'coalesce_interval_ms':int(r.get('coalesce',1)),'sticky_buttons':bool(r['sticky'])}
 # JSON is valid YAML 1.2; write conventional ROS YAML without a YAML dependency.
 text='/**:\n  ros__parameters:\n'+''.join('    '+k+': '+json.dumps(v)+'\n' for k,v in params.items())
 path=folder/'joy.yaml';path.write_text(text);path.chmod(0o600)
 (folder/'device.json').write_text(json.dumps({k:row[k] for k in ['id','name','vendor','product','physical','layout','driver']},indent=2)+'\n')
 command='ros2 run joy '+r['node']+' --ros-args --params-file '+shlex.quote(str(path))+' -r __ns:=/den/input'
 (folder/'README.md').write_text('# Controller input profile\n\n'+command+'\n\nRun inside your chosen ROS 2 environment after sourcing it. First run `ros2 run joy joy_enumerate_devices` and verify device_name matches this controller. Containers need explicit access to this joystick; no device permissions or container settings were changed.\n\nInspect `/den/input/joy` before defining any teleoperation mapping. Evdev axis/button codes in the desktop tester are not ROS Joy array indices. This export publishes input only: no teleop node, cmd_vel, arming or vehicle control. For actual teleoperation, configure a held enable/dead-man button, verify axes in simulation, and use a command timeout in the robot controller.\n')
 return {'note':'ROS input-only profile exported. Verify SDL device name inside your ROS environment; no robot commands were launched.','path':str(folder),'command':command}

def environments():
 names=[]
 if shutil.which('docker'):
  result=subprocess.run(['docker','ps','--format','{{.Names}}'],capture_output=True,text=True,timeout=5)
  if result.returncode==0:names=[n for n in result.stdout.splitlines() if re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,63}',n)]
 return {'environments':['host']+names}

def parse_ros_devices(text):
 rows=[]
 for line in text.splitlines():
  match=re.fullmatch(r'\s*(\d+)\s*:\s*([0-9a-fA-F]{32})\s*:\s*(true|false)\s*:\s*(true|false)\s*:\s*(.+)',line)
  if not match:continue
  index,guid,gamepad,mapped,name=match.groups();raw=bytes.fromhex(guid)
  rows.append({'index':int(index),'vendor':int.from_bytes(raw[4:6],'little'),'product':int.from_bytes(raw[8:10],'little'),'name':name.strip()[:200],'mapped':mapped=='true','guid':guid.lower()})
 return rows

def probe_ros(key,environment):
 if environment not in environments()['environments']:raise ValueError('Choose host or a running Docker environment')
 d=find(key)
 try:vendor,product=d.info.vendor,d.info.product
 finally:d.close()
 # SDL's mapped controller name may differ from the raw joystick name used by joy_node.
 script="""import ctypes as C,json
s=C.CDLL('libSDL2-2.0.so.0')
class GUID(C.Structure):_fields_=[('data',C.c_ubyte*16)]
s.SDL_JoystickGetDeviceGUID.restype=GUID
s.SDL_JoystickNameForIndex.restype=C.c_char_p
s.SDL_GameControllerNameForIndex.restype=C.c_char_p
if s.SDL_Init(0x2200):raise SystemExit(4)
try:
 rows=[]
 for i in range(s.SDL_NumJoysticks()):
  raw=bytes(s.SDL_JoystickGetDeviceGUID(i).data);name=s.SDL_JoystickNameForIndex(i);mapped=s.SDL_GameControllerNameForIndex(i)
  rows.append({'vendor':int.from_bytes(raw[4:6],'little'),'product':int.from_bytes(raw[8:10],'little'),'name':(name or b'').decode(),'controller_name':(mapped or b'').decode(),'mapped':bool(s.SDL_IsGameController(i))})
 print(json.dumps(rows))
finally:s.SDL_Quit()
"""
 cmd=['python3','-c',script] if environment=='host' else ['docker','exec',environment,'python3','-c',script]
 result=subprocess.run(cmd,capture_output=True,text=True,timeout=10)
 if result.returncode:raise ValueError('SDL2 enumeration unavailable here. Install Python 3 and SDL2 inside the chosen ROS environment first.')
 if len(result.stdout)>65536:raise ValueError('ROS device report exceeded the bounded limit')
 matches=[row for row in json.loads(result.stdout) if row['vendor']==vendor and row['product']==product]
 if len(matches)!=1:raise ValueError('ROS identity is absent or ambiguous. Check device access and identical-controller ordering in this environment.')
 row=matches[0];p=profiles();r=p.setdefault(key,{}).setdefault('ros',{});r.update(device_name=row['name'],environment=environment,mapped=row['mapped'],controller_name=row.get('controller_name',''));save(p)
 return {'note':'ROS input verified in '+environment+': '+row['name']+' · '+('SDL mapping available' if row['mapped'] else 'no SDL mapping reported; use generic joystick unless you supply a mapping'),'ros':row}
