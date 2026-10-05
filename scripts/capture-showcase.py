#!/usr/bin/env python3
"""Capture real, temporarily staged workspace windows; restore the original focus."""
import json
import signal
import subprocess
import time
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/assets'
OUT.mkdir(exist_ok=True)
QS = Path.home() / '.local/opt/sensei-quickshell/bin/qs'
QS = str(QS if QS.exists() else 'qs')
PUBLIC_ROS = Path.home() / 'tmp/mongla_ws/tools/flow_derot_calibrate.py'
ROS_SOURCE = PUBLIC_ROS if PUBLIC_ROS.exists() else ROOT / 'examples/robotics-bringup.py'
ROS_RANGE = ['--line-range=84:113'] if ROS_SOURCE == PUBLIC_ROS else []


def run(*argv, timeout=15):
    return subprocess.run(argv, check=True, capture_output=True, text=True, timeout=timeout).stdout.strip()


def ipc(*args):
    return run(QS, '-c', 'wrayth', 'ipc', 'call', *args)


def dispatch(body):
    return run('hyprctl', '-i', '0', 'dispatch', body)


def clients():
    return json.loads(run('hyprctl', '-i', '0', 'clients', '-j'))


def capture(name, output='eDP-1'):
    ipc('demo', 'ping')
    run('grim', '-s', '1', '-l', '1', '-o', output, str(OUT / (name + '.png')), timeout=12)
    print('Screenshot:', name, flush=True)


def window_for(cls):
    for _ in range(70):
        match = next((c for c in clients() if c.get('class') == cls), None)
        if match:
            return match
        time.sleep(.1)
    raise RuntimeError('Showcase window did not appear: ' + cls)


def terminal(cls, title, args, x, y, width, height):
    subprocess.Popen(['kitty', '-o', 'font_size=10.4', '--class', cls, '--title', title, '--hold', *args],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    c = window_for(cls)
    target = 'address:' + c['address']
    for body in (
        f'hl.dsp.window.float({{action="set",window="{target}"}})',
        f'hl.dsp.window.resize({{x={width},y={height},relative=false,window="{target}"}})',
        f'hl.dsp.window.move({{x={x},y={y},relative=false,window="{target}"}})',
    ):
        dispatch(body)
    time.sleep(.3)


def recorder(name, output):
    return subprocess.Popen(['wf-recorder', '--no-dmabuf', '-r', '15', '-c', 'libx264',
                             '-p', 'preset=ultrafast', '-p', 'crf=27', '-o', output,
                             '-f', str(OUT / (name + '.mp4'))],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def stop_recording(proc):
    if not proc:
        return
    if proc.poll() is None:
        proc.send_signal(signal.SIGINT)
    proc.wait(timeout=15)


def make_gif(name):
    source = OUT / (name + '.mp4')
    if not source.exists() or source.stat().st_size < 10000:
        print('No usable recording for', name, flush=True)
        return
    gif = OUT / (name + '.gif')
    filt = ('fps=9,scale=1120:-1:flags=lanczos,split[a][b];'
            '[a]palettegen=max_colors=112:stats_mode=diff[p];'
            '[b][p]paletteuse=dither=bayer:bayer_scale=3')
    run('ffmpeg', '-v', 'error', '-y', '-i', str(source), '-filter_complex', filt,
        '-loop', '0', str(gif), timeout=180)
    print('Motion:', gif.name, gif.stat().st_size, 'bytes', flush=True)


original = json.loads(run('hyprctl', '-i', '0', 'activewindow', '-j')).get('address')
preexisting = {c['address'] for c in clients()}
if any(c.get('workspace', {}).get('id') == 4 for c in clients()):
    raise SystemExit('Workspace 4 is occupied; choose a free stage before capturing.')
recording = None
try:
    ipc('demo', 'on', '120')
    dispatch('hl.dsp.focus({workspace="4"})')
    recording = recorder('flight-deck', 'eDP-1')
    time.sleep(.7)
    terminal('sensei-showcase-ros', 'Mongla // held-out flow fit',
             ['bat', '--paging=never', '--style=numbers,header', '--color=always',
              *ROS_RANGE, str(ROS_SOURCE)], 66, 142, 940, 860)
    terminal('sensei-showcase-compose', 'ARM + CUDA // compose',
             ['bat', '--paging=never', '--style=numbers,header', '--color=always',
              str(ROOT / 'examples/compose.robotics.yaml')], 1160, 142, 680, 480)
    terminal('sensei-showcase-system', 'SYSTEM // field notes',
             ['fastfetch', '--logo', 'none', '--structure',
              'OS:Kernel:WM:Terminal:CPU:GPU:Memory:Uptime:Battery'], 1135, 654, 700, 320)
    time.sleep(.9)
    capture('floating-workstation')
    Image.open(OUT / 'floating-workstation.png').crop((66, 140, 1008, 1013)).save(OUT / 'mongla-code.png')
    ipc('dropdown', 'open', 'system')
    time.sleep(1.1)
    capture('floating-system')
    ipc('dropdown', 'close')
    time.sleep(.5)
    ipc('dropdown', 'open', 'spotify')
    time.sleep(1.1)
    capture('floating-music')
    ipc('dropdown', 'close')
    time.sleep(.8)
    stop_recording(recording)
    recording = None
    make_gif('flight-deck')
    recording = recorder('screenpad-tools', 'DP-2')
    time.sleep(.4)
    for name, target, page in [('monitor', 'monitor', '0'),
                               ('usb', 'usb', None)]:
        if page is not None:
            ipc(target, 'page', page)
        else:
            ipc('dropdown', 'open', target)
        time.sleep(1.5)
        ipc('dropdown', 'close')
        time.sleep(.45)
    stop_recording(recording)
    recording = None
    make_gif('screenpad-tools')
finally:
    try:
        stop_recording(recording)
    except Exception:
        pass
    for call in [('dropdown', 'close'), ('demo', 'off')]:
        try:
            ipc(*call)
        except Exception:
            pass
    for c in clients():
        if c['address'] not in preexisting and c.get('class', '').startswith('sensei-showcase-'):
            try:
                dispatch('hl.dsp.window.close({window="address:' + c['address'] + '"})')
            except Exception:
                pass
    if original:
        dispatch('hl.dsp.focus({window="address:' + original + '"})')
