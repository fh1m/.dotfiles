#!/usr/bin/env python3
"""Inspect and resume the agent-labelled vault from completed native acceptance."""
import json,os,time,subprocess
from pathlib import Path
from noesis_native_fixture import Fixture,REPO,QS
report=json.loads((REPO/'docs/learning-system/assets/self-service/acceptance.json').read_text())
home=Path(report['fixture'])
assert str(home).startswith('/var/tmp/noesis-lifecycle-') and report['learner_achievement'] is False
f=Fixture.__new__(Fixture);f.home=home;f.vault=home/'vault';f.config=home/'.config/quickshell/noesis';f.process=None
f.env=dict(os.environ,HOME=str(home),XDG_CONFIG_HOME=str(home/'.config'),XDG_CACHE_HOME=str(home/'.cache'),XDG_STATE_HOME=str(home/'.local/state'),NOESIS_WINDOW_MODE='normal',NOESIS_STUDY_DESK_FIXTURE='1',QS_DISABLE_CRASH_HANDLER='1',NOESIS_QS=QS)
assets=REPO/'docs/learning-system/assets/self-service'
def capture(name):
 path=assets/(name+'.png');path.unlink(missing_ok=True);f.ipc('journey-fixture','capture',str(path))
 deadline=time.monotonic()+5
 while not path.exists() and time.monotonic()<deadline:time.sleep(.1)
 assert path.exists()
try:
 f.start(resume=True);f.ipc('journey-fixture','init');time.sleep(.8)
 original=json.loads(f.ipc('journey-fixture','state'))['selected'];assert 'unavailable pdf' in original['title']
 f.ipc('journey-fixture','mode','fullscreen');time.sleep(.6);capture('fullscreen-source')
 f.ipc('journey-fixture','framesStart');time.sleep(1);frames=json.loads(f.ipc('journey-fixture','framesStop'));frames.sort()
 f.key('n','CTRL');time.sleep(.3);assert f.ipc('journey-fixture','type','learning-title','agent draft recovery')=='agent draft recovery'
 f.exit();f.start(resume=True);f.ipc('journey-fixture','init');time.sleep(.6)
 assert json.loads(f.ipc('journey-fixture','state'))['selected']['id']==original['id']
 f.key('n','CTRL');time.sleep(.3);assert f.ipc('journey-fixture','field','learning-title')=='agent draft recovery'
 f.ipc('journey-fixture','scale','2');time.sleep(.5);capture('start-learning-200-percent')
 assert f.ipc('journey-fixture','click','Cancel')=='clicked';f.ipc('journey-fixture','scale','1');f.ipc('journey-fixture','mode','fullscreen');time.sleep(.5)
 desk=json.loads(f.ipc('noesis-study-desk','state'));assert desk['visible'],desk
 f.ipc('noesis-study-desk','repaintNow');time.sleep(.6)
 layers=json.loads(subprocess.check_output(['hyprctl','layers','-j'],text=True))['DP-2']['levels']['3']
 assert len(layers)==1 and layers[0]['pid']==f.process.pid,layers
 subprocess.run(['grim','-o','DP-2',str(assets/'screenpad.png')],check=True)
 capture('main-and-screenpad-context')
 f.exit()
 result={'exact_record_restart':True,'start_draft_close_restart':True,'fullscreen':True,'interface_reading_scale_200_percent':True,'screenpad_owned_native_capture':True,'frame_p95_ms':frames[int(.95*(len(frames)-1))] if frames else None,'frame_samples':len(frames),'physical_input_latency_measured':False,'learner_achievement':False}
 (assets/'layout-acceptance.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
finally:f.stop()
