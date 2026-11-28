"""Exercise cancellation using synthetic recorder processes, never real ROS topics."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

import pytest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'home/.local/share/sensei'))
import job_runtime


@pytest.fixture
def recorder(tmp_path):
    binary=tmp_path/'bin'
    binary.mkdir()
    executable=binary/'ros2'
    executable.write_text('#!'+sys.executable+'\n'+'''
import json,os,pathlib,signal,subprocess,sys,time
if '--help' in sys.argv:
    print('--topics');raise SystemExit(0)
output=pathlib.Path(sys.argv[sys.argv.index('-o')+1]);output.mkdir()
(output/'synthetic.mcap').write_text('synthetic recorder fragment, not an actual MCAP')
signal.signal(signal.SIGINT,signal.SIG_IGN);signal.signal(signal.SIGTERM,signal.SIG_IGN)
ready=output/'child.ready'
program='import pathlib,signal,time;signal.signal(signal.SIGINT,signal.SIG_IGN);signal.signal(signal.SIGTERM,signal.SIG_IGN);pathlib.Path('+repr(str(ready))+').touch();time.sleep(60)'
child=subprocess.Popen([sys.executable,'-c',program])
while not ready.exists():time.sleep(.005)
(output/'fixture-pids.json').write_text(json.dumps([os.getpid(),child.pid]))
time.sleep(60)
''')
    executable.chmod(0o755)
    return dict(os.environ,PATH=str(binary)+':'+os.environ['PATH'])


@pytest.mark.parametrize('cancel', [False, True])
def test_forced_capture_stop_reaps_group_and_preserves_partial_receipt(tmp_path,recorder,cancel):
    output=tmp_path/'capture'
    program=('import importlib.machinery,importlib.util;'
             f'loader=importlib.machinery.SourceFileLoader("capture",{str(ROOT/"home/.local/bin/sensei-mcap-capture")!r});'
             'spec=importlib.util.spec_from_loader(loader.name,loader);module=importlib.util.module_from_spec(spec);loader.exec_module(module);'
             'module.INTERRUPT_GRACE_SECONDS=.05;module.TERMINATE_GRACE_SECONDS=.05;'
             f'raise SystemExit(module.main(["--output",{str(output)!r},"--seconds","1","--topic","/synthetic"]))')
    controller=subprocess.Popen([sys.executable,'-c',program],env=recorder,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    pids=[]
    try:
        deadline=time.monotonic()+5
        while not (output/'fixture-pids.json').exists() and time.monotonic()<deadline:
            time.sleep(.01)
        assert (output/'fixture-pids.json').exists()
        pids=json.loads((output/'fixture-pids.json').read_text())
        if cancel:controller.terminate()
        stdout,stderr=controller.communicate(timeout=5)
        assert controller.returncode==(143 if cancel else 1),stderr
        receipt=json.loads((tmp_path/'capture-capture.json').read_text())
        assert receipt['reason']==('cancelled' if cancel else 'duration')
        assert receipt['exitCode']==-signal.SIGKILL
        assert receipt['partial'] and receipt['forcedStop']
        assert json.loads(stdout)==receipt
        assert (output/'synthetic.mcap').read_text().startswith('synthetic recorder fragment')
        deadline=time.monotonic()+1
        while any(job_runtime.identity(pid) for pid in pids) and time.monotonic()<deadline:
            time.sleep(.01)
        assert all(job_runtime.identity(pid) is None for pid in pids)
        assert (tmp_path/'capture-capture.json').stat().st_mode&0o777==0o600
    finally:
        if controller.poll() is None:
            controller.kill();controller.wait(timeout=5)
        for pid in pids:
            if job_runtime.identity(pid):os.kill(pid,signal.SIGKILL)
