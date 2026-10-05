#!/usr/bin/env python3
"""Capture real widgets on a clean code workspace; restore focus/privacy mode."""
import json, subprocess, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/assets';OUT.mkdir(exist_ok=True)
QS=Path.home()/'.local/opt/sensei-quickshell/bin/qs'
QS=str(QS if QS.exists() else 'qs')
PUBLIC_ROS=Path.home()/'tmp/mongla_ws/tools/flow_derot_calibrate.py'
ROS_SOURCE=PUBLIC_ROS if PUBLIC_ROS.exists() else ROOT/'examples/robotics-bringup.py'
ROS_RANGE=['--line-range=84:113'] if ROS_SOURCE==PUBLIC_ROS else []
def command(args, timeout=15):
 r=subprocess.run(args,capture_output=True,text=True,timeout=timeout)
 if r.returncode:raise RuntimeError('Command failed: '+args[0]+' '+r.stderr[:160])
 return r.stdout

def ipc(*args):return command([QS,'-c','wrayth','ipc','call',*args])
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
 shot('desktop-empty-main')
 shot('desktop-empty-screenpad','DP-2')
 subprocess.Popen(['kitty','-o','font_size=10.4','--class','sensei-showcase','--title','Mongla // held-out flow fit','--hold','bat','--paging=never','--style=numbers,header','--color=always',*ROS_RANGE,str(ROS_SOURCE)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 time.sleep(1.5)
 # The second terminal is real source, not fabricated telemetry or a chat.
 hypr('hl.dsp.focus({workspace="5"})')
 subprocess.Popen(['kitty','-o','font_size=10.4','--class','sensei-showcase','--title','CUDA // container recipe','--hold','bat','--paging=never','--style=numbers,header','--color=always',str(ROOT/'examples/compose.robotics.yaml')],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 time.sleep(1)
 hypr('hl.dsp.focus({workspace="4"})');ipc('dropdown','close')
 shot('desktop-main');shot('desktop-screenpad','DP-2')
 ipc('dropdown','open','ident');shot('operator',delay=1.2)
 from PIL import Image
 operator=Image.open(OUT/'operator.png')
 operator.crop((18,58,614,482)).save(OUT/'operator.png')
 ipc('dropdown','close');time.sleep(.25)
 ipc('comic','latest');shot('comic',delay=2)
 comic=Image.open(OUT/'comic.png')
 comic.crop((18,58,758,744)).save(OUT/'comic.png')
 ipc('dropdown','close');time.sleep(.25)
 for name,page,target in [('system','0','system'),('monitor','0','monitor'),('spotify','0','spotify'),('sound','0','sound'),('calendar','0','calendar')]:
  ipc(target,'page',page);shot(name,'DP-2' if name=='monitor' else 'eDP-1',1.1);ipc('dropdown','close');time.sleep(.25)
 ipc('dropdown','open','docker');time.sleep(.8);ipc('dockerlab','page','6');shot('docker',delay=4);ipc('dropdown','close');time.sleep(.25)
 ipc('dropdown','open','phone');time.sleep(.8);ipc('phonepanel','page','4');shot('phone','DP-2');ipc('dropdown','close');time.sleep(.25)
 ipc('dropdown','open','usb');shot('usb','DP-2',1.2);ipc('dropdown','close');time.sleep(.25)
 ipc('weather','page','1');shot('weather',delay=1);ipc('dropdown','close');time.sleep(.25)
 ipc('launcher','open')
 try:
  shot('launcher',delay=1.8)
  from PIL import Image
  launcher=Image.open(OUT/'launcher.png')
  launcher.crop((620,190,1300,676)).save(OUT/'launcher.png')
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
