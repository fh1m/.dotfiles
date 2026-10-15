import json,sys,tempfile,unittest,uuid,shutil,os,subprocess
from pathlib import Path
from unittest.mock import patch
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.persistence import migration
from noesis.models import create
from noesis.activities import record_activity
from noesis.index import Index
from noesis.readers import resource_props,command
from noesis.views import overview

class Materials(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.home=Path(self.temp.name)
  self.patch=patch('pathlib.Path.home',return_value=self.home);self.patch.start()
  self.root=self.home/'vault';(self.root/'System').mkdir(parents=True)
  (self.root/'System/System.json').write_text(json.dumps({'layout':'network'}));migration(self.root,True)
  self.course=create(self.root,'resource','Textbook',fields={'source_kind':'book','local_file':'book.pdf','edition':'First edition'})
  (self.root/'book.pdf').write_bytes(b'disposable document')
  self.lesson=create(self.root,'unit','Chapter 3',fields={'unit_kind':'chapter'},parent_id=self.course['id'])
 def tearDown(self):self.patch.stop();self.temp.cleanup()
 def index(self):
  index=Index(self.root);self.addCleanup(index.close);index.reconcile();return index
 def replace(self,head=None,operation=None,**extra):
  return record_activity(self.root,self.lesson['path'],'material-change','A clearer explanation of the same chapter.',operation_id=operation,
   expected_head=head,material=extra or {'source_kind':'video','source':'https://www.youtube.com/watch?v=synthetic'},expected_id=self.lesson['id'])
 def test_replacement_retains_history_and_resets_consumption_then_survives_move_and_cache_loss(self):
  originals={row['path']:(self.root/row['path']).read_bytes() for row in (self.lesson,self.course)}
  old=record_activity(self.root,self.lesson['path'],'study',state={'status':'read','locator':{'kind':'page','value':17}})
  operation=str(uuid.uuid4());changed=self.replace(old['id'],operation)
  self.assertEqual(self.replace(old['id'],operation)['id'],changed['id'])
  self.assertEqual(changed['source_snapshot']['local_file'],'book.pdf')
  self.assertEqual(changed['source_snapshot']['edition'],'First edition')
  self.assertEqual(changed['source_snapshot']['record_ref']['record_id'],self.course['id'])
  self.assertEqual(changed['previous_position']['locator']['value'],17)
  index=self.index();record=index.record(self.lesson['id'])
  self.assertIsNone(record['state']['locator']);self.assertEqual(record['state']['status'],'queued')
  self.assertIsNone(record['effective_source']['local_file']);self.assertEqual(record['effective_source']['source_kind'],'video')
  self.assertEqual(overview(index,self.course['id'])['counts']['other_units']['consumed'],0)
  studied=record_activity(self.root,self.lesson['path'],'study',state={'locator':{'kind':'timestamp','value':'12:34'}})
  self.assertEqual(studied['material_revision'],changed['id']);self.assertIn('youtube',studied['source_snapshot']['source'])
  self.assertNotIn('local_file',studied['source_snapshot'])
  (self.root/self.lesson['path']).rename(self.root/'moved chapter.md')
  index.close();shutil.rmtree(self.home/'.cache/noesis')
  rebuilt=self.index();record=rebuilt.record(self.lesson['id'])
  self.assertEqual(record['path'],'moved chapter.md')
  self.assertIn('t=754s',command(self.root,resource_props(rebuilt,self.lesson['id']),record['state'])[1])
  self.assertEqual(len(rebuilt.timeline(self.lesson['id'])),3)
  self.assertEqual((self.root/'moved chapter.md').read_bytes(),originals[self.lesson['path']])
  self.assertEqual((self.root/self.course['path']).read_bytes(),originals[self.course['path']])
 def test_attempt_source_is_preserved_and_unfinished_work_blocks_replacement(self):
  started=record_activity(self.root,self.lesson['path'],'attempt-start',mode='derive')
  self.assertEqual(started['source_snapshot']['edition'],'First edition')
  with self.assertRaisesRegex(ValueError,'unfinished attempt'):self.replace()
  result=record_activity(self.root,self.lesson['path'],'attempt','An independent reconstruction failed',attempt_id=started['id'],outcome='failed',assistance=['none'])
  self.assertEqual(result['source_snapshot'],started['source_snapshot'])
  changed=self.replace()
  retry=record_activity(self.root,self.lesson['path'],'attempt-start',mode='derive')
  self.assertEqual(retry['material_revision'],changed['id'])
  self.assertNotIn('edition',retry['source_snapshot'])
  self.assertEqual(self.index().timeline(self.lesson['id'])[1]['source_snapshot']['edition'],'First edition')
 def test_stale_invalid_and_missing_material_never_commits(self):
  old=record_activity(self.root,self.lesson['path'],'study',state={'position':'page 9'})
  for data in ({'source_kind':'video','source':'javascript:bad'}, {'source_kind':'pdf','local_file':'../outside.pdf'},
   {'source_kind':'video','source':'https://user:secret@example.com'}, {'source_kind':'pdf','local_file':'missing.pdf'},
   {'source_kind':'video','source':'https://example.com','local_file':'book.pdf'}):
   with self.assertRaises(ValueError):self.replace(old['id'],**data)
  with self.assertRaisesRegex(ValueError,'concurrently'):self.replace()
  with self.assertRaisesRegex(ValueError,'Explain why'):record_activity(self.root,self.lesson['path'],'material-change','',material={'source_kind':'pdf','local_file':'book.pdf'},expected_head=old['id'])
  task=create(self.root,'task','Assignment')
  with self.assertRaises(ValueError):record_activity(self.root,task['path'],'material-change','Changed assignment',material={'source_kind':'pdf','local_file':'book.pdf'},expected_head=None)
  self.assertEqual(len(self.index().timeline(self.lesson['id'])),1)
 def test_interrupted_publication_retry_and_competing_changes(self):
  import noesis.activities as module
  original=module.publish;operation=str(uuid.uuid4())
  def interrupted(path,text,*args):
   original(path,text,*args);raise OSError('Injected interruption after atomic publication')
  with patch.object(module,'publish',side_effect=interrupted):
   with self.assertRaises(OSError):self.replace(operation=operation)
  committed=self.replace(operation=operation)
  self.assertEqual(len(self.index().timeline(self.lesson['id'])),1)
  def competing(number):
   try:return self.replace(committed['id'],source_kind='video',source='https://example.com/lesson'+str(number))
   except ValueError as error:return str(error)
  with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(competing,(1,2)))
  self.assertEqual(sum(isinstance(result,dict) for result in results),1)
  self.assertEqual(sum(isinstance(result,str) and 'concurrently' in result for result in results),1)
  self.assertEqual(len(self.index().timeline(self.lesson['id'])),2)
 def test_cli_replacement_captures_owner_and_refuses_stale_target(self):
  executable=Path(__file__).resolve().parents[1]/'home/.local/bin/sensei-learn'
  args=[sys.executable,str(executable),'event','--vault',str(self.root),self.lesson['path'],'material-change',
   '--target-id',self.lesson['id'],'--evidence','Clearer source','--data',json.dumps({'material':{'source_kind':'pdf','local_file':'book.pdf'},'expected_head':None})]
  result=subprocess.run(args,env=dict(os.environ,HOME=str(self.home)),text=True,capture_output=True)
  self.assertEqual(result.returncode,0,result.stderr)
  receipt=json.loads(result.stdout);self.assertEqual(receipt['target']['record_id'],self.lesson['id'])
  args[args.index('--target-id')+1]=str(uuid.uuid4())
  refused=subprocess.run(args,env=dict(os.environ,HOME=str(self.home)),text=True,capture_output=True)
  self.assertNotEqual(refused.returncode,0);self.assertIn('identity changed',refused.stderr)
  self.assertEqual(len(self.index().timeline(self.lesson['id'])),1)
 def test_failed_publication_preserves_old_source_and_resume_state(self):
  old=record_activity(self.root,self.lesson['path'],'study',state={'locator':{'kind':'page','value':17}})
  operation=str(uuid.uuid4())
  with patch('noesis.activities.publish',side_effect=OSError('Injected before publication')):
   with self.assertRaises(OSError):self.replace(old['id'],operation)
  index=self.index();record=index.record(self.lesson['id'])
  self.assertEqual(record['state']['locator']['value'],17)
  self.assertEqual(resource_props(index,self.lesson['id'])['local_file'],'book.pdf')
  self.assertEqual(len(index.timeline(self.lesson['id'])),1)
  committed=self.replace(old['id'],operation)
  self.assertEqual(committed['previous'],old['id'])
  self.assertEqual(len(self.index().timeline(self.lesson['id'])),2)
 def test_reader_does_not_inherit_foreign_parent_with_colliding_local_uuid(self):
  orphan=create(self.root,'unit','Unlinked chapter',fields={'unit_kind':'chapter'})
  vault=self.index().manifest['vault_id'];foreign=str(uuid.uuid4())
  create(self.root,'relationship','Foreign containment',fields={'source':self.course['id'],'target':orphan['id'],'relation':'contains',
   'source_ref':{'vault_id':foreign,'record_id':self.course['id']},'target_ref':{'vault_id':vault,'record_id':orphan['id']}})
  self.assertNotIn('local_file',resource_props(self.index(),orphan['id']))
