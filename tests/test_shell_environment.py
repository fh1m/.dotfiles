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
