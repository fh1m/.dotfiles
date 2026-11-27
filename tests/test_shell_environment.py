import importlib.util
import os
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('den_shell_env_installer', ROOT / 'scripts/install.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


@pytest.mark.skipif(not shutil.which('zsh'), reason='native zsh required')
@pytest.mark.parametrize('locale,expected', [(None, 'C.UTF-8'), ('en_US.UTF-8', 'en_US.UTF-8')])
def test_noninteractive_locale_preserves_existing_user_environment(tmp_path, locale, expected):
    config = tmp_path / '.config/zsh'
    config.mkdir(parents=True)
    shutil.copy2(ROOT / 'home/.config/zsh/sensei-env.zsh', config / 'sensei-env.zsh')
    (tmp_path / '.zshenv').write_text('export ORIGINAL_SHELL_SETTING=kept\n')
    backup = tmp_path / 'backup'
    assert installer.install_shell_environment(tmp_path, backup, True)
    assert not installer.install_shell_environment(tmp_path, backup, True)
    env = dict(os.environ, HOME=str(tmp_path))
    for name in ('LANG', 'LC_ALL', 'ZDOTDIR'):
        env.pop(name, None)
    if locale is not None:
        env['LANG'] = locale
    result = subprocess.run(['zsh', '-c', 'printf "%s|%s" "$LANG" "$ORIGINAL_SHELL_SETTING"'], env=env, capture_output=True, text=True, check=True)
    assert result.stdout == expected + '|kept'
    assert (backup / '.zshenv').read_text() == 'export ORIGINAL_SHELL_SETTING=kept\n'


def test_environment_bootstrap_refuses_external_symlink_target(tmp_path):
    home = tmp_path / 'home'
    home.mkdir()
    outside = tmp_path / 'outside'
    outside.write_text('preserved\n')
    (home / '.zshenv').symlink_to(outside)
    with pytest.raises(ValueError):
        installer.install_shell_environment(home, home / 'backup', True)
    assert outside.read_text() == 'preserved\n'


@pytest.mark.parametrize('failure', ['import-environment', 'start'])
def test_desktop_start_failure_never_falls_back_into_terminal_scope(tmp_path, failure):
    binary = tmp_path / 'bin'
    binary.mkdir()
    marker = tmp_path / 'unmanaged-shell-started'
    manager = binary / 'systemctl'
    manager.write_text('#!/bin/sh\nif [ "$2" = "' + failure + '" ]; then exit 23; fi\nexit 0\n')
    manager.chmod(0o755)
    shell = binary / 'qs'
    shell.write_text('#!/bin/sh\ntouch "' + str(marker) + '"\nexit 0\n')
    shell.chmod(0o755)
    env = dict(os.environ, HOME=str(tmp_path), PATH=str(binary)+':'+os.environ['PATH'],
               WAYLAND_DISPLAY='disposable-display')
    for name in ('SENSEI_SHELL_SERVICE', 'SENSEI_QS_ARGS', 'SENSEI_QS_BIN',
                 'HYPRLAND_INSTANCE_SIGNATURE'):
        env.pop(name, None)
    result = subprocess.run(
        ['bash', str(ROOT/'home/.config/quickshell/sensei/external/sensei-shell')],
        env=env, capture_output=True, text=True, timeout=5)
    assert result.returncode == 23
    assert not marker.exists(), 'failed supervision must not start a caller-owned desktop'
