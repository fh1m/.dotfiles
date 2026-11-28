"""Native regressions for async QuickShell service ownership and refresh cadence."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
QS = os.environ.get('SENSEI_QS_BINARY', '')
HAS_QS = bool(QS and Path(QS).is_file())
SERVICES = ROOT / 'home/.config/quickshell/sensei/services'

SHELL_STATE = '''pragma Singleton
import QtQuick
QtObject {
    property string dropdown: ""
    property int systemPage: 0
    property bool externalDialogOpen: false
    property string dropdownOriginScreen: ""
    property real dropdownAnchorX: 0
    property var screens: []
    property var externalScreens: []
    property var bottomBarScreens: []
    function closeAll() { dropdown = "" }
    function focusedScreenName() { return "" }
    function openDropdown(name) { dropdown = name }
    function openDropdownOn(name, output) { dropdownOriginScreen = output; dropdown = name }
}
'''

YOUTUBE_DESK = '''pragma Singleton
import QtQuick
QtObject {
    property bool ownsAudio: false
    property bool loading: false
    property string error: ""
    property var snapshot: ({backend:"headless",track:{},playing:false,progress:0,volume:70})
    property var queue: []
    property real position: 0
    property bool nativeVideo: false
    property var nativePlayer: null
    property var track: ({id:"",kind:""})
    property string engineOutput: ""
    property bool watchMode: false
    function release() {}
    function action(name, args) {}
    function play(item, watch) {}
}
'''

NATIVE_ENV = {
    'QT_QPA_PLATFORM': 'offscreen',
    'QT_QUICK_BACKEND': 'software',
    'LC_ALL': 'C.UTF-8',
    'QS_NO_RELOAD_POPUP': '1',
}


def put(tmp_path, relative, content, executable=False):
    path = tmp_path / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    if executable:
        path.chmod(0o700)
    return path


def service(tmp_path, name):
    source = (SERVICES / name).read_text()
    return put(tmp_path, 'services/' + name, source.replace('@HOME@', str(tmp_path)))


def setup_services(tmp_path, *names):
    for name in names:
        service(tmp_path, name)
    put(tmp_path, 'services/ShellState.qml', SHELL_STATE)


def run_native(tmp_path, harness, extra_env=None, timeout=8):
    assert HAS_QS, 'Set SENSEI_QS_BINARY to the explicitly selected native Quickshell runtime'
    shell = put(tmp_path, 'shell.qml', harness)
    # Keep native IPC socket paths bounded even under long pytest test names.
    with tempfile.TemporaryDirectory(prefix="den-qml-") as runtime:
        env = dict(os.environ)
        env.update({
            'HOME': str(tmp_path),
            'XDG_RUNTIME_DIR': runtime,
            'XDG_CONFIG_HOME': str(tmp_path / 'config'),
            'XDG_STATE_HOME': str(tmp_path / 'state'),
            'XDG_CACHE_HOME': str(tmp_path / 'cache'),
            'DBUS_SESSION_BUS_ADDRESS': 'unix:path=' + runtime + '/no-bus',
        })
        env.update(NATIVE_ENV)
        if extra_env:
            env.update(extra_env)
        result = subprocess.run([str(QS), '-p', str(shell)], env=env,
                                capture_output=True, text=True, timeout=timeout)
    report = result.stdout + result.stderr
    assert result.returncode == 0, report
    return report


def helper(tmp_path, name, body):
    return put(tmp_path, '.local/bin/' + name,
               '#!' + sys.executable + '\n' + body, executable=True)


USB_HELPER = r'''import json, sys, time
from pathlib import Path
a=sys.argv[1:]
if a and a[0]=='--history':
    query=a[1]; offset=int(a[2])
    with (Path.home()/'usb-requests.jsonl').open('a') as f:
        f.write(json.dumps({'query':query,'offset':offset})+'\n')
    if query=='old': time.sleep(.35)
    else: time.sleep(.025)
    print(json.dumps({'events':[{'port':query,'action':'fixture'}], 'total':201,'offset':offset}))
else:
    print(json.dumps({'devices':[],'history':[],'logs':[]}))
'''

USB_HARNESS = '''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    id: root
    property int phase: 0
    property int ticks: 0
    property bool staleSeen: false
    Connections { target: UsbLab; function onHistoryChanged() {
        if ((UsbLab.history.events||[]).some(e=>e.port==='old')) root.staleSeen=true
    }}
    Timer { interval: 20; running: true; onTriggered: {
        UsbLab.query='old'; UsbLab.offset=0; UsbLab.loadHistory(); root.phase=1
    }}
    Timer { interval: 55; running: true; onTriggered: {
        UsbLab.query='newest'; UsbLab.offset=100; UsbLab.loadHistory(); root.phase=2
    }}
    Timer { interval: 20; repeat: true; running: true; onTriggered: {
        root.ticks++
        if (root.staleSeen) { console.error('PROOF_FAIL stale USB response displayed'); Qt.exit(2); return }
        if (root.phase===2 && UsbLab.history.events.length && UsbLab.history.events[0].port==='newest') {
            if (UsbLab.history.offset!==100) { console.error('PROOF_FAIL USB pagination owner lost'); Qt.exit(2); return }
            console.log('PROOF_PASS usb-coalesce'); Qt.quit(); return
        }
        if (root.ticks>100) { console.error('PROOF_FAIL USB newest query timed out'); Qt.exit(3) }
    }}
}
'''


@pytest.mark.skipif(not HAS_QS, reason='Set SENSEI_QS_BINARY to an explicit native QuickShell runtime')
def test_usb_history_coalesces_and_rejects_stale_response(tmp_path):
    setup_services(tmp_path, 'UsbLab.qml')
    helper(tmp_path, 'sensei-usb', USB_HELPER)
    report = run_native(tmp_path, USB_HARNESS, timeout=8)
    assert 'PROOF_PASS usb-coalesce' in report, report
    requests = [json.loads(line) for line in (tmp_path / 'usb-requests.jsonl').read_text().splitlines()]
    assert requests[-1] == {'query': 'newest', 'offset': 100}


CALENDAR_HELPER = r'''import json, sys, time
from pathlib import Path
month=sys.argv[2]
with (Path.home()/'calendar-requests.jsonl').open('a') as f: f.write(month+'\n')
time.sleep(.28)
print(json.dumps({'linked':[],'events':[{'month':month,'date':month[:7]+'-12','title':month}],
                  'clocks':[],'tasks':[],'upcoming':[],'focus':{}}))
'''

CALENDAR_HARNESS = '''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    id: root
    property int phase: 0
    property int ticks: 0
    property bool staleSeen: false
    Connections { target: CalendarDesk; function onEventsChanged() {
        if (CalendarDesk.events.length && CalendarDesk.events[0].month!==CalendarDesk.month) root.staleSeen=true
    }}
    Timer { interval: 20; running: true; onTriggered: { CalendarDesk.month='2026-01-01'; CalendarDesk.refresh(); root.phase=1 } }
    Timer { interval: 65; running: true; onTriggered: { CalendarDesk.month='2026-02-01'; CalendarDesk.refresh(); root.phase=2 } }
    Timer { interval: 110; running: true; onTriggered: { CalendarDesk.month='2026-03-01'; CalendarDesk.refresh(); root.phase=3 } }
    Timer { interval: 20; repeat: true; running: true; onTriggered: {
        root.ticks++
        if (root.staleSeen) { console.error('PROOF_FAIL stale calendar month displayed'); Qt.exit(2); return }
        if (root.phase===3 && CalendarDesk.events.length && CalendarDesk.events[0].month==='2026-03-01') {
            console.log('PROOF_PASS calendar-latest-month'); Qt.quit(); return
        }
        if (root.ticks>100) { console.error('PROOF_FAIL calendar latest month timed out'); Qt.exit(3) }
    }}
}
'''


@pytest.mark.skipif(not HAS_QS, reason='Set SENSEI_QS_BINARY to an explicit native QuickShell runtime')
def test_calendar_month_navigation_coalesces_and_owns_results(tmp_path):
    setup_services(tmp_path, 'CalendarDesk.qml')
    helper(tmp_path, 'sensei-calendar', CALENDAR_HELPER)
    report = run_native(tmp_path, CALENDAR_HARNESS, timeout=8)
    assert 'PROOF_PASS calendar-latest-month' in report, report
    requests = (tmp_path / 'calendar-requests.jsonl').read_text().splitlines()
    assert requests[-1] == '2026-03-01'
    assert len(requests) <= 2, requests


DISPLAY_HELPER = r'''import json, sys, time
from pathlib import Path
a=sys.argv[1:]
with (Path.home()/'display-sync.jsonl').open('a') as f: f.write(json.dumps(a)+'\n')
time.sleep(.02)
print(json.dumps({'displays':[],'outputs':[]}))
'''

DISPLAY_IDLE_HARNESS = '''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    property var displayState: ExternalDisplays.data
    Timer { interval: 1700; running: true; onTriggered: { console.log('PROOF_PASS display-idle'); Qt.quit() } }
}
'''

DISPLAY_HARNESS = '''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    Timer { interval: 200; running: true; onTriggered: {
        ExternalDisplays.recoveryInterval=350
        ShellState.dropdown='external-display'
    }}
    Timer { interval: 1700; running: true; onTriggered: { console.log('PROOF_PASS display-recovery'); Qt.quit() } }
}
'''


@pytest.mark.skipif(not HAS_QS, reason='Set SENSEI_QS_BINARY to an explicit native QuickShell runtime')
def test_external_display_has_no_hidden_idle_poll(tmp_path):
    setup_services(tmp_path, 'ExternalDisplays.qml')
    helper(tmp_path, 'sensei-displays', DISPLAY_HELPER)
    report = run_native(tmp_path, DISPLAY_IDLE_HARNESS, timeout=8)
    assert 'PROOF_PASS display-idle' in report, report
    requests = [json.loads(line) for line in (tmp_path / 'display-sync.jsonl').read_text().splitlines()]
    assert requests == [['sync']], requests


@pytest.mark.skipif(not HAS_QS, reason='Set SENSEI_QS_BINARY to an explicit native QuickShell runtime')
def test_external_display_visible_recovery_uses_lightweight_sync(tmp_path):
    setup_services(tmp_path, 'ExternalDisplays.qml')
    helper(tmp_path, 'sensei-displays', DISPLAY_HELPER)
    report = run_native(tmp_path, DISPLAY_HARNESS, timeout=8)
    assert 'PROOF_PASS display-recovery' in report, report
    requests = [json.loads(line) for line in (tmp_path / 'display-sync.jsonl').read_text().splitlines()]
    assert requests[0] == ['sync'], requests
    assert len(requests) >= 3, requests
    assert all(request == ['sync', '--no-layout', '--no-notify'] for request in requests[1:]), requests


SPOTIFY_HELPER = r'''import json, os, sys, time
from pathlib import Path
a=sys.argv[1:]
if a and a[0]=='queue':
    scenario=os.environ['SENSEI_SCENARIO']
    p=Path.home()/'spotify-queue-count'
    count=int(p.read_text())+1 if p.exists() else 1
    p.write_text(str(count))
    time.sleep(.36 if count==1 else .025)
    if count==1: row={'uri':'spotify:old','id':'queue-1' if scenario=='mutation' else 'old'}
    elif scenario=='mutation': row={'uri':'spotify:old','id':'queue-2'}
    else: row={'uri':'spotify:new','id':'new'}
    print(json.dumps({'rows':[row]}))
elif a and a[0]=='account': print(json.dumps({'service':'fixture','cachedLogin':False}))
else: print('{}')
'''

SPOTIFY_CONTROL = r'''import json, sys
if len(sys.argv)>1 and sys.argv[1]=='status':
    print(json.dumps({'backend':'headless','track':{'title':'Old','artist':'Fixture','uri':'spotify:old'},
                      'playing':False,'progress':0,'volume':70,'eventTime':1,'ready':True}))
else: print('{}')
'''

SPOTIFY_HARNESS = '''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    id: root
    property string scenario: Quickshell.env('SENSEI_SCENARIO')
    property int phase: 0
    property int ticks: 0
    property bool staleSeen: false
    property bool firstQueueSeen: false
    Connections { target: SpotifyDesk; function onSpotifyQueueRowsChanged() {
        const rows=SpotifyDesk.spotifyQueueRows||[]
        if (root.scenario==='track-change' && rows.some(r=>r.id==='old')) root.staleSeen=true
        if (rows.some(r=>r.id==='queue-1')) root.firstQueueSeen=true
    }}
    Timer { interval: 120; running: true; onTriggered: {
        SpotifyDesk.spotifyState=Object.assign({},SpotifyDesk.spotifyState,{backend:'headless',
            track:{title:'Old',artist:'Fixture',uri:'spotify:old'},eventTime:1})
        SpotifyDesk.dispatch('queue'); root.phase=1
    }}
    Timer { interval: 190; running: true; onTriggered: {
        if (root.scenario==='mutation') {
            SpotifyDesk.spotifyState=Object.assign({},SpotifyDesk.spotifyState,{eventTime:99})
        } else {
            SpotifyDesk.spotifyState=Object.assign({},SpotifyDesk.spotifyState,{backend:'headless',
                track:{title:'New',artist:'Fixture',uri:'spotify:new'},eventTime:2})
        }
        SpotifyDesk.dispatch('queue'); root.phase=2
    }}
    Timer { interval: 20; repeat: true; running: true; onTriggered: {
        root.ticks++
        if (root.staleSeen) { console.error('PROOF_FAIL old Spotify queue replaced new track'); Qt.exit(2); return }
        const expected=root.scenario==='mutation'?'queue-2':'new'
        if (root.phase===2 && SpotifyDesk.spotifyQueueRows.length && SpotifyDesk.spotifyQueueRows[0].id===expected) {
            if (root.scenario==='mutation'&&!root.firstQueueSeen) { console.error('PROOF_FAIL status timestamp invalidated same-track queue'); Qt.exit(2); return }
            console.log('PROOF_PASS spotify-'+root.scenario); Qt.quit(); return
        }
        if (root.ticks>120) { console.error('PROOF_FAIL Spotify queue refresh timed out',root.scenario); Qt.exit(3) }
    }}
}
'''


@pytest.mark.skipif(not HAS_QS, reason='Set SENSEI_QS_BINARY to an explicit native QuickShell runtime')
@pytest.mark.parametrize('scenario', ['mutation', 'track-change'])
def test_spotify_queue_coalesces_mutations_and_scopes_track_results(tmp_path, scenario):
    setup_services(tmp_path, 'SpotifyDesk.qml')
    put(tmp_path, 'services/YouTubeDesk.qml', YOUTUBE_DESK)
    put(tmp_path, 'config/MachineProfile.qml', '''pragma Singleton\nimport QtQuick\nQtObject { property string primaryOutput: "TEST" }\n''')
    helper(tmp_path, 'sensei-spotify', SPOTIFY_HELPER)
    helper(tmp_path, 'sensei-spotify-control', SPOTIFY_CONTROL)
    report = run_native(tmp_path, SPOTIFY_HARNESS, {'SENSEI_SCENARIO': scenario}, timeout=8)
    assert 'PROOF_PASS spotify-' + scenario in report, report
    assert (tmp_path / 'spotify-queue-count').read_text() == '2'


WIFI_HARNESS = '''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    Component.onCompleted: {
        Wifi.scanned=[{ssid:'old-network',signal:50,secured:true}]
        Wifi.refresh()
        if (Wifi.scanned.length!==0) { console.error('PROOF_FAIL radio-off refresh retained networks'); Qt.exit(2); return }
        const oldEpoch=Wifi.radioEpoch
        Wifi.listRequestEpoch=oldEpoch
        Wifi.listOutput=':90:WPA2:stale-network'
        Wifi.radioChanged(false)
        Wifi.finishScan(0)
        if (Wifi.scanned.length!==0) { console.error('PROOF_FAIL stale scan repopulated after radio off'); Qt.exit(2); return }
        Wifi.scanned=[{ssid:'old-network',signal:50,secured:true}]
        Wifi.applyScanResult(1,Wifi.radioEpoch,':90:WPA2:failed-network',true)
        if (Wifi.scanned.length!==1 || Wifi.scanned[0].ssid!=='old-network') { console.error('PROOF_FAIL failed scan changed network rows'); Qt.exit(2); return }
        Wifi.applyScanResult(0,Wifi.radioEpoch,'',true)
        if (Wifi.scanned.length!==0) { console.error('PROOF_FAIL valid empty scan retained prior rows'); Qt.exit(2); return }
        console.log('PROOF_PASS wifi-scan-ownership'); Qt.callLater(Qt.quit)
    }
}
'''


@pytest.mark.skipif(not HAS_QS, reason='Set SENSEI_QS_BINARY to an explicit native QuickShell runtime')
def test_wifi_radio_epoch_exit_code_and_empty_scan_ownership(tmp_path):
    setup_services(tmp_path, 'Wifi.qml')
    put(tmp_path, 'config/Machine.qml', '''pragma Singleton\nimport QtQuick\nQtObject { property string wifiInterface: "" }\n''')
    put(tmp_path, 'config/Demo.qml', '''pragma Singleton\nimport QtQuick\nQtObject { property bool active:false; function ssidAt(name,index,connected) { return name } }\n''')
    put(tmp_path, 'services/Ethernet.qml', '''pragma Singleton\nimport QtQuick\nQtObject { property bool connected:false }\n''')
    report = run_native(tmp_path, WIFI_HARNESS, timeout=8)
    assert 'PROOF_PASS wifi-scan-ownership' in report, report


@pytest.mark.skipif(not HAS_QS, reason="Explicit native Quickshell runtime required")
def test_cpu_guest_time_is_not_double_counted_and_small_graph_uses_real_groups(tmp_path):
    setup_services(tmp_path, 'SysInfo.qml')
    put(tmp_path, 'config/Machine.qml', 'pragma Singleton\nimport QtQuick\nQtObject {property string netInterface:""}\n')
    helper(tmp_path, 'sensei-net-sampler', '')
    harness = r'''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    property var counters:SysInfo
    Timer {interval:100;running:true;onTriggered:{
        SysInfo._cpuPrev=[];
        SysInfo._readCpu("cpu 100 0 0 100 0 0 0 0 40 0\ncpu0 100 0 0 100 0 0 0 0 40 0\n");
        SysInfo._readCpu("cpu 200 0 0 200 0 0 0 0 140 0\ncpu0 200 0 0 200 0 0 0 0 140 0\n");
        if(Math.abs(SysInfo.cpuPercent-50)>.001 || Math.abs(SysInfo.cpuThreads[0]-50)>.001)
            throw new Error("Guest CPU time was counted twice");
        SysInfo.cpuThreads=[0,50,100,25,75];
        if(JSON.stringify(SysInfo.threadGroups(3))!=="[0,75,50]")
            throw new Error("Compact CPU groups are not measured averages");
        if(JSON.stringify(SysInfo.threadGroups(8))!=="[0,50,100,25,75]")
            throw new Error("Small CPU topology lost observations");
        SysInfo.cpuThreads=[];
        if(SysInfo.threadGroups(8).length)throw new Error("Missing CPU samples became fake load");
        console.log("PROOF_PASS");Qt.quit();
    }}
}'''
    assert 'PROOF_PASS' in run_native(tmp_path,harness)


SCANLINE_HARNESS = r'''import QtQuick
import Quickshell
import qs.components
import qs.services
ShellRoot {
    id: root
    property string scenario: Quickshell.env("SENSEI_SCENARIO")
    property var actor: null
    property var passive: null
    property int phase: 0
    property int ticks: 0
    property real previousPhase: 0
    Window {
        id: canvas
        visible: true
        width: 320
        height: 200
        Item { id: host; anchors.fill: parent }
    }
    Component { id: surface; Scanlines {} }
    function fail(message) {
        console.error("PROOF_FAIL", scenario, phase, message);
        Qt.exit(2);
    }
    function held(expected) {
        if (Effects.bandUsers !== expected) {
            fail("Visible rolling-band ownership: expected " + expected + ", got " + Effects.bandUsers);
            return false;
        }
        return true;
    }
    Timer {
        interval: 20
        repeat: true
        running: true
        onTriggered: {
            if (++root.ticks > 150) { root.fail("Animation lifecycle timed out"); return; }
            if (!Effects.loaded) return;
            if (root.phase === 0) {
                Effects.scanlines = root.scenario === "preview" ? "NONE" : "ROLLING";
                root.actor = surface.createObject(host, root.scenario === "preview"
                    ? {forced: "CRT"} : {surface: "wallpaper"});
                root.phase = 1;
            } else if (root.phase === 1) {
                if (!root.actor.bandWanted || (root.scenario === "preview" && !root.actor.vignetteWanted)) {
                    root.fail("A treatment preview must work independently of the selected treatment");
                    return;
                }
                if (!root.held(1)) return;
                root.previousPhase = Effects.bandPhase;
                root.phase = 2;
            } else if (root.phase === 2) {
                if (Effects.bandPhase === root.previousPhase) return;
                root.passive = surface.createObject(host, {active: false});
                root.phase = 3;
            } else if (root.phase === 3) {
                if (!root.held(1)) return;
                root.passive.destroy();
                root.passive = null;
                root.phase = 4;
            } else if (root.phase === 4) {
                if (!root.held(1)) return;
                host.visible = false;
                root.phase = 5;
            } else if (root.phase === 5) {
                if (!root.held(0)) return;
                host.visible = true;
                root.phase = 6;
            } else if (root.phase === 6) {
                if (!root.held(1)) return;
                canvas.visible = false;
                root.phase = 7;
            } else if (root.phase === 7) {
                if (!root.held(0)) return;
                canvas.visible = true;
                root.phase = 8;
            } else if (root.phase === 8) {
                if (!root.held(1)) return;
                root.actor.destroy();
                root.actor = null;
                root.phase = 9;
            } else {
                if (!root.held(0)) return;
                console.log("PROOF_PASS scanline-" + root.scenario);
                Qt.quit();
            }
        }
    }
}
'''


@pytest.mark.skipif(not HAS_QS, reason="Explicit native Quickshell runtime required")
@pytest.mark.parametrize("scenario", ["preview", "wallpaper"])
def test_scanline_clock_lifecycle(tmp_path, scenario):
    service(tmp_path, "Effects.qml")
    for name in ("scanline.png", "scanline-wide.png", "vignette.png"):
        target = tmp_path / "assets" / name
        target.parent.mkdir(exist_ok=True)
        shutil.copy2(ROOT / "home/.config/quickshell/sensei/assets" / name, target)
    target = tmp_path / "components/Scanlines.qml"
    target.parent.mkdir()
    shutil.copy2(ROOT / "home/.config/quickshell/sensei/components/Scanlines.qml", target)
    put(tmp_path, "config/Paths.qml", '''pragma Singleton
import QtQuick
QtObject {
    property string effectsFile: ''' + json.dumps(str(tmp_path / "effects.json")) + '''
    function url(path) { return "file://" + path; }
}
''')
    put(tmp_path, "config/Demo.qml", 'pragma Singleton\nimport QtQuick\nQtObject {property string scanlines:""}\n')
    put(tmp_path, "config/Appearance.qml", 'pragma Singleton\nimport QtQuick\nQtObject {property var duration:({enter:0,exit:0})}\n')
    report = run_native(tmp_path, SCANLINE_HARNESS, {"SENSEI_SCENARIO": scenario})
    assert "PROOF_PASS scanline-" + scenario in report, report


@pytest.mark.skipif(not HAS_QS, reason="Explicit native Quickshell runtime required")
def test_effect_timing_rejects_malformed_metadata_without_speeding_up_glitches(tmp_path):
    service(tmp_path, "Effects.qml")
    put(tmp_path, "config/Paths.qml", 'pragma Singleton\nimport QtQuick\nQtObject {property string effectsFile:' + json.dumps(str(tmp_path / "effects.json")) + '}\n')
    put(tmp_path, "config/Demo.qml", 'pragma Singleton\nimport QtQuick\nQtObject {property string scanlines:""}\n')
    harness = r'''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    property var effects: Effects
    Timer {interval:50;running:true;onTriggered:{
        Effects.glitchFrom=40;
        Effects.glitchTo=80;
        Effects.glitchEvery=60;
        const unchanged=()=>Effects.glitchFrom===40&&Effects.glitchTo===80&&Effects.glitchEvery===60;
        for (const invalid of ["abc","",null,true,[],{}]) {
            Effects.adopt(JSON.stringify({glitchFrom:invalid,glitchTo:invalid,glitchEvery:invalid}));
            if (!unchanged()) throw new Error("Malformed timing replaced the saved schedule");
        }
        Effects.adopt('{"glitchFrom":1e309,"glitchTo":1e309,"glitchEvery":1e309}');
        if (!unchanged()) throw new Error("Non-finite timing replaced the saved schedule");
        Effects.adopt('{"glitchFrom":3.6,"glitchTo":1e4,"glitchEvery":0}');
        if (Effects.glitchFrom!==4||Effects.glitchTo!==Effects.maxSeconds||Effects.glitchEvery!==Effects.minSeconds)
            throw new Error("Valid timing bounds or rounding were lost");
        console.log("PROOF_PASS effect-timing-metadata");
        Qt.quit();
    }}
}'''
    assert "PROOF_PASS effect-timing-metadata" in run_native(tmp_path, harness)
