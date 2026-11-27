import importlib.machinery
import importlib.util
import json
import os
import signal
import subprocess
import sys
import time
from pathlib import Path
from unittest.mock import patch

import pytest

ROOT = Path(__file__).resolve().parents[1]


def test_cancelled_transfer_stops_child_and_preserves_terminal_receipt(tmp_path):
    pytest.importorskip("dbus")
    sys.path.insert(0, str(ROOT / "home/.local/share/sensei"))
    import job_runtime
    source = ROOT / "home/.local/bin/sensei-phone"
    loader = importlib.machinery.SourceFileLoader("phone_cancel_native", str(source))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    with patch.object(Path, "home", return_value=tmp_path):
        loader.exec_module(module)
    folder = module.STATE / "jobs"
    folder.mkdir()
    record = folder / "1234.json"
    child_pid = tmp_path / "child.pid"
    program = "import os,pathlib,time;pathlib.Path(" + repr(str(child_pid)) + ").write_text(str(os.getpid()));time.sleep(60)"
    record.write_text(json.dumps({"state": "starting", "created": time.time(), "args": [sys.executable, "-c", program], "log": str(folder / "1234.log")}))
    env = dict(os.environ, HOME=str(tmp_path), PYTHONPATH=str(ROOT / "home/.local/share/sensei"))
    worker = subprocess.Popen([sys.executable, str(source), "--job", str(record)], env=env,
                              start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        deadline = time.monotonic() + 5
        while not child_pid.exists() and worker.poll() is None and time.monotonic() < deadline:
            time.sleep(.01)
        assert child_pid.exists(), "Disposable transfer never started"
        child = int(child_pid.read_text())
        result = module.action("cancel-transfer", args=[record.name])
        assert result["ok"]
        worker.wait(timeout=5)
        saved = json.loads(record.read_text())
        assert saved["state"] == "cancelled" and saved["finished"] >= saved["created"]
        assert job_runtime.identity(child) is None
        before = record.read_bytes()
        assert not module.action("cancel-transfer", args=[record.name])["ok"]
        assert record.read_bytes() == before
    finally:
        if worker.poll() is None:
            worker.terminate()
            try:
                worker.wait(timeout=5)
            except subprocess.TimeoutExpired:
                worker.kill()
                worker.wait(timeout=2)
        if child_pid.exists():
            pid = int(child_pid.read_text())
            command = Path("/proc") / str(pid) / "cmdline"
            try:
                if command.exists() and str(child_pid).encode() in command.read_bytes():
                    os.killpg(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
