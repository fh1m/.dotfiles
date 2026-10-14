#!/usr/bin/env python3
"""Verify rendering, generic monitor safety, backup and idempotent installation."""
import importlib.util, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
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
    # Live layout: each linked path is a symlink to its external file, and the target exists.
    for relative, target in m.LINKS.items():
        assert (home/relative).is_symlink() and (home/relative).resolve() == (home/target).resolve(), relative
        assert (home/target).is_file(), target
    # Every file the desktop loads by path must exist after install.
    import re
    for name in ['hyprland.lua', 'custom-setup.lua']:
        for ref in re.findall(r'dofile\("([^"]+)"\)', (home/'.config/hypr'/name).read_text()):
            assert Path(ref).is_file(), (name, ref)
    for unit in (home/'.config/systemd/user').glob('*.service'):
        for ref in re.findall(r'ExecStart=%h/(\S+)', unit.read_text()):
            assert (home/ref).exists(), (unit.name, ref)
    # Seed wallpaper: the lockedFile the seed names must exist, and the copy must have run.
    assert (home/'.config/quickshell/sensei/assets/wallpapers/net-circuit.png').is_file()
    assert (home/'Pictures/wallpapers/sensei/net-circuit.png').is_file()
    # A live directory link into the repo must not be rendered back over the repo source.
    linked = Path(tempfile.mkdtemp(prefix='dotfiles-dirlink-'))
    (linked/'.config').mkdir(); (linked/'.config/nvim').symlink_to(ROOT/'home/.config/nvim')
    assert not any(c.startswith('.config/nvim/') for c in m.install(linked)['changed'])
    # Machine-local files keep the live content, even when the repo copy differs.
    phone = home/'.config/quickshell/sensei/services/PhoneBridge.qml'
    phone.write_text('live phone address\n')
    m.install(home, True, 'generic')
    assert phone.read_text() == 'live phone address\n'
    # A live symlink must be replaced by a link, never written through.
    live = Path(tempfile.mkdtemp(prefix='dotfiles-live-'))
    other = live/'elsewhere.conf'; other.write_text('keep me\n')
    (live/'.config/kitty').mkdir(parents=True); (live/'.config/kitty/kitty.conf').symlink_to(other)
    m.install(live, True, 'generic')
    assert other.read_text() == 'keep me\n'
    assert (live/'.config/kitty/kitty.conf').resolve() == (live/'.config/quickshell/sensei/external/kitty.conf').resolve()
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
