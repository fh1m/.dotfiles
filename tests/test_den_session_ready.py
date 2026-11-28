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


def operator_backend(tmp_path, monkeypatch):
    commands = tmp_path / 'bin'
    commands.mkdir()
    binary = commands / 'hyprctl'
    binary.write_text('#!' + sys.executable + r'''
import json,os,sys
from pathlib import Path
a=sys.argv[1:]
if a==['instances','-j']:
 print(os.environ['TEST_INSTANCES']);raise SystemExit
selected=os.environ.get('HYPRLAND_INSTANCE_SIGNATURE','0')
if '-i' in a:selected=a[a.index('-i')+1]
if selected=='0':selected='first'
Path(os.environ['TEST_DESKTOP_QUERY']).write_text(selected)
if 'clients' in a:print('[]')
else:print(json.dumps([{'name':selected,'width':1920,'height':1080,'scale':1,'x':0,'y':0,'activeWorkspace':{'id':1}}]))
''')
    binary.chmod(0o700)
    monkeypatch.setenv('PATH', str(commands) + os.pathsep + os.environ['PATH'])
    monkeypatch.setenv('TEST_DESKTOP_QUERY', str(tmp_path / 'queried-session'))
    loader = importlib.machinery.SourceFileLoader('den_operator_session', str(ROOT / 'home/.local/bin/sensei-den'))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def test_operator_ambiguous(tmp_path, monkeypatch):
    module = operator_backend(tmp_path, monkeypatch)
    first, one = endpoints(tmp_path, 'first', True)
    second, two = endpoints(tmp_path, 'second', True)
    monkeypatch.setenv('XDG_RUNTIME_DIR', str(tmp_path))
    monkeypatch.setenv('TEST_INSTANCES', json.dumps([first, second]))
    monkeypatch.delenv('HYPRLAND_INSTANCE_SIGNATURE', raising=False)
    try:
        with pytest.raises(ValueError, match='Desktop session unavailable or ambiguous'):
            module.run(['hyprctl', 'monitors', '-j'], timeout=2)
        assert not (tmp_path / 'queried-session').exists()
    finally:
        for server in one + two:
            server.close()


def test_companion_selected_session(tmp_path, monkeypatch):
    module = operator_backend(tmp_path, monkeypatch)
    monkeypatch.setenv('HYPRLAND_INSTANCE_SIGNATURE', 'second')
    assert module.companion_available() == ['second']
