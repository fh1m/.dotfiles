import importlib.util
import hashlib
import json
import os
import sys
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'home/.local/share/sensei'))


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


cursor = load('den_cursor_runtime_test', ROOT / 'pc/den/den-cursor.py')
installer = load('den_installer_runtime_test', ROOT / 'scripts/install.py')


def owned_build(home, version):
    prefix = home / '.local/opt/sensei-quickshell'
    (prefix / 'bin').mkdir(parents=True)
    binary = prefix / 'bin/quickshell'
    binary.write_bytes(b'owned local build fixture\n')
    binary.chmod(0o755)
    (prefix / 'bin/qs').symlink_to('quickshell')
    if version is not None:
        (prefix / 'qt-version').write_text(version + '\n')
    return prefix


@pytest.mark.parametrize('built,installed,local', [('6.12.0', '6.12.0', True), ('6.11.2', '6.12.0', False), (None, '6.12.0', False)])
def test_cursor_rejects_incompatible_or_unstamped_private_runtime(tmp_path, monkeypatch, built, installed, local):
    prefix = owned_build(tmp_path, built)
    monkeypatch.delenv('SENSEI_QS_BIN', raising=False)
    monkeypatch.setattr(cursor.pathlib.Path, 'home', lambda: tmp_path)
    monkeypatch.setattr(cursor.subprocess, 'check_output', lambda *a, **kw: installed + '\n')
    monkeypatch.setattr(cursor.shutil, 'which', lambda _: '/usr/bin/qs')
    assert cursor.graphical_binary() == (str(prefix / 'bin/qs') if local else '/usr/bin/qs')


def test_pc_install_preserves_stamped_local_binary_and_link(tmp_path):
    prefix = owned_build(tmp_path, '6.12.0')
    before = (prefix / 'bin/quickshell').read_bytes()
    installer.install(tmp_path, apply=True, hardware='pc')
    assert os.readlink(prefix / 'bin/qs') == 'quickshell'
    assert (prefix / 'bin/qs').read_bytes() == before
    assert (prefix / 'qt-version').read_text().strip() == '6.12.0'


@pytest.mark.parametrize('changed', ['system-library', 'backport-library', 'explicit-runtime'])
def test_supervisor_rejects_expired_or_inapplicable_qt_backport(tmp_path, changed):
    prefix = tmp_path / '.local/opt/sensei-qt-wayland'
    (prefix / 'lib').mkdir(parents=True)
    output = prefix / 'lib/libQt6WaylandClient.so.6.12.0'
    output.write_bytes(b'compiled client fixture')
    (prefix / 'lib/libQt6WaylandClient.so.6').symlink_to(output.name)
    system = tmp_path / 'installed-qt-library'
    system.write_bytes(b'exact build input')
    stamp = prefix / 'qt-libraries.sha256'
    stamp.write_text(
        hashlib.sha256(system.read_bytes()).hexdigest() + '  ' + str(system) + '\n' +
        hashlib.sha256(output.read_bytes()).hexdigest() + '  lib/' + output.name + '\n')
    commands = tmp_path / '.local/bin'
    commands.mkdir(parents=True)
    report = tmp_path / 'launched.json'
    qs = commands / 'qs'
    qs.write_text('#!' + sys.executable + '\nimport json,os,pathlib\n'
                  'pathlib.Path(os.environ["RUNTIME_REPORT"]).write_text(json.dumps({"libraries":os.environ.get("LD_LIBRARY_PATH","")}))\n')
    qs.chmod(0o755)
    hyprctl = commands / 'hyprctl'
    hyprctl.write_text('#!/bin/sh\nprintf "false\\n"\n')
    hyprctl.chmod(0o755)
    runtime = tmp_path / 'runtime'
    runtime.mkdir()
    env = dict(os.environ, HOME=str(tmp_path), XDG_RUNTIME_DIR=str(runtime),
               XDG_STATE_HOME=str(tmp_path / 'state'), RUNTIME_REPORT=str(report))
    for key in ('SENSEI_QS_BIN', 'SENSEI_QS_ARGS', 'HYPRLAND_INSTANCE_SIGNATURE', 'LD_LIBRARY_PATH'):
        env.pop(key, None)
    wrapper = ROOT / 'home/.config/quickshell/sensei/external/sensei-shell'
    subprocess.run(['bash', str(wrapper)], env=env, check=True, timeout=10)
    assert json.loads(report.read_text())['libraries'] == str(prefix / 'lib')
    if changed == 'system-library':
        system.write_bytes(b'upgraded Qt with a different private ABI')
    elif changed == 'backport-library':
        output.write_bytes(b'interrupted or corrupt rebuild')
    else:
        env['SENSEI_QS_BIN'] = str(qs)
    subprocess.run(['bash', str(wrapper)], env=env, check=True, timeout=10)
    assert json.loads(report.read_text())['libraries'] == ''
