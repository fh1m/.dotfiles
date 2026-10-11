#!/usr/bin/env python3
"""Native fullscreen handoffs with owned external windows on another workspace."""
import json,os,time,subprocess,signal
from pathlib import Path
from noesis_native_fixture import REPO
prefix=(REPO/'scripts/check-noesis-self-service.py').read_text().split('clipboard=subprocess.run')[0]
exec(compile(prefix,'native-desktop-instrumentation','exec'))
assets=REPO/'docs/learning-system/assets/core-learning'
prior=json.loads((assets/'acceptance.json').read_text());f.vault=Path(prior['fixture'])/'vault'
(f.home/'.config/sensei-learning/config.json').write_text(json.dumps({'active_vault':str(f.vault)}))
import sys
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.persistence import parse
records=[]
for path in (f.vault/'Records').rglob('*.md'):
 props,_=parse(path.read_text());records.append(dict(props,path=str(path.relative_to(f.vault)),vault=str(f.vault)))
scratch=next(r for r in records if r.get('title')=='Agent validation · sampled signal check')
file=f.vault/scratch['local_file'];socket=f.home/'desktop-editor.sock'
pilot=f.home/'.config/noesis-desktop';pilot.mkdir();(pilot/'init.lua').write_text('vim.fn.serverstart('+json.dumps(str(socket))+')\n')
f.env['NVIM_APPNAME']='noesis-desktop'
def clients():return json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True))
def dispatch(value):subprocess.run(['hyprctl','dispatch',value],check=True,capture_output=True)
initial={c['address']:(c['pid'],c['workspace']['id']) for c in clients()};initial_focus=json.loads(subprocess.check_output(['hyprctl','activewindow','-j'],text=True)).get('address')
existing=None;new=None
try:
 # A pre-existing external editor is owned by this test, never a personal window.
 existing=subprocess.Popen([str(Path.home()/'.local/bin/sensei-terminal'),'--title','Noesis desktop acceptance · existing editor','-e','nvim','-u','NONE',str(file)],env=f.env,start_new_session=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 deadline=time.monotonic()+10
 while time.monotonic()<deadline:
  rows=[c for c in clients() if c['pid']==existing.pid]
  if rows:break
  time.sleep(.1)
 assert rows,'Existing test editor did not map';other=rows[0]
 dispatch('hl.dsp.window.move({workspace="2",window='+json.dumps('address:'+other['address'])+'})')
 dispatch('hl.dsp.focus({workspace="4"})');f.start(resume=True);f.ipc('journey-fixture','init');f.ipc('journey-fixture','open',json.dumps(scratch));f.wait(lambda s:s['experiment']);f.ipc('journey-fixture','mode','fullscreen');time.sleep(.6)
 assert f.ipc('journey-fixture','click','Edit scratch code')=='clicked';f.wait(lambda s:not s['visible'] and not s['working'],seconds=15)
 deadline=time.monotonic()+10
 while not socket.exists() and time.monotonic()<deadline:time.sleep(.1)
 assert socket.exists(),'Closed editor did not launch'
 exact=subprocess.check_output(['nvim','--server',str(socket),'--remote-expr','expand("%:p")'],env=f.env,text=True).strip();assert Path(exact)==file
 new=next(c for c in clients() if c['title']=='Noesis · '+scratch['title']);assert new['workspace']['id']==4,new['workspace']
 assert next(c for c in clients() if c['address']==other['address'])['workspace']['id']==2,'Pre-existing external window relocated'
 desk=json.loads(f.ipc('noesis-study-desk','state'));assert desk['visible'] and desk['record']==scratch['id'];assert not f.state()['worker'],'Hidden app still indexes'
 dispatch('hl.dsp.focus({window='+json.dumps('address:'+other['address'])+'})');time.sleep(.3)
 f.ipc('noesis','open');f.wait(lambda s:s['visible'] and s['worker']);assert json.loads(f.ipc('journey-fixture','state'))['selected']['id']==scratch['id']
 image=assets/'desktop-fullscreen-return.png';image.unlink(missing_ok=True);f.ipc('journey-fixture','capture',str(image));time.sleep(.5);assert image.exists()
 f.exit();assert existing.poll() is None,'Noesis close terminated external editor';f.start(resume=True);f.ipc('journey-fixture','init');assert json.loads(f.ipc('journey-fixture','state'))['selected']['id']==scratch['id']
 surviving={c['address']:(c['pid'],c['workspace']['id']) for c in clients()};assert all(surviving.get(address)==value for address,value in initial.items()),'An unrelated window moved or exited'
 result={'closed_editor_launch':True,'exact_code_file':True,'existing_editor_other_workspace_preserved':True,'fullscreen_return':True,'held_screenpad':True,'hidden_worker_stopped':True,'restart_origin_retained':True,'unrelated_windows_preserved':True,'native_state':f.state()}
 (assets/'desktop-acceptance.json').write_text(json.dumps(result,indent=2)+'\n');print('PASS: fullscreen, closed editor, existing editor on another workspace, held ScreenPad, restart and unrelated windows')
finally:
 f.stop()
 if socket.exists():subprocess.run(['nvim','--server',str(socket),'--remote-expr','execute("qall!")'],env=f.env,capture_output=True)
 if existing and existing.poll() is None:os.killpg(existing.pid,signal.SIGTERM);existing.wait(timeout=5)
 if initial_focus and any(c['address']==initial_focus for c in clients()):dispatch('hl.dsp.focus({window='+json.dumps('address:'+initial_focus)+'})')
