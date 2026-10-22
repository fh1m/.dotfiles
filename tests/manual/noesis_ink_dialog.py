"""Disposable headless ink-dialog probe; ScreenPad surface stubbed (no physical UI claim)."""
import os,sys,time,json,subprocess,shutil
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'scripts'))
from noesis_native_fixture import Fixture,QS
f=Fixture();f.env.update(QT_QPA_PLATFORM='offscreen',QSG_RHI_BACKEND='software',LC_ALL='C.UTF-8',XDG_RUNTIME_DIR='/run/user/1000',DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1000/bus')
window=f.home/'.local/share/sensei-learning/ui/NoesisWindow.qml'
window.write_text(window.read_text().replace('NoesisStudyDesk {id:secondaryDesk;workspace:content.item}', 'Item {id:secondaryDesk;visible:false;property bool enabledByUser:false;property bool hasSource:false;property var deskScreen:null;function saveLayout(){}}'))
workspace=f.home/'.local/share/sensei-learning/ui/NoesisWorkspace.qml'
workspace.write_text(workspace.read_text().replace(' id:root',' id:root\n function inkFixtureState(){return {modal:explorationDialog.visible,mode:drawingMode.currentIndex,paper:inkPaper.currentIndex,pdf:inkPdfPath.placeholderText,visible:drawingMode.visible};}',1))
shell=f.config/'shell.qml';s=shell.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:inkWindow;width:1440;height:960}')
s=s.replace('ShellRoot {','''ShellRoot {
 function find(o,name){if(!o)return null;if(o.objectName===name)return o;for(let c of o.children||[]){let r=find(c,name);if(r)return r;}return null;}
 IpcHandler {target:"ink-check";function open():void{inkWindow.workspacePage.contextAction("drawing");}function state():string{return JSON.stringify(inkWindow.workspacePage.inkFixtureState());}function capture(path:string):bool{inkWindow.update();return inkWindow.contentItem.grabToImage(r=>r.saveToFile(path));}}
''')
shell.write_text(s)
try:
 f.log=(f.home/'qml.log').open('a');f.process=subprocess.Popen([QS,'-p',str(f.config),'--no-color'],env=f.env,stdout=f.log,stderr=f.log,start_new_session=True)
 f.wait(lambda s:s.get('visible') and s.get('worker'),seconds=15)
 f.ipc('noesis-window','section','Practice');f.wait(lambda s:s.get('rows')==1)
 f.ipc('noesis-window','select','problem.md');f.wait(lambda s:s.get('selected')=='problem.md' and s.get('preview_length',0)>0)
 f.ipc('ink-check','open');time.sleep(.4)
 state=json.loads(f.ipc('ink-check','state'));assert state['mode']==2 and state['paper']==0 and state['visible'],state
 print(json.dumps({'offscreen_dialog':state,'qml_loaded':True}))

except Exception:
 print((f.home/'qml.log').read_text()[-3000:]);raise
finally:f.stop();shutil.rmtree(f.home)
