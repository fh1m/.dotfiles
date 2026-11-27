"""Opt-in native libmpv object lifetime test; never plays user media."""
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.skipif(not os.environ.get("SENSEI_QS_BINARY"), reason="Requires native Quickshell and the installed Sensei.Media module")
def test_output_handoffs_release_old_native_engines(tmp_path):
    services = tmp_path / "services"
    services.mkdir()
    (tmp_path / "config").mkdir()
    (tmp_path / "config/Placeholder.qml").write_text('import QtQuick\nQtObject {}\n')
    for name in ("YouTubeDesk.qml", "MpvEngine.qml"):
        shutil.copy2(ROOT / "home/.config/quickshell/sensei/services" / name, services / name)
    (services / "ShellState.qml").write_text('pragma Singleton\nimport QtQuick\nQtObject {property string dropdown:"";property string dropdownOriginScreen:""}\n')
    (services / "SpotifyDesk.qml").write_text('pragma Singleton\nimport QtQuick\nQtObject {property string videoMode:"";property bool musicVisible:false;property int page:0;property string videoWindowOutput:"";property bool videoAudioLinked:false;function closeVideo(linked){videoAudioLinked=false;}}\n')
    (tmp_path / "shell.qml").write_text('''import QtQuick
import Quickshell
import "services"
ShellRoot {
    id: root
    property int step: 0
    Variants {
        model: ["fixture-a","fixture-b","fixture-c"]
        Scope {
            required property string modelData
            Loader {
                active: YouTubeDesk.usedDisplays.includes(modelData)
                source: "services/MpvEngine.qml"
                onLoaded: { if(item.ownerOutput!==undefined)item.ownerOutput=modelData;YouTubeDesk.registerEngine(modelData,item); }
            }
        }
    }
    Timer {interval:250;repeat:true;running:true;onTriggered:{
        if(root.step<6){YouTubeDesk.selectEngine(["fixture-a","fixture-b","fixture-c"][root.step%3],1200,true);root.step++;return;}
        const keys=Object.keys(YouTubeDesk.engines);
        if(keys.length!==1||keys[0]!==YouTubeDesk.engineOutput||YouTubeDesk.usedDisplays.length!==1)throw new Error("Stopped native engines retained after handoff: "+keys);
        YouTubeDesk.release();stop();finish.restart();
    }}
    Timer {id:finish;interval:250;onTriggered:{
        if(Object.keys(YouTubeDesk.engines).length||YouTubeDesk.usedDisplays.length)throw new Error("Native media engines retained after release");
        console.log("PROOF_PASS bounded native media engines");Qt.quit();
    }}
}
''')
    with tempfile.TemporaryDirectory(prefix="den-media-life-") as runtime:
        env = dict(os.environ, HOME=str(tmp_path), XDG_RUNTIME_DIR=runtime,
                   XDG_CONFIG_HOME=str(tmp_path / "private-config"), XDG_CACHE_HOME=str(tmp_path / "cache"),
                   DBUS_SESSION_BUS_ADDRESS="unix:path=" + runtime + "/no-bus", QT_QPA_PLATFORM="offscreen",
                   QT_QUICK_BACKEND="software", LC_ALL="C.UTF-8", QS_NO_RELOAD_POPUP="1",
                   QML_IMPORT_PATH=str(Path.home() / ".local/lib/qt6/qml"))
        result = subprocess.run([os.environ["SENSEI_QS_BINARY"], "-p", str(tmp_path / "shell.qml")],
                                env=env, capture_output=True, text=True, timeout=15)
    report = result.stdout + result.stderr
    assert result.returncode == 0, report
    assert "PROOF_PASS bounded native media engines" in report, report
