import sys,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.persistence import migration
from noesis.models import create
from noesis.activities import record_activity
from noesis.index import Index
from noesis.policies import next_actions
from noesis.views import today

class ManualPriorities(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.home=Path(self.temp.name);self.mock=patch('pathlib.Path.home',return_value=self.home);self.mock.start()
  self.root=self.home/'vault';(self.root/'System').mkdir(parents=True);(self.root/'System/System.json').write_text('{}');migration(self.root,True)
  self.paper=create(self.root,'resource','Paper question',fields={'source_kind':'paper'});self.run=create(self.root,'experiment','Eligible experiment')
  self.index=Index(self.root);self.index.reconcile()
 def tearDown(self):self.index.close();self.mock.stop();self.temp.cleanup()
 def update(self,record,**state):
  result=record_activity(self.root,record['path'],'disposition',state=state);self.index.reconcile();return result
 def test_pins_priorities_and_quiet_are_durable_without_completion(self):
  event=self.update(self.paper,pin=True,manual_priority='normal')
  rows=next_actions(self.index);self.assertEqual(rows[0]['id'],self.paper['id']);self.assertEqual(rows[0]['reason'],'Manually pinned')
  self.update(self.paper,pin=False,manual_priority='high')
  self.assertEqual(next_actions(self.index)[0]['reason'],'Learner-selected high priority')
  self.update(self.paper,manual_priority='quiet')
  self.assertNotIn(self.paper['id'],[row['id'] for row in next_actions(self.index)])
  self.assertEqual(today(self.index,self.paper['id'])['continue']['id'],self.paper['id'])
  self.assertNotEqual(self.index.record(self.paper['id'])['state'].get('status'),'complete')
  self.index.close();self.index=Index(self.root,Path(self.temp.name)/'fresh-cache');self.index.reconcile()
  self.assertEqual(self.index.record(self.paper['id'])['state']['manual_priority'],'quiet')
  self.assertIn(event['id'],[row['id'] for row in self.index.timeline(self.paper['id'])])
 def test_completed_and_consumed_work_stays_excluded_and_inputs_validated(self):
  self.update(self.paper,pin=True,status='read',manual_priority='high')
  self.assertNotIn(self.paper['id'],[row['id'] for row in next_actions(self.index)])
  self.assertNotEqual((today(self.index,self.paper['id'])['continue'] or {}).get('id'),self.paper['id'])
  self.update(self.run,pin=True,status='complete',manual_priority='high')
  self.assertNotIn(self.run['id'],[row['id'] for row in next_actions(self.index)])
  for state in ({'pin':1},{'manual_priority':'automatic'}):
   with self.assertRaises(ValueError):self.update(self.run,**state)
  with self.assertRaises(ValueError):record_activity(self.root,self.run['path'],'study',state={'pin':True})
