import json
from pathlib import Path
import re
import subprocess
import sys
import tomllib

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.parametrize('split', [False, True])
def test_wallpaper_colors_reach_terminal_and_toolkits_without_rearranging_tmux(tmp_path, monkeypatch, split):
    Image = pytest.importorskip('PIL.Image')
    monkeypatch.setenv('HOME', str(tmp_path))
    bindir = tmp_path / 'bin'
    bindir.mkdir()
    binary = bindir / 'hyprctl'
    binary.write_text('#!/bin/sh\nexit 0\n')
    binary.chmod(0o700)
    monkeypatch.setenv('PATH', str(bindir))
    config = tmp_path / '.config'
    terminal = config / 'alacritty' / ('sensei-colors.toml' if split else 'alacritty.toml')
    terminal.parent.mkdir(parents=True)
    if split:
        terminal.with_name('alacritty.toml').write_text('[general]\nimport = [' + json.dumps(str(terminal)) + ']\n')
    terminal.write_text('[colors.primary]\nbackground = "#171717"\nforeground = "#eeeeee"\n'
                        '[colors.selection]\nbackground = "#f23d70"\n')
    for version in ['gtk-3.0', 'gtk-4.0']:
        target = config / version / 'colors.css'
        target.parent.mkdir()
        target.write_text((ROOT / 'home/.config' / version / 'colors.css').read_text())
    qt = config / 'qt6ct/colors/matugen.conf'
    qt.parent.mkdir(parents=True)
    qt.touch()
    tmux = config / 'tmux/sensei-theme.conf'
    tmux.parent.mkdir()
    template = (ROOT / 'home/.config/tmux/sensei-theme.template.conf').read_text()
    tmux.with_name('sensei-theme.template.conf').write_text(template)
    normalized = lambda t: re.sub(r'#[0-9a-fA-F]{6}|@[A-Z]+@', 'color', t)
    snapshot = []
    for name, rgb in [('rose.png', (238, 22, 109)), ('amber 100% #2.png', (243, 157, 22)), ('mono.png', (48, 48, 48))]:
        image = tmp_path / name
        Image.new('RGB', (32, 32), rgb).save(image)
        subprocess.run([sys.executable, str(ROOT / 'home/.local/bin/sensei-palette'), str(image)],
                       check=True, capture_output=True, timeout=10)
        palette = json.loads((config / 'sensei/wallpaper-palette.json').read_text())
        assert palette['wallpaper'] == str(image)
        colors = tomllib.loads(terminal.read_text())['colors']
        assert colors['primary']['background'] == '#000000'
        assert colors['selection']['background'] == palette['primary']
        rendered_tmux = tmux.read_text()
        assert palette['primary'] in rendered_tmux
        assert normalized(rendered_tmux) == normalized(template)
        for version in ['gtk-3.0', 'gtk-4.0']:
            assert f"@define-color accent_bg_color {palette['primary']};" in (config / version / 'colors.css').read_text()
        assert palette['primary'] in qt.read_text()
        snapshot.append(palette['primary'])
    assert len(set(snapshot)) == 3
    assert len({snapshot[-1][i:i+2] for i in (1, 3, 5)}) == 1
