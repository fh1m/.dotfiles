#!/usr/bin/env python3
"""Read-only prerequisite and session checks; never print account data."""
import json, shutil, subprocess
from pathlib import Path

commands = ['qs', 'hyprctl', 'kitty', 'wl-copy', 'grim', 'slurp', 'wf-recorder',
            'wpctl', 'pactl', 'playerctl', 'bluetoothctl', 'nmcli', 'docker',
            'tmux', 'kdeconnect-cli', 'tailscale', 'syncthing', 'sshfs', 'rsync']
result = {'commands': {c: bool(shutil.which(c)) for c in commands}}
def output(args):
    try:
        r = subprocess.run(args, capture_output=True, text=True, timeout=8)
        return r.stdout.strip() if r.returncode == 0 else 'unavailable'
    except (OSError, subprocess.TimeoutExpired): return 'unavailable'
result['hyprlandErrors'] = output(['hyprctl', '-i', '0', 'configerrors'])
monitor_json = output(['hyprctl', '-i', '0', 'monitors', '-j'])
try:
    result['monitors'] = [{k: m[k] for k in ('name', 'width', 'height', 'scale', 'x', 'y')} for m in json.loads(monitor_json)]
except (ValueError, TypeError, KeyError): result['monitors'] = 'unavailable'
result['dockerServer'] = output(['docker', 'version', '--format', '{{.Server.Version}}'])
result['nvidia'] = output(['nvidia-smi', '--query-gpu=name,driver_version', '--format=csv,noheader'])
result['arm64Binfmt'] = Path('/proc/sys/fs/binfmt_misc/qemu-aarch64').exists()
result['fonts'] = {name: output(['fc-match', '-f', '%{family}', name]) for name in ['ZedMono Nerd Font', 'Iosevka Nerd Font Mono']}
result['spotifyBinary'] = (Path.home()/'.local/share/sensei-spotify-client/bin/spotify_player').is_file()
print(json.dumps(result, indent=2))
