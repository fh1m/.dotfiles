"""Explicit, one-way Homie playback through a selected Arete output."""
import array,fcntl,json,math,os,shlex,signal,stat,subprocess,time
from pathlib import Path
HOME=Path.home();CONFIG=HOME/'.config/sensei-den/audio.json';STATE=HOME/'.local/state/sensei-den/audio-state.json'
UNIT='sensei-den-audio.service';HUB='alsa_input.usb-_Powerlink_Combi-00.mono-fallback'
def command(argv,**kwargs):return subprocess.run(argv,capture_output=True,text=True,timeout=8,**kwargs)
def read(path):
 try:return json.loads(path.read_text())
 except (OSError,ValueError):return {}
def write(path,value):
 path.parent.mkdir(parents=True,exist_ok=True,mode=0o700);tmp=path.with_suffix('.tmp');tmp.write_text(json.dumps(value));tmp.chmod(0o600);tmp.replace(path)
def desktop():return read(HOME/'.config/sensei/machine.json').get('profile')=='pc'
def forward(args):
 conf=HOME/'.local/state/homie-control/master-client.conf'
 r=command(['ssh','-T','-o','BatchMode=yes','-o','ConnectTimeout=3','-F',str(conf),'arete-den-control',shlex.join(['den-audio',*args])])
 if r.returncode:raise ValueError('Arete audio control is unavailable. Check the laptop connection.')
 return json.loads(r.stdout)
def nodes(kind):
 r=command(['pactl','-f','json','list',kind])
 if r.returncode:raise ValueError('PipeWire audio is unavailable.')
 return json.loads(r.stdout)
def level(node):
 values=[v.get('value',0)/65536*100 for v in node.get('volume',{}).values()]
 return round(max(values,default=0))
def output_record(n):
 ports=n.get('ports',[])
 if isinstance(ports,dict):ports=list(ports.values())
 port=next((p for p in ports if p.get('name')==n.get('active_port')), {})
 return {'name':n['name'],'description':n.get('description',n['name']),'port':port.get('description',n.get('active_port','')),'ports':[{'name':p['name'],'description':p.get('description',p['name']),'available':p.get('availability',p.get('available','unknown'))} for p in ports],'activePort':n.get('active_port',''),'muted':n.get('mute',False),'volume':level(n),'state':n.get('state','unknown'),'format':n.get('sample_specification','')}
def signal_probe(sink):
 # Playback monitor only. Samples stay in RAM; never record a microphone.
 p=subprocess.Popen(['parec','--device='+sink+'.monitor','--format=s16le','--rate=48000','--channels=1','--latency-msec=20','--raw'],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
 try:p.communicate(timeout=1.5)
 except subprocess.TimeoutExpired:
  p.terminate()
  try:raw=p.communicate(timeout=2)[0]
  except subprocess.TimeoutExpired:p.kill();raw=p.communicate()[0]
 else:raise ValueError('Playback monitor could not be sampled.')
 samples=array.array('h',raw[:len(raw)//2*2]);peak=max((abs(v) for v in samples),default=0);rms=math.sqrt(sum(v*v for v in samples)/max(1,len(samples)))
 if not samples:raise ValueError('Playback monitor returned no samples. Refresh the route and retry.')
 return {'detected':peak>8,'peakDb':round(20*math.log10(max(1,peak)/32768),1),'rmsDb':round(20*math.log10(max(1,rms)/32768),1),'samples':len(samples)}
def peer(check=False):
 sink=command(['pactl','get-default-sink']).stdout.strip();out=next((n for n in nodes('sinks') if n['name']==sink),None)
 if not out:raise ValueError('Homie has no default playback output.')
 data=output_record(out);data['applications']=[{'name':n.get('properties',{}).get('application.name','Audio app'),'muted':n.get('mute',False),'volume':level(n),'sink':n.get('sink')} for n in nodes('sink-inputs')]
 if check:data['signal']=signal_probe(sink)
 return data
def remote(args):
 r=command(['ssh','-T','-o','BatchMode=yes','-o','ConnectTimeout=3','-F',str(HOME/'.local/state/homie-control/client.conf'),'homie',shlex.join([str(HOME/'.local/bin/sensei-den-audio'),'peer',*args])])
 if r.returncode:raise ValueError('Homie is unavailable or its audio helper needs updating.')
 return json.loads(r.stdout)
def status():
 prefs=read(CONFIG);out=nodes('sinks');sources=nodes('sources');active=command(['systemctl','--user','is-active',UNIT]).stdout.strip()=='active'
 selected=next((n for n in out if n['name']==prefs.get('output')),None);streams=nodes('sink-inputs')
 linked=any(n.get('sink')==selected['index'] and n.get('properties',{}).get('node.name')=='den-homie-audio' for n in streams) if selected else False
 data={'active':active,'linked':linked,'mode':prefs.get('mode','lan'),'output':prefs.get('output',''),'outputs':[output_record(n) for n in out],'destination':output_record(selected) if selected else {},'hubAvailable':any(n['name']==HUB for n in sources),'error':'' if active else read(STATE).get('error',''),'note':'Stereo / 48 kHz · encrypted LAN · playback only' if prefs.get('mode','lan')=='lan' else 'PowerCombi microphone input · mono · requires a cable into the input contact'}
 if active:
  try:data['source']=remote([])
  except (ValueError,OSError,subprocess.SubprocessError):data['error']='Homie cannot be reached. Check LAN/SSH; Stop and Listen to reconnect.'
  if not selected:data['error']='Selected laptop output was disconnected. Choose another output.'
  elif prefs.get('mode','lan')=='lan' and not linked:data['error']='Route is starting or disconnected. Refresh; if it persists, select Listen again.'
  elif selected.get('mute'):data['error']='Laptop destination is muted. Unmute it in Outputs.'
  elif level(selected)==0:data['error']='Laptop destination volume is zero.'
  elif data.get('source',{}).get('muted'):data['error']='Homie playback output is muted.'
 data['signal']=read(STATE).get('signal',{})
 return data
def check():
 prefs=read(CONFIG);destination=prefs.get('output','')
 if destination not in {n['name'] for n in nodes('sinks')}:raise ValueError('Choose an attached laptop output first.')
 source=remote(['check']);sink=signal_probe(destination)
 receipt={'at':time.time(),'source':source.get('signal',{}),'destination':sink}
 receipt['message']='Signal reaches the laptop output. Check its physical jack/port if inaudible.' if sink['detected'] else 'Homie is producing sound, but it has not reached this laptop output.' if source.get('signal',{}).get('detected') else 'No PC playback detected. Start a song or use Test PC sound, then check again.'
 write(STATE,{'signal':receipt,'error':''});return status()
def test_sound():
 # Quiet, fading chord on the PC; does not seize a Spotify session or change gain.
 samples=array.array('h')
 for i in range(96000):
  fade=min(1,i/2400,(96000-i)/2400);v=int(2200*fade*(math.sin(i*2*math.pi*440/48000)+math.sin(i*2*math.pi*660/48000))*.5);samples.extend((v,v))
 subprocess.run(['pw-play','--raw','--format=s16','--rate=48000','--channels=2','-'],input=samples.tobytes(),check=True,timeout=5,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 return {'ok':True}
def start(mode,output):
 if mode not in ('lan','aux'):raise ValueError('Choose LAN or AUX audio.')
 if output not in {n['name'] for n in nodes('sinks')}:raise ValueError('Select an attached laptop output.')
 if mode=='aux' and HUB not in {n['name'] for n in nodes('sources')}:raise ValueError('PowerCombi capture input is not attached.')
 command(['systemctl','--user','stop',UNIT]);write(CONFIG,{'mode':mode,'output':output});write(STATE,{'error':''})
 r=command(['systemd-run','--user','--unit=sensei-den-audio','--collect','--quiet','--property=Restart=on-failure','--property=RestartSec=3s','--property=StartLimitIntervalSec=60s','--property=StartLimitBurst=3',str(HOME/'.local/bin/sensei-den-audio'),'worker',mode,output])
 if r.returncode:raise ValueError('Could not start the owned audio route.')
 time.sleep(.6)
 return status()
def stop():
 command(['systemctl','--user','stop',UNIT]);write(STATE,{'error':''});return status()
def port(output,name):
 node=next((n for n in nodes('sinks') if n['name']==output),None)
 if not node or name not in {p['name'] for p in output_record(node)['ports']}:raise ValueError('Select an available output port.')
 if command(['pactl','set-sink-port',output,name]).returncode:raise ValueError('Output port could not be selected.')
 return status()
def worker(mode,output):
 if mode not in ('lan','aux') or output not in {n['name'] for n in nodes('sinks')}:raise ValueError('Invalid audio route.')
 processes=[];oldmute=None;oldvol=None;stopping=False;failed=False;fifo=None;fifo_fd=None
 def terminate(*_):
  nonlocal stopping
  stopping=True
  for p in processes:
   if p.poll() is None:p.terminate()
 signal.signal(signal.SIGTERM,terminate);signal.signal(signal.SIGINT,terminate)
 try:
  if mode=='aux':
   source=next(n for n in nodes('sources') if n['name']==HUB);oldmute=source['mute'];oldvol=[str(v['value']) for v in source['volume'].values()]
   command(['pactl','set-source-mute',HUB,'0']);command(['pactl','set-source-volume',HUB,'8%'])
   processes.append(subprocess.Popen(['pw-loopback','--name','Den Homie AUX','--capture',HUB,'--playback',output,'--channels','1','--latency','50'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL))
  else:
   # Capture the PC's playback monitor, never its microphone. No open audio port.
   remote='parec --device=@DEFAULT_MONITOR@ --format=s16le --rate=48000 --channels=2 --latency-msec=30 --raw'
   # PipeWire's pipe tunnel rate-adapts between host clocks; pw-play treats a
   # raw network stream as a file and can accumulate jitter/drift.
   fifo=HOME/'.local/state/sensei-den/homie-audio.pcm'
   fifo.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
   if fifo.exists() or fifo.is_symlink():
    if not stat.S_ISFIFO(fifo.lstat().st_mode):raise ValueError('Audio FIFO path contains a non-FIFO file; refusing to replace it.')
    fifo.unlink()
   os.mkfifo(fifo,0o600)
   fifo_fd=os.open(fifo,os.O_RDWR)
   props={'tunnel.mode':'playback','tunnel.may-pause':True,'pipe.filename':str(fifo),'audio.format':'S16LE','audio.rate':48000,'audio.channels':2,'stream.props':{'target.object':output,'node.name':'den-homie-audio','node.description':'Homie / Den Audio','application.name':'Homie / Den Audio','node.latency':'2048/48000','stream.is-live':True}}
   play=subprocess.Popen(['pw-cli','-m','load-module','libpipewire-module-pipe-tunnel',json.dumps(props)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);processes.append(play)
   ssh=subprocess.Popen(['ssh','-T','-o','BatchMode=yes','-o','ConnectTimeout=4','-o','ServerAliveInterval=5','-o','ServerAliveCountMax=2','-o','Compression=no','-F',str(HOME/'.local/state/homie-control/client.conf'),'homie',remote],stdout=fifo_fd,stderr=subprocess.DEVNULL);processes.append(ssh)

  while not stopping and all(p.poll() is None for p in processes):time.sleep(.2)
  if not stopping:
   failed=True;write(STATE,{'error':'Audio route ended. Reconnecting briefly; if it stays off, check Homie/output and select Listen.'})
 finally:
  terminate()
  for p in processes:
   try:p.wait(timeout=3)
   except subprocess.TimeoutExpired:p.kill();p.wait()
  if fifo_fd is not None:os.close(fifo_fd)
  if fifo is not None:fifo.unlink(missing_ok=True)
  if oldmute is not None:
   command(['pactl','set-source-mute',HUB,str(int(oldmute))]);command(['pactl','set-source-volume',HUB,*oldvol])
 if failed:raise ValueError('Audio route disconnected; bounded reconnect attempts exhausted or pending.')
 return {'stopped':True}
def dispatch(args):
 if args[0]=='peer':return test_sound() if args[1:]==['test'] else peer(args[1:]==['check'])
 if desktop():return forward(args)
 if args[0]=='status':return status()
 if args[0]=='worker':return worker(args[1],args[2])
 path=STATE.with_name('audio.lock');path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
 with path.open('a') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX)
  return change(args)
def change(args):
 if args[0]=='start':return start(args[1],args[2])
 if args[0]=='stop':return stop()
 if args[0]=='port':return port(args[1],args[2])
 if args[0]=='check':return check()
 if args[0]=='test':remote(['test']);return status()
 raise ValueError('Unknown audio action.')
