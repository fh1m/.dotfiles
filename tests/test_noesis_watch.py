"""Exercise a real disposable inotify queue overflow, not a mocked event string."""
import json
import os
from pathlib import Path
import select
import signal
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(sys.platform.startswith('linux'), 'Linux inotify required')
class Watch(unittest.TestCase):
    def test_overflow_requests_full_reconciliation(self):
        queue_limit = int(Path('/proc/sys/fs/inotify/max_queued_events').read_text())
        if queue_limit > 65536:self.skipTest('Kernel queue unusually large for a disposable test')
        with tempfile.TemporaryDirectory(prefix='noesis-watch-') as temporary:
            root = Path(temporary)
            watcher = subprocess.Popen([sys.executable, str(ROOT / 'home/.local/bin/sensei-learning-watch'), str(root)],
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            try:
                deadline = time.monotonic() + 3
                while time.monotonic() < deadline:
                    info = list(Path(f'/proc/{watcher.pid}/fdinfo').glob('*'))
                    established = False
                    for path in info:
                        try:established = established or 'inotify wd:' in path.read_text()
                        except FileNotFoundError:pass
                    if established:break
                    time.sleep(.02)
                else:self.fail('Watcher did not establish its root watch')
                watcher.send_signal(signal.SIGSTOP)
                for i in range(queue_limit // 2 + 256):
                    (root / (str(i) + '.md')).write_text('Synthetic overflow record')
                watcher.send_signal(signal.SIGCONT)
                overflow = False
                pending = b''
                deadline = time.monotonic() + 10
                while time.monotonic() < deadline:
                    if not select.select([watcher.stdout], [], [], .2)[0]:continue
                    data = os.read(watcher.stdout.fileno(), 65536)
                    if not data:break
                    pending += data
                    while b'\n' in pending:
                        line, pending = pending.split(b'\n', 1)
                        event = json.loads(line)
                        if event.get('reason') == 'overflow':
                            self.assertTrue(event['reconcile']);overflow = True;break
                    if overflow:break
                self.assertTrue(overflow, 'Queue overflow was not visibly reconciled')
            finally:
                watcher.send_signal(signal.SIGCONT)
                watcher.terminate();watcher.communicate(timeout=5)


if __name__ == '__main__':unittest.main()
