"""Root-boundary and atomic-preparation tests use disposable files, never sudo."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import types

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'home/.local/share/sensei'))
import protected_backup as backup

spec = importlib.util.spec_from_file_location('protected_reader', ROOT / 'scripts/protected-rootfs-reader.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)


def enrolled(root):
    root.mkdir()
    (root / 'evidence').write_text('original')
    value = root.stat()
    return {'source': str(root), 'device': value.st_dev, 'inode': value.st_ino}


def description(config):
    fd = reader.open_root(config)
    try:
        return reader.describe(config, fd)
    finally:
        os.close(fd)


def test_root_replacement_and_symlink_cannot_redirect_privileged_reader(tmp_path):
    root = tmp_path / 'rootfs'
    config = enrolled(root)
    saved = tmp_path / 'saved'
    root.rename(saved)
    root.mkdir()
    with pytest.raises(ValueError):
        reader.open_root(config)
    root.rmdir()
    root.symlink_to(saved, target_is_directory=True)
    with pytest.raises(OSError):
        reader.open_root(config)


def test_fingerprint_tracks_source_changes_without_following_outside_links(tmp_path):
    root = tmp_path / 'rootfs'
    config = enrolled(root)
    outside = tmp_path / 'private'
    outside.write_text('outside')
    (root / 'link').symlink_to(outside)
    before = description(config)
    outside.write_text('changed outside')
    assert description(config) == before
    (root / 'evidence').write_text('changed inside')
    assert description(config)['fingerprint'] != before['fingerprint']


@pytest.mark.parametrize('failure', ['nonzero', 'source-change'])
def test_failed_or_inconsistent_export_preserves_previous_archive(tmp_path, monkeypatch, failure):
    root = tmp_path / 'rootfs'
    config = enrolled(root)
    state = tmp_path / 'state'
    folder = state / 'backup-exports'
    folder.mkdir(parents=True)
    archive = folder / 'rootfs.tar.zst'
    archive.write_bytes(b'previous recoverable archive')
    monkeypatch.setattr(backup, 'inspect_source', lambda: description(config))
    monkeypatch.setattr(backup.shutil, 'disk_usage', lambda _: types.SimpleNamespace(free=100 * backup.GIB))
    real_popen = subprocess.Popen
    program = 'import os,sys;os.write(1,b"partial new archive");os.write(2,b"x"*40000);'
    if failure == 'nonzero':
        program += 'sys.exit(7)'
    else:
        program += 'from pathlib import Path;Path(' + repr(str(root / 'evidence')) + ').write_text("mutated")'
    def exporter(_command, **kwargs):
        return real_popen([sys.executable, '-c', program], **kwargs)
    monkeypatch.setattr(backup.subprocess, 'Popen', exporter)
    with pytest.raises(ValueError):
        backup.prepare({'source': str(root)}, state)
    assert archive.read_bytes() == b'previous recoverable archive'
    assert not (folder / 'rootfs.json').exists()
    assert not list(folder.glob('.rootfs-*.tmp'))
    assert (folder / 'rootfs-diagnostics.log').stat().st_size <= 8192


def test_low_space_cannot_replace_prior_archive(tmp_path, monkeypatch):
    root = tmp_path / 'rootfs'
    config = enrolled(root)
    state = tmp_path / 'state'
    folder = state / 'backup-exports'
    folder.mkdir(parents=True)
    archive = folder / 'rootfs.tar.zst'
    archive.write_bytes(b'preserve')
    monkeypatch.setattr(backup, 'inspect_source', lambda: description(config))
    monkeypatch.setattr(backup.shutil, 'disk_usage', lambda _: types.SimpleNamespace(free=backup.GIB))
    with pytest.raises(ValueError):
        backup.prepare({'source': str(root)}, state)
    assert archive.read_bytes() == b'preserve'
    assert not list(folder.glob('.rootfs-*.tmp'))


def test_wrong_enrollment_cannot_authorize_an_exclusion(tmp_path, monkeypatch):
    source = tmp_path / 'rootfs'
    source.mkdir()
    monkeypatch.setattr(backup, 'inspect_source', lambda: {'source': '/another/rootfs'})
    with pytest.raises(ValueError):
        backup.prepare({'source': str(source)}, tmp_path / 'state')
    assert not (tmp_path / 'state/backup-exports/rootfs.tar.zst').exists()
