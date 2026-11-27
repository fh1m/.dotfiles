#!/usr/bin/env python3
"""Finite, private CPU/PSS/swap sampling. No window titles, arguments or account data."""
import argparse,json,os,time
from pathlib import Path

def sample(previous):
 now=time.monotonic();tick=os.sysconf('SC_CLK_TCK');rows=[];current={}
 for p in Path('/proc').iterdir():
  if not p.name.isdigit():continue
  try:
   name=(p/'comm').read_text().strip()
   if name not in ('Hyprland','qs','quickshell'):continue
   fields=(p/'stat').read_text().rsplit(') ',1)[1].split();identity=(p.name,fields[19]);ticks=int(fields[11])+int(fields[12]);old=previous.get(identity);current[identity]=(now,ticks)
   values={k:int(v.split()[0]) for k,v in [line.split(':',1) for line in (p/'smaps_rollup').read_text().splitlines() if ':' in line] if k in ('Pss','Swap','Pss_Anon','Anonymous','AnonHugePages')}
   args=(p/'cmdline').read_bytes().split(b'\0');role='compositor' if name=='Hyprland' else 'main' if b'-c' in args and b'sensei' in args else 'overlay'
   rows.append({'pid':int(p.name),'startTicks':int(fields[19]),'role':role,'cpuOneCorePercent':round(max(0,(ticks-old[1])/tick/(now-old[0])*100),3) if old else None,'threads':int(fields[17]),'fds':len(list((p/'fd').iterdir())),'memoryKiB':values})
  except (OSError,ValueError,IndexError):continue
 mem={k:int(v.split()[0]) for k,v in [line.split(':',1) for line in Path('/proc/meminfo').read_text().splitlines()]}
 return {'at':time.time(),'processes':rows,'availableKiB':mem['MemAvailable'],'swapUsedKiB':mem['SwapTotal']-mem['SwapFree']},current

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--duration',type=float,default=60);p.add_argument('--interval',type=float,default=10);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 if not 1<=a.duration<=86400 or not 1<=a.interval<=300:p.error('Duration must be 1–86400s, interval 1–300s')
 a.output.parent.mkdir(parents=True,exist_ok=True,mode=0o700);fd=os.open(a.output,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600);previous={};deadline=time.monotonic()+a.duration;count=0
 with os.fdopen(fd,'w') as stream:
  while True:
   record,previous=sample(previous);stream.write(json.dumps(record)+'\n');stream.flush();count+=1
   if time.monotonic()>=deadline:break
   time.sleep(min(a.interval,max(0,deadline-time.monotonic())))
 print(json.dumps({'samples':count,'output':str(a.output),'scope':'Observed workload; not a guarantee of idle usage or absence of leaks'}))
if __name__=='__main__':main()
