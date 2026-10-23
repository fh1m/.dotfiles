import unittest,tempfile,sys,json,uuid
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.academic import catalog,record,audit,assessment_summary
class Academic(unittest.TestCase):
 def test_catalogue_requirement_arithmetic(self):
  c=catalog();self.assertEqual(c['degree_credits'],141);self.assertEqual(len(c['courses']),122);self.assertTrue(c['issues'])
 def test_duplicate_retry_and_credit_identity(self):
  with tempfile.TemporaryDirectory() as d:
   r=Path(d);op=str(uuid.uuid4());record(r,'result',{'course':'ENG1011','term':'Fall 2026','grade':'A','confirmed':True},op)
   record(r,'result',{'course':'ENG1011','term':'Fall 2026','grade':'A','confirmed':True},op)
   a=audit(r);self.assertEqual(a['earned_credits'],3);self.assertEqual(a['cgpa'],4);self.assertEqual(a['result_count'],1)
   record(r,'result',{'course':'ENG1011','term':'Spring 2027','grade':'B','confirmed':True},str(uuid.uuid4()))
   a=audit(r);self.assertEqual(a['earned_credits'],3);self.assertIsNone(a['cgpa']);self.assertIn('retake',a['cgpa_status'])
 def test_attendance_unknown_is_not_absent_and_override_preserved(self):
  with tempfile.TemporaryDirectory() as d:
   r=Path(d)
   for i,state in enumerate(['attended','absent','unknown','cancelled']):record(r,'attendance',{'course':'ENG1011','term':'Fall 2026','date':'2026-10-'+str(27+i),'state':state},str(uuid.uuid4()))
   record(r,'override',{'course':'ENG1011','term':'Fall 2026','reason':'Advisor confirmed exception'},str(uuid.uuid4()))
   a=audit(r);self.assertEqual(a['attendance'][0]['known_percent'],50);self.assertEqual(a['attendance'][0]['unknown'],1);self.assertEqual(len(a['overrides']),1)
 def test_scores_are_not_final_grades(self):
  s=assessment_summary([{'weight':30,'score':25,'maximum':30},{'weight':70,'score':None,'maximum':100}]);self.assertEqual(s['earned_points'],25);self.assertEqual(s['remaining_weight'],70);self.assertFalse(s['final'])
 def test_bad_grade_and_unknown_course_rejected(self):
  with tempfile.TemporaryDirectory() as d:
   for data in [{'course':'FAKE1','term':'Fall 2026','grade':'A'},{'course':'ENG1011','term':'Fall 2026','grade':'A++'}]:
    with self.assertRaises(ValueError):record(Path(d),'result',data,str(uuid.uuid4()))

 def test_attendance_correction_preserves_history_without_double_count(self):
  with tempfile.TemporaryDirectory() as d:
   r=Path(d)
   for state in ['absent','attended']:record(r,'attendance',{'course':'ENG1011','term':'Fall 2026','date':'2026-10-27','state':state},str(uuid.uuid4()))
   a=audit(r);self.assertEqual(a['attendance'][0]['known_percent'],100);self.assertEqual(len(a['events']),2)

 def test_total_assessment_weight_rejected_before_commit(self):
  with tempfile.TemporaryDirectory() as d:
   r=Path(d);base={'course':'ENG1011','term':'Fall 2026','weight':60,'maximum':100}
   record(r,'assessment',dict(base,name='A'),str(uuid.uuid4()))
   with self.assertRaises(ValueError):record(r,'assessment',dict(base,name='B'),str(uuid.uuid4()))
   self.assertEqual(len(audit(r)['events']),1)

 def test_owner_ignores_unmanaged_registered_vault(self):
  from unittest.mock import patch
  from noesis.academic import owner
  with tempfile.TemporaryDirectory() as d:
   home=Path(d);path=home/'.config/noesis/academic.json';path.parent.mkdir(parents=True);path.write_text(json.dumps({'vault_id':'target'}));good=home/'good';bad=home/'unmanaged'
   def identity(p):
    if p==bad:raise ValueError('No Noesis manifest')
    return 'target'
   with patch('noesis.scopes.locations',return_value={bad,good}),patch('noesis.scopes.identity',side_effect=identity):self.assertEqual(owner(home),good)
