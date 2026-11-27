import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('den_apps',ROOT/'scripts/setup-den-apps.py')
apps=importlib.util.module_from_spec(spec);spec.loader.exec_module(apps)


def test_config_sync_excludes_credentials_and_preserves_existing_destinations(tmp_path):
    source=tmp_path/'source';source.mkdir()
    for name,value in (('.claude/settings.json','{}'),('.claude/.credentials.json','secret'),('.codex/auth.json','secret'),('.cache/spotify-player/device_token.json','secret'),('.config/spotify-player/app.toml','[device]')):
        path=source/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(value)
    names=apps.config_files(source)
    assert '.claude/settings.json' in names
    assert '.config/spotify-player/app.toml' in names
    assert not any('credentials' in name or '/auth.json' in name or name.endswith('_token.json') for name in names)
    archive=io.BytesIO()
    with tarfile.open(fileobj=archive,mode='w:gz') as tar:
        for name in names:
            info=tarfile.TarInfo(name);data=(source/name).read_bytes();info.size=len(data);tar.addfile(info,io.BytesIO(data))
    destination=tmp_path/'destination';existing=destination/'.claude/settings.json';existing.parent.mkdir(parents=True);existing.write_text('user-owned')
    env=dict(os.environ,HOME=str(destination))
    result=subprocess.run([sys.executable,'-c',apps.receiver_code()],input=archive.getvalue(),capture_output=True,env=env,check=True,text=False)
    summary=json.loads(result.stdout)
    assert summary['credentialsCopied'] is False and summary['nativeSignInRequired'] is True
    assert existing.read_text()=='user-owned'
    assert (destination/'.config/spotify-player/app.toml').is_file()
    assert not (destination/'.cache/spotify-player/device_token.json').exists()


def test_receiver_rejects_auth_archive_before_installing_any_files(tmp_path):
    archive=io.BytesIO()
    with tarfile.open(fileobj=archive,mode='w:gz') as tar:
        for name,value in (('.claude/settings.json',b'{}'),('.claude/.credentials.json',b'secret')):
            info=tarfile.TarInfo(name);info.size=len(value);tar.addfile(info,io.BytesIO(value))
    destination=tmp_path/'destination';env=dict(os.environ,HOME=str(destination))
    result=subprocess.run([sys.executable,'-c',apps.receiver_code()],input=archive.getvalue(),capture_output=True,env=env)
    assert result.returncode!=0
    assert not (destination/'.claude/settings.json').exists()