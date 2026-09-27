#!/usr/bin/env python3
"""Verify rendering, generic monitor safety, backup and idempotent installation."""
import importlib.util, tempfile
from pathlib import Path
spec = importlib.util.spec_from_file_location('installer', Path(__file__).with_name('install.py'))
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
with tempfile.TemporaryDirectory(prefix='dotfiles-test-') as directory:
    home = Path(directory)
    original = home / '.tmux.conf'; original.write_text('existing configuration\n')
    dry = m.install(home); assert dry['changed'] and original.read_text() == 'existing configuration\n'
    applied = m.install(home, True)
    assert (Path(applied['backup'])/'.tmux.conf').read_text() == 'existing configuration\n'
    config = (home/'.config/hypr/custom-setup.lua').read_text()
    assert '@HOME@' not in config and 'position = "0x1080"' not in config
    assert str(home) in (home/'.config/hypr/hyprland.lua').read_text()
    assert (home/'.local/bin/wrayth-shell').is_symlink()
    assert m.install(home, True)['changed'] == []
print('PASS: dry run, home rendering, backup, generic monitors, helper links, idempotence')
