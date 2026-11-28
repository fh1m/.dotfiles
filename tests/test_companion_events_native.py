"""Engineering receipts must wait for an actual presentation opportunity."""
import json
import os
from pathlib import Path

import pytest

from test_quickshell_ui_freshness import HAS_QS, run_native

ROOT = Path(__file__).resolve().parents[1]
COMPANION = ROOT / 'home/.local/share/sensei-companion'


@pytest.mark.skipif(
    not HAS_QS or not os.environ.get('SENSEI_NATIVE_COMPANION_TEST'),
    reason='Explicit native Wayland companion regression required',
)
@pytest.mark.parametrize('blocked', ['no-room', 'card-space', 'guest', 'peer-dnd'])
def test_engineering_receipt_waits_until_it_can_be_presented(tmp_path, blocked):
    # The production component requires a Wayland PanelWindow backend. Its
    # disposable surfaces remain transparent and input-empty throughout.
    (tmp_path / 'Actor').symlink_to(COMPANION, target_is_directory=True)
    state_dir = tmp_path / '.local/state/sensei-den'
    state_dir.mkdir(parents=True)
    wayland = os.environ.get('WAYLAND_DISPLAY', '')
    assert wayland, 'A live Wayland compositor is required'
    if not wayland.startswith('/'):
        wayland = '/run/user/' + str(os.getuid()) + '/' + wayland
    harness = '''import QtQuick
import Quickshell
import "Actor" as Actor
ShellRoot {
    id: test
    property string blocked: @BLOCKED@
    property string receipt: "engineering-presentation-probe"
    property var guest: null
    property int suppressed:0
    function position(available) {
        const screen=Quickshell.screens[0]
        return {available:available,x:Math.max(12,screen.width/2-48),
                y:Math.max(52,screen.height-160)}
    }
    Region { id: emptyInput }
    function suppressSurfaces(item) {
        const objects=item.data||[]
        for(let i=0;i<objects.length;i++) {
            const child=objects[i]
            if(!child) continue
            if(child.contentItem) {
                child.contentItem.opacity=0
                child.mask=emptyInput
                if(child.contentItem.opacity!==0) throw new Error('Test surface is not transparent')
                suppressed++
            } else if(child.data) suppressSurfaces(child)
        }
    }
    Component.onCompleted: {
        suppressSurfaces(buddy)
        if(suppressed<4) { console.error('PROOF_FAIL test surfaces not isolated'); Qt.exit(2) }
    }
    Actor.Companion {
        id: buddy
        ownerOutput: "native-fixture-output"
        // Keep the fixture's placement independent of real application geometry.
        dragging: true
        preferences: ({enabled:true,quiet:false,roaming:false,reducedMotion:true,
                       chatter:false,notificationChatter:false,welcome:false})
    }
    Timer { interval: 450; running: true; onTriggered: {
        test.guest=buddy.children.find(child=>child.historyReady!==undefined&&child.active!==undefined)
        if(!test.guest) { console.error('PROOF_FAIL guest controller missing'); Qt.exit(2); return }
        buddy.engineeringMemoryLoaded=true
        buddy.notices={host:'arete',dnd:false,unread:0}
        buddy.journey=test.blocked==='peer-dnd'
            ? {schema:1,expires:Date.now()/1000+60,deskNotices:[{host:'homie',dnd:true,unread:0}]}
            : ({})
        buddy.placement=test.position(test.blocked!=='no-room')
        if(test.blocked==='card-space') buddy.occupied=[{x:0,y:0,w:99999,h:99999}]
        if(test.blocked==='guest') test.guest.active=true
        buddy.localEngineeringEvents=[{id:test.receipt,host:'arete',at:Date.now()/1000,
            kind:'hardware.disconnected',data:{label:'Fixture board'}}]
    }}
    Timer { interval: 3000; running: true; onTriggered: {
        if(!buddy.eligible) {
            console.error('PROOF_FAIL fixture never reached an eligible desktop')
            Qt.exit(2); return
        }
        if(buddy.engineeringSeen.includes(test.receipt)||buddy.speaking) {
            console.error('PROOF_FAIL receipt consumed before presentation: '+test.blocked)
            Qt.exit(2); return
        }
        test.guest.active=false
        buddy.journey=({})
        buddy.occupied=[]
        buddy.placement=test.position(true)
    }}
    Timer { interval: 4800; running: true; onTriggered: {
        if(!buddy.engineeringSeen.includes(test.receipt)||!buddy.speaking) {
            console.error('PROOF_FAIL pending receipt did not present after unblocking')
            Qt.exit(2); return
        }
        if(buddy.engineeringSeen.filter(id=>id===test.receipt).length!==1) {
            console.error('PROOF_FAIL receipt was acknowledged more than once')
            Qt.exit(2); return
        }
        console.log('PROOF_PASS engineering receipt deferred then presented: '+test.blocked)
        Qt.quit()
    }}
}
'''.replace('@BLOCKED@', json.dumps(blocked))
    report = run_native(tmp_path, harness, extra_env={
        'QT_QPA_PLATFORM': 'wayland',
        'QT_QUICK_BACKEND': '',
        'WAYLAND_DISPLAY': wayland,
        'XDG_RUNTIME_DIR': '/run/user/' + str(os.getuid()),
    })
    assert 'PROOF_PASS engineering receipt deferred then presented' in report
    acknowledged = json.loads((state_dir / 'zondo-engineering-seen.json').read_text())
    assert acknowledged['ids'] == ['engineering-presentation-probe']
