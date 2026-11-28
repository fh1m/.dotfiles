import json
from pathlib import Path
import subprocess
import sys
import tomllib

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.parametrize('profile, config', [('', 'alacritty.toml'), ('profiles/pc/', 'sensei-colors.toml')])
def test_palette_changes_accent_without_recoloring_terminal_or_status_bar(tmp_path, monkeypatch, profile, config):
    Image = pytest.importorskip('PIL.Image')
    monkeypatch.setenv('HOME', str(tmp_path))
    bindir = tmp_path / 'bin'
    bindir.mkdir()
    for name in ['gsettings', 'hyprctl']:
        binary = bindir / name
        binary.write_text('#!/bin/sh\nexit 0\n')
        binary.chmod(0o700)
    monkeypatch.setenv('PATH', str(bindir))
    config_dir = tmp_path / '.config'
    wallpapers = config_dir / 'sensei/wallpapers.json'
    wallpapers.parent.mkdir(parents=True)
    wallpapers.write_text('{}')
    terminal = config_dir / 'alacritty' / config
    terminal.parent.mkdir()
    terminal.write_text('[colors.primary]\nbackground = "#171717"\nforeground = "#eeeeee"\n'
                        '[colors.selection]\nbackground = "#f23d70"\n')
    tmux = config_dir / 'tmux/sensei-theme.conf'
    tmux.parent.mkdir()
    tmux.write_text('set -g status-style bg=black\n')
    tmux.with_name('sensei-theme.template.conf').write_text('set -g status-style bg=@GROUND@\n')
    snapshot = []
    for name, rgb in [('rose.png', (238, 22, 109)), ('amber 100% #2.png', (243, 157, 22))]:
        image = tmp_path / name
        Image.new('RGB', (32, 32), rgb).save(image)
        subprocess.run([sys.executable, str(ROOT / (profile + 'home/.local/bin/sensei-palette')), str(image)],
                       check=True, capture_output=True, timeout=10)
        palette = json.loads(wallpapers.with_name('wallpaper-palette.json').read_text())
        colors = tomllib.loads(terminal.read_text())['colors']
        assert colors['primary']['background'] == '#000000'
        assert colors['selection']['background'] == palette['primary']
        assert tmux.read_text() == 'set -g status-style bg=black\n'
        snapshot.append(palette['primary'])
    assert snapshot[0] != snapshot[1]
