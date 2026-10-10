"""Actual starter and independent-case contracts, not a Dijkstra backend."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
EXAMPLE = ROOT/'home/.local/share/sensei-learning/examples/dijkstra'
sys.path.insert(0,str(ROOT/'scripts'))
from noesis_authored_examples import DIJKSTRA

class AlgorithmExample(unittest.TestCase):
 def test_unaided_skeleton_fails_and_preserves_actual_failure(self):
  with tempfile.TemporaryDirectory() as home:
   destination=Path(home)/'implementation';shutil.copytree(EXAMPLE,destination)
   result=subprocess.run([sys.executable,'check_cases.py','--output','output.json'],cwd=destination,capture_output=True,text=True)
   self.assertEqual(result.returncode,1);observed=json.loads((destination/'output.json').read_text());self.assertFalse(observed['learner_achievement']);self.assertFalse(observed['all_agree']);self.assertTrue(all('NotImplementedError' in row['error'] for row in observed['cases']));self.assertEqual(len(observed['cases']),8)
 def test_corrected_code_matches_hand_expected_and_independent_oracle(self):
  with tempfile.TemporaryDirectory() as home:
   destination=Path(home)/'implementation';shutil.copytree(EXAMPLE,destination);(destination/'dijkstra.py').write_text(DIJKSTRA)
   result=subprocess.run([sys.executable,'check_cases.py'],cwd=destination,capture_output=True,text=True)
   self.assertEqual(result.returncode,0,result.stderr);observed=json.loads(result.stdout);self.assertTrue(observed['all_agree']);self.assertEqual(observed['cases'][0]['observed']['B'],2);self.assertEqual(observed['cases'][3]['observed']['X'],'unreachable');self.assertEqual(observed['cases'][-1]['observed'],'ValueError');self.assertIsNone(observed['code_revision'])
