"""Controller exports retain their origin when hotplug changes the selection."""
import pytest

from test_quickshell_ui_freshness import HAS_QS, helper, run_native, setup_services


@pytest.mark.skipif(not HAS_QS, reason='Explicit native Quickshell runtime required')
def test_export_cannot_be_relabelled_as_the_fallback_controller(tmp_path):
    setup_services(tmp_path, 'Controllers.qml')
    helper(tmp_path, 'sensei-controllers', '''import json, sys, time
from pathlib import Path
home=Path.home()
if sys.argv[1]=='list':
    devices=[{'id':'B','name':'Fallback pad'}]
    if not (home/'hotplug').exists():devices.insert(0,{'id':'A','name':'Original pad'})
    print(json.dumps({'controllers':devices}))
elif sys.argv[1]=='ros-export':
    origin=sys.argv[2]
    (home/'hotplug').touch()
    time.sleep(.2)
    print(json.dumps({'path':str(home/('export-'+origin)), 'command':'launch-for-'+origin}))
''')
    harness = '''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    property int phase:0
    property int ticks:0
    Timer {interval:20;repeat:true;running:true;onTriggered:{
        ticks++
        if(ticks>150) {console.error('PROOF_FAIL export timed out');Qt.exit(2);return}
        if(phase===0&&Controllers.data.controllers.length===2) {
            Controllers.selected='A'
            Controllers.action('ros-export','fixture')
            phase=1
        } else if(phase===1&&Controllers.busy) {
            Controllers.data={controllers:[{id:'B',name:'Fallback pad'}]}
            phase=2
        } else if(phase===2&&!Controllers.busy&&Controllers.exportPath) {
            if(Controllers.device.id!=='B'||Controllers.exportDevice!=='A'||Controllers.exportCommand!=='launch-for-A') {
                console.error('PROOF_FAIL export assigned to the wrong controller');Qt.exit(2);return
            }
            console.log('PROOF_PASS exported files retain disconnected controller identity')
            Qt.quit()
        }
    }}
}
'''
    assert 'PROOF_PASS exported files retain disconnected controller identity' in run_native(tmp_path, harness)
