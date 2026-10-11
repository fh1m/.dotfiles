"""Regression coverage for native playback and private desktop adapters."""
import importlib.machinery
import importlib.util
import json
import os
import socket
import subprocess
import tempfile
import threading
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]

def load(name):
    loader = importlib.machinery.SourceFileLoader(name.replace('-', '_'), str(ROOT/'home/.local/bin'/name))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module

class Adapters(unittest.TestCase):
    def test_account_cache_is_private_and_atomic(self):
        m = load('sensei-code')
        with tempfile.TemporaryDirectory() as directory, patch.object(m, 'CACHE', Path(directory)/'cache'):
            path = m.CACHE/'user-overview.json'
            m.save(path, {'repositories': []})
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(m.CACHE.stat().st_mode & 0o777, 0o700)
            self.assertFalse(list(m.CACHE.glob('*.tmp-*')))

    def test_cached_overview_does_not_require_network(self):
        m = load('sensei-code')
        with tempfile.TemporaryDirectory() as directory, patch.object(m, 'CACHE', Path(directory)), patch.object(m.subprocess, 'check_output', return_value='fh1m\n'), patch.object(m, 'gh') as network, patch.object(m, 'emit') as output:
            m.save(m.CACHE/'fh1m-overview.json', {'fetchedAt':m.time.time(), 'login':'fh1m'})
            m.code()
            network.assert_not_called()
            self.assertEqual(output.call_args.args[0]['login'], 'fh1m')

    def test_invalid_repository_never_reaches_gh(self):
        m = load('sensei-code')
        with patch.object(m, 'gh') as network:
            with self.assertRaises(ValueError): m.details('owner/repo;$(command)')
            network.assert_not_called()

    def test_account_states_do_not_confuse_free_or_network_with_expiry(self):
        m = load('sensei-code')
        account = {'type':'chatgpt','planType':'plus'}
        self.assertEqual(m.account_state({'account':account})['kind'], 'active')
        self.assertEqual(m.account_state({'account':account,'rateLimits':{'primary':{'usedPercent':100}}})['kind'], 'exhausted')
        self.assertEqual(m.account_state({'account':dict(account,planType='free')})['kind'], 'free')
        self.assertEqual(m.account_state({'account':account,'error':'offline'})['kind'], 'unavailable')
        self.assertEqual(m.account_state({})['kind'], 'signin')

    def test_opencode_aggregates_exclude_transcripts(self):
        m = load('sensei-code')
        result = subprocess.CompletedProcess([],0,'│Sessions            4 │\n│Total Cost          $1.20 │\nprivate transcript\n')
        with patch.object(m.shutil,'which',return_value='/usr/bin/opencode'), patch.object(m,'run_owned',return_value=result), patch.object(m,'emit') as output:
            m.opencode_snapshot()
            self.assertEqual(output.call_args.args[0]['stats'], {'Sessions':'4','Total Cost':'$1.20'})
            self.assertNotIn('transcript',json.dumps(output.call_args.args[0]))

    def test_autotabs_excludes_nonordinary_windows(self):
        m = load('sensei-tabs')
        base = {'workspace':{'id':3}, 'mapped':True, 'class':'Alacritty'}
        self.assertTrue(m.eligible(base, 3))
        for change in ({'floating':True}, {'fullscreen':1}, {'pinned':True}, {'mapped':False}, {'workspace':{'id':-1}}):
            self.assertFalse(m.eligible(dict(base, **change), 3))
        self.assertFalse(m.eligible(base, 4))

class NativeTransport(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.binary = Path(cls.temp.name)/'transport'
        flags = subprocess.check_output(['pkg-config','--cflags','--libs','json-c','openssl'], text=True).split()
        subprocess.run(['cc','-O2','-Wall',str(ROOT/'src/spotify/transport.c'),'-o',str(cls.binary),*flags], check=True)

    @classmethod
    def tearDownClass(cls): cls.temp.cleanup()

    def request(self, action, fail_closed=False):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            cfg = home/'.config/spotify-player'; cfg.mkdir(parents=True)
            cache = home/'.cache/sensei-spotify'; cache.mkdir(parents=True)
            server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            server.bind(('127.0.0.1',0)); server.settimeout(.8)
            (cfg/'app.toml').write_text('client_port = '+str(server.getsockname()[1])+'\n')
            bindir = home/'bin'; bindir.mkdir()
            restart = bindir/'systemctl'; restart.write_text('#!/bin/sh\nexit 0\n'); restart.chmod(0o755)
            calls = []
            def serve():
                try:
                    while True:
                        raw, addr = server.recvfrom(65536)
                        calls.append(json.loads(raw))
                        response = {'Err':list(b'channel closed')} if fail_closed else {'Ok':[]}
                        server.sendto(json.dumps(response).encode(),addr); server.sendto(b'',addr)
                except socket.timeout: pass
            thread = threading.Thread(target=serve); thread.start()
            env = dict(os.environ, SENSEI_SPOTIFY_HOME=str(home), PATH=str(bindir)+':'+os.environ['PATH'])
            result = subprocess.run([str(self.binary),action], env=env, capture_output=True, text=True, timeout=4)
            thread.join(); server.close()
            return result, calls

    def test_skip_sends_exactly_one_control_without_snapshot(self):
        for action, native in [('next','Next'),('previous','Previous')]:
            result, calls = self.request(action)
            self.assertEqual(result.returncode,0,result.stdout)
            self.assertEqual(calls,[{'Playback':native}])

    def test_restart_never_replays_mutation(self):
        result, calls = self.request('next', fail_closed=True)
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(calls,[{'Playback':'Next'}])
        self.assertIn('restarted',json.loads(result.stdout)['error'])

if __name__ == '__main__': unittest.main()
