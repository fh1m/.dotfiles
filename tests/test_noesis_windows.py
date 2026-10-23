import unittest,tempfile,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.windows import state_file,validate_id,merge_state
class Windows(unittest.TestCase):
 def test_primary_path_stays_compatible(self):
  self.assertEqual(state_file(Path('/home/test'),'main').name,'window.json')
 def test_secondary_is_private_and_separate(self):
  self.assertNotEqual(state_file(Path('/home/test'),'study-2'),state_file(Path('/home/test'),'main'))
  for value in ['../escape','','a/b','x'*100]:
   with self.assertRaises(ValueError):validate_id(value)
 def test_legacy_state_defaults_do_not_relocate(self):
  s=merge_state({'drafts':{'a':'keep'}},{'monitor':'DP-1'})
  self.assertEqual(s['drafts'],{'a':'keep'});self.assertEqual(s['placement'],'current');self.assertEqual(s['return_behavior'],'stay')

class SyncConflicts(unittest.TestCase):
 def test_conflict_copy_is_not_an_extra_note(self):
  from noesis.persistence import notes
  with tempfile.TemporaryDirectory() as d:
   root=Path(d);(root/'note.md').write_text('original');(root/'note.sync-conflict-20261023-device.md').write_text('alternate')
   self.assertEqual(len(list(notes(root))),1);self.assertEqual(len(list(notes(root,include_conflicts=True))),2)
