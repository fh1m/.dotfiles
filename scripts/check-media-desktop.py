#!/usr/bin/env python3
"""Explicit live media check. Requires an already-playing YouTube/Twitch video.

Does not move the pointer or restart services. Changes the video presentation on
specified outputs and restores its original mode/output in finally. Receipt has
no titles, account identifiers, credentials or stream URLs.
"""
import argparse,json,re,subprocess,time

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--pid',required=True,type=int)
 parser.add_argument('--outputs',required=True,help='Comma-separated attached output names')
 parser.add_argument('--settle',type=float,default=4)
 args=parser.parse_args()
 def ipc(target,method,*values):
  result=subprocess.run(['qs','ipc','--pid',str(args.pid),'call',target,method,*map(str,values)],capture_output=True,text=True,timeout=8,check=True)
  return json.loads(result.stdout) if result.stdout.strip() else None
 original=ipc('music-video-window','state');before=ipc('spotify','state')
 if before['source'] not in ('youtube','twitch') or not before['playing'] or not before['videoLinked']:
  parser.error('Start a native YouTube/Twitch video first; this harness never chooses content for you.')
 receipt={'source':before['source'],'routes':[],'transport':{}};failures=[]
 try:
  for i,output in enumerate(args.outputs.split(',')):
   previous=ipc('spotify','state')['position'];mode='mini' if i%2==0 else 'fullscreen';ipc('music-video-window','mode',mode,output);time.sleep(max(1,min(args.settle,10)))
   deadline=time.monotonic()+14;started=time.monotonic()
   while True:
    first=ipc('spotify','state');first_window=ipc('music-video-window','state');time.sleep(1);second=ipc('spotify','state');window=ipc('music-video-window','state')
    result={'output':output,'actualOutput':window['display'],'mode':mode,'visible':window['visible'],'frameSize':window['size'],'audioAdvanceMs':round(second['position']-first['position']),'videoAdvanceMs':round(second['videoPosition']-first['videoPosition']),'driftMs':round(abs(second['position']-second['videoPosition'])),'renderUpdates':window.get('renderUpdates',0)-first_window.get('renderUpdates',0),'avsyncMs':round(abs(window.get('avsync',0))*1000,2),'readyAfterMs':round((time.monotonic()-started+args.settle)*1000),'previousPositionMs':round(previous),'resumedPositionMs':round(second['position'])}
    result['passed']=result['visible'] and result['actualOutput']==output and result['audioAdvanceMs']>300 and result['videoAdvanceMs']>300 and result['driftMs']<1500 and all(int(n)>0 for n in re.findall(r'-?\d+',result['frameSize'])) and result['renderUpdates']>3 and result['avsyncMs']<150 and second['position']>=previous-1000
    if result['passed'] or time.monotonic()>=deadline:break
   receipt['routes'].append(result)
   if not result['passed']:failures.append(output)
  ipc('spotify','action','pause');time.sleep(.6);paused=ipc('spotify','state');time.sleep(.7);still=ipc('spotify','state')
  receipt['transport']['pausePassed']=not paused['playing'] and abs(still['position']-paused['position'])<150
  ipc('spotify','action','play');time.sleep(1);receipt['transport']['resumePassed']=ipc('spotify','state')['playing']
 finally:
  ipc('music-video-window','mode',original['mode'] if original['mode'] in ('mini','fullscreen') else 'inline',original['display'])
 receipt['passed']=not failures and all(receipt['transport'].values())
 print(json.dumps(receipt,indent=2));return 0 if receipt['passed'] else 1
if __name__=='__main__':raise SystemExit(main())
