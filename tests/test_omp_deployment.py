import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('omp_deploy',ROOT/'scripts/install-omp.py')
deploy=importlib.util.module_from_spec(spec);spec.loader.exec_module(deploy)


class DeploymentTests(unittest.TestCase):
    def test_restore_preserves_previous_work_and_rejects_intervening_edit(self):
        with tempfile.TemporaryDirectory() as tmp:
            home=Path(tmp);target=home/'.local/bin/omp-work';target.parent.mkdir(parents=True)
            target.write_text('previous user launcher\n');target.chmod(0o700)
            result=deploy.install(home,apply=True)
            manifest=Path(result['manifest'])
            self.assertEqual(deploy.install(home,apply=True)['changed'],[])
            target.write_text('new user work after deployment\n')
            with self.assertRaises(ValueError):deploy.rollback(manifest,apply=True)
            self.assertEqual(target.read_text(),'new user work after deployment\n')
            installed=(ROOT/'home/.local/bin/omp-work').read_text().replace('@HOME@',str(home)).replace('/home/fh1m',str(home))
            target.write_text(installed)
            deploy.rollback(manifest,apply=True)
            self.assertEqual(target.read_text(),'previous user launcher\n')
            self.assertEqual(target.stat().st_mode&0o777,0o700)
            self.assertFalse((home/'.local/share/omp-den/work.py').exists())

if __name__=='__main__':unittest.main()
