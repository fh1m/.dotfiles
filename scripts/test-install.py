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
    assert (home/'.local/bin/sensei-shell').is_symlink()
    assert m.install(home, True)['changed'] == []
    # Caches never reach the home directory.
    assert not any('__pycache__' in p.parts or p.suffix == '.pyc' for p in home.rglob('*'))
    # Seed-only state keeps a live value, and is seeded only when missing.
    state = home/'.config/hypr/zenbook-controls.json'
    state.write_text('{"touchpad": false}\n')
    assert '.config/hypr/zenbook-controls.json' not in m.install(home, True)['changed']
    assert state.read_text() == '{"touchpad": false}\n'
    fresh = Path(tempfile.mkdtemp(prefix='dotfiles-seed-'))
    m.install(fresh, True)
    assert (fresh/'.config/hypr/zenbook-controls.json').is_file()
print('PASS: dry run, home rendering, backup, generic monitors, helper links, idempotence, seed-only state, no caches')
# --apply needs an explicit hardware choice; the CLI refuses an implicit one.
import subprocess, sys
refused = subprocess.run([sys.executable, str(Path(__file__).with_name('install.py')), '--apply'], capture_output=True, text=True)
assert refused.returncode != 0 and '--hardware' in refused.stderr, refused.stderr
print('PASS: --apply without --hardware is refused')
