import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.skipif(not os.environ.get("SENSEI_QS_BINARY"), reason="Requires an explicitly selected native Quickshell runtime")
def test_expiry_hover_resume_and_persistent_cards(tmp_path):
    for directory in ("notifications", "components", "config", "services"):
        (tmp_path / directory).mkdir()
    shutil.copy2(ROOT / "home/.config/quickshell/sensei/modules/notifications/NotificationCard.qml", tmp_path / "notifications/NotificationCard.qml")
    # Static visual providers are isolated; the production lifetime animation,
    # pause/resume methods, card instances and dismissal signals run unchanged.
    providers = {
        "components/ChamferPanel.qml": 'import QtQuick\nItem {property real chamfer:0;property real chamferBottomLeft:0;property color fillColor;property color borderColor}\n',
        "components/SlantBlock.qml": 'import QtQuick\nRectangle {property color fillColor}\n',
        "components/NrLabel.qml": 'import QtQuick\nText {property bool tracked:true;property real pixelSize:11;font.pixelSize:pixelSize}\n',
        "components/ActionButton.qml": 'import QtQuick\nItem {property string text;property bool accented:false;property color textColor;signal clicked()}\n',
        "config/Theme.qml": 'pragma Singleton\nimport QtQuick\nQtObject {property real radiusPanel:0;property color signalRed:"red";property color paperMuted:"gray";property color ink:"black";property color rule:"gray";property color surfaceOne:"black";property color mute:"gray";property color bright:"white";property color text:"white";property color accent:"pink";property color dim:"gray"}\n',
        "config/Appearance.qml": 'pragma Singleton\nimport QtQuick\nQtObject {property var font:({ui:"monospace",weightSemi:600});property string separator:" · "}\n',
        "services/Notifications.qml": 'pragma Singleton\nimport QtQuick\nQtObject {function levelOf(n){return n.urgency===2?"CRITICAL":"NORMAL";}function plainSummary(s){return s;}function safeBody(s){return s;}}\n',
        "services/Deck.qml": 'pragma Singleton\nimport QtQuick\nQtObject {function leave(){}}\n',
    }
    for relative, contents in providers.items():
        (tmp_path / relative).write_text(contents)
    shutil.copy2(ROOT / "tests/fixtures/notification-lifetime.qml", tmp_path / "shell.qml")
    with tempfile.TemporaryDirectory(prefix="den-notice-") as runtime:
        env = dict(os.environ, HOME=str(tmp_path), XDG_RUNTIME_DIR=runtime,
                   XDG_CONFIG_HOME=str(tmp_path / "private-config"), XDG_CACHE_HOME=str(tmp_path / "cache"),
                   DBUS_SESSION_BUS_ADDRESS="unix:path=" + runtime + "/no-bus", QT_QPA_PLATFORM="offscreen",
                   QT_QUICK_BACKEND="software", LC_ALL="C.UTF-8", QS_NO_RELOAD_POPUP="1")
        result = subprocess.run([os.environ["SENSEI_QS_BINARY"], "-p", str(tmp_path / "shell.qml")],
                                env=env, capture_output=True, text=True, timeout=20)
    report = result.stdout + result.stderr
    assert result.returncode == 0, report
    assert "PROOF_PASS notification expiry and pause" in report, report
    assert "setPaused() cannot" not in report, report
