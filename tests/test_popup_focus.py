import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.skipif(not os.environ.get('SENSEI_QS_BINARY'), reason='Requires an explicitly selected native Quickshell runtime')
def test_cached_hidden_clipboard_does_not_claim_search_focus(tmp_path):
    source = ROOT / 'home/.config/quickshell/sensei'
    for name in ('components', 'config'):
        shutil.copytree(source / name, tmp_path / name)
    shutil.copytree(source / 'modules/dropdowns', tmp_path / 'panels')
    (tmp_path / 'assets').mkdir()
    for name in ('scanline.png', 'scanline-wide.png'):
        shutil.copy2(source / 'assets' / name, tmp_path / 'assets' / name)
    (tmp_path / 'services').mkdir()
    providers = {
        'ShellState': 'property string dropdown:""',
        'ClipboardVault': 'property var detail:({});property var items:[];property string query:"";property string filter:"all";property string selected:"";property bool paused:false;property string error:"";property int count:0;property int events:0;property int bytes:0;property int limit:150;function action(){} function refresh(){} function select(){}',
        'Effects': 'property var treatment:({pitch:0,strength:0,band:false,vignette:false});property bool scanlinesOn:false;property bool scanlinesOnPanels:false;property bool scanlinesOnWallpaper:false;property bool scanlinesOverWindows:false;property real bandPhase:0;function treatmentFor(){return treatment} function holdBand(){}',
    }
    for name, properties in providers.items():
        (tmp_path / 'services' / (name + '.qml')).write_text('pragma Singleton\nimport QtQuick\nQtObject {' + properties + '}\n')
    (tmp_path / 'shell.qml').write_text('''import QtQuick
import QtQuick.Window
import Quickshell
import "panels" as Panels
import "services"
ShellRoot {
 id: root
 property int step: 0
 function field(item) {
  if (typeof item.placeholderText === "string" && typeof item.selectByMouse === "boolean") return item
  for (const child of (item.children || [])) { const result=field(child); if (result) return result }
  return null
 }
 function check(value, message) { if (!value) { console.error("PROOF_FAIL",message); Qt.exit(2); return false }; return true }
 FloatingWindow {id:a;visible:false;implicitWidth:1080;implicitHeight:700;Panels.ClipboardDropdown{id:first;width:parent.width}}
 FloatingWindow {id:b;visible:false;implicitWidth:1080;implicitHeight:700;Panels.ClipboardDropdown{id:second;width:parent.width}}
 Timer {interval:250;repeat:true;running:true;onTriggered:{
  const x=root.field(first),y=root.field(second)
  if(!root.check(!!x&&!!y,"search fields unavailable")) return
  if(root.step===0) ShellState.dropdown="clipboard"
  else if(root.step===1) {if(!root.check(!x.focus&&!y.focus,"hidden cached search claimed focus"))return;a.visible=true;first.Window.window.requestActivate()}
  else if(root.step===2) {if(!root.check(x.focus&&!y.focus,"visible search did not own focus exclusively"))return;a.visible=false;b.visible=true;second.Window.window.requestActivate()}
  else if(root.step===3) {if(!root.check(!x.focus&&y.focus,"focus remained on the previous output"))return;b.visible=false}
  else if(root.step===4) {if(!root.check(!x.focus&&!y.focus,"closed search retained focus"))return;console.log("PROOF_PASS popup search focus ownership");Qt.quit()}
  root.step++
 }}
}
''')
    with tempfile.TemporaryDirectory(prefix='den-focus-') as runtime:
        env = dict(os.environ, HOME=str(tmp_path), XDG_RUNTIME_DIR=runtime,
                   XDG_CONFIG_HOME=str(tmp_path / 'private-config'), XDG_STATE_HOME=str(tmp_path / 'state'),
                   XDG_CACHE_HOME=str(tmp_path / 'cache'), DBUS_SESSION_BUS_ADDRESS='unix:path=' + runtime + '/no-bus',
                   QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', LC_ALL='C.UTF-8', QS_NO_RELOAD_POPUP='1')
        result = subprocess.run([os.environ['SENSEI_QS_BINARY'], '-p', str(tmp_path / 'shell.qml')], env=env,
                                capture_output=True, text=True, timeout=20)
    report = result.stdout + result.stderr
    assert result.returncode == 0, report
    assert 'PROOF_PASS popup search focus ownership' in report, report
