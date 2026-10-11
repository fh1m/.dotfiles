#!/usr/bin/env python3
"""Native UX entry/reading regression, isolated owner and ordinary create controls."""
import json, subprocess, time
from pathlib import Path
from noesis_native_fixture import Fixture, REPO

f = Fixture()
f.env['NOESIS_STUDY_DESK_FIXTURE'] = '1'
assets = REPO / 'docs/learning-system/assets/ux-finalization'
assets.mkdir(parents=True, exist_ok=True)
before = json.loads(subprocess.check_output(['hyprctl', 'activewindow', '-j']))
clipboard = subprocess.run(['wl-paste', '--no-newline'], capture_output=True)
window = f.home / '.local/share/sensei-learning/ui/NoesisWindow.qml'
window.write_text(window.read_text().replace(
    ' readonly property var applicationSurface:applicationContent',
    ' readonly property var applicationSurface:applicationContent\n readonly property var reviewSurface:reviewCapture'
).replace(' ColumnLayout {id:applicationContent;', ' Item {id:reviewCapture;anchors.fill:parent\n ColumnLayout {id:applicationContent;').replace(
    ' IpcHandler {target:"noesis-window"', ' }\n IpcHandler {target:"noesis-window"'))
shell = f.config / 'shell.qml'
source = shell.read_text().replace('LearningUi.NoesisWindow {}', 'LearningUi.NoesisWindow {id:window}').replace('import QtQuick', 'import QtQuick\nimport QtTest', 1)
source = source.replace('ShellRoot {', r'''ShellRoot {
 TestCase {id:input;parent:window.reviewSurface;when:false;visible:false}
 FontInfo {id:resolved;font.family:LearningUi.NoesisStyle.uiFont}
 function find(item,test){if(test(item))return item;for(let child of item.children||[]){let found=find(child,test);if(found)return found;}return null;}
 function expose(item){for(let parent=item.parent;parent;parent=parent.parent){if(typeof parent.contentY==="number"){for(let n=0;n<80;n++){let pt=item.mapToItem(parent,0,0);if(pt.y>=0&&pt.y+Math.min(item.height,40)<=parent.height)break;input.mouseWheel(parent,30,30,0,pt.y<0?240:-240);input.wait(25);}}}}
 IpcHandler {target:"ux-entry";
  function init():void{window.workspacePage.reviewOverlay.parent=window.reviewSurface;}
  function click(label:string):string{let item=find(window.contentItem,i=>i.visible&&i.enabled&&i.text===label&&typeof i.clicked==="function");if(!item)return "missing";expose(item);input.mouseClick(item,item.width/2,item.height/2);return "clicked";}
  function focus(name:string):string{let item=find(window.contentItem,i=>i.objectName===name&&i.visible);if(!item)return "missing";expose(item);input.mouseClick(item,20,20);item.forceActiveFocus();input.keyClick(Qt.Key_A,Qt.ControlModifier);return "focused";}
  function paste():void{input.keyClick(Qt.Key_V,Qt.ControlModifier);input.wait(100);}
  function state():string{return JSON.stringify({selected:window.workspacePage.selected,tab:window.workspacePage.contextTab,modal:window.workspacePage.modalOpen,notes:window.workspacePage.evidence.text,relations:window.workspacePage.relations,font:resolved.family,focus:find(window.contentItem,i=>i.activeFocus&&!!i.objectName)?.objectName||""});}
  function capture(path:string):void{window.reviewSurface.grabToImage(result=>result.saveToFile(path));}
  function scale(value:real):void{LearningUi.NoesisStyle.interfaceScale=value;LearningUi.NoesisStyle.readingScale=value;}
  function mode(value:string):void{LearningUi.NoesisController.presentationMode=value;LearningUi.NoesisController.savePreferences();}
 }
''')
workspace = f.home / '.local/share/sensei-learning/ui/NoesisWorkspace.qml'
workspace.write_text(workspace.read_text().replace(' id:root', ' id:root\n readonly property var reviewOverlay:Overlay.overlay', 1))
shell.write_text(source)

def state(): return json.loads(f.ipc('ux-entry', 'state'))
def click(label):
    assert f.ipc('ux-entry', 'click', label) == 'clicked', label
    time.sleep(.25)
def fill(name, value):
    assert f.ipc('ux-entry', 'focus', name) == 'focused', name
    subprocess.run(['wl-copy'], input=value, text=True, check=True)
    f.ipc('ux-entry', 'paste')
def capture(name):
    path = assets / (name + '.png'); path.unlink(missing_ok=True)
    time.sleep(.6); f.ipc('ux-entry', 'capture', str(path))
    deadline = time.monotonic() + 10
    while not path.exists() and time.monotonic() < deadline: time.sleep(.1)
    assert path.exists(), name

try:
    f.start(); f.ipc('ux-entry', 'init')
    click('Start learning')
    fill('learning-origin', 'https://docs.scipy.org/doc/scipy/reference/signal.html')
    fill('learning-title', 'Agent validation · Signal processing questions')
    click('Continue'); click('Save')
    f.wait(lambda s: not s['working'] and s['selected'] != 'problem.md')
    identity = state()['selected']['id']; owner = state()['selected']['vault_id']
    assert state()['selected']['source'].startswith('https://docs.scipy.org/')
    assert state()['font'] == 'Zed Sans', state()
    fill('reading-reasoning', 'Agent validation draft: which assumptions preserve a sampled signal?')
    assert state()['focus'] == 'reading-reasoning', state()
    f.ipc('noesis', 'open'); time.sleep(.4)
    assert state()['focus'] == 'reading-reasoning' and state()['selected']['id'] == identity, state()
    click('Start learning'); fill('learning-title', 'Agent validation unfinished source')
    f.ipc('noesis', 'open'); time.sleep(.3)
    assert state()['modal'], state()
    f.key('Escape'); time.sleep(.2)
    click('Ask a source-linked question')
    fill('record-title','Agent validation · Which sampling assumption matters?')
    fill('record-purpose','Agent validation question; no understanding claim.')
    click('Save'); f.wait(lambda s: not s['working'] and state()['selected']['id']!=identity)
    assert any(row.get('other_id')==identity for row in state()['relations']),state()
    f.key('Left','ALT'); f.wait(lambda s:state()['selected'].get('id')==identity)
    assert 'sampled signal' in state()['notes'],state()
    click('Hide'); f.wait(lambda s: not s['visible'] and not s['worker'])
    assert not json.loads(f.ipc('noesis-study-desk', 'state'))['visible']
    f.ipc('noesis', 'open'); f.wait(lambda s: s['visible'] and s['worker'])
    assert state()['selected']['id'] == identity and 'sampled signal' in state()['notes']
    f.exit(); f.start(resume=True); f.ipc('ux-entry', 'init')
    f.wait(lambda s: s['selected'] != '' and not s['working'])
    assert state()['selected']['id'] == identity and state()['selected']['vault_id'] == owner, state()
    assert 'sampled signal' in state()['notes'], state()
    for mode, scale, name in [('fullscreen',1,'source-native-resumed'),('fullscreen',2,'source-native-200'),('normal',1.5,'source-native-150')]:
        f.ipc('ux-entry','mode',mode); f.ipc('ux-entry','scale',str(scale)); time.sleep(.7); capture(name)
    warnings = [line for line in (f.home/'qml.log').read_text().splitlines() if ('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line]
    assert not warnings, warnings
    result = {'fixture':str(f.home),'record_id':identity,'owner_id':owner,'native_source_creation':True,'native_linked_question_and_return':True,'repeated_open_retains_focus_and_modal':True,'hide_stops_worker_and_desk':True,'restart_retains_owner_record_draft':True,'resolved_ui_font':state()['font'],'learner_achievement':False,'physical_input_latency_measured':False,'external_tool_round_trip':'not tested by this check'}
    (assets/'entry-acceptance.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))
finally:
    f.stop()
    if clipboard.returncode == 0: subprocess.run(['wl-copy'], input=clipboard.stdout, check=True)
    else: subprocess.run(['wl-copy','--clear'],check=True)
    if before.get('address'): subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+json.dumps('address:'+before['address'])+'})'],capture_output=True)
