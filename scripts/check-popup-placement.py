#!/usr/bin/env python3
"""Click real bar buttons, verify popup geometry, then restore cursor/folds.
Explicit --live required. No text input, input grab, app close or library edits.
"""
import argparse,json,subprocess,time

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--pid',type=int,required=True);p.add_argument('--live',action='store_true');a=p.parse_args()
 if not a.live:p.error('--live required; this moves the pointer and clicks bar controls')
 from evdev import UInput,ecodes as e
 def ipc(target,method,*args):
  r=subprocess.run(['qs','ipc','--pid',str(a.pid),'call',target,method,*map(str,args)],capture_output=True,text=True,check=True,timeout=8)
  return json.loads(r.stdout) if r.stdout.strip() else None
 def hypr(*args):return subprocess.check_output(['hyprctl','-i','0',*args],text=True)
 cursor=json.loads(hypr('cursorpos','-j'));monitors=json.loads(hypr('monitors','-j'));receipt=[];folds=[]
 try:
  with UInput({e.EV_KEY:[e.BTN_LEFT],e.EV_REL:[e.REL_X,e.REL_Y]},name='Den popup placement acceptance') as mouse:
   time.sleep(.2)
   for m in monitors:
    target='bar-controls-'+m['name']
    try:bar=ipc(target,'state')
    except (subprocess.CalledProcessError,json.JSONDecodeError):bar=None
    cases=[]
    if bar:
     folds.append((target,'top',bar['expanded']))
     for expanded in ('off','on'):
      ipc(target,'expand',expanded);time.sleep(.5);cases.append((target,'sound','top',False,expanded))
    bottom='bar-controls-bottom-'+m['name']
    try:b=ipc(bottom,'state');cases.append((bottom,'display','top' if b['top'] else 'bottom',True,''))
    except (subprocess.CalledProcessError,json.JSONDecodeError):pass
    for target,button,edge,is_bottom,expanded in cases:
     if expanded:ipc(target,'expand',expanded);time.sleep(.5)
     pos=ipc(target,'state')[button];x=round(m['x']+pos['x']);y=round(m['y']+pos['y']+(m['height']/m['scale']-44 if edge=='bottom' else 0))
     ipc('dropdown','close');time.sleep(.25)
     hypr('dispatch',f'hl.dsp.cursor.move({{x={x},y={y}}})');time.sleep(.15)
     mouse.write(e.EV_REL,e.REL_X,1);mouse.syn();time.sleep(.04);mouse.write(e.EV_REL,e.REL_X,-1);mouse.syn();time.sleep(.1)
     mouse.write(e.EV_KEY,e.BTN_LEFT,1);mouse.syn();time.sleep(.04);mouse.write(e.EV_KEY,e.BTN_LEFT,0);mouse.syn();time.sleep(1)
     state=ipc('popup-'+m['name'],'state');context=ipc('dropdown','context');w=m['width']/m['scale'];h=m['height']/m['scale']
     assert context['origin']==m['name'] and context['edge']==edge,(m['name'],context)
     assert state['visible'] and abs(context['anchor']-pos['x'])<2,(pos,state,context)
     assert state['x']>=0 and state['x']+state['width']<=w+1 and state['y']>=0 and state['y']+state['height']<=h+1,state
     receipt.append({'output':m['name'],'button':button,'edge':edge,'expanded':expanded,'withinOutput':True,'clickAnchor':True})
  print(json.dumps({'passed':True,'cases':receipt},indent=2))
 finally:
  ipc('dropdown','close')
  for target,_,expanded in folds:ipc(target,'expand','on' if expanded else 'off')
  hypr('dispatch',f'hl.dsp.cursor.move({{x={cursor["x"]},y={cursor["y"]}}})')
if __name__=='__main__':main()
