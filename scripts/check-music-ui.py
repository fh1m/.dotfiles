#!/usr/bin/env python3
"""Live listening-room acceptance. Changes music UI; never edits the library.

Sends one paired Escape through a short-lived virtual keyboard (no input grab).
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
        # Exclusive music surface owns this bounded, modifier-free key.
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


if __name__ == '__main__':
    main()
