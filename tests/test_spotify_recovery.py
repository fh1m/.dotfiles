#!/usr/bin/env python3
"""A closed local channel must not restart or interrupt a remote Spotify device."""

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

    flags = subprocess.check_output(['pkg-config', '--cflags', '--libs', 'json-c', 'openssl'], text=True).split()
    executable = root / 'transport'
    subprocess.run(['cc', '-O2', str(Path(__file__).resolve().parents[1]/'src/spotify/transport.c'), '-o', str(executable), *flags], check=True)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as server:
        server.bind(("127.0.0.1", 0))
        (root / ".config/spotify-player/app.toml").write_text(
            f"client_port = {server.getsockname()[1]}\n"
        )
        requests = []
        server.settimeout(1)

        def reply():
            for number in range(2):
                try: packet, address = server.recvfrom(65536)
                except TimeoutError: break
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
            [str(executable), "pause"],
            env=env,
            capture_output=True,
            text=True,
            timeout=8,
        )
        thread.join(timeout=2)
        assert result.returncode != 0, result.stderr + result.stdout
        assert "Playback on another device is untouched" in result.stdout
        assert len(requests) == 1
        assert not (root / "restarted").exists()
        print("Closed channel: no restart, no repeated transport action")
