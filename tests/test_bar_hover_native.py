"""Opt-in real Quickshell state test; no access to the running desktop session."""
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.skipif(not os.environ.get("SENSEI_QS_BINARY"), reason="Requires an explicitly selected native Quickshell runtime")
def test_parked_remote_cursor_and_overlapping_bars(tmp_path):
    binary = Path(os.environ["SENSEI_QS_BINARY"]).expanduser()
    services = tmp_path / "services"
    config = tmp_path / "config"
    services.mkdir()
    config.mkdir()
    shutil.copy2(ROOT / "home/.config/quickshell/sensei/services/ShellState.qml", services / "ShellState.qml")
    # Isolate unrelated hardware/theme discovery, not the state under test.
    (services / "DesktopTools.qml").write_text("pragma Singleton\nimport QtQuick\nQtObject {property bool quiet:false}\n")
    (services / "Spaces.qml").write_text('pragma Singleton\nimport QtQuick\nQtObject {property var focusedMonitor:({name:"DP-detached"})}\n')
    (services / "SpotifyDesk.qml").write_text('pragma Singleton\nimport QtQuick\nQtObject {property bool fullscreen:false}\n')
    (config / "MachineProfile.qml").write_text('pragma Singleton\nimport QtQuick\nQtObject {property bool desktop:false;property string primaryOutput:"fixture-a";function role(name:string):string{return "main";}}\n')
    (config / "Appearance.qml").write_text("pragma Singleton\nimport QtQuick\nQtObject {property var metrics:({barHeight:30})}\n")
    shutil.copy2(ROOT / "tests/fixtures/bar-hover.qml", tmp_path / "shell.qml")
    home = tmp_path / "home"
    (home / ".local/state/sensei-den").mkdir(parents=True)
    # Keep Unix socket names below sockaddr_un's limit, regardless of pytest's path.
    with tempfile.TemporaryDirectory(prefix="den-hover-") as runtime:
        owner = Path(runtime) / "sensei-den-cursor-owner.json"
        owner.write_text(json.dumps({"version": 1, "owned": False, "output": ""}))
        owner.chmod(0o600)
        env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"),
                   XDG_STATE_HOME=str(home / ".local/state"), XDG_DATA_HOME=str(home / ".local/share"),
                   XDG_CACHE_HOME=str(home / ".cache"), XDG_RUNTIME_DIR=runtime,
                   DBUS_SESSION_BUS_ADDRESS="unix:path=" + runtime + "/no-bus",
                   QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", QS_NO_RELOAD_POPUP="1")
        result = subprocess.run([str(binary), "-p", str(tmp_path / "shell.qml")], env=env,
                                capture_output=True, text=True, timeout=22)
    report = result.stdout + result.stderr
    assert result.returncode == 0, report
    assert "PROOF_PASS parked hover" in report, report
    assert "PROOF_PASS disconnected popup fallback" in report, report
