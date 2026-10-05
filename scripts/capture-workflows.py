#!/usr/bin/env python3
"""Record read-only lab and tmux tours on an otherwise empty workspace.

Only showcase windows and the isolated tmux socket are closed on exit.
"""
import json
import signal
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/assets'
QS = Path.home() / '.local/opt/sensei-quickshell/bin/qs'
QS = str(QS if QS.exists() else 'qs')
SOCKET = 'sensei-gallery'


def run(*args, timeout=20):
    return subprocess.run(args, check=True, capture_output=True, text=True,
                          timeout=timeout).stdout.strip()


def ipc(*args):
    return run(QS, '-c', 'wrayth', 'ipc', 'call', *args)


def dispatch(command):
    return run('hyprctl', '-i', '0', 'dispatch', command)


def clients():
    return json.loads(run('hyprctl', '-i', '0', 'clients', '-j'))


def showcase_window(cls, command, x, y, width, height):
    subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(80):
        found = next((c for c in clients() if c.get('class') == cls), None)
        if found:
            break
        time.sleep(.1)
    else:
        raise RuntimeError(f'Window did not appear: {cls}')
    target = 'address:' + found['address']
    for action in (
        f'hl.dsp.window.float({{action="set",window="{target}"}})',
        f'hl.dsp.window.resize({{x={width},y={height},relative=false,window="{target}"}})',
        f'hl.dsp.window.move({{x={x},y={y},relative=false,window="{target}"}})',
    ):
        dispatch(action)
    time.sleep(.5)
    return found['address']


def record(name):
    return subprocess.Popen(['wf-recorder', '--no-dmabuf', '-r', '15', '-c', 'libx264',
                             '-p', 'preset=ultrafast', '-p', 'crf=25', '-o', 'eDP-1',
                             '-f', str(OUT / f'{name}.mp4')],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def stop(proc):
    if proc and proc.poll() is None:
        proc.send_signal(signal.SIGINT)
        proc.wait(timeout=20)


def gif(name, crop=None):
    source = OUT / f'{name}.mp4'
    if source.stat().st_size < 10000:
        raise RuntimeError(f'Empty recording: {source}')
    pre = f'crop={crop},' if crop else ''
    filt = (f'{pre}fps=10,scale=1360:-1:flags=lanczos,split[a][b];'
            '[a]palettegen=max_colors=96:stats_mode=diff[p];'
            '[b][p]paletteuse=dither=bayer:bayer_scale=3')
    run('ffmpeg', '-v', 'error', '-y', '-i', str(source), '-filter_complex', filt,
        '-loop', '0', str(OUT / f'{name}.gif'), timeout=240)
    print(name, (OUT / f'{name}.gif').stat().st_size, 'bytes', flush=True)


def tmux(*args):
    return run('tmux', '-L', SOCKET, *args)


original = json.loads(run('hyprctl', '-i', '0', 'activewindow', '-j')).get('address')
existing = {c['address'] for c in clients()}
if any(c.get('workspace', {}).get('id') == 4 for c in clients()):
    raise SystemExit('Workspace 4 is occupied; no capture started.')
rec = None
try:
    ipc('demo', 'on', '120')
    dispatch('hl.dsp.focus({workspace="4"})')
    code = Path.home() / 'tmp/mongla_ws/tools/flow_derot_calibrate.py'
    if not code.exists():
        code = ROOT / 'examples/robotics-bringup.py'
    showcase_window('sensei-showcase-lab',
                    ['kitty', '-o', 'font_size=10.4', '--class', 'sensei-showcase-lab',
                     '--title', 'Mongla // optical flow', '--hold', 'bat',
                     '--paging=never', '--style=numbers,header', '--color=always',
                     '--line-range=84:113', str(code)],
                    70, 145, 950, 835)
    ipc('dockerlab', 'open')
    ipc('dockerlab', 'page', '0')
    time.sleep(1)
    rec = record('robotics-lab')
    for page in (2, 5, 6, 7, 0):
        ipc('dockerlab', 'page', str(page))
        time.sleep(1.25)
    stop(rec)
    rec = None
    ipc('dropdown', 'close')
    gif('robotics-lab', '2200:1700:0:100')

    # An isolated socket keeps the user's actual daily_dev tmux sessions intact.
    tmux('-f', str(Path.home() / '.tmux.conf'), 'new-session', '-d',
         '-s', 'field_lab', '-n', 'Calibration')
    tmux('new-window', '-t', 'field_lab:', '-n', 'Containers')
    tmux('send-keys', '-t', 'field_lab:2',
         'nvidia-smi --query-gpu=name,temperature.gpu,memory.used,memory.total,utilization.gpu --format=csv,noheader',
         'Enter')
    tmux('split-window', '-h', '-t', 'field_lab:2')
    tmux('send-keys', '-t', 'field_lab:2.2',
         'docker info --format "Containers: {{.Containers}}  Images: {{.Images}}  Driver: {{.Driver}}"',
         'Enter')
    tmux('select-window', '-t', 'field_lab:1')
    showcase_window('sensei-showcase-tmux',
                    ['alacritty', '--class', 'sensei-showcase-tmux', '--title',
                     'Sensei · field lab', '-e', 'tmux', '-L', SOCKET,
                     'attach-session', '-t', 'field_lab'],
                    140, 135, 1640, 870)
    tmux('send-keys', '-t', 'field_lab:1',
         f'clear; bat --paging=never --style=numbers,header --color=always --line-range=63:82 {code}', 'Enter')
    tmux('split-window', '-h', '-t', 'field_lab:1')
    tmux('send-keys', '-t', 'field_lab:1.2',
         'bash ~/.dotfiles/scripts/gallery-field-report.sh',
         'Enter')
    time.sleep(.6)
    run('grim', '-s', '1', '-l', '1', '-o', 'eDP-1',
        str(OUT / 'tmux-field-lab.png'), timeout=15)
    rec = record('tmux-field-lab')
    time.sleep(.8)
    tmux('select-window', '-t', 'field_lab:2')
    time.sleep(1.6)
    tmux('select-window', '-t', 'field_lab:1')
    time.sleep(1.1)
    stop(rec)
    rec = None
    gif('tmux-field-lab', '3320:1800:260:240')
finally:
    stop(rec)
    try:
        ipc('dropdown', 'close')
        ipc('demo', 'off')
    except Exception:
        pass
    for c in clients():
        if (c['address'] not in existing and
                c.get('class', '').startswith('sensei-showcase-')):
            try:
                dispatch(f'hl.dsp.window.close({{window="address:{c["address"]}"}})')
            except Exception:
                pass
    try:
        tmux('kill-server')
    except Exception:
        pass
    if original:
        dispatch(f'hl.dsp.focus({{window="address:{original}"}})')
