"""Meaningful disposable course data; simulated evidence is not learner mastery."""
import json,sys,tempfile,unittest,uuid
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.persistence import migration
from noesis.models import create,relationship
from noesis.activities import record_activity,operation_status
from noesis.index import Index
from noesis.courses import learning_context,move
from noesis.views import overview,today

class LearningDay(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.home=Path(self.temp.name)
  self.mock=patch('pathlib.Path.home',return_value=self.home);self.mock.start()
  self.addCleanup(self.temp.cleanup);self.addCleanup(self.mock.stop)
  self.root=self.home/'Mathematics';(self.root/'System').mkdir(parents=True)
  (self.root/'System/System.json').write_text('{}');migration(self.root,True)
  self.course=create(self.root,'resource','Linear algebra',fields={'source_kind':'course'})
  self.module=create(self.root,'unit','Vector spaces',fields={'unit_kind':'module'},parent_id=self.course['id'])
  self.lessons=[create(self.root,'unit',f'Lecture {n+1}',fields={'unit_kind':'lecture'},parent_id=self.module['id']) for n in range(6)]
  self.exercise=create(self.root,'task','Basis exercise','## Problem statement\n\nDetermine whether the columns are independent.',parent_id=self.lessons[2]['id'],relation='assigns')
  self.gap=create(self.root,'task','Span reconstruction','## Problem statement\n\nExplain the span of two dependent vectors.')
  self.edge=relationship(self.root,self.lessons[2]['id'],self.gap['id'],'prerequisite','gate','Needed to interpret the lecture')
 def index(self):
  index=Index(self.root);index.reconcile();self.addCleanup(index.close);return index
 def test_lesson_context_preserves_positions_attempts_and_ownership_after_move(self):
  record_activity(self.root,self.lessons[2]['path'],'study',state={'locator':{'kind':'timestamp','value':'12:34'}})
  record_activity(self.root,self.exercise['path'],'attempt','Incorrect basis',outcome='failed',assistance=['none'])
  context=learning_context(self.index(),self.lessons[2]['id'])
  self.assertEqual(context['parents'][0]['id'],self.module['id'])
  self.assertEqual(context['prerequisites'][0]['id'],self.gap['id'])
  self.assertEqual(context['assignments'][0]['assessment']['outcome'],'failed')
  self.assertEqual(context['next_lesson']['id'],self.lessons[3]['id'])
  (self.root/self.gap['path']).rename(self.root/'Moved prerequisite.md')
  self.assertEqual(learning_context(self.index(),self.lessons[2]['id'])['prerequisites'][0]['path'],'Moved prerequisite.md')
  self.assertEqual(self.index().record(self.lessons[2]['id'])['state']['locator']['value'],'12:34')
 def test_module_is_structure_and_consumption_never_completes_assessment(self):
  for lesson in self.lessons[:3]:record_activity(self.root,lesson['path'],'study',state={'status':'read'})
  counts=overview(self.index(),self.course['id'])['counts']
  self.assertEqual(counts['lectures']['consumed'],3)
  self.assertEqual(counts['other_units']['total'],0)
  self.assertEqual(counts['assignments']['reported_success'],0)
  self.assertNotEqual(today(self.index(),self.lessons[2]['id'])['continue']['id'] if today(self.index(),self.lessons[2]['id'])['continue'] else None,self.lessons[2]['id'])
  record_activity(self.root,self.exercise['path'],'attempt','Worked explanation',outcome='succeeded',assistance=['reference'])
  counts=overview(self.index(),self.course['id'])['counts']
  self.assertEqual(counts['assignments']['reported_success'],1)
  self.assertEqual(counts['assignments']['independent_reported_success'],0)
 def test_prerequisite_readiness_is_an_explicit_context_decision(self):
  from noesis.policies import next_actions
  record_activity(self.root,self.gap['path'],'attempt','Reconstructed the span',outcome='succeeded',assistance=['none'])
  self.assertNotEqual(learning_context(self.index(),self.lessons[2]['id'])['prerequisites'][0]['readiness'],'passed')
  self.assertTrue(any(row['evidence_id']==self.edge['id'] for row in next_actions(self.index())))
  decision=record_activity(self.root,self.edge['path'],'disposition','The span explanation is usable for this lesson',state='passed',actor='learner',scope=self.lessons[2]['id'])
  self.assertEqual(learning_context(self.index(),self.lessons[2]['id'])['prerequisites'][0]['readiness'],'passed')
  self.assertFalse(any(row['evidence_id']==self.edge['id'] for row in next_actions(self.index())))
  self.assertIsNone(self.index().record(self.gap['id'])['state']['status'])
  self.assertEqual(decision['scope'],self.lessons[2]['id'])
  record_activity(self.root,self.edge['path'],'disposition','Changed lesson needs another check',state='active',actor='learner',scope=self.lessons[2]['id'])
  self.assertEqual(len(self.index().timeline(self.edge['id'])),2)
  self.assertTrue(any(row['evidence_id']==self.edge['id'] for row in next_actions(self.index())))
 def test_next_lesson_uses_durable_order_and_large_outlines(self):
  for n in range(55):create(self.root,'unit',f'Additional lecture {n}',fields={'unit_kind':'lecture'},parent_id=self.module['id'])
  move(self.root,self.module['id'],self.lessons[3]['id'],'up')
  self.assertEqual(learning_context(self.index(),self.lessons[1]['id'])['next_lesson']['id'],self.lessons[3]['id'])
  members=self.index().db.execute("SELECT id FROM records WHERE title IN ('Additional lecture 50','Additional lecture 51') ORDER BY title").fetchall()
  self.assertEqual(learning_context(self.index(),members[0][0])['next_lesson']['id'],members[1][0])
 def test_relationship_retry_has_one_durable_receipt(self):
  operation=str(uuid.uuid4())
  args=(self.root,self.lessons[1]['id'],self.gap['id'],'prerequisite','parallel','Useful for intuition')
  first=relationship(*args,operation_id=operation);again=relationship(*args,operation_id=operation)
  self.assertEqual(first['id'],again['id'])
  self.assertEqual(operation_status(self.root,operation)['status'],'committed')
  with self.assertRaisesRegex(ValueError,'changed record content'):
   relationship(*args[:-1],'Changed reason',operation_id=operation)
 def test_interrupted_link_publication_retries_without_duplicate_edges(self):
  import noesis.models as models
  operation=str(uuid.uuid4());publish=models.publish
  def interrupted(path,text,*args):
   publish(path,text,*args)
   if path.suffix=='.md':raise OSError('Interrupted after relationship publication')
  args=(self.root,self.lessons[1]['id'],self.gap['id'],'prerequisite','parallel','Study alongside')
  with patch.object(models,'publish',side_effect=interrupted):
   with self.assertRaises(OSError):relationship(*args,operation_id=operation)
  result=relationship(*args,operation_id=operation)
  self.assertEqual(len(operation_status(self.root,operation)['records']),1)
  self.assertEqual(relationship(*args,operation_id=operation)['id'],result['id'])
 def test_foreign_uuid_collision_cannot_become_a_local_prerequisite(self):
  owner=self.index().manifest['vault_id'];foreign=str(uuid.uuid4())
  create(self.root,'relationship','Foreign prerequisite',fields={'source':self.lessons[0]['id'],'target':self.gap['id'],'relation':'prerequisite','role':'gate',
   'source_ref':{'vault_id':owner,'record_id':self.lessons[0]['id']},'target_ref':{'vault_id':foreign,'record_id':self.gap['id']}})
  self.assertEqual(learning_context(self.index(),self.lessons[0]['id'])['prerequisites'],[])
