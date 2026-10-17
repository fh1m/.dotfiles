import importlib.util,unittest,random
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'home/.local/share/sensei/zondo_dialog.py'
s=importlib.util.spec_from_file_location('dialog',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
class Dialogue(unittest.TestCase):
 def test_success_is_not_mistaken_for_a_bug_complaint(self):
  self.assertEqual(m.respond('I finally solved that bug!',{},random.Random(1))[1],'celebrate')
 def test_failure_is_not_mistaken_for_success(self):
  self.assertNotEqual(m.respond('It worked yesterday but now it is broken',{},random.Random(1))[1],'celebrate')
 def test_replies_do_not_repeat_immediately_and_do_not_store_user_text(self):
  state={};previous=''
  for _ in range(25):
   reply,_=m.respond('hello private phrase',state,random.Random(2));self.assertNotEqual(reply,previous);previous=reply
  self.assertNotIn('private phrase',str(state));self.assertLessEqual(len(state['recentReplies']),12)
 def test_empty_input_is_rejected(self):
  with self.assertRaises(ValueError):m.respond(' ',{})
