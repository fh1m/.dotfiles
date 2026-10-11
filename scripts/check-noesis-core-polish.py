import json,time,subprocess
from pathlib import Path
from noesis_native_fixture import REPO
prefix=(REPO/'scripts/check-noesis-self-service.py').read_text().split('clipboard=subprocess.run')[0]
exec(compile(prefix,'native-polish-instrumentation','exec'))
shell=f.config/'shell.qml';shell.write_text(shell.read_text().replace('function chooseDesk(index:int)', 'function captureDesk(path:string):void{window.studyDesk.applicationSurface.grabToImage(r=>r.saveToFile(path));}\n  function chooseDesk(index:int)'))
assets=REPO/'docs/learning-system/assets/core-learning'
previous=json.loads((assets/'acceptance.json').read_text());f.vault=Path(previous['fixture'])/'vault'
(f.home/'.config/sensei-learning/config.json').write_text(json.dumps({'active_vault':str(f.vault)}))
# Read previously native-created records; no learning records are constructed here.
import sys
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.persistence import parse
records=[]
for path in (f.vault/'Records').rglob('*.md'):
 props,_=parse(path.read_text());records.append(dict(props,path=str(path.relative_to(f.vault)),vault=str(f.vault)))
def capture(name):
 f.ipc('noesis','open');f.wait(lambda s:s['visible'] and not s['mode_pending'],seconds=10);time.sleep(.4)
 path=assets/(name+'.png');path.unlink(missing_ok=True);f.ipc('journey-fixture','capture',str(path));deadline=time.monotonic()+5
 while not path.exists() and time.monotonic()<deadline:time.sleep(.1)
 assert path.exists()
try:
 f.start(resume=True);f.ipc('journey-fixture','init')
 figure=next(r for r in records if r.get('title')=='Run artifact windup.png')
 f.ipc('journey-fixture','open',json.dumps(figure));f.wait(lambda s:s['loaded_figures']>=1);capture('figure-detail');assert f.ipc('journey-fixture','click','Read figure at full width')=='clicked';time.sleep(.3);capture('figure-full-width')
 f.ipc('journey-fixture','mode','fullscreen');f.ipc('noesis-study-desk','showView','figures');time.sleep(.7);assert json.loads(f.ipc('noesis-study-desk','state'))['visible'];assert f.ipc('journey-fixture','deskClick','Read figure at full width')=='clicked';time.sleep(.3)
 desk_image=assets/'screenpad-full-width.png';desk_image.unlink(missing_ok=True);f.ipc('journey-fixture','captureDesk',str(desk_image));time.sleep(.5);assert desk_image.exists();f.ipc('journey-fixture','mode','normal');time.sleep(.5)
 assert f.ipc('journey-fixture','click','Return to originating activity')=='clicked';f.wait(lambda state:state['experiment'] and state['selected']==next(r['path'] for r in records if r['id']==figure['parent_ref']['record_id']));capture('figure-origin-return');f.ipc('journey-fixture','mode','fullscreen');time.sleep(.4);capture('fullscreen-experiment');f.ipc('journey-fixture','mode','normal');time.sleep(.3)
 assert f.ipc('journey-fixture','click','Help')=='clicked';time.sleep(.8);capture('updated-guide');assert f.ipc('journey-fixture','click','Close guide')=='clicked'
 question=next(r for r in records if r.get('title')=='Agent validation · sampling uncertainty');f.ipc('journey-fixture','open',json.dumps(question));time.sleep(.5)
 f.ipc('journey-fixture','scale','2');time.sleep(.4);assert f.ipc('journey-fixture','click','Draw / Diagram')=='clicked';capture('drawing-dialog-200');assert f.ipc('journey-fixture','click','Cancel')=='clicked';f.ipc('journey-fixture','scale','1');time.sleep(.4)
 result={'source':'current source after final preview and recovery fixes','figure_preview':True,'guide_reachable':True,'scale_200_footer_reachable':True,'native_state':f.state()}
 (assets/'polish-acceptance.json').write_text(json.dumps(result,indent=2)+'\n');print('PASS: native figure detail, guide, 200% drawing dialog and visible footer')
finally:f.stop()
