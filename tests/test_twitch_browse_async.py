"""Twitch results and bookmark mutations must belong to the visible tab."""
from pathlib import Path
import json

import pytest

from test_quickshell_ui_freshness import HAS_QS, helper, put, run_native
from test_youtube_search_async import prepare_panel

PANEL = Path(__file__).resolve().parents[1] / 'home/.config/quickshell/sensei/modules/dropdowns/TwitchPanel.qml'


@pytest.mark.skipif(not HAS_QS, reason='Explicit native Quickshell runtime required')
@pytest.mark.parametrize('scenario', ['newest', 'saved', 'bookmark'])
def test_twitch_request_and_bookmark_ownership(tmp_path, scenario):
    prepare_panel(tmp_path)
    put(tmp_path, 'TwitchPanel.qml', PANEL.read_text().replace('@HOME@', str(tmp_path)))
    helper(tmp_path, 'sensei-spotify', '''import json,sys,time
from pathlib import Path
command=sys.argv[1]
receipt=Path(__file__).with_name('bookmark-command')
if command=='twitch-browse':
    key=sys.argv[3] if sys.argv[2]=='search' else sys.argv[2]
    time.sleep(.30 if key=='old' else .03)
    print(json.dumps({'rows':[{'id':key,'artist':key,'title':key,'art':''}]}))
elif command=='twitch-saved':
    print(json.dumps({'rows':[] if receipt.exists() else [{'id':'saved-only','artist':'Saved','title':'Saved','art':''}]}))
elif command.startswith('twitch-'):
    with receipt.open('a') as f:
        f.write(command+':'+sys.argv[2]+'\\n')
    print('{}')
''')
    harness = '''import QtQuick
import Quickshell
ShellRoot {
    id: test
    property int phase:0
    property int ticks:0
    property string scenario:@SCENARIO@
    Item {width:1200;height:800;TwitchPanel {id:panel;width:1200;height:800}}
    Timer {interval:20;repeat:true;running:true;onTriggered:{
        test.ticks++
        if(test.phase===0) {
            panel.query=test.scenario==='bookmark'?'first':'old';panel.browse(2);test.phase=1
        } else if(test.phase===1) {
            if(test.scenario==='bookmark') {
                if(!panel.rows.length)return
                const obsolete=panel.rows[0];panel.browse(3);
                if(panel.rows.length) {console.error('PROOF_FAIL prior rows remain actionable in Saved');Qt.exit(2);return}
                panel.setBookmark(obsolete);test.phase=2
            } else if(test.ticks>=4) {
                if(test.scenario==='saved')panel.browse(3)
                else {panel.query='new';panel.browse(2)}
                test.phase=2
            }
        }
        if(test.phase===2&&test.scenario==='bookmark'&&panel.rows.length&&panel.rows[0].id==='saved-only') {
            panel.setBookmark(panel.rows[0]);test.phase=3
        }
        if((test.phase===2&&test.scenario!=='bookmark'||test.phase===3)&&test.ticks>=55) {
            const expected=test.scenario==='newest'?'new':'saved-only'
            const section=test.scenario==='newest'?2:3
            const correctRows=test.scenario==='bookmark'?panel.rows.length===0:panel.rows.length===1&&panel.rows[0].id===expected
            if(panel.section!==section||!correctRows) {
                console.error('PROOF_FAIL stale or lost Twitch request: '+test.scenario);Qt.exit(2);return
            }
            console.log('PROOF_PASS Twitch ownership');Qt.quit()
        }
        if(test.ticks>140){console.error('PROOF_FAIL Twitch timeout');Qt.exit(2)}
    }}
}
'''.replace('@SCENARIO@', json.dumps(scenario))
    assert 'PROOF_PASS Twitch ownership' in run_native(tmp_path, harness)
    command = tmp_path / '.local/bin/bookmark-command'
    if scenario == 'bookmark':
        assert command.read_text().splitlines() == ['twitch-remove:saved-only']
    else:
        assert not command.exists()
