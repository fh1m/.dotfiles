import json
import os
import select
import signal
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_reconnect_reports_health_without_forwarding_private_titles(tmp_path):
    binary = tmp_path / "bin"
    binary.mkdir()
    discovery = binary / "hyprctl"
    discovery.write_text("#!/bin/sh\nprintf '%s\\n' '[{\"instance\":\"fixture\",\"wl_socket\":\"fixture-wayland\"}]'\n")
    discovery.chmod(0o755)
    with tempfile.TemporaryDirectory(prefix="den-event-") as runtime:
        path = Path(runtime) / "hypr/fixture/.socket2.sock"
        path.parent.mkdir(parents=True)
        listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        listener.bind(str(path))
        listener.listen(2)
        listener.settimeout(5)
        env = dict(os.environ, XDG_RUNTIME_DIR=runtime, HYPRLAND_INSTANCE_SIGNATURE="fixture",
                   PATH=str(binary) + ":" + os.environ["PATH"],
                   PYTHONPATH=str(ROOT / "home/.local/share/sensei"))
        worker = subprocess.Popen([sys.executable, str(ROOT / "home/.local/bin/sensei-workspace-events")],
                                  env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                  start_new_session=True, bufsize=0)
        pending = bytearray()
        received = []

        def next_event():
            deadline = time.monotonic() + 5
            while b"\n" not in pending:
                remaining = deadline - time.monotonic()
                assert remaining > 0 and select.select([worker.stdout], [], [], remaining)[0], "Watcher stopped reporting connection state"
                data = os.read(worker.stdout.fileno(), 65536)
                assert data, "Watcher exited unexpectedly"
                pending.extend(data)
            line, _, rest = pending.partition(b"\n")
            pending[:] = rest
            received.append(bytes(line))
            return json.loads(line)

        connection = None
        try:
            connection, _ = listener.accept()
            assert next_event()["name"] == "connected"
            connection.sendall(b"windowtitle>>PRIVATE_TITLE_MARKER\nworkspace>>2\n")
            assert next_event() == {"name": "workspace", "data": ""}
            connection.close()
            connection = None
            listener.close()
            path.unlink()
            assert next_event()["name"] == "disconnected"
            listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            listener.bind(str(path))
            listener.listen(2)
            listener.settimeout(5)
            connection, _ = listener.accept()
            assert next_event()["name"] == "connected"
            assert b"PRIVATE_TITLE_MARKER" not in b"\n".join(received)
        finally:
            if connection is not None:
                connection.close()
            listener.close()
            if worker.poll() is None:
                os.killpg(worker.pid, signal.SIGTERM)
            worker.wait(timeout=5)
            worker.stdout.close()
            worker.stderr.close()
