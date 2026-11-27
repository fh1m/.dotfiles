import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import json
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / 'home/.local/bin/sensei-app-run'

class AppRunnerContract(unittest.TestCase):
    def test_private_graphics_paths_do_not_replace_user_ros_or_cuda_environment(self):
        with tempfile.TemporaryDirectory() as tmp:
            d = Path(tmp); bindir=d/'bin'; bindir.mkdir(); log=d/'argv'
            stub=bindir/'systemd-run'
            stub.write_text('#!/usr/bin/env python3\nimport json,os,sys\nopen(os.environ["CAPTURE"],"w").write(json.dumps({"argv":sys.argv[1:],"cwd":os.getcwd(),"ld":os.environ.get("LD_LIBRARY_PATH"),"qt":os.environ.get("QT_PLUGIN_PATH"),"cuda":os.environ.get("CUDA_HOME")}))\n')
            stub.chmod(0o755)
            env=os.environ.copy(); env.update(PATH=str(bindir)+':'+env['PATH'],CAPTURE=str(log),HOME=tmp,LD_LIBRARY_PATH=f':{tmp}/.local/opt/sensei-mesa-egl/lib:/usr/lib/cuda:/opt/ros/lib:',QT_PLUGIN_PATH=f':{tmp}/.local/opt/sensei-qt-wayland/plugins:/usr/lib/qt/plugins:',CUDA_HOME='/usr/local/cuda')
            completed=subprocess.run([str(RUNNER),'--cwd',tmp,'--','printf','a b',';not-shell'],env=env,capture_output=True,text=True)
            self.assertEqual(completed.returncode,0,completed.stderr)
            import json
            got=json.loads(log.read_text())
            self.assertEqual(got['ld'],':/usr/lib/cuda:/opt/ros/lib:'); self.assertEqual(got['qt'],':/usr/lib/qt/plugins:'); self.assertEqual(got['cuda'],'/usr/local/cuda')
    def test_manager_absence_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            env={'PATH':tmp,'HOME':tmp}
            p=subprocess.run(['/bin/bash',str(RUNNER),'--','true'],env=env,capture_output=True,text=True)
            self.assertNotEqual(p.returncode,0); self.assertIn('refusing unmanaged launch',p.stderr)

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

if __name__ == '__main__': unittest.main()
