import subprocess,json,time,shlex
from pathlib import Path
ssh=['ssh','-F',str(Path.home()/'.local/state/homie-control/client.conf'),'homie']
def local(*args):return subprocess.check_output(['hyprctl','-i','0',*args]).decode()
def remote(*args):return subprocess.check_output(ssh+['hyprctl -i 0 '+' '.join(shlex.quote(x) for x in args)]).decode()
def warp(x,y):local('dispatch',f'hl.dsp.cursor.move({{x={x},y={y}}})')
def peerwarp(x,y):remote('dispatch',f'hl.dsp.cursor.move({{x={x},y={y}}})')
# Own receiver only; no test input reaches a user application.
clients=json.loads(remote('clients','-j'));fixture=next(c for c in clients if c['title']=='Den input harness');remote('dispatch','hl.dsp.focus({window="address:'+fixture['address']+'"})')
for entry,exit in [('top','bottom'),('right','left'),('top','left'),('right','bottom')]:
 for n in range(2):
  if entry=='top':warp(960,40);warp(960,0)
  else:warp(-40,-540);warp(-1,-540)
  time.sleep(.6)
 pos=json.loads(remote('cursorpos','-j'))
 if entry=='top':assert pos['y']>=1060,('enter',entry,pos)
 else:assert pos['x']<=20,('enter',entry,pos)
 if exit=='bottom':peerwarp(960,1079)
 else:peerwarp(0,540)
 for n in range(30):
  time.sleep(.05);pos=json.loads(local('cursorpos','-j'))
  if (exit=='bottom' and pos['y']==3) or (exit=='left' and pos['x']==-4):break
 assert (exit=='bottom' and pos['y']==3) or (exit=='left' and pos['x']==-4),('exit',entry,exit,pos)
 print(entry,'→ Homie →',exit,'passed',pos,flush=True)
