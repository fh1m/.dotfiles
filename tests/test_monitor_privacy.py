import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]


def test_private_sampler_omits_identities_and_clears_cached_inventory(tmp_path):
    cache = tmp_path / "fh1m-monitor.json"
    cache.write_text(json.dumps({"time": time.monotonic(), "extraTime": time.monotonic(),
                                 "extra": {"routes": "SYNTHETIC_PRIVATE_ROUTE"},
                                 "ips": ["198.18.0.42"], "addressTime": time.monotonic()}))
    env = dict(os.environ, XDG_RUNTIME_DIR=str(tmp_path), SENSEI_MONITOR_PRIVATE="1",
               SENSEI_MONITOR_DETAIL="1", SENSEI_MONITOR_INVENTORY="1")
    result = subprocess.run([sys.executable, str(ROOT / "home/.local/bin/system-monitor-data")],
                            env=env, capture_output=True, text=True, check=True, timeout=10)
    data = json.loads(result.stdout)
    assert data["private"] is True and data["host"] == "Private"
    for field in ("processes", "mounts", "ips", "extra"):
        if data[field]:
            pytest.fail("Private sampler exposed " + field)
    if any(not row["name"].startswith("Interface ") for row in data["network"]):
        pytest.fail("Private sampler exposed interface identities")
    saved = json.loads(cache.read_text())
    if saved["extra"] or saved["ips"] or saved["pids"]:
        pytest.fail("Private sampler retained sensitive inventory")


@pytest.mark.skipif(not os.environ.get("SENSEI_QS_BINARY"), reason="Requires an explicitly selected native Quickshell runtime")
def test_late_unredacted_frame_is_rejected_after_privacy_toggle(tmp_path):
    services = tmp_path / "services"
    services.mkdir()
    shutil.copy2(ROOT / "home/.config/quickshell/sensei/services/LiveMonitor.qml", services / "LiveMonitor.qml")
    providers = {
        "Demo": "property bool active:false",
        "ShellState": 'property string dropdown:"monitor";property int monitorPage:4',
        "CodeDesk": "property int tab:0",
        "RobotBench": "property var data:({gpu:{usage:0}})",
    }
    for name, properties in providers.items():
        (services / (name + ".qml")).write_text("pragma Singleton\nimport QtQuick\nQtObject {" + properties + "}\n")
    # Preserve the production command template; isolate its executable via cwd.
    binary = tmp_path / "@HOME@/.local/bin/system-monitor-data"
    binary.parent.mkdir(parents=True)
    normal = {"private": False, "host": "SYNTHETIC_PRIVATE_HOST", "network": [], "cpu": 1,
              "memory": {"used": 10, "total": 100}, "processes": [], "mounts": [],
              "storage": [], "ips": ["198.18.0.42"], "extra": {"routes": "PRIVATE_ROUTE"}}
    producer = "#!" + sys.executable + "\nimport json,sys,time\nnormal=" + repr(normal) + "\nprint(json.dumps(normal),flush=True)\n"
    producer += "for line in sys.stdin:\n request=json.loads(line)\n if request.get('private'):\n  print(json.dumps(normal),flush=True)\n  time.sleep(.1)\n  private=dict(normal,private=True,host='Private',ips=[],extra={})\n  print(json.dumps(private),flush=True)\n"
    binary.write_text(producer)
    binary.chmod(0o755)
    shutil.copy2(ROOT / "tests/fixtures/monitor-privacy.qml", tmp_path / "shell.qml")
    home = tmp_path / "home"
    home.mkdir()
    with tempfile.TemporaryDirectory(prefix="den-private-") as runtime:
        env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"),
                   XDG_STATE_HOME=str(home / ".local/state"), XDG_DATA_HOME=str(home / ".local/share"),
                   XDG_CACHE_HOME=str(home / ".cache"), XDG_RUNTIME_DIR=runtime,
                   DBUS_SESSION_BUS_ADDRESS="unix:path=" + runtime + "/no-bus", QT_QPA_PLATFORM="offscreen",
                   QT_QUICK_BACKEND="software", QS_NO_RELOAD_POPUP="1")
        result = subprocess.run([os.environ["SENSEI_QS_BINARY"], "-p", str(tmp_path / "shell.qml")],
                                cwd=tmp_path, env=env, capture_output=True, text=True, timeout=20)
    report = result.stdout + result.stderr
    assert result.returncode == 0, report
    assert "PROOF_PASS private transition" in report, report
