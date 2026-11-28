import os
from pathlib import Path
import shutil
import subprocess

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.skipif(not shutil.which('tmux'), reason='Native tmux required')
def test_daily_reuses_existing_work_after_creating_independent_sessions(tmp_path):
    tmux = shutil.which('tmux')
    socket = tmp_path / 'tmux.sock'
    runner = tmp_path / 'tmux'
    runner.write_text(f'''#!/bin/sh
case "$1" in
  attach-session) printf '%s\\n' "$3"; exit 0;;
esac
exec {tmux} -S "{socket}" "$@"
''')
    runner.chmod(0o700)
    env = {**os.environ, 'PATH': f'{tmp_path}:{os.environ["PATH"]}',
           'HOME': str(tmp_path), 'XDG_STATE_HOME': str(tmp_path / 'state')}
    env.pop('TMUX', None)
    env.pop('TMUX_PANE', None)

    def native(*args):
        return subprocess.check_output([tmux, '-S', str(socket), *args], env=env, text=True, timeout=6).strip()

    def launch(*args):
        return subprocess.check_output([str(ROOT / 'home/.local/bin/sensei-tmux'), *args],
                                       env=env, text=True, timeout=6).strip()

    try:
        native('new-session', '-d', '-s', 'dev_062', '-n', 'Existing')
        assert launch() == '=dev_062'
        assert launch() == '=dev_062'
        assert launch('--new') == '=dev_063'
        assert launch() == '=dev_062'
        assert native('list-windows', '-t', '=dev_062', '-F', '#{window_name}') == 'Existing'
        assert set(native('list-sessions', '-F', '#{session_name}').splitlines()) == {'dev_062', 'dev_063'}
    finally:
        subprocess.run([tmux, '-S', str(socket), 'kill-server'], env=env, check=False, timeout=5)
