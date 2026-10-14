#!/usr/bin/env python3
"""Exercise the one-shot closed-channel recovery without touching the real player."""

import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import threading


with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    (root / ".config/spotify-player").mkdir(parents=True)
    (root / "bin").mkdir()
    stub = root / "bin/systemctl"
    stub.write_text('#!/bin/sh\nprintf called > "$SENSEI_SPOTIFY_HOME/restarted"\n')
    stub.chmod(0o755)

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as server:
        server.bind(("127.0.0.1", 0))
        (root / ".config/spotify-player/app.toml").write_text(
            f"client_port = {server.getsockname()[1]}\n"
        )
        requests = []

        def reply():
            for number in range(2):
                packet, address = server.recvfrom(65536)
                requests.append(json.loads(packet))
                response = (
                    {"Err": list(b"Bad request: Internal error { channel closed }")}
                    if number == 0
                    else {"Ok": list(b"{}")}
                )
                server.sendto(json.dumps(response).encode(), address)
                server.sendto(b"", address)

        thread = threading.Thread(target=reply, daemon=True)
        thread.start()
        env = dict(
            os.environ,
            SENSEI_SPOTIFY_HOME=str(root),
            PATH=str(root / "bin") + ":" + os.environ["PATH"],
        )
        result = subprocess.run(
            [str(Path.home() / ".local/bin/sensei-spotify-transport"), "pause"],
            env=env,
            capture_output=True,
            text=True,
            timeout=8,
        )
        thread.join(timeout=1)
        assert result.returncode == 0, result.stderr + result.stdout
        assert result.stdout.strip() == '{"ok":true}'
        assert len(requests) == 2
        assert (root / "restarted").exists()
        print("Closed channel: one restart, one successful retry")
