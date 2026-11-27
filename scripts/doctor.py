#!/usr/bin/env python3
"""Read-only prerequisite and session checks; never print account data."""
import argparse,json,shutil,subprocess
from pathlib import Path

COMMANDS=['qs','hyprctl','alacritty','chafa','wl-copy','grim','slurp','wf-recorder','wpctl','pactl','playerctl','bluetoothctl','nmcli','docker','tmux','kdeconnect-cli','tailscale','syncthing','sshfs','rsync']
def output(args):
    try:
        r=subprocess.run(args,capture_output=True,text=True,timeout=8)
        return r.stdout.strip() if r.returncode==0 else 'unavailable'
    except (OSError,subprocess.TimeoutExpired):return 'unavailable'

def report():
    result={'commands':{c:bool(shutil.which(c)) for c in COMMANDS}}
    result['hyprlandErrors']=output(['hyprctl','configerrors'])
    try:result['monitors']=[{k:m[k] for k in ('name','width','height','scale','x','y')} for m in json.loads(output(['hyprctl','monitors','-j']))]
    except (ValueError,TypeError,KeyError):result['monitors']='unavailable'
    result['dockerServer']=output(['docker','version','--format','{{.Server.Version}}'])
    result['nvidia']=output(['nvidia-smi','--query-gpu=name,driver_version','--format=csv,noheader'])
    result['arm64Binfmt']=Path('/proc/sys/fs/binfmt_misc/qemu-aarch64').exists()
    result['fonts']={n:output(['fc-match','-f','%{family}',n]) for n in ['ZedMono Nerd Font','Iosevka Nerd Font Mono']}
    result['spotifyBinary']=(Path.home()/'.local/opt/go-librespot/go-librespot').is_file()
    return result

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--json',action='store_true',help='Emit JSON (also the default)')
    p.add_argument('--strict',action='store_true',help='Exit 1 when a prerequisite or session is unavailable')
    args=p.parse_args();result=report();print(json.dumps(result,indent=2))
    return int(args.strict and (not all(result['commands'].values()) or result['hyprlandErrors'] not in ('','unavailable') or result['monitors']=='unavailable'))
if __name__=='__main__':raise SystemExit(main())
