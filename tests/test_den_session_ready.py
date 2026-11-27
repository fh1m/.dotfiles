import importlib.machinery
import importlib.util
import json
import os
import socket
import sys
from pathlib import Path
from unittest.mock import patch

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "home/.local/share/sensei"))


def launcher():
    loader = importlib.machinery.SourceFileLoader("den_session_ready", str(ROOT / "pc/den/den-session.py"))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def endpoints(runtime, name, live):
    directory = runtime / "hypr" / name
    directory.mkdir(parents=True)
    paths = [directory / ".socket.sock", runtime / (name + "-wayland")]
    sockets = []
    for path in paths:
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(str(path))
        if live:
            server.listen(8)
            sockets.append(server)
        else:
            server.close()  # The socket inode remains: it is not a live server.
    return {"instance": name, "wl_socket": name + "-wayland"}, sockets


def test_socket_inodes_alone_are_not_graphical_readiness(tmp_path):
    module = launcher()
    row, _ = endpoints(tmp_path, "stale", False)
    with patch.dict(os.environ, {"XDG_RUNTIME_DIR": str(tmp_path), "HYPRLAND_INSTANCE_SIGNATURE": "stale"}), patch.object(module.subprocess, "check_output", return_value=json.dumps([row]).encode()):
        with pytest.raises(TimeoutError, match="no live graphical socket"):
            module.wait_for_session(timeout=.05)


def test_ambiguous_live_sessions_require_explicit_identity(tmp_path):
    module = launcher()
    first, first_sockets = endpoints(tmp_path, "first", True)
    second, second_sockets = endpoints(tmp_path, "second", True)
    try:
        with patch.dict(os.environ, {"XDG_RUNTIME_DIR": str(tmp_path), "HYPRLAND_INSTANCE_SIGNATURE": "unknown"}), patch.object(module.subprocess, "check_output", return_value=json.dumps([first, second]).encode()):
            with pytest.raises(RuntimeError, match="multiple graphical sessions"):
                module.wait_for_session(timeout=.5)
        with patch.dict(os.environ, {"XDG_RUNTIME_DIR": str(tmp_path), "HYPRLAND_INSTANCE_SIGNATURE": "second"}), patch.object(module.subprocess, "check_output", return_value=json.dumps([first, second]).encode()):
            selected, runtime = module.wait_for_session(timeout=.5)
            assert selected == second and runtime == tmp_path
    finally:
        for server in first_sockets + second_sockets:
            server.close()


def test_typo_cannot_start_input_capture():
    module = launcher()
    with pytest.raises(ValueError, match="Choose reset"):
        module.main("raedy")
