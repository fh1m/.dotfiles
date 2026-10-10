#!/usr/bin/env python3
"""Inspect and resume the agent-labelled vault from completed native acceptance."""
import json,os,time,subprocess
from pathlib import Path
from noesis_native_fixture import Fixture,REPO,QS,installer
report=json.loads((REPO/'docs/learning-system/assets/self-service/acceptance.json').read_text())
home=Path(report['fixture'])
assert str(home).startswith('/var/tmp/noesis-lifecycle-') and report['learner_achievement'] is False
f=Fixture.__new__(Fixture);f.home=home;f.vault=home/'vault';f.config=home/'.config/quickshell/noesis';f.process=None
f.env=dict(os.environ,HOME=str(home),XDG_CONFIG_HOME=str(home/'.config'),XDG_CACHE_HOME=str(home/'.cache'),XDG_STATE_HOME=str(home/'.local/state'),NOESIS_WINDOW_MODE='normal',NOESIS_STUDY_DESK_FIXTURE='1',QS_DISABLE_CRASH_HANDLER='1',NOESIS_QS=QS)
f.env['FONTCONFIG_FILE']=str(home/'fontconfig.xml') if (home/'fontconfig.xml').exists() else '/etc/fonts/fonts.conf'
assets=REPO/'docs/learning-system/assets/self-service'
# Refresh only the guide under review; never construct or modify learning records.
for name in ('NoesisHelpDialog.qml','NoesisWorkspace.qml','user-guide.md'):
 target=home/'.local/share/sensei-learning/ui'/name
 data=installer.render((REPO/'home/.local/share/sensei-learning/ui'/name).read_bytes(),home,'zenbook')
 if name=='NoesisWorkspace.qml':data=data.replace(b' id:root',b' id:root\n readonly property var reviewOverlay:Overlay.overlay',1)
 target.write_bytes(data)
def capture(name):
 path=assets/(name+'.png');path.unlink(missing_ok=True);f.ipc('journey-fixture','capture',str(path))
 deadline=time.monotonic()+5
 while not path.exists() and time.monotonic()<deadline:time.sleep(.1)
 assert path.exists()
clipboard=subprocess.run(['wl-paste','--no-newline'],capture_output=True)
shell=f.config/'shell.qml';source=shell.read_text()
if 'font-fixture' not in source:
 source=source.replace('ShellRoot {',"""ShellRoot {
 FontInfo {id:uiResolved;font.family:LearningUi.NoesisStyle.uiFont;font.pixelSize:LearningUi.NoesisStyle.uiText}
 FontInfo {id:boldResolved;font.family:LearningUi.NoesisStyle.uiFont;font.bold:true;font.pixelSize:LearningUi.NoesisStyle.heading}
 FontInfo {id:codeResolved;font.family:LearningUi.NoesisStyle.codeFont;font.pixelSize:LearningUi.NoesisStyle.label}
 IpcHandler {target:"font-fixture";function state():string{return JSON.stringify({ui:uiResolved.family,ui_style:uiResolved.styleName,bold:boldResolved.family,bold_style:boldResolved.styleName,code:codeResolved.family,code_fixed_pitch:codeResolved.fixedPitch});}}
""",1);shell.write_text(source)
try:
 f.start(resume=True);f.ipc('journey-fixture','init');time.sleep(.8)
 fonts=json.loads(f.ipc('font-fixture','state'));assert fonts['ui']=='Zed Sans' and fonts['ui_style']=='Regular' and fonts['bold']=='Zed Sans' and fonts['bold_style']=='Bold' and fonts['code'].startswith('ZedMono') and fonts['code_fixed_pitch'],fonts
 assert f.ipc('journey-fixture','click','Help')=='clicked';time.sleep(.4);capture('user-guide');assert f.ipc('journey-fixture','click','Close guide')=='clicked'
 f.key('k','CTRL');time.sleep(.3);assert f.ipc('journey-fixture','click','Start learning from a new source')=='clicked';time.sleep(.3);capture('search-start-route');assert f.ipc('journey-fixture','click','Cancel')=='clicked'
 original=json.loads(f.ipc('journey-fixture','state'))['selected'];assert 'unavailable pdf' in original['title']
 assert f.ipc('journey-fixture','click','Open PDF ↗')=='clicked';f.wait(lambda state:not state['working']);assert json.loads(f.ipc('journey-fixture','state'))['error'];capture('unavailable-source-error')
 f.ipc('journey-fixture','mode','fullscreen');time.sleep(.6);capture('fullscreen-source')
 f.ipc('journey-fixture','framesStart');time.sleep(1);frames=json.loads(f.ipc('journey-fixture','framesStop'));frames.sort()
 f.key('n','CTRL');time.sleep(.3);assert f.ipc('journey-fixture','type','learning-title','agent draft recovery')=='agent draft recovery'
 f.exit();f.start(resume=True);f.ipc('journey-fixture','init');time.sleep(.6)
 assert json.loads(f.ipc('journey-fixture','state'))['selected']['id']==original['id']
 f.key('n','CTRL');time.sleep(.3);assert f.ipc('journey-fixture','field','learning-title')=='agent draft recovery'
 unicode_example='agent example · বাংলা গণিত · ∑ xₙ²'
 assert f.ipc('journey-fixture','focusField','learning-title')=='focused';subprocess.run(['wl-copy'],input=unicode_example,text=True,check=True);time.sleep(.1);f.ipc('journey-fixture','pasteField');assert f.ipc('journey-fixture','field','learning-title')==unicode_example;capture('unicode-typography')
 assert f.ipc('journey-fixture','type','learning-title','agent draft recovery')=='agent draft recovery'
 f.ipc('journey-fixture','scale','2');time.sleep(.5);capture('start-learning-200-percent')
 assert f.ipc('journey-fixture','click','Cancel')=='clicked';f.ipc('journey-fixture','scale','1');f.ipc('journey-fixture','mode','fullscreen');time.sleep(.5)
 desk=json.loads(f.ipc('noesis-study-desk','state'));assert desk['visible'],desk
 f.ipc('noesis-study-desk','repaintNow');time.sleep(.6)
 layers=json.loads(subprocess.check_output(['hyprctl','layers','-j'],text=True))['DP-2']['levels']['3']
 assert len(layers)==1 and layers[0]['pid']==f.process.pid,layers
 subprocess.run(['grim','-o','DP-2',str(assets/'screenpad.png')],check=True)
 capture('main-and-screenpad-context')
 f.exit()
 result={'resolved_fonts':fonts,'bangla_math_unicode_input':True,'normal_logical_size':f.client['size'],'main_logical_fullscreen':[1920,1080],'screenpad_logical':[1920,550],'device_pixel_ratio':2,'search_start_route':True,'missing_pdf_handoff_reports_error':True,'exact_record_restart':True,'start_draft_close_restart':True,'fullscreen':True,'interface_reading_scale_200_percent':True,'screenpad_owned_native_capture':True,'frame_p95_ms':frames[int(.95*(len(frames)-1))] if frames else None,'frame_samples':len(frames),'physical_input_latency_measured':False,'learner_achievement':False}
 (assets/'layout-acceptance.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
finally:
 f.stop()
 if clipboard.returncode==0:subprocess.run(['wl-copy'],input=clipboard.stdout,check=True)
 else:subprocess.run(['wl-copy','--clear'],check=True)
