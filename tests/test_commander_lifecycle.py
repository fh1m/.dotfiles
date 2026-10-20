import importlib.machinery
import importlib.util
from pathlib import Path
import unittest
import shutil
import subprocess
import tempfile
import time
import json
import sys

path=Path(__file__).resolve().parents[1]/'home/.local/bin/sensei-commander'
loader=importlib.machinery.SourceFileLoader('commander',str(path))
spec=importlib.util.spec_from_loader(loader.name,loader)
m=importlib.util.module_from_spec(spec);loader.exec_module(m)


class Lifecycle(unittest.TestCase):
    def setUp(self):
        self.time=0;self.records=[];self.notices=[]
        self.flow=m.Lifecycle(self.records.append,lambda s:self.notices.append(s) or True,lambda:self.time)
    def test_only_verified_delivery_path_counts_as_connected(self):
        self.assertIsNone(m.event('✅ Channel subscribed'))
        self.assertIsNone(m.event('User: private@example.com token=secret'))
        self.assertIsNone(m.event('   - 🔌 Connected to Remote MCP'))
        self.assertEqual(m.event('👋 Presence tracked (device redacted visible as online)'), 'connected')
        self.assertEqual(m.event('❌ Channel error: socket closed'), 'reconnecting')
    def test_brief_drop_does_not_flicker_or_repeat_online(self):
        f=self.flow;f.change('connected');f.tick()
        self.time=20;f.change('reconnecting');f.tick()
        self.time=24;f.change('connected');f.tick()
        self.assertEqual(self.notices,['connected'])
    def test_sustained_outage_notified_once_then_recovery(self):
        f=self.flow;f.change('connected');f.tick()
        self.time=20;f.change('reconnecting')
        self.time=29;f.tick();f.tick()
        self.time=60;f.change('connected');f.tick()
        self.assertEqual(self.notices,['connected','reconnecting','connected'])
    def test_notifications_wait_for_desktop_and_use_latest_state(self):
        f=self.flow;f.announce=lambda _:False
        f.change('reconnecting');self.time=30;f.tick()
        f.change('connected');f.announce=lambda s:self.notices.append(s) or True;f.tick()
        self.assertEqual(self.notices,['connected'])
    def test_revoked_auth_not_classified_as_transient_network_failure(self):
        self.assertEqual(m.event('   1. Verify this device in your browser:'),'authentication-required')
        self.assertIsNone(m.event('fetch failed; retrying'))

class Supervisor(unittest.TestCase):
    @unittest.skipUnless(shutil.which('node'),'Node needed for real child lifecycle test')
    def test_crashed_child_restarts_without_leaking_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);(root/'.desktop-commander-device').mkdir()
            (root/'.desktop-commander-device/device.json').write_text('{}')
            entry=root/'agent.js'
            entry.write_text("""const fs=require('fs'),p=__dirname+'/attempt';
            let n=fs.existsSync(p)?Number(fs.readFileSync(p,'utf8'))+1:1;fs.writeFileSync(p,String(n));
            console.log('private account details must not reach the journal');
            console.log('Desktop Commander Remote is connected');
            if(n===1){let c=require('child_process').spawn(process.execPath,['-e','setInterval(()=>{},1000)'],{stdio:'ignore'});fs.writeFileSync(__dirname+'/orphan',String(c.pid));setTimeout(()=>process.exit(1),150);}else setInterval(()=>{},1000);""")
            worker="""import importlib.machinery,importlib.util,sys
from pathlib import Path
loader=importlib.machinery.SourceFileLoader('agent',sys.argv[1]);spec=importlib.util.spec_from_loader(loader.name,loader);m=importlib.util.module_from_spec(spec);loader.exec_module(m)
m.HOME=Path(sys.argv[2]);m.STATE=m.HOME/'state/status.json';m.ENTRY=m.HOME/'agent.js';m.notify=lambda state:True
raise SystemExit(m.main())
"""
            proc=subprocess.Popen([sys.executable,'-c',worker,str(path),str(root)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
            try:
                end=time.monotonic()+18
                recovered=False
                while time.monotonic()<end:
                    receipt=root/'state/status.json'
                    if receipt.exists():
                        record=json.loads(receipt.read_text())
                        if record.get('attempt',0)>=2 and record['status']=='connected':
                            recovered=True;break
                    time.sleep(.1)
                self.assertTrue(recovered,'Supervisor did not restart the crashed child')
            finally:
                proc.terminate()
                output,_=proc.communicate(timeout=15)
            self.assertEqual(proc.returncode,0,output)
            self.assertNotIn('private account',output)
            orphan=Path('/proc')/(root/'orphan').read_text()/'stat'
            self.assertTrue(not orphan.exists() or orphan.read_text().split()[2]=='Z', 'Orphaned MCP child survived cleanup')
            self.assertEqual(json.loads((root/'state/status.json').read_text())['status'],'stopped')

if __name__=='__main__':unittest.main()
