import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
s=importlib.util.spec_from_file_location('den_projects',ROOT/'scripts/setup-den-projects.py');m=importlib.util.module_from_spec(s);s.loader.exec_module(m)


class ProjectHandoff(unittest.TestCase):
    def test_incomplete_metadata_repaired_without_touching_work_or_staged_state(self):
        with tempfile.TemporaryDirectory() as directory:
            d=Path(directory);source=d/'source';source.mkdir();handoff=d/'handoff';handoff.mkdir();mirror=d/'mirror';target=mirror/'robot';target.mkdir(parents=True)
            def git(*args):return subprocess.check_output(['git','-C',str(source),*args],stderr=subprocess.DEVNULL)
            git('init','-q','-b','main');git('config','user.name','Den fixture');git('config','user.email','fixture@example.invalid')
            (source/'control.py').write_text('gain = 1\n');git('add','.');git('commit','-qm','baseline')
            head=git('rev-parse','HEAD').decode().strip()
            (source/'control.py').write_text('gain = 2\n');git('add','control.py')
            (handoff/'history.bundle').write_bytes(git('bundle','create','-','--all','HEAD'))
            (handoff/'index.patch').write_bytes(git('diff','--cached','--binary'))
            (handoff/'record.json').write_text(json.dumps({'relative':'robot','head':head,'branch':'main'}))
            (target/'.git/objects').mkdir(parents=True);(target/'control.py').write_text('gain = 3 # independent work\n')
            self.assertTrue(m.seed_repository(handoff,mirror)['seeded'])
            self.assertEqual((target/'control.py').read_text(),'gain = 3 # independent work\n')
            self.assertEqual(subprocess.check_output(['git','-C',str(target),'show',':control.py']),b'gain = 2\n')
            self.assertTrue(list(handoff.glob('incomplete-git-*')))
            self.assertFalse(m.seed_repository(handoff,mirror)['seeded'])
            self.assertEqual((target/'control.py').read_text(),'gain = 3 # independent work\n')

    def test_path_escape_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            d=Path(directory);(d/'record.json').write_text(json.dumps({'relative':'../escape'}))
            with self.assertRaises(ValueError):m.seed_repository(d,d/'mirror')


if __name__=='__main__':unittest.main()
