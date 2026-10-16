#!/usr/bin/env python3
"""Live listening-room acceptance. Changes music UI; never edits the library.

Clicks a blank room margin, then sends one paired Escape through a short-lived virtual keyboard (no input grab).
Use only while a brief music-overlay test is welcome.
"""
import argparse
import json
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--live', action='store_true')
    args = parser.parse_args()
    if not args.live:
        parser.error('--live is required for visible UI and Escape input')
    from evdev import UInput, ecodes as e

    def call(target, *args):
        return subprocess.check_output(['qs', 'ipc', '--any-display', '-c', 'sensei', 'call', target, *args], text=True).strip()

    def state(target='spotify'):
        return json.loads(call(target, 'state'))

    def wait(predicate, target='spotify'):
        for _ in range(100):
            value = state(target)
            if predicate(value):
                return value
            time.sleep(.15)
        raise RuntimeError('Music UI acceptance timed out')

    cursor=json.loads(subprocess.check_output(["hyprctl","-i","0","cursorpos","-j"],text=True))
    saved = state()
    preferences=state("music-fullscreen")
    try:
        call('music-fullscreen','mode','normal')
        call('music-fullscreen','backdrop','false')
        call('spotify', 'page', '2')
        wait(lambda s: not s['loading'] and s['playlists'] > 0)
        before = state()
        call('spotify', 'fullscreen')
        room = wait(lambda s: s['visible'] and s['rows'] > 0, 'music-fullscreen')
        assert room['width'] >= 1000 and room['height'] >= 650, room
        if room.get('duration'):
            assert abs(room['seek'] - room['position']/room['duration']) < .01, room
        call('music-fullscreen', 'collection', '1')
        wait(lambda s: s['collection'] == 1 and s['rows'] > 0, 'music-fullscreen')
        # OnDemand surfaces need a real inside click before receiving keys.
        # IPC may open on a monitor different from the cursor's monitor.
        monitors=json.loads(subprocess.check_output(['hyprctl','-i','0','monitors','-j'],text=True))
        monitor=next(m for m in monitors if m['name']==room['output'])
        x,y=monitor['x']+12,monitor['y']+90
        subprocess.run(['hyprctl','-i','0','dispatch',f'hl.dsp.cursor.move({{x={x},y={y}}})'],check=True,stdout=subprocess.DEVNULL)
        with UInput({e.EV_KEY:[e.BTN_LEFT]},name='Den music blank-margin focus') as pointer:
            time.sleep(.2)
            pointer.write(e.EV_KEY,e.BTN_LEFT,1);pointer.syn()
            try:time.sleep(.04)
            finally:pointer.write(e.EV_KEY,e.BTN_LEFT,0);pointer.syn()
            time.sleep(.2)
        # No media action, text input, modifier or device grab.
        with UInput({e.EV_KEY: [e.KEY_ESC]}, name='Den paired Escape acceptance') as device:
            time.sleep(.2)
            try:
                device.write(e.EV_KEY, e.KEY_ESC, 1)
                device.syn()
                time.sleep(.04)
            finally:
                device.write(e.EV_KEY, e.KEY_ESC, 0)
                device.syn()
            time.sleep(.2)
        wait(lambda s: not s['visible'], 'music-fullscreen')
        restored = state()
        assert restored['page'] == before['page'] and restored['contextId'] == before['contextId']
        print(json.dumps({'fullscreen': True, 'queue': True, 'playlists': True, 'seekFraction': True, 'realEscapeRestoresContext': True, 'output': room['output']}))
    finally:
        call('spotify', 'closeFullscreen')
        call('spotify', 'page', str(saved['page']))
        call('music-fullscreen','mode','focus' if preferences.get('zen') else 'normal')
        call('music-fullscreen','backdrop','true' if preferences.get('backdrop') else 'false')
        subprocess.run(['hyprctl','-i','0','dispatch',f'hl.dsp.cursor.move({{x={cursor["x"]},y={cursor["y"]}}})'],check=False,stdout=subprocess.DEVNULL)


if __name__ == '__main__':
    main()
