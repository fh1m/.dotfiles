import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import uuid

ROOT=Path(__file__).resolve().parents[1]
BUN=Path.home()/'.bun/bin/bun'
OMP=Path.home()/'.bun/install/global/node_modules/@oh-my-pi/pi-coding-agent'


@unittest.skipUnless(BUN.exists() and OMP.exists(),'Requires the installed OMP importer')
class HistoryTests(unittest.TestCase):
    def test_changed_original_becomes_separate_revision_without_erasing_native_work(self):
        with tempfile.TemporaryDirectory() as tmp:
            home=Path(tmp);state=home/'.local/share/omp-unified';state.mkdir(parents=True)
            source=home/'.codex/sessions/2026/10/30/rollout-fixture.jsonl';source.parent.mkdir(parents=True)
            session=str(uuid.uuid4());stamp='2026-10-30T00:00:00.000Z'
            source.write_text('\n'.join(json.dumps(row) for row in [
                {'type':'session_meta','timestamp':stamp,'payload':{'id':session,'cwd':tmp}},
                {'type':'event_msg','timestamp':stamp,'payload':{'type':'user_message','message':'Investigate the numerical fixture'}},
                {'type':'response_item','timestamp':stamp,'payload':{'type':'message','role':'assistant','content':[{'type':'output_text','text':'Baseline captured.'}]}}
            ])+'\n')
            env={**os.environ,'OMP_UNIFIED_HOST_HOME':tmp,'PI_CODING_AGENT_DIR':str(home/'native-agent')}
            command=[str(BUN),str(ROOT/'home/.local/share/omp-unified/omp-unified.ts'),'import',session,'--no-open']
            original=hashlib.sha256(source.read_bytes()).hexdigest()
            first=subprocess.run(command,env=env,capture_output=True,text=True,timeout=30)
            self.assertEqual(first.returncode,0,first.stderr)
            self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(),original)
            registry=json.loads((state/'imports.json').read_text());old=Path(next(iter(registry.values()))['native'])
            self.assertTrue(old.is_relative_to(home/'native-agent'))
            native_hash=hashlib.sha256(old.read_bytes()).hexdigest()
            with source.open('a') as f:f.write(json.dumps({'type':'event_msg','timestamp':stamp,'payload':{'type':'user_message','message':'Preserve this later continuation too'}})+'\n')
            denied=subprocess.run(command,env=env,capture_output=True,text=True,timeout=30)
            self.assertNotEqual(denied.returncode,0)
            self.assertIn('Source changed',denied.stderr)
            self.assertEqual(hashlib.sha256(old.read_bytes()).hexdigest(),native_hash)
            second=subprocess.run([*command,'--new-revision'],env=env,capture_output=True,text=True,timeout=30)
            self.assertEqual(second.returncode,0,second.stderr)
            registry=json.loads((state/'imports.json').read_text());self.assertEqual(len(registry),2)
            self.assertEqual(hashlib.sha256(old.read_bytes()).hexdigest(),native_hash)
            self.assertTrue(all(Path(x['sourcePath']).is_relative_to(state/'revisions') for x in registry.values()))
            repeat=subprocess.run([*command,'--new-revision'],env=env,capture_output=True,text=True,timeout=30)
            self.assertEqual(repeat.returncode,0,repeat.stderr)
            self.assertEqual(len(json.loads((state/'imports.json').read_text())),2)

if __name__=='__main__':unittest.main()
