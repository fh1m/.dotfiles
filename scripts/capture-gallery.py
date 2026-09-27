#!/usr/bin/env python3
"""Capture real widgets on a clean code workspace; restore focus/privacy mode."""
import json, subprocess, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/assets';OUT.mkdir(exist_ok=True)
def command(args, timeout=15):
 r=subprocess.run(args,capture_output=True,text=True,timeout=timeout)
 if r.returncode:raise RuntimeError('Command failed: '+args[0]+' '+r.stderr[:160])
 return r.stdout

def ipc(*args):return command(['qs','-c','wrayth','ipc','call',*args])
def hypr(code):return command(['hyprctl','-i','0','dispatch',code])
def clients():return json.loads(command(['hyprctl','-i','0','clients','-j']))
def shot(name,output='eDP-1',delay=.8):
 ipc('demo','ping');time.sleep(delay)
 command(['grim','-l','1','-s','1','-o',output,str(OUT/(name+'.png'))],20)
 print('Captured',name,flush=True)

original=json.loads(command(['hyprctl','-i','0','activewindow','-j'])).get('address')
existing=[c['address'] for c in clients()]
try:
 ipc('demo','on','120');ipc('navigationview','showcaseHide',','.join(existing))
 hypr('hl.dsp.focus({workspace="4"})')
 subprocess.Popen(['kitty','--class','sensei-showcase','--title','ROS 2 // heartbeat','--hold','bat','--paging=never','--style=numbers,header','--color=always',str(ROOT/'examples/robotics-bringup.py')],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 time.sleep(1.5)
 # The second terminal is real source, not fabricated telemetry or a chat.
 hypr('hl.dsp.focus({workspace="5"})')
 subprocess.Popen(['kitty','--class','sensei-showcase','--title','CUDA // container recipe','--hold','bat','--paging=never','--style=numbers,header','--color=always',str(ROOT/'examples/compose.robotics.yaml')],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 time.sleep(1)
 hypr('hl.dsp.focus({workspace="4"})');ipc('dropdown','close')
 shot('desktop-main');shot('desktop-screenpad','DP-2')
 for name,page,target in [('system','0','system'),('monitor','0','monitor'),('spotify','0','spotify'),('sound','0','sound'),('calendar','0','calendar')]:
  ipc(target,'page',page);shot(name,'DP-2' if name=='monitor' else 'eDP-1',1.1);ipc('dropdown','close');time.sleep(.25)
 ipc('dropdown','open','docker');time.sleep(.8);ipc('dockerlab','page','6');shot('docker',delay=4);ipc('dropdown','close');time.sleep(.25)
 ipc('dropdown','open','phone');time.sleep(.8);ipc('phonepanel','page','4');shot('phone','DP-2');ipc('dropdown','close');time.sleep(.25)
 ipc('dropdown','open','usb');shot('usb','DP-2',1.2);ipc('dropdown','close');time.sleep(.25)
 ipc('weather','page','1');shot('weather',delay=1);ipc('dropdown','close');time.sleep(.25)
 ipc('launcher','open')
 try:shot('launcher')
 except subprocess.TimeoutExpired: print('Launcher capture stalled; keeping the previous reviewed image.', flush=True)
 ipc('launcher','close');time.sleep(.25)
 # Navigation uses private window thumbnails. Screenshot capture can stall
 # on the hybrid GPU while the overlay requests foreign-toplevel frames;
 # use the live switcher directly rather than publish a fabricated image.
finally:
 for args in [('dropdown','close'),('launcher','close'),('switcher','close'),('navigationview','freeze','false'),('navigationview','showcaseHide','clear'),('demo','off')]:
  try:ipc(*args)
  except Exception:pass
 for c in clients():
  if c['class']=='sensei-showcase':
   try:hypr('hl.dsp.window.close({window='+json.dumps('address:'+c['address'])+'})')
   except Exception:pass
 if original:hypr('hl.dsp.focus({window='+json.dumps('address:'+original)+'})')
