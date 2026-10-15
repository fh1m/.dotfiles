"""Exercise the real C transport against an owned loopback UDP fixture."""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import threading
import unittest

ROOT=Path(__file__).resolve().parents[1]
class Transport(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not shutil.which('cc') or not shutil.which('pkg-config'):raise unittest.SkipTest('C tools unavailable')
        cls.build=tempfile.TemporaryDirectory();cls.binary=Path(cls.build.name)/'transport'
        flags=subprocess.check_output(['pkg-config','--cflags','--libs','json-c','openssl'],text=True).split()
        subprocess.run(['cc','-O1',str(ROOT/'src/spotify/transport.c'),'-o',str(cls.binary),*flags],check=True)
    @classmethod
    def tearDownClass(cls):cls.build.cleanup()
    def test_skip_is_exactly_one_playback_command(self):
        for action,expected in [('next','Next'),('previous','Previous')]:
            with self.subTest(action=action), tempfile.TemporaryDirectory() as d, socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as server:
                server.bind(('127.0.0.1',0));server.settimeout(.5);seen=[]
                p=Path(d)/'.config/spotify-player';p.mkdir(parents=True)
                (p/'app.toml').write_text('client_port = '+str(server.getsockname()[1])+'\n')
                def serve():
                    while True:
                        try:raw,peer=server.recvfrom(65535)
                        except socket.timeout:return
                        seen.append(json.loads(raw));server.sendto(b'{"Ok":[]}',peer);server.sendto(b'',peer)
                t=threading.Thread(target=serve);t.start()
                result=subprocess.run([str(self.binary),action,'playing'],env=dict(os.environ,HOME=d),capture_output=True,text=True,timeout=3)
                t.join();self.assertEqual(result.returncode,0,result.stdout+result.stderr)
                self.assertEqual(seen,[{'Playback':expected}])
if __name__=='__main__':unittest.main()
