import unittest,tempfile,sys,uuid
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.planning import Planner
class Planning(unittest.TestCase):
 def test_disconnected_is_actionable_not_error(self):
  with tempfile.TemporaryDirectory() as d:
   p=Planner(Path(d));self.assertEqual(p.status()['connection'],'needs_connection')
 def test_offline_queue_is_durable_idempotent_and_not_mastery(self):
  with tempfile.TemporaryDirectory() as d:
   p=Planner(Path(d));op=str(uuid.uuid4());row=p.enqueue('Tasks','Read chapter',{'Area':'Explore'},op);p.enqueue('Tasks','Read chapter',{'Area':'Explore'},op)
   self.assertEqual(len(p.pending()),1);self.assertFalse(row['competence_awarded']);self.assertEqual(len(Planner(Path(d)).pending()),1)
   with self.assertRaises(ValueError):p.enqueue('Tasks','Changed',{},op)
 def test_remote_conflict_keeps_pending(self):
  with tempfile.TemporaryDirectory() as d:
   p=Planner(Path(d));p.enqueue('Tasks','Read chapter',{},str(uuid.uuid4()),remote_id='remote',base_revision='old')
   p.api=lambda method,path,body=None:{'id':'remote','last_edited_time':'new'}
   result=p.sync();self.assertEqual(result['conflicts'],1);self.assertEqual(len(p.pending()),1)

 def test_update_preserves_remote_identity(self):
  with tempfile.TemporaryDirectory() as d:
   p=Planner(Path(d));row=p.enqueue('Tasks','Revised',{},str(uuid.uuid4()),remote_id='existing',base_revision='revision')
   self.assertNotIn('Noesis ID',p.properties(row))
 def test_unknown_state_rejected(self):
  with tempfile.TemporaryDirectory() as d:
   with self.assertRaises(ValueError):Planner(Path(d)).enqueue('Tasks','Task',{'State':'Mastered'},str(uuid.uuid4()))

 def test_fresh_setup_has_collection_map(self):
  with tempfile.TemporaryDirectory() as d:
   p=Planner(Path(d));p.save(p.config,{'token':'test','parent_id':str(uuid.uuid4())})
   def api(method,path,body=None):
    if path.startswith('blocks/'):return {'results':[]}
    if path=='pages':return {'id':'root','url':'https://www.notion.so/root'}
    if path=='databases':return {'id':str(uuid.uuid4()),'data_sources':[{'id':str(uuid.uuid4())}]}
    raise AssertionError(path)
   p.api=api;self.assertEqual(len(p.setup()['collections']),5)

 def test_partial_scheduled_cache_is_visible(self):
  import importlib.util,json
  spec=importlib.util.spec_from_file_location('agenda_planning',Path(__file__).resolve().parents[1]/'home/.local/share/sensei/agenda.py');agenda=importlib.util.module_from_spec(spec);spec.loader.exec_module(agenda)
  with tempfile.TemporaryDirectory() as d:
   p=Planner(Path(d));p.save(p.root/'cache.json',{'records':[{'id':'record','properties':{'When':{'date':{'start':'2026-10-27'}},'State':{'select':None},'Area':{'select':None},'Title':{'title':[{'plain_text':'Study'}]}}}]})
   rows=agenda.planning(Path(d));self.assertEqual(len(rows),1);self.assertEqual(rows[0]['category'],'Planning')
