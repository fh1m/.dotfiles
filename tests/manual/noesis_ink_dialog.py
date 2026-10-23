"""Disposable headless ink-dialog probe; ScreenPad surface stubbed (no physical UI claim)."""
import os,sys,time,json,subprocess,shutil
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'scripts'))
from noesis_native_fixture import Fixture,QS
f=Fixture();f.env.update(QT_QPA_PLATFORM='offscreen',QSG_RHI_BACKEND='software',LC_ALL='C.UTF-8',XDG_RUNTIME_DIR='/run/user/1000',DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1000/bus')
window=f.home/'.local/share/sensei-learning/ui/NoesisWindow.qml'
window.write_text(window.read_text().replace('NoesisStudyDesk {id:secondaryDesk;primaryWindow:!win.secondary;workspace:content.item}', 'Item {id:secondaryDesk;visible:false;property bool primaryWindow:true;property bool enabledByUser:false;property bool hasSource:false;property var deskScreen:null;function saveLayout(){}}'))
workspace=f.home/'.local/share/sensei-learning/ui/NoesisWorkspace.qml'
workspace.write_text(workspace.read_text().replace(' id:root',' id:root\n function universityFixtureOpen(){explorationDialog.close();university.open();}function planningFixtureOpen(){university.close();planning.open();}function academicFixtureState(){return {university:university.visible,planning:planning.visible,courses:university.catalog?.courses?.length||0};}function inkFixtureState(){return {modal:explorationDialog.visible,mode:drawingMode.currentIndex,paper:inkPaper.currentIndex,pdf:inkPdfPath.placeholderText,visible:drawingMode.visible};}',1))
shell=f.config/'shell.qml';s=shell.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:inkWindow;width:1440;height:960}')
s=s.replace('ShellRoot {','''ShellRoot {
 function find(o,name){if(!o)return null;if(o.objectName===name)return o;for(let c of o.children||[]){let r=find(c,name);if(r)return r;}return null;}
 IpcHandler {target:"ink-check";function open():void{inkWindow.workspacePage.contextAction("drawing");}function second():string{let w=LearningUi.NoesisController.createWindow("fixture-screen");return w.windowId;}function closeSecond():void{let c=LearningUi.NoesisController.childWindows[0].controller;c.drafts={proof:"retained"};c.requestExit(false);}function reopenSecond():string{let c=LearningUi.NoesisController.childWindows[0].controller;c.open();return JSON.stringify({exitRequested:c.exitRequested,drafts:c.drafts});}function windows():string{return JSON.stringify(LearningUi.NoesisController.childWindows.map(w=>({id:w.windowId,ready:w.controller.hostReady,screen:w.controller.mainMonitor,drafts:w.controller.drafts})));}function university():void{inkWindow.workspacePage.universityFixtureOpen();}function planning():void{inkWindow.workspacePage.planningFixtureOpen();}function academicState():string{return JSON.stringify(inkWindow.workspacePage.academicFixtureState());}function state():string{return JSON.stringify(inkWindow.workspacePage.inkFixtureState());}function capture(path:string):bool{inkWindow.update();return inkWindow.contentItem.grabToImage(r=>r.saveToFile(path));}}
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
 f.ipc('ink-check','second');time.sleep(1)
 windows=json.loads(f.ipc('ink-check','windows'));assert len(windows)==1 and windows[0]['ready'] and windows[0]['screen']=='fixture-screen',windows
 print(json.dumps({'independent_secondary_window':True,'window_id':windows[0]['id']}))
 f.ipc('ink-check','closeSecond');time.sleep(.5);reopened=json.loads(f.ipc('ink-check','reopenSecond'));assert not reopened['exitRequested'] and reopened['drafts']['proof']=='retained',reopened
 print(json.dumps({'secondary_close_reopen_preserves_drafts':True}))
 f.ipc('ink-check','university');time.sleep(.5);a=json.loads(f.ipc('ink-check','academicState'));assert a['university'],a
 f.ipc('ink-check','planning');time.sleep(.5);a=json.loads(f.ipc('ink-check','academicState'));assert a['planning'] and not a['university'],a
 print(json.dumps({'university_and_planning_dialogs':True}))

except Exception:
 print((f.home/'qml.log').read_text()[-3000:]);raise
finally:f.stop();shutil.rmtree(f.home)
