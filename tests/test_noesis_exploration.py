import json, sys, tempfile, unittest, uuid
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.persistence import migration
from noesis.models import create
from noesis.exploration import prepare, run, reconnect, local_file
from noesis.activities import operation_status

class Exploration(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name);(self.root/'System').mkdir();(self.root/'System/System.json').write_text(json.dumps({'directories':['Notes']}));migration(self.root,True);self.origin=create(self.root,'question','Why does the mechanism fail?')
 def tearDown(self):self.tmp.cleanup()
 def op(self):return str(uuid.uuid4())
 def test_canvas_origin_and_retry(self):
  operation=self.op();a=prepare(self.root,self.origin['id'],'Mechanism','canvas',operation);b=prepare(self.root,self.origin['id'],'Mechanism','canvas',operation)
  self.assertEqual(a['id'],b['id']);self.assertEqual(a['origin_ref']['record_id'],self.origin['id']);canvas=json.loads((self.root/a['local_file']).read_text());self.assertIn(self.origin['path'],canvas['nodes'][0]['text']);self.assertNotIn('file',canvas['nodes'][0]);self.assertEqual(operation_status(self.root,operation)['status'],'committed')
 def test_unavailable_editor_preserves_scratch(self):
  from noesis.exploration import open_code
  record=prepare(self.root,self.origin['id'],'Code retained','scratch',self.op());file=self.root/record['local_file'];before=file.read_bytes()
  with patch('noesis.exploration.shutil.which',return_value=None):
   with self.assertRaisesRegex(ValueError,'Neovim is unavailable'):open_code(self.root,record['id'])
  self.assertEqual(file.read_bytes(),before)

 def test_actual_success_failure_and_no_replay(self):
  scratch=prepare(self.root,self.origin['id'],'Numerical check','scratch',self.op());file=self.root/scratch['local_file'];self.assertNotIn('print(',file.read_text());file.write_text('print(2 ** 5)\n');op=self.op();result=run(self.root,scratch['id'],op);self.assertEqual(result['observed']['exit_code'],0);self.assertFalse(result['learner_achievement']);output=list(file.parent.glob('runs/*/stdout.txt'))[0];self.assertEqual(output.read_text().strip(),'32')
  with self.assertRaisesRegex(ValueError,'already started'):run(self.root,scratch['id'],op)
  file.write_text('raise ValueError("agent validation failure")\n');result=run(self.root,scratch['id'],self.op());self.assertEqual(result['observed']['exit_code'],1);self.assertTrue(any('agent validation failure' in p.read_text() for p in file.parent.glob('runs/*/stderr.txt')))
 def test_missing_reconnect_retains_id(self):
  a=prepare(self.root,self.origin['id'],'Map','canvas',self.op());file=self.root/a['local_file'];moved=file.with_name('renamed.canvas');file.rename(moved)
  with self.assertRaisesRegex(ValueError,'missing'):local_file(self.root,a['id'])
  reconnect(self.root,a['id'],str(moved.relative_to(self.root)),'Renamed map',self.op());record,actual=local_file(self.root,a['id']);self.assertEqual(actual,moved);self.assertEqual(record['props']['id'],a['id']);self.assertEqual(record['props']['title'],'Renamed map')
  with self.assertRaises(ValueError):reconnect(self.root,a['id'],'../other.canvas','Bad',self.op())
 def test_no_plugin_install_and_wrong_origin(self):
  with self.assertRaisesRegex(ValueError,'Obsidian vault'):prepare(self.root,self.origin['id'],'Freehand','freehand',self.op())
  with self.assertRaises(ValueError):prepare(self.root,self.op(),'Missing','canvas',self.op())

 def test_partial_canvas_can_recover_without_repeating_external_creation(self):
  from noesis.exploration import reserve, recover
  op=self.op();request={'action':'prepare','origin':self.origin['id'],'title':'Recoverable map','mode':'canvas','prediction':'','code_file':None};reserve(self.root,op,request)
  file=self.root/'Explorations'/op/'map.canvas';file.parent.mkdir(parents=True);file.write_text('{"nodes":[],"edges":[]}')
  record=recover(self.root,op);self.assertEqual(record['title'],'Recoverable map');self.assertEqual(operation_status(self.root,op)['status'],'committed')
  missing=self.op();reserve(self.root,missing,dict(request,title='Missing map'))
  with self.assertRaisesRegex(ValueError,'will not repeat'):recover(self.root,missing)

 def test_existing_non_git_code_and_prediction(self):
  file=self.root/'existing.py';file.write_text('print("independently created file")\n')
  record=prepare(self.root,self.origin['id'],'Existing code','scratch',self.op(),prediction='I expect one line',code_file=str(file))
  result=run(self.root,record['id'],self.op());self.assertEqual(result['execution']['prediction'],'I expect one line');self.assertEqual(result['execution']['cwd'],str(self.root));self.assertEqual(result['observed']['exit_code'],0);self.assertEqual(file.read_text(),'print("independently created file")\n')
 def test_unfinished_capture_is_visible_without_a_verdict(self):
  from noesis.experiments import context
  from noesis.index import Index
  record=prepare(self.root,self.origin['id'],'Interrupted check','scratch',self.op());folder=self.root/'.Noesis/Executions';(folder/(self.op()+'.json')).write_text(json.dumps({'record_id':record['id'],'status':'started','started_at':'2026-10-11T00:00:00Z'}))
  index=Index(self.root)
  try:
   index.reconcile();view=context(index,index.record(record['id']));self.assertEqual(len(view['unfinished_executions']),1);self.assertEqual(view['comparison_count'],0)
  finally:index.close()

 def test_native_rename_lost_acknowledgement_confirms_bytes_without_replay(self):
  import subprocess
  a=prepare(self.root,self.origin['id'],'Map','canvas',self.op());old=self.root/a['local_file'];calls=[]
  def lost_ack(root,command,*args):
   calls.append(command);destination=root/next(arg[3:] for arg in args if arg.startswith('to='));old.rename(destination);raise subprocess.TimeoutExpired('obsidian',20)
  op=self.op();reconnect(self.root,a['id'],a['local_file'],'Renamed',op,lost_ack)
  record,file=local_file(self.root,a['id']);self.assertEqual(file.name,'Renamed.canvas');self.assertEqual(calls,['move']);self.assertEqual(operation_status(self.root,op)['status'],'committed')
  collision=file.with_name('Existing.canvas');collision.write_text('{}');op=self.op()
  with self.assertRaisesRegex(ValueError,'already uses'):reconnect(self.root,a['id'],record['props']['local_file'],'Existing',op,lost_ack)
  self.assertEqual(operation_status(self.root,op)['status'],'not-committed');self.assertEqual(calls,['move'])

 def test_code_removed_during_run_preserves_output_and_identity_uncertainty(self):
  record=prepare(self.root,self.origin['id'],'Self-removing check','scratch',self.op());file=self.root/record['local_file'];file.write_text('from pathlib import Path\nPath(__file__).unlink()\nprint("completed before file removal")\n')
  result=run(self.root,record['id'],self.op());self.assertEqual(result['observed']['exit_code'],0);self.assertTrue(result['execution']['code_changed']);self.assertTrue(result['execution']['code_unavailable_after_run']);self.assertTrue(list(file.parent.glob('runs/*/code.py')))
