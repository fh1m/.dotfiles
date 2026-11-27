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


def test_payload_contains_only_allowlisted_preferences(tmp_path):
    source=tmp_path/'.config/spotify-player/app.toml';source.parent.mkdir(parents=True)
    source.write_text('theme = "dracula"\nclient_id = "private-client"\nplayer_event_hook_command = { command = "private-command" }\n')
    payload=apps.config_payload(tmp_path)
    assert list(payload)==['.config/spotify-player/app.toml']
    text=payload['.config/spotify-player/app.toml'].decode()
    assert 'theme = "dracula"' in text
    assert 'client_id' not in text and 'private-client' not in text and 'player_event_hook_command' not in text


def test_receiver_preserves_existing_preferences_and_rejects_unlisted_members(tmp_path):
    data=b'theme = "dracula"\n'
    archive=io.BytesIO()
    with tarfile.open(fileobj=archive,mode='w:gz') as tar:
        info=tarfile.TarInfo('.config/spotify-player/app.toml');info.size=len(data);tar.addfile(info,io.BytesIO(data))
    destination=tmp_path/'destination';existing=destination/'.config/spotify-player/app.toml';existing.parent.mkdir(parents=True);existing.write_text('user-owned')
    env=dict(os.environ,HOME=str(destination))
    result=subprocess.run([sys.executable,'-c',apps.receiver_code()],input=archive.getvalue(),capture_output=True,env=env,check=True,text=False)
    summary=json.loads(result.stdout)
    assert summary['credentialsCopied'] is False and summary['nativeSignInRequired'] is True
    assert existing.read_text()=='user-owned'
    bad=io.BytesIO()
    with tarfile.open(fileobj=bad,mode='w:gz') as tar:
        for name in ('.config/spotify-player/app.toml','.ssh/authorized_keys'):
            info=tarfile.TarInfo(name);info.size=len(data);tar.addfile(info,io.BytesIO(data))
    result=subprocess.run([sys.executable,'-c',apps.receiver_code()],input=bad.getvalue(),capture_output=True,env=dict(os.environ,HOME=str(tmp_path/'bad-home')))
    assert result.returncode!=0
    assert not (tmp_path/'bad-home/.config/spotify-player/app.toml').exists()
