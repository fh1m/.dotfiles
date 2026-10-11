#!/usr/bin/env python3
"""Real ArchiveButton/bridge routes in an isolated bar, without restarting Wrayth."""
import json, subprocess, time, uuid
from types import SimpleNamespace
from noesis_native_fixture import Fixture, QS, REPO

f=Fixture(); config=f.home/'.config/quickshell/wrayth'
app=f.config/'shell.qml'
app.write_text(app.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:applicationWindow}\n IpcHandler {target:"bar-app";function state():string{return JSON.stringify({modal:applicationWindow.workspacePage.modalOpen});}}'))
(f.home/'qml.log').touch()
prior=json.loads(subprocess.check_output(['hyprctl','activewindow','-j']))
(config/'shell.qml').write_text('//@ pragma AppId org.fh1m.Noesis.BarProbe'+uuid.uuid4().hex+'\n'+r'''
import QtQuick
import QtQuick.Controls
import QtTest
import Quickshell
import Quickshell.Io
import "modules/bar" as Bar
ShellRoot {
 FloatingWindow {id:window;visible:true;implicitWidth:420;implicitHeight:200;title:"Noesis isolated bar route";color:"#090807"
  Bar.ArchiveButton {id:entry;anchors.centerIn:parent;target:"oasis";label:"Noesis";glyph:"N"}
 }
 TestCase {id:input;parent:window.contentItem;when:false;visible:false}
 FrameAnimation {running:entry.launchMenu.visible;onTriggered:{}}
 function find(i,test){if(test(i))return i;for(let c of i.children||[]){let result=find(c,test);if(result)return result;}return null;}
 IpcHandler {target:"bar-proof";
  function showing():bool{return entry.launchMenu.visible;}
  function open():void{input.mouseClick(entry,entry.width/3,entry.height/2);}
  function menu():string{let button=find(entry,i=>i.Accessible?.name==="Noesis start and capture");button.forceActiveFocus();return JSON.stringify({w:entry.width,h:entry.height,x:entry.x,y:entry.y,visible:entry.visible,parentw:entry.parent.width,parenth:entry.parent.height,buttonVisible:button.visible,buttonw:button.width,opened:entry.launchMenu.opened});}
  function action(label:string):string{let item=find(entry.launchMenu.contentItem,i=>i.text===label&&i.visible&&typeof i.clicked==="function");if(!item){let values=[];function walk(i){values.push({type:String(i),text:i.text,visible:i.visible,trigger:typeof i.triggered,click:typeof i.clicked});for(let c of i.children||[])walk(c);}walk(entry.launchMenu.contentItem);return JSON.stringify({opened:entry.launchMenu.opened,values:values});}item.forceActiveFocus();return "focused";}
  function capture(path:string):bool{return find(entry.launchMenu.contentItem,i=>i.objectName==="noesis-launch-actions").grabToImage(result=>result.saveToFile(path));}
 }
}
''')
# Use an object name for reliable native test lookup, without replacing the component.
p=config/'modules/bar/ArchiveButton.qml'
p.write_text(p.read_text().replace(' id:root',' id:root\n readonly property var launchMenu:learningMenu',1).replace('ToolButton {visible:', 'ToolButton {objectName:"bar-actions";visible:'))
p=config/'shell.qml';p.write_text(p.read_text().replace('i.Accessible?.name==="Noesis start and capture"','i.objectName==="bar-actions"'))
log=(f.home/'bar.log').open('w');bar=None;app_pid=None
def ipc(method,*args):
 r=subprocess.run([QS,'-p',str(config),'ipc','call','bar-proof',method,*args],env=f.env,text=True,capture_output=True,timeout=5)
 if r.returncode:raise RuntimeError(r.stderr)
 return r.stdout.strip()
try:
 bar=subprocess.Popen([QS,'-p',str(config),'--no-color'],env=f.env,stdout=log,stderr=log)
 deadline=time.monotonic()+10
 while time.monotonic()<deadline:
  try:ipc('open');break
  except RuntimeError:time.sleep(.1)
 else:raise AssertionError((f.home/'bar.log').read_text())
 f.wait(lambda s:s['visible'] and s['worker']);hello=f.hello();app_pid=hello['instance']['pid'];f.process=SimpleNamespace(pid=app_pid)
 assert not f.state()['capture_open']
 # Opening repeatedly uses the same process; the ordinary entry does not create a sheet.
 bar_client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if c['pid']==bar.pid)
 subprocess.run(['hyprctl','dispatch','hl.dsp.focus({workspace='+json.dumps(bar_client['workspace']['name'])+'})'],check=True,capture_output=True)
 ipc('open');time.sleep(.7);assert f.hello()['instance']['pid']==app_pid
 assert json.loads(subprocess.check_output(['hyprctl','activewindow','-j'])).get('pid')==app_pid,'Warm Open did not focus Noesis from the other workspace'
 clients=json.loads(subprocess.check_output(['hyprctl','clients','-j']))
 assert len([c for c in clients if c['pid']==app_pid and c['title'].startswith('Noesis')])==1
 # Menu works even though Noesis now owns compositor focus: QtTest targets the bar.
 client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if c['pid']==bar.pid)
 subprocess.run(['hyprctl','dispatch','hl.dsp.focus({workspace='+json.dumps(client['workspace']['name'])+'})'],check=True,capture_output=True)
 target=json.dumps('address:'+client['address'])
 for dispatch in ['hl.dsp.window.float({action="enable",window='+target+'})','hl.dsp.window.resize({x=420,y=240,relative=false,window='+target+'})','hl.dsp.window.center({window='+target+'})','hl.dsp.focus({window='+target+'})']:subprocess.run(['hyprctl','dispatch',dispatch],check=True,capture_output=True)
 time.sleep(.3)
 client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if c['pid']==bar.pid)
 ipc('menu')
 subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods="",key="space",window='+target+'})'],check=True,capture_output=True)
 time.sleep(.3)
 asset=REPO/'docs/learning-system/assets/ux-finalization/bar-menu.png';asset.unlink(missing_ok=True)
 print('POPUP',ipc('showing'),ipc('capture',str(asset)),flush=True);deadline=time.monotonic()+5
 while not asset.exists() and time.monotonic()<deadline:time.sleep(.1)
 assert asset.exists()
 subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods="",key="Escape"})'],check=True,capture_output=True);time.sleep(.2);assert ipc('showing')=='false'
 ipc('menu');subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods="",key="space",window='+target+'})'],check=True,capture_output=True);time.sleep(.2)
 result=ipc('action','Start learning');assert result=='focused',result;subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods="",key="space"})'],check=True,capture_output=True);time.sleep(.8)
 assert f.hello()['instance']['pid']==app_pid
 assert json.loads(f.ipc('bar-app','state'))['modal']
 # Escape the sheet in the Noesis window, then use the alternate Capture route.
 f.key('Escape');subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+target+'})'],check=True,capture_output=True);ipc('menu');subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods="",key="space",window='+target+'})'],check=True,capture_output=True);time.sleep(.2);assert ipc('action','Quick capture')=='focused';subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods="",key="space"})'],check=True,capture_output=True)
 f.wait(lambda s:s['capture_open']);assert f.hello()['instance']['pid']==app_pid
 warnings=[line for line in (f.home/'bar.log').read_text().splitlines() if ('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line]
 assert not warnings,warnings
 result={'isolated_bar_native_click':True,'ordinary_open_single_instance':True,'warm_open_from_other_workspace':True,'start_menu':True,'capture_menu':True,'escape_dismissal':True,'personal_wrayth_restarted':False,'fixture':str(f.home)}
 (REPO/'docs/learning-system/assets/ux-finalization/bar-acceptance.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
finally:
 if app_pid:
  try:f.ipc('noesis','exit')
  except RuntimeError:pass
 if bar and bar.poll() is None:bar.terminate();bar.wait(timeout=5)
 log.close()
 if prior.get('workspace'):subprocess.run(['hyprctl','dispatch','hl.dsp.focus({workspace='+json.dumps(prior['workspace']['name'])+'})'],capture_output=True)
 if prior.get('address'):subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+json.dumps('address:'+prior['address'])+'})'],capture_output=True)
