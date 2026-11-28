"""Real panel subprocesses must not publish an obsolete search or mix pages."""
from pathlib import Path
import json

import pytest

from test_quickshell_ui_freshness import HAS_QS, helper, put, run_native, SHELL_STATE

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / 'home/.config/quickshell/sensei/modules/dropdowns/YouTubePanel.qml'


def prepare_panel(tmp_path):
    put(tmp_path, 'YouTubePanel.qml', PANEL.read_text().replace('@HOME@', str(tmp_path)))
    put(tmp_path, 'services/ShellState.qml', SHELL_STATE)
    put(tmp_path, 'services/YouTubeDesk.qml', '''pragma Singleton
import QtQuick
QtObject {
 property bool ownsAudio:false
 property string platform:'YouTube'
 property var track: ({})
 property var queue:[]
 property bool loading:false
 property string error:''
 property bool transcriptOpen:false
 property bool captionsEnabled:false
 property var transcript:[]
 property var chapters:[]
 property real speed:1
 property int quality:1080
 property int volume:65
 property bool playing:false
 property int duration:0
 property int position:0
 function play(item) {}
 function watch(item) {}
 function release() {}
 function action(name,args) {}
 function changeQuality(value) {}
 function loadTranscript() {}
 function enqueue(item) {}
 function removeQueued(item) {}
 function moveQueued(item,direction) {}
}
''')
    put(tmp_path, 'services/SpotifyDesk.qml', '''pragma Singleton
import QtQuick
QtObject {
 property bool videoAudioLinked:false
 property string videoSource:''
 property string videoMode:'inline'
 property string videoDisplay:''
 property var videoSlot: ({})
 function fmt(value) {return String(value)}
 function action(name,args) {}
 function expand() {}
 function showVideo(mode,output) {}
}
''')
    put(tmp_path, 'config/Appearance.qml', '''pragma Singleton
import QtQuick
QtObject {
 property var font: ({heading:'Iosevka',reading:'Iosevka',data:'Iosevka'})
 property var textSize: ({body:14,caption:12,title:20,section:18,secondary:13})
}
''')
    colors = ['paper', 'paperMuted', 'widgetAccent', 'rule', 'surfaceOne', 'ink']
    put(tmp_path, 'config/Theme.qml', 'pragma Singleton\nimport QtQuick\nQtObject {\n' +
        '\n'.join(' property color ' + name + ': "#888888"' for name in colors) + '\n}\n')
    put(tmp_path, 'components/Placeholder.qml', 'import QtQuick\nQtObject {}\n')
    leaf_items = {
        'MediaTransport': 'Item {height:64}',
        'MediaCaptions': 'Item {}',
        'MediaTranscript': 'Item {}',
        'MusicButton': 'Item {property string label:"";property string glyph:"";property int textSize:12;property bool selected:false;signal activated()}',
        'ControlSlider': 'Item {property string title:"";property real level:0;signal edited(real value)}',
        'ChamferPanel': 'Item {property color fillColor:"transparent";property color borderColor:"transparent";property int chamfer:0;property bool scanlines:false}',
        'RoundedArtwork': 'Item {property url source;property bool asynchronous:false;property int fillMode:0;property real cornerRadius:0}',
    }
    for name, body in leaf_items.items():
        put(tmp_path, name + '.qml', 'import QtQuick\n' + body + '\n')
    for name, base in [('DeskTextField', 'TextField'), ('DeskComboBox', 'ComboBox'), ('DeskScrollBar', 'ScrollBar')]:
        put(tmp_path, name + '.qml', 'import QtQuick\nimport QtQuick.Controls\n' + base + ' {}\n')
    helper(tmp_path, 'sensei-spotify', '''import json,sys,time
command=sys.argv[1]
query=sys.argv[2]
if query=='old':time.sleep(.25)
else:time.sleep(.025)
row={'id':query,'kind':'youtube','title':query,'artist':'Fixture','art':'','duration':1000}
print(json.dumps({'rows':[row],'next':1,'warning':''}))
''')


@pytest.mark.skipif(not HAS_QS, reason='Explicit native Quickshell runtime required')
@pytest.mark.parametrize('scenario', ['newest', 'saved', 'library', 'pagination'])
def test_search_result_ownership_and_latest_intent(tmp_path, scenario):
    prepare_panel(tmp_path)
    harness = '''import QtQuick
import Quickshell
ShellRoot {
    id: test
    property int phase:0
    property int ticks:0
    property string scenario:@SCENARIO@
    Item {width:1200;height:800;YouTubePanel {id:panel;width:1200;height:800}}
    Timer {interval:20;repeat:true;running:true;onTriggered:{
        test.ticks++
        if(test.phase===0) {
            panel.query='old';panel.search(false);test.phase=1
        } else if(test.phase===1) {
            if(test.scenario==='pagination') {
                if(panel.results.length&&panel.results[0].id==='old') {
                    panel.query='new';panel.search(false,true);test.phase=2
                }
            } else if(test.ticks>=5) {
                if(test.scenario==='saved')panel.section=1
                else if(test.scenario==='library')panel.openLibrary(3,false)
                else {panel.query='new';panel.search(false)}
                test.phase=2
            }
        }
        if(test.phase===2&&test.ticks>=55) {
            const expected=test.scenario==='library'?'playlists':'new'
            const valid=test.scenario==='saved'
                ? panel.section===1&&panel.results.length===0&&panel.nextPage===-1
                : panel.results.length===1&&panel.results[0].id===expected
            if(!valid) {console.error('PROOF_FAIL stale or lost YouTube request: '+test.scenario);Qt.exit(2);return}
            console.log('PROOF_PASS YouTube request ownership: '+test.scenario);Qt.quit()
        }
        if(test.ticks>150) {console.error('PROOF_FAIL YouTube request timeout');Qt.exit(2)}
    }}
}
'''.replace('@SCENARIO@', json.dumps(scenario))
    assert 'PROOF_PASS YouTube request ownership' in run_native(tmp_path, harness)
