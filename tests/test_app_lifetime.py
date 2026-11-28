import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import json
import sys
import shutil
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / 'home/.local/bin/sensei-app-run'

class AppRunnerContract(unittest.TestCase):
    def test_manager_absence_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            env={'PATH':tmp,'HOME':tmp}
            p=subprocess.run(['/bin/bash',str(RUNNER),'--','true'],env=env,capture_output=True,text=True)
            self.assertNotEqual(p.returncode,0)

    @unittest.skipUnless(os.environ.get('SENSEI_TEST_USER_MANAGER')=='1','Explicit opt-in required for disposable native user units')
    def test_application_survives_stopping_launcher_with_literal_arguments_and_environment(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory=Path(tmp);receipt=directory/'receipt.json'
            launcher='den-app-lifetime-test-'+uuid.uuid4().hex
            program='import json,os,sys,time;from pathlib import Path;p=Path(sys.argv[1]);p.write_text(json.dumps({\"pid\":os.getpid(),\"cgroup\":Path(\"/proc/self/cgroup\").read_text(),\"cwd\":os.getcwd(),\"args\":sys.argv[2:],\"ld\":os.environ.get(\"LD_LIBRARY_PATH\")}));time.sleep(60)'
            env=dict(os.environ,LD_LIBRARY_PATH=str(Path.home()/'.local/opt/sensei-mesa-egl/lib')+':/opt/ros/humble/lib:/usr/lib/cuda')
            start=subprocess.run(['systemd-run','--user','--collect','--remain-after-exit','--expand-environment=no',
                                  '--setenv=LD_LIBRARY_PATH','--unit='+launcher,str(RUNNER),'--cwd',tmp,'--',
                                  sys.executable,'-c',program,str(receipt),'a b',';not-shell','$HOME'],
                                 env=env,capture_output=True,text=True,timeout=10)
            self.assertEqual(start.returncode,0,start.stderr)
            app=None
            try:
                deadline=time.monotonic()+10
                while not receipt.exists() and time.monotonic()<deadline:time.sleep(.05)
                self.assertTrue(receipt.exists(),'Disposable app never became ready')
                app=json.loads(receipt.read_text())
                self.assertEqual(app['cwd'],tmp)
                self.assertEqual(app['args'],['a b',';not-shell','$HOME'])
                self.assertEqual(app['ld'],'/opt/ros/humble/lib:/usr/lib/cuda')
                stopped=subprocess.run(['systemctl','--user','stop',launcher],capture_output=True,text=True,timeout=10)
                self.assertEqual(stopped.returncode,0,stopped.stderr)
                os.kill(app['pid'],0)
                self.assertNotIn(launcher,app['cgroup'])
                self.assertNotIn('sensei-shell.service',app['cgroup'])
                print('NATIVE_APP_LIFETIME_PASS '+app['cgroup'].strip())
            finally:
                subprocess.run(['systemctl','--user','stop',launcher],capture_output=True,text=True,timeout=10)
                if receipt.exists():
                    unit=json.loads(receipt.read_text())['cgroup'].strip().rsplit('/',1)[-1]
                    if unit.startswith('run-') and unit.endswith('.service'):
                        subprocess.run(['systemctl','--user','stop',unit],capture_output=True,text=True,timeout=10)

    @unittest.skipUnless(os.environ.get('SENSEI_TEST_USER_MANAGER')=='1','Explicit opt-in required for disposable native user units')
    def test_forked_application_survives_its_successful_launcher_exit(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory=Path(tmp);receipt=directory/'child.json';released=directory/'launcher-finished'
            child='import json,os,signal,sys;from pathlib import Path;Path(sys.argv[1]).write_text(json.dumps({"pid":os.getpid(),"cgroup":Path("/proc/self/cgroup").read_text()}));signal.pause()'
            parent='''import subprocess,sys,time
from pathlib import Path
subprocess.Popen([sys.executable,"-c",sys.argv[1],sys.argv[2]],start_new_session=True)
deadline=time.monotonic()+5
while not Path(sys.argv[2]).exists():
    if time.monotonic()>deadline:raise RuntimeError("child did not start")
    time.sleep(.02)
Path(sys.argv[3]).touch()
'''
            started=subprocess.run([str(RUNNER),'--',sys.executable,'-c',parent,child,str(receipt),str(released)],capture_output=True,text=True,timeout=10)
            self.assertEqual(started.returncode,0,started.stderr)
            unit=None
            try:
                # Native process/service transitions cannot be driven by fake timers.
                deadline=time.monotonic()+10
                while not released.exists() and time.monotonic()<deadline:time.sleep(.02)
                self.assertTrue(released.exists(),'Forking launcher never completed')
                data=json.loads(receipt.read_text());unit=data['cgroup'].strip().rsplit('/',1)[-1]
                self.assertTrue(unit.startswith('run-') and unit.endswith('.service'))
                while time.monotonic()<deadline:
                    main=subprocess.run(['systemctl','--user','show',unit,'-p','MainPID','--value'],capture_output=True,text=True,timeout=3)
                    if main.stdout.strip()=='0':break
                    time.sleep(.02)
                self.assertEqual(main.stdout.strip(),'0','Launcher is still running')
                active=subprocess.run(['systemctl','--user','is-active',unit],capture_output=True,text=True,timeout=3)
                self.assertEqual(active.stdout.strip(),'active','Successful launcher exit terminated its GUI child')
                state=(Path('/proc')/str(data['pid'])/'stat').read_text().rsplit(') ',1)[1].split()[0]
                self.assertNotEqual(state,'Z','Application was already killed')
            finally:
                if unit:subprocess.run(['systemctl','--user','stop',unit],capture_output=True,text=True,timeout=10)

    @unittest.skipUnless(os.environ.get('SENSEI_TEST_USER_MANAGER')=='1','Explicit opt-in required for disposable native user units')
    def test_spotify_client_survives_stopping_its_control_caller(self):
        with tempfile.TemporaryDirectory() as tmp:
            home=Path(tmp);receipt=home/'spotify-child.json'
            helper=home/'.local/bin/sensei-app-run'
            helper.parent.mkdir(parents=True)
            shutil.copy2(RUNNER,helper)
            launcher=home/'bin/spotify-launcher'
            launcher.parent.mkdir()
            launcher.write_text('#!'+sys.executable+'\n'
                'import json,os,signal\nfrom pathlib import Path\n'
                'Path(os.environ["DEN_SPOTIFY_TEST_RECEIPT"]).write_text(json.dumps({'
                '"pid":os.getpid(),"cgroup":Path("/proc/self/cgroup").read_text()}))\n'
                'signal.pause()\n')
            launcher.chmod(0o700)
            caller='den-spotify-launch-test-'+uuid.uuid4().hex
            program='import sys;sys.path.insert(0,sys.argv[1]);import spotify_control;spotify_control.main(["launch"])'
            env=dict(os.environ,HOME=str(home),PATH=str(launcher.parent)+':'+os.environ['PATH'],
                     DEN_SPOTIFY_TEST_RECEIPT=str(receipt))
            started=subprocess.run(['systemd-run','--user','--collect','--remain-after-exit',
                '--expand-environment=no','--setenv=HOME','--setenv=PATH',
                '--setenv=DEN_SPOTIFY_TEST_RECEIPT','--unit='+caller,sys.executable,
                '-c',program,str(ROOT/'home/.local/share/sensei')],
                env=env,capture_output=True,text=True,timeout=10)
            self.assertEqual(started.returncode,0,started.stderr)
            try:
                deadline=time.monotonic()+10
                while not receipt.exists() and time.monotonic()<deadline:time.sleep(.02)
                self.assertTrue(receipt.exists(),'The stand-in official client did not start')
                child=json.loads(receipt.read_text())
                stopped=subprocess.run(['systemctl','--user','stop',caller],
                    capture_output=True,text=True,timeout=10)
                self.assertEqual(stopped.returncode,0,stopped.stderr)
                try:
                    state=(Path('/proc')/str(child['pid'])/'stat').read_text().rsplit(') ',1)[1].split()[0]
                except FileNotFoundError:
                    state=None
                self.assertNotIn(state,(None,'Z'),'Stopping Spotify control killed its launched client')
                self.assertNotIn(caller,child['cgroup'])
            finally:
                subprocess.run(['systemctl','--user','stop',caller],capture_output=True,text=True,timeout=10)
                if receipt.exists():
                    unit=json.loads(receipt.read_text())['cgroup'].strip().rsplit('/',1)[-1]
                    if unit.startswith('run-') and unit.endswith('.service'):
                        subprocess.run(['systemctl','--user','stop',unit],capture_output=True,text=True,timeout=10)

if __name__ == '__main__': unittest.main()
