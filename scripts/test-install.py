#!/usr/bin/env python3
"""Exercise three profiles, private-state preservation and reversible writes."""
import importlib.util
import os
import tempfile
from pathlib import Path
spec=importlib.util.spec_from_file_location('installer',Path(__file__).with_name('install.py'))
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
for profile in ('generic','zenbook','pc'):
    with tempfile.TemporaryDirectory(prefix='dotfiles-test-') as folder:
        home=Path(folder)
        original=home/'.tmux.conf';original.write_text('existing configuration\n');original.chmod(0o640)
        private=home/'.config/hypr/chrome-gpu.json';private.parent.mkdir(parents=True);private.write_text('{"privatePreference": true}')
        link=home/'.local/bin/wrayth-shell';link.parent.mkdir(parents=True);link.symlink_to('/a/previous/helper')
        before={p.relative_to(home).as_posix():(os.readlink(p) if p.is_symlink() else p.read_bytes()) for p in home.rglob('*') if p.is_file() or p.is_symlink()}
        dry=m.install(home,hardware=profile)
        assert dry['changed'] and original.read_text()=='existing configuration\n'
        assert not (home/'.local/state/dotfiles-backups').exists()
        applied=m.install(home,True,profile)
        assert (Path(applied['backup'])/'.tmux.conf').read_text()=='existing configuration\n'
        assert private.read_text()=='{"privatePreference": true}'
        assert link.is_symlink() and link.resolve().is_file()
        assert m.install(home,True,profile)['changed']==[], profile
        config=(home/'.config/hypr/custom-setup.lua').read_text()
        assert '@HOME@' not in config and '/home/fh1m' not in config
        if profile=='generic':assert 'position = "0x1080"' not in config
        if profile=='zenbook':assert 'position = "0x1080"' in config
        if profile=='pc':
            assert not (home/'.config/environment.d/vaapi.conf').exists()
            assert not (home/'.local/bin/zenbook-controls').exists()
            assert 'asusctl' not in config and 'zenbook' not in config
            assert 'MOZ_DISABLE_RDD_SANDBOX' not in config
            assert (home/'.config/sensei/machine.json').is_file()
            assert 'sm_75' not in (home/'.zshrc').read_text() # no global toolkit assumptions
        m.restore(Path(applied['backup']),home)
        for relative,data in before.items():
            p=home/relative
            assert (os.readlink(p) if p.is_symlink() else p.read_bytes())==data
        assert original.stat().st_mode & 0o777==0o640
        assert not (home/'.config/hypr/hyprland.lua').exists()
# A malicious/surprising parent symlink must not redirect deployment outside home.
with tempfile.TemporaryDirectory() as folder, tempfile.TemporaryDirectory() as outside:
    home=Path(folder);(home/'.config').symlink_to(outside)
    try:m.install(home,True,'pc')
    except ValueError:pass
    else:raise AssertionError('Installer accepted a destination outside target home')
print('PASS: generic/zenbook/pc dry run, path rendering, state preservation, backup, links, idempotence, restore and escape guard')
