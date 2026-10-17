import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('job',ROOT/'home/.local/share/sensei/den_job.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Receipts(unittest.TestCase):
 def test_execution_records_success_and_checksums(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);receipt=p/'receipt.json'
   receipt.write_text(json.dumps({'project':d,'command':[sys.executable,'-c','from pathlib import Path; Path("result.txt").write_text("measurement")'],'expectedArtifacts':['result.txt']}))
   self.assertEqual(m.execute(receipt),0);data=json.loads(receipt.read_text());self.assertEqual(data['state'],'succeeded');self.assertEqual(data['artifacts'][0]['sha256'],m.digest(p/'result.txt'));self.assertGreaterEqual(data['finished'],data['started'])
 def test_failed_experiment_is_preserved(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'receipt.json';p.write_text(json.dumps({'project':d,'command':[sys.executable,'-c','raise SystemExit(3)'],'expectedArtifacts':['missing.csv']}))
   self.assertEqual(m.execute(p),3);data=json.loads(p.read_text());self.assertEqual(data['exitCode'],3);self.assertEqual(data['state'],'failed');self.assertTrue(data['artifactErrors'])
 def test_artifact_escape_and_symlink_rejected(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);(p/'project').mkdir();(p/'private').write_text('secret');(p/'project/link').symlink_to(p/'private')
   for name in ('../private','link'):
    with self.assertRaises(ValueError):m.artifact(p/'project',name)

 def test_changed_queued_input_is_not_executed(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d);source=root/'input';source.write_text('original');expected=m.digest(source);source.write_text('changed')
   receipt=root/'receipt.json';receipt.write_text(json.dumps({'project':d,'command':[sys.executable,'-c','from pathlib import Path;Path("ran").touch()'],'inputs':[{'path':str(source),'sha256':expected}]}))
   self.assertNotEqual(m.execute(receipt),0);self.assertFalse((root/'ran').exists());self.assertEqual(json.loads(receipt.read_text())['state'],'failed')
