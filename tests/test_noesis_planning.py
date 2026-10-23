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
   rows=agenda.planning(Path(d));self.assertEqual(len(rows),1);self.assertEqual(rows[0]['category'],'Planning');self.assertTrue(rows[0]['all_day'])

 def test_throttle_retries_bounded_and_honors_retry_after(self):
  import io,urllib.error
  from unittest.mock import patch
  with tempfile.TemporaryDirectory() as d:
   p=Planner(Path(d));p._token='fixture'
   error=urllib.error.HTTPError('https://api.notion.com',429,'limited',{'Retry-After':'2'},None)
   with patch('urllib.request.urlopen',side_effect=[error,io.BytesIO(b'{"ok":true}')]) as request,patch('time.sleep') as sleep:
    self.assertTrue(p.api('GET','users/me')['ok']);self.assertEqual(request.call_count,2);sleep.assert_called_once_with(2)
 def test_duplicate_retry_reuses_existing_remote_record(self):
  with tempfile.TemporaryDirectory() as d:
   p=Planner(Path(d));p.save(p.config,{'token':'fixture','collections':{'Tasks':{'source_id':'source'}}})
   p.enqueue('Tasks','Read',{'Area':'Explore'},str(uuid.uuid4()))
   p.query=lambda source,filters=None:[{'id':'existing','properties':{}}]
   def no_creation(*args):raise AssertionError('Duplicate remote creation')
   p.api=no_creation;result=p.sync();self.assertEqual(result['sent'],1);self.assertEqual(p.status()['pending'],0)
 def test_auth_expiration_preserves_offline_work(self):
  import urllib.error
  from unittest.mock import patch
  with tempfile.TemporaryDirectory() as d:
   p=Planner(Path(d));p._token='fixture';p.enqueue('Tasks','Read',{},str(uuid.uuid4()))
   with patch('urllib.request.urlopen',side_effect=urllib.error.HTTPError('https://api.notion.com',401,'expired',{},None)):
    with self.assertRaisesRegex(ValueError,'renewed authorization'):p.api('GET','users/me')
   self.assertEqual(len(p.pending()),1)

 def test_connector_snapshot_does_not_claim_desktop_authorization(self):
  with tempfile.TemporaryDirectory() as d:
   p=Planner(Path(d));p.save(p.root/'workspace.json',{'root_id':'workspace','collections':{}})
   p.save(p.root/'cache.json',{'source':'notion-connector','records':[{'id':'fixture','read_only':True}]})
   s=p.status();self.assertEqual(s['connection'],'workspace_ready');self.assertEqual(s['cache_source'],'notion-connector');self.assertTrue(s['records'][0]['read_only'])
