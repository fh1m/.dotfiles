"""Explicit, bounded receiver actions. No network listener or background scanning."""
import contextlib,csv,fcntl,json,os,select,shutil,signal,subprocess,time,uuid
from pathlib import Path
ROOT=Path.home()/'.local/state/sensei-radio'
BANDS={'fm':('FM broadcast',88e6,108e6,100e3),'ism433':('433 MHz ISM',433.05e6,434.79e6,10e3),'ism868':('868 MHz ISM',863e6,870e6,25e3),'ism915':('915 MHz ISM',902e6,928e6,100e3),'air':('Airband spectrum',118e6,137e6,25e3),'cellular':('900 MHz spectrum only',935e6,960e6,100e3),'adsb':('1090 MHz beacon spectrum',1089e6,1091e6,10e3)}
def save(path,value):
 path.parent.mkdir(parents=True,exist_ok=True,mode=0o700);tmp=path.with_name(path.name+'.'+str(os.getpid())+'.tmp')
 with tmp.open('w') as f:os.chmod(tmp,0o600);json.dump(value,f)
 tmp.replace(path)
def receipt(value):
 value=dict(value,id=uuid.uuid4().hex)
 save(ROOT/'receipts'/(value['id']+'.json'),value);save(ROOT/'latest.json',value)
 return value

def history():
 records=[]
 for path in sorted((ROOT/'receipts').glob('*.json'),key=lambda p:p.stat().st_mtime,reverse=True)[:40]:
  try:
   value=json.loads(path.read_text());records.append({k:v for k,v in value.items() if k not in ('bins','packets')})
  except (OSError,ValueError):continue
 return {'receipts':records}


def devices():
 rows=[]
 for p in Path('/sys/bus/usb/devices').glob('*'):
  try:
   if (p/'idVendor').read_text().strip()=='0bda' and (p/'idProduct').read_text().strip() in ('2832','2838'):
    rows.append({'node':p.name,'name':(p/'product').read_text().strip(),'vendor':'0bda','product':(p/'idProduct').read_text().strip()})
  except OSError:pass
 return rows
def status():
 try:receipt=json.loads((ROOT/'latest.json').read_text())
 except (OSError,ValueError):receipt={}
 return {'devices':devices(),'tools':{x:bool(shutil.which(x)) for x in ('rtl_test','rtl_power','rtl_fm','rtl_433','gqrx')},'receipt':receipt,'bands':[{'id':k,'label':v[0],'lowMHz':v[1]/1e6,'highMHz':v[2]/1e6} for k,v in BANDS.items()]}
@contextlib.contextmanager
def receiver():
 if not devices():raise ValueError('Connect the RTL-SDR receiver to this machine.')
 ROOT.mkdir(parents=True,exist_ok=True,mode=0o700)
 with (ROOT/'receiver.lock').open('a') as f:
  try:fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB)
  except BlockingIOError:raise ValueError('Radio is in use by a Den action. Stop FM before another capture.') from None
  yield

def bounded(argv,seconds):
 try:r=subprocess.run(argv,capture_output=True,text=True,timeout=seconds)
 except subprocess.TimeoutExpired as e:
  return (e.stdout or b'').decode(errors='replace') if isinstance(e.stdout,bytes) else e.stdout or '',(e.stderr or b'').decode(errors='replace') if isinstance(e.stderr,bytes) else e.stderr or ''
 if r.returncode:raise ValueError('Receiver could not open. Close Gqrx/other SDR tools, check the USB cable and permissions, then retry.')
 return r.stdout,r.stderr

def test():
 with receiver():
  out,err=bounded(['rtl_test','-s','2048000'],7);text=out+err
  if 'Sampling at' not in text:raise ValueError('Receiver did not reach sampling state. Check USB access and close other receiver apps.')
  import re
  lost=sum(int(n) for n in re.findall(r'lost at least (\d+)',text));tuner=next((line.strip() for line in text.splitlines() if 'tuner' in line.lower() and 'found' in line.lower()),'Tuner initialized')
  result={'kind':'usb-test','at':time.time(),'sampleRate':2048000,'seconds':7,'lostSamplesReported':lost,'tuner':tuner,'passed':lost==0}
  return receipt(result)

def parse_power(path):
 bins=[]
 with Path(path).open() as f:
  for row in csv.reader(f):
   if len(row)<7:continue
   try:
    start,step=float(row[2]),float(row[4]);values=[float(v) for v in row[6:]]
    bins.extend({'hz':round(start+(i+.5)*step),'db':round(v,2)} for i,v in enumerate(values) if __import__('math').isfinite(v))
   except ValueError:continue
 if not bins:raise ValueError('No spectrum samples returned.')
 # Multiple integrations retain one strongest observation per bin, never fabricate signals.
 merged={}
 for b in bins:merged[b['hz']]=max(b['db'],merged.get(b['hz'],-999))
 return [{'hz':k,'db':v} for k,v in sorted(merged.items())][:4096]

def scan(band):
 if band not in BANDS:raise ValueError('Select one of the listed receive bands.')
 with receiver():
  label,low,high,step=BANDS[band];path=ROOT/('spectrum-'+uuid.uuid4().hex+'.csv')
  try:
   bounded(['rtl_power','-g','20','-f',f'{int(low)}:{int(high)}:{int(step)}','-i','1','-e','5s',str(path)],18)
   bins=parse_power(path);result={'kind':'spectrum','band':band,'label':label,'at':time.time(),'bins':bins,'units':'relative dB · uncalibrated','seconds':5,'artifact':str(path),'peakMHz':round(max(bins,key=lambda b:b['db'])['hz']/1e6,4)}
   return receipt(result)
  except Exception:path.unlink(missing_ok=True);raise

def tune(frequency,gain):
 frequency=float(frequency);gain=float(gain)
 if not 87.5<=frequency<=108 or not 0<=gain<=49.6:raise ValueError('FM: 87.5–108 MHz; gain: 0–49.6 dB.')
 return frequency,gain

def fm(frequency,gain=20):
 frequency,gain=tune(frequency,gain)
 if not devices():raise ValueError('Receiver is not connected.')
 # Stop/restart only this owned unit; never kill an unrelated receiver application.
 subprocess.run(['systemctl','--user','stop','sensei-radio-fm.service'],capture_output=True)
 r=subprocess.run(['systemd-run','--user','--unit=sensei-radio-fm','--collect','--quiet',str(Path.home()/'.local/bin/sensei-radio'),'fm-worker',str(frequency),str(gain)],capture_output=True,text=True)
 if r.returncode:raise ValueError('Could not start the owned FM player.')
 return {'kind':'fm','frequencyMHz':frequency,'gainDb':gain,'note':'FM audio starts through PipeWire. Stop it before scanning or opening Gqrx.'}

def fm_worker(frequency,gain):
 frequency,gain=tune(frequency,gain)
 with receiver():
  radio=subprocess.Popen(['rtl_fm','-M','wbfm','-f',str(round(frequency*1e6)),'-s','200000','-r','48000','-g',str(gain)],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
  try:audio=subprocess.Popen(['pw-play','--raw','--rate=48000','--channels=1','--format=s16','--volume=.45','-'],stdin=radio.stdout,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
  except Exception:radio.terminate();radio.wait();raise
  radio.stdout.close()
  def stop(*_):
   for p in (radio,audio):
    if p.poll() is None:p.terminate()
  previous=signal.signal(signal.SIGTERM,stop)
  try:
   while radio.poll() is None and audio.poll() is None:time.sleep(.2)
  finally:
   stop();radio.wait();audio.wait();signal.signal(signal.SIGTERM,previous)
  return {'stopped':True}

def stop():
 subprocess.run(['systemctl','--user','stop','sensei-radio-fm.service'],capture_output=True,check=False);return {'stopped':True}
def open_receiver():
 if not devices():raise ValueError('Connect the receiver first.')
 if not shutil.which('gqrx'):raise ValueError('Install Gqrx on this machine.')
 stop();subprocess.Popen(['gqrx'],stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True);return {'opened':'Gqrx'}
def watch():
 print(json.dumps(status()),flush=True)
 p=subprocess.Popen(['udevadm','monitor','--udev','--subsystem-match=usb'],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True)
 try:
  for line in p.stdout:
   if line.startswith('UDEV'):time.sleep(.25);print(json.dumps(status()),flush=True)
 finally:p.terminate();p.wait()


def record_iq(frequency):
 import hashlib,datetime
 frequency,gain=tune(frequency,20)
 with receiver():
  count=5120000;base=ROOT/('fm-'+uuid.uuid4().hex);data=base.with_suffix('.sigmf-data');meta=base.with_suffix('.sigmf-meta')
  try:
   started=datetime.datetime.now(datetime.timezone.utc)
   bounded(['rtl_sdr','-f',str(round(frequency*1e6)),'-s','1024000','-g','20','-n',str(count),str(data)],15)
   data.chmod(0o600)
   if data.stat().st_size!=count*2:raise ValueError('IQ recording was interrupted; incomplete data was removed.')
   digest=hashlib.sha512(data.read_bytes()).hexdigest()
   document={'global':{'core:datatype':'cu8','core:sample_rate':1024000,'core:version':'1.2.5','core:sha512':digest,'core:hw':'RTL2838 / R820T','core:description':'Five-second broadcast-FM experiment; RF gain 20 dB.'},'captures':[{'core:sample_start':0,'core:frequency':round(frequency*1e6),'core:datetime':started.isoformat().replace('+00:00','Z')}],'annotations':[]}
   save(meta,document)
   return receipt({'kind':'iq','at':time.time(),'frequencyMHz':frequency,'sampleRate':1024000,'seconds':5,'bytes':data.stat().st_size,'datatype':'cu8','sha512':digest,'artifact':str(meta),'data':str(data)})
  except Exception:data.unlink(missing_ok=True);meta.unlink(missing_ok=True);raise

def sensors():
 with receiver():
  out,err=bounded(['rtl_433','-f','433920000','-T','15','-F','json','-M','time:iso'],22);packets=[]
  for line in out.splitlines():
   try:
    item=json.loads(line)
    if isinstance(item,dict):packets.append(item)
   except ValueError:pass
  artifact=ROOT/('sensors-'+uuid.uuid4().hex+'.json');save(artifact,packets[:2000])
  return receipt({'kind':'sensors','at':time.time(),'frequencyMHz':433.92,'seconds':15,'packetCount':len(packets),'models':sorted({str(x.get('model','Unknown')) for x in packets})[:40],'artifact':str(artifact),'note':'No matching packets heard is a valid result. Compare only devices you recognize.'})

def stream(band):
 if band not in BANDS:raise ValueError('Unknown spectrum band.')
 with receiver():
  label,low,high,step=BANDS[band];p=subprocess.Popen(['stdbuf','-oL','rtl_power','-g','20','-f',f'{int(low)}:{int(high)}:{int(step)}','-i','1','-e','10m','-'],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True,bufsize=1)
  def terminate(*_):raise SystemExit(0)
  previous=signal.signal(signal.SIGTERM,terminate);stamp=None;merged={}
  try:
   for row in csv.reader(p.stdout):
    if len(row)<7:continue
    new=tuple(row[:2])
    if stamp and new!=stamp and merged:
     bins=[{'hz':k,'db':v} for k,v in sorted(merged.items())][:4096];print(json.dumps({'kind':'live','label':label,'bins':bins,'units':'relative dB · uncalibrated'}),flush=True);merged={}
    stamp=new
    try:
     start,step=float(row[2]),float(row[4])
     for i,value in enumerate(row[6:]):
      v=float(value)
      if __import__('math').isfinite(v):merged[round(start+(i+.5)*step)]=round(v,2)
    except ValueError:continue
   if p.wait()!=0:raise ValueError('Live scope could not open the receiver. Stop FM and close other SDR applications.')
  finally:
   signal.signal(signal.SIGTERM,previous)
   if p.poll() is None:p.terminate()
   try:p.wait(timeout=3)
   except subprocess.TimeoutExpired:p.kill();p.wait()


def compare():
 rows=[]
 for path in sorted((ROOT/'receipts').glob('*.json'),key=lambda p:p.stat().st_mtime,reverse=True):
  try:
   value=json.loads(path.read_text())
   if value.get('kind')=='spectrum' and (not rows or value.get('band')==rows[0].get('band')):rows.append(value)
   if len(rows)==2:break
  except (OSError,ValueError):continue
 if len(rows)<2:raise ValueError('Capture the same band twice, with a deliberate antenna/configuration change between runs.')
 newer,older=rows;old={b['hz']:b['db'] for b in older['bins']};delta=[b['db']-old[b['hz']] for b in newer['bins'] if b['hz'] in old]
 if not delta:raise ValueError('The two captures have no common frequency bins.')
 return receipt({'kind':'comparison','at':time.time(),'band':newer['band'],'references':[older['id'],newer['id']],'commonBins':len(delta),'meanDeltaDb':round(sum(delta)/len(delta),2),'note':f'Mean change {sum(delta)/len(delta):+.2f} dB across {len(delta)} common bins. Signal variation is a confound; this is not calibrated antenna gain.'})
