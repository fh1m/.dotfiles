"""Regression coverage for native playback and private desktop adapters."""
import importlib.machinery
import importlib.util
import json
import os
import socket
import sys
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
        with patch.object(m.shutil,'which',return_value='/usr/bin/opencode'), patch.object(m,'run_owned',return_value=result), patch.object(m,'opencode_go_usage',return_value={}), patch.object(m,'opencode_local_usage',return_value=None), patch.object(m,'emit') as output:
            m.opencode_snapshot()
            self.assertEqual(output.call_args.args[0]['stats'], {'Sessions':'4','Total Cost':'$1.20'})
            self.assertNotIn('transcript',json.dumps(output.call_args.args[0]))

    def test_go_entitlement_failure_is_not_claimed_as_expiry(self):
        import urllib.request, urllib.error
        from unittest.mock import MagicMock
        m=load('sensei-code')
        with tempfile.TemporaryDirectory() as directory, patch.object(m,'HOME',Path(directory)), patch.object(m,'CACHE',Path(directory)/'cache'):
            auth=m.HOME/'.local/share/opencode/auth.json';auth.parent.mkdir(parents=True);auth.write_text(json.dumps({'opencode-go':{'type':'api','key':'fake-test-key'}}))
            opener=MagicMock();opener.open.side_effect=urllib.error.HTTPError('https://opencode.ai',403,'Forbidden',{},None)
            with patch.object(urllib.request,'build_opener',return_value=opener):
                result=m.opencode_go_usage()
                self.assertEqual(result['kind'],'verify')
                self.assertNotIn('fake-test-key',json.dumps(result))
                self.assertEqual(m.opencode_go_usage()['kind'],'verify')
                self.assertEqual(opener.open.call_count,1)

    def test_go_quota_validates_dates_and_preserves_window_identity(self):
        m=load('sensei-code')
        payload={'usage':{'rolling':{'percent':80,'resetsAt':'2026-10-12T10:00:00Z','status':'ok'},'weekly':{'percent':101,'resetsAt':'bad'}}}
        result=m.normalize_go_usage(payload)
        self.assertEqual(list(result),['rolling'])
        self.assertEqual(result['rolling']['percent'],80)

    def test_autotabs_excludes_nonordinary_windows(self):
        m = load('sensei-tabs')
        base = {'workspace':{'id':3}, 'mapped':True, 'class':'Alacritty'}
        self.assertTrue(m.eligible(base, 3))
        for change in ({'floating':True}, {'fullscreen':1}, {'pinned':True}, {'mapped':False}, {'workspace':{'id':-1}}):
            self.assertFalse(m.eligible(dict(base, **change), 3))
        self.assertFalse(m.eligible(base, 4))

class PackageJobs(unittest.TestCase):
    def test_interactive_transaction_preserves_id_and_output(self):
        m=load('sensei-package-job')
        with tempfile.TemporaryDirectory() as directory:
            m.STATE=Path(directory)/'state'
            script=str(ROOT/'home/.local/bin/sensei-package-job')
            fake="import sys; print('Proceed with installation? [Y/n]',flush=True); answer=input(); print('accepted='+answer,flush=True); sys.exit(0 if answer=='y' else 1)"
            wrapper="import importlib.machinery; m=importlib.machinery.SourceFileLoader('job',"+repr(script)+").load_module(); from pathlib import Path; m.STATE=Path("+repr(str(m.STATE))+"); m.command=lambda *_:"+repr([sys.executable,'-c',fake])+"; m.shutil.which=lambda _:None; m.run('repo','')"
            child=subprocess.Popen([sys.executable,'-c',wrapper],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
            try:
                import time
                deadline=time.monotonic()+4
                state={}
                while time.monotonic()<deadline:
                    state=m.read_state()
                    if 'Proceed' in state.get('log',''):break
                    time.sleep(.05)
                self.assertEqual(state['status'],'running')
                with self.assertRaises(ValueError):m.send('wrong-job','y')
                m.send(state['id'],'y')
                out,err=child.communicate(timeout=4)
                self.assertEqual(child.returncode,0,err)
                result=m.read_state()
                self.assertEqual(result['id'],state['id'])
                self.assertEqual(result['status'],'done')
                self.assertIn('accepted=y',result['log'])
                self.assertEqual((m.STATE/'job.json').stat().st_mode&0o777,0o600)
            finally:
                if child.poll() is None:child.terminate();child.wait(timeout=3)

    def test_split_question_default_and_provider_selection(self):
        import time
        m=load('sensei-package-job')
        with tempfile.TemporaryDirectory() as directory:
            m.STATE=Path(directory)/'state'
            fake="import sys,time; sys.stdout.write('Proceed'); sys.stdout.flush(); time.sleep(.1); print(' with installation? [Y/n]',flush=True); a=input(); print('default='+repr(a),flush=True); print('Enter a selection (default=1):',flush=True); b=input(); print('provider='+b,flush=True); sys.exit(0 if a=='' and b=='2' else 1)"
            wrapper="import importlib.machinery; m=importlib.machinery.SourceFileLoader('job',"+repr(str(ROOT/'home/.local/bin/sensei-package-job'))+").load_module(); from pathlib import Path; m.STATE=Path("+repr(str(m.STATE))+"); m.command=lambda *_:"+repr([sys.executable,'-c',fake])+"; m.shutil.which=lambda _:None; m.run('repo','')"
            child=subprocess.Popen([sys.executable,'-c',wrapper],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
            def wait_question(text):
                deadline=time.monotonic()+4
                while time.monotonic()<deadline:
                    state=m.read_state()
                    if text in state.get('prompt',''):return state
                    time.sleep(.05)
                self.fail('Question did not reach persisted widget state')
            try:
                first=wait_question('Proceed with');m.send(first['id'],'')
                second=wait_question('Enter a selection');self.assertEqual(first['id'],second['id']);m.send(second['id'],'2')
                out,err=child.communicate(timeout=4)
                self.assertEqual(child.returncode,0,err)
                state=m.read_state();self.assertEqual(state['status'],'done');self.assertEqual(state['prompt'],'')
                self.assertIn("default=''",state['log']);self.assertIn('provider=2',state['log'])
            finally:
                if child.poll() is None:child.terminate();child.wait(timeout=3)

    def test_rejects_package_shell_injection_and_detects_prompts(self):
        m=load('sensei-package-job')
        for name in ['../../tmp/file','bash; rm','$(command)']:
            with self.assertRaises(ValueError):m.command('install',name)
        self.assertEqual(m.phase('Proceed? [Y/n]','Starting'),'Your confirmation is needed')
        self.assertEqual(m.command('flatpak'),['flatpak','update'])

class OpenCodeDetails(unittest.TestCase):
    def test_free_activity_does_not_treat_zero_cost_go_as_free(self):
        import sqlite3,time
        m=load('sensei-code')
        with tempfile.TemporaryDirectory() as directory,patch.object(m,'HOME',Path(directory)):
            database=m.HOME/'.local/share/opencode/opencode.db';database.parent.mkdir(parents=True)
            with sqlite3.connect(database) as c:
                c.execute('create table message(session_id text,time_created integer,data text)')
                for provider,model in [('opencode','known-free'),('opencode-go','paid-model'),('opencode','unknown-zero')]:
                    record={'role':'assistant','providerID':provider,'modelID':model,'cost':0,'tokens':{'input':10,'output':5},'secret-text':'must not export'}
                    c.execute('insert into message values(?,?,?)',('session',int(time.time()*1000),json.dumps(record)))
            d=m.opencode_local_usage()
            self.assertEqual(d['freeResponses'],1)
            self.assertEqual(d['freeTokens'],15)
            self.assertEqual(d['goResponses'],1)
            self.assertNotIn('secret-text',json.dumps(d))
            self.assertNotIn('must not export',json.dumps(d))

    def test_device_authorization_keeps_tokens_private(self):
        m=load('sensei-opencode-connect')
        with tempfile.TemporaryDirectory() as directory,patch.object(m,'STATE',Path(directory)/'state'),patch.object(m,'TOKEN',Path(directory)/'state/token.json'),patch.object(m,'emit') as output,patch.object(m.time,'sleep'),patch.object(m.subprocess,'Popen') as browser:
            results=[{'verification_uri_complete':'https://opencode.ai/console/device?code=test','user_code':'test','device_code':'private-device','expires_in':60,'interval':2},
                     {'access_token':'private-access','refresh_token':'private-refresh','expires_in':300},[{'id':'org','name':'Personal'}]]
            with patch.object(m,'request',side_effect=results):m.connect()
            self.assertEqual(m.TOKEN.stat().st_mode&0o777,0o600)
            self.assertEqual(m.STATE.stat().st_mode&0o777,0o700)
            self.assertNotIn('private-access',str(output.call_args_list))
            self.assertNotIn('private-refresh',str(output.call_args_list))
            browser.assert_called_once()

    def test_authorization_rejects_foreign_browser_origin(self):
        m=load('sensei-opencode-connect')
        with patch.object(m,'request',return_value={'verification_uri_complete':'https://evil.test/'}),patch.object(m.subprocess,'Popen') as browser:
            with self.assertRaises(ValueError):m.connect()
            browser.assert_not_called()

class TerminalWorkflow(unittest.TestCase):
    def test_concurrent_launches_have_independent_windows_and_persistent_names(self):
        from concurrent.futures import ThreadPoolExecutor
        with tempfile.TemporaryDirectory() as directory:
            env=dict(os.environ,TMUX_TMPDIR=directory,XDG_STATE_HOME=directory+'/state')
            env.pop('TMUX',None)
            subprocess.run(['tmux','-f','/dev/null','new-session','-d','-s','fixture'],env=env,check=True)
            script=str(ROOT/'home/.local/bin/sensei-tmux')
            def create():return subprocess.check_output([sys.executable,script,'--create'],env=env,text=True).strip()
            try:
                with ThreadPoolExecutor(max_workers=3) as pool:names=list(pool.map(lambda _:create(),range(3)))
                self.assertEqual(set(names),{'dev_001','dev_002','dev_003'})
                windows=[subprocess.check_output(['tmux','list-windows','-t','='+name,'-F','#{window_id}'],env=env,text=True).strip() for name in names]
                self.assertEqual(len(set(windows)),3)
                for name in names:
                    group=subprocess.check_output(['tmux','display-message','-p','-t','='+name,'#{session_group}'],env=env,text=True).strip()
                    self.assertEqual(group,'')
                    subprocess.run(['tmux','kill-session','-t','='+name],env=env,check=True)
                self.assertEqual(create(),'dev_004')
            finally:subprocess.run(['tmux','kill-server'],env=env,capture_output=True)

    def test_password_dialog_returns_only_password_and_releases_focus(self):
        with tempfile.TemporaryDirectory() as directory:
            home=Path(directory);binary=home/'.local/opt/sensei-quickshell/bin/qs';binary.parent.mkdir(parents=True)
            binary.write_text('#!/bin/sh\necho "$@" >> "$HOME/bridge.log"\n');binary.chmod(0o755)
            zenity=home/'zenity';zenity.write_text('#!/bin/sh\nprintf fixture-password\n');zenity.chmod(0o755)
            result=subprocess.run([str(ROOT/'home/.local/bin/sensei-package-askpass')],env=dict(os.environ,HOME=directory,PATH=directory+':'+os.environ['PATH']),capture_output=True,text=True)
            self.assertEqual(result.returncode,0)
            self.assertEqual(result.stdout,'fixture-password')
            calls=(home/'bridge.log').read_text().splitlines()
            self.assertEqual(calls,['-c sensei ipc call system authentication on','-c sensei ipc call system authentication off'])

    def test_terminal_focus_never_launches_even_when_already_focused(self):
        m=load('sensei-app')
        window={'address':'0x123','class':'Alacritty','focusHistoryID':0,'workspace':{'id':1}}
        with tempfile.TemporaryDirectory() as directory,patch.dict(os.environ,{'XDG_RUNTIME_DIR':directory}),patch.object(sys,'argv',['sensei-app','terminal','focus-or-launch','--dry-run']),patch.object(m.subprocess,'check_output',return_value=json.dumps([window])),patch.object(m.subprocess,'Popen') as launch,patch('builtins.print') as output:
            m.main()
            self.assertEqual(json.loads(output.call_args.args[0])['action'],'focus')
            launch.assert_not_called()

    def test_battery_units_missing_fields_and_readonly_snapshot(self):
        m=load('sensei-battery')
        with tempfile.TemporaryDirectory() as directory,patch.object(m,'SUPPLIES',Path(directory)):
            battery=Path(directory)/'BAT0';battery.mkdir()
            values={'type':'Battery','energy_full':'30000000','energy_full_design':'60000000','energy_now':'15000000','power_now':'12000000','voltage_now':'16000000','capacity':'50','charge_control_end_threshold':'60'}
            for key,value in values.items():(battery/key).write_text(value)
            data=m.snapshot()['batteries'][0]
            self.assertEqual(data['health'],50)
            self.assertEqual(data['watts'],12)
            self.assertEqual(data['voltage'],16)
            self.assertEqual(data['energy'],15)
            self.assertIsNone(data['cycles'])
            self.assertEqual((battery/'charge_control_end_threshold').read_text(),'60')

    def test_package_question_forms_cover_selection_and_defaults(self):
        m=load('sensei-package-job')
        for question in ['Continue? [N/y]','Enter a selection (default=all):','Packages to exclude:','Which provider should be used?',':: Import PGP key? [Y/n]']:
            self.assertEqual(m.phase(question,'Starting'),'Your confirmation is needed')

class NativeTransport(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.binary = Path(cls.temp.name)/'transport'
        flags = subprocess.check_output(['pkg-config','--cflags','--libs','json-c','openssl'], text=True).split()
        subprocess.run(['cc','-O2','-Wall',str(ROOT/'src/spotify/transport.c'),'-o',str(cls.binary),*flags], check=True)

    @classmethod
    def tearDownClass(cls): cls.temp.cleanup()

    def request(self, action, fail_closed=False, event=None, snapshot=None):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            cfg = home/'.config/spotify-player'; cfg.mkdir(parents=True)
            cache = home/'.cache/sensei-spotify'; cache.mkdir(parents=True)
            if event is not None:(cache/'native-event.json').write_text(json.dumps(event))
            server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            server.bind(('127.0.0.1',0)); server.settimeout(.8)
            (cfg/'app.toml').write_text('client_port = '+str(server.getsockname()[1])+'\n')
            bindir = home/'bin'; bindir.mkdir()
            restart = bindir/'systemctl'; restart.write_text('#!/bin/sh\nexit 99\n'); restart.chmod(0o755)
            calls = []
            def serve():
                try:
                    while True:
                        raw, addr = server.recvfrom(65536)
                        calls.append(json.loads(raw))
                        response = {'Err':list(b'channel closed')} if fail_closed else {'Ok':list(json.dumps(snapshot).encode()) if snapshot is not None else []}
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

    def test_closed_channel_never_restarts_or_replays_mutation(self):
        result, calls = self.request('next', fail_closed=True)
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(calls,[{'Playback':'Next'}])
        self.assertIn('connection closed',json.loads(result.stdout)['error'])

    def test_closed_status_does_not_retry_or_restart(self):
        result, calls = self.request('status', fail_closed=True)
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(calls,[{'Get':{'Key':'Playback'}}])
        self.assertIn('connection closed',json.loads(result.stdout)['error'])

    def test_released_local_event_cannot_replace_remote_playback(self):
        import time
        event={'released':True,'playing':True,'player_pid':os.getpid(),'time':time.time(),'progress':0,
               'uri':'spotify:track:old','track':{'id':'old','uri':'spotify:track:old','duration':300000}}
        snapshot={'is_playing':True,'progress_ms':12000,'device':{'name':'Remote speaker','id':'remote'},
                  'item':{'id':'new','uri':'spotify:track:new','name':'Remote song','duration_ms':300000}}
        result,calls=self.request('status',event=event,snapshot=snapshot)
        self.assertEqual(result.returncode,0,result.stdout)
        state=json.loads(result.stdout)
        self.assertEqual(state['device'],'Remote speaker')
        self.assertEqual(state['track']['id'],'new')
        self.assertTrue(state['localReleased'])
        self.assertEqual(calls,[{'Get':{'Key':'Playback'}}])

if __name__ == '__main__': unittest.main()
