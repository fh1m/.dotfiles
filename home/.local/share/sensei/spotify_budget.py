#!/usr/bin/env python3
"""Private cross-process Spotify request gate. Never stores URLs or credentials."""
import argparse
import fcntl
import json
import math
import os
from pathlib import Path
import tempfile
import time


class Budget:
    def __init__(self, root=None, clock=time.time):
        self.root = Path(root or os.environ.get('SENSEI_SPOTIFY_BUDGET_ROOT',
                         str(Path.home()/'.cache/sensei-spotify')))
        self.clock = clock

    def transact(self, action, category='other', seconds=0, reason='rate'):
        self.root.mkdir(parents=True, exist_ok=True, mode=0o700)
        with (self.root/'web-api.lock').open('a') as lock:
            os.chmod(lock.name, 0o600)
            fcntl.flock(lock, fcntl.LOCK_EX)
            path = self.root/'web-api-budget.json'
            try:
                state = json.loads(path.read_text())
                finite=lambda x:isinstance(x,(int,float)) and not isinstance(x,bool) and math.isfinite(x) and x>=0
                if (not isinstance(state,dict) or state.get('schema')!=1
                    or not finite(state.get('until')) or not isinstance(state.get('quota'),bool)
                    or not isinstance(state.get('stamps'),list) or not all(finite(x) for x in state['stamps'])
                    or not isinstance(state.get('counts'),dict)
                    or not all(isinstance(v,int) and not isinstance(v,bool) and v>=0 for v in state['counts'].values())):
                    raise ValueError('Invalid budget')
            except FileNotFoundError:
                state = {'schema': 1, 'until': 0, 'quota': False, 'stamps': [], 'counts': {}}
            except (ValueError, TypeError, OverflowError):
                # Corruption is not a reason to flood the API.
                return {'allowed': False, 'reason': 'state_invalid', 'retryAt': None}
            now = self.clock()
            state['stamps'] = [x for x in state.get('stamps', []) if 0 <= now-x < 30]
            if action == 'reset':
                state.update(until=0, quota=False, stamps=[])
            elif action == 'penalise':
                wait = max(5, float(seconds)) + 1
                state['until'] = max(state.get('until', 0), now+wait)
                state['quota'] = state.get('quota', False) or reason == 'QUOTA_EXCEEDED'
                state['observedAt'] = now
            why = 'quota' if state.get('quota') else 'rate' if state.get('until', 0) > now else 'budget' if len(state['stamps']) >= 10 else ''
            if action == 'acquire' and not why:
                state['stamps'].append(now)
                # Only fixed endpoint categories, never user-provided paths/searches.
                category = category if category in {'player', 'library', 'search', 'catalogue'} else 'other'
                day = time.strftime('%Y-%m-%d', time.gmtime(now))
                if state.get('day') != day: state.update(day=day, counts={})
                state['counts'][category] = state['counts'].get(category, 0)+1
            retry = state.get('until', 0) if why == 'rate' else (state['stamps'][0]+30 if why == 'budget' else None)
            fd, temp = tempfile.mkstemp(prefix='.web-api-', dir=self.root)
            try:
                with os.fdopen(fd, 'w') as out:
                    json.dump(state, out); out.flush(); os.fsync(out.fileno())
                os.replace(temp, path)
            finally:
                if os.path.exists(temp): os.unlink(temp)
            return {'allowed': not bool(why), 'reason': why, 'retryAt': retry,
                    'counts': state.get('counts', {}), 'observedAt': state.get('observedAt'),
                    'remainingLocalBudget': max(0, 10-len(state['stamps']))}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('action', choices=['status', 'acquire', 'penalise', 'reset'])
    p.add_argument('category', nargs='?', default='other')
    p.add_argument('--seconds', type=float, default=0)
    p.add_argument('--reason', default='rate')
    a = p.parse_args()
    if a.seconds < 0 or not __import__('math').isfinite(a.seconds): p.error('Invalid wait')
    print(json.dumps(Budget().transact(a.action, a.category, a.seconds, a.reason)))


if __name__ == '__main__': main()
