"""Exercise the archive with a private HOME and a fake Wayland clipboard."""
import base64
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1]/'home/.local/bin/clipboard-vault'


class ClipboardRoundTrip(unittest.TestCase):
    def test_text_image_pause_and_sensitive_selection(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binary = root/'bin';binary.mkdir()
            stub = binary/'wl-copy'
            stub.write_text('#!/usr/bin/python3\nimport os,sys\nfrom pathlib import Path\nPath(os.environ["TEST_COPY"]).write_bytes(sys.stdin.buffer.read())\nPath(os.environ["TEST_COPY"]+".mime").write_text(sys.argv[2])\n')
            stub.chmod(0o755)
            env = dict(os.environ, HOME=directory, PATH=str(binary)+':'+os.environ['PATH'], TEST_COPY=str(root/'copied'))
            env.pop('CLIPBOARD_STATE', None)
            def run(*args, data=None, sensitive=False):
                return subprocess.check_output([str(SCRIPT), *args], input=data, env=dict(env, **({'CLIPBOARD_STATE':'sensitive'} if sensitive else {})))
            text = 'A < b; robotics ✓\n'.encode()
            image = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a2ioAAAAASUVORK5CYII=')
            run('store','text',data=text)
            run('store','image',data=image)
            run('store','text',data=b'private fixture',sensitive=True)
            run('pause');run('store','text',data=b'paused fixture')
            self.assertTrue(json.loads(run('list'))['paused'])
            run('pause')
            items = json.loads(run('list'))['items']
            self.assertEqual(len(items),2)
            for item in items:
                run('copy',str(item['id']))
                self.assertEqual((root/'copied').read_bytes(), image if item['kind']=='image' else text)
                self.assertEqual((root/'copied.mime').read_text(), item['mime'])


if __name__ == '__main__':unittest.main()
