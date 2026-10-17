import importlib.util,json,os,tempfile,time,unittest
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('engineering',ROOT/'home/.local/share/sensei/engineering.py');e=importlib.util.module_from_spec(spec);spec.loader.exec_module(e)
class Engineering(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.h=Path(self.tmp.name)
  self.env=patch.dict(os.environ,{'SENSEI_ENGINEERING_HOME':str(self.h)});self.env.start();self.addCleanup(self.env.stop)
  self.root=self.h/'project';self.root.mkdir();self.task={'argv':['python3','-c','print(1)'],'inputs':[],'artifacts':[]}
  self.p={'id':'test','locations':{e.machine():str(self.root)},'tasks':{'check':self.task},'trusted_tasks':{'check':e.fingerprint(self.task)}}
  self.write()
 def write(self):e.save(e.config()/'projects.json',{'version':1,'projects':[self.p]})
 def test_queries_need_no_confirmation(self):self.assertTrue(e.invoke('project.preflight',{'project':'test'})['ok'])
 def test_unknown_action_and_unexpected_params_rejected(self):
  for action,params in [('shell.run',{}),('jobs.list',{'command':'rm'})]:
   with self.assertRaises(ValueError):e.prepare(action,params)
 def test_execution_requires_prepare(self):
  with self.assertRaises(ValueError):e.invoke('job.launch',{'project':'test','task':'check'})
 def test_confirmation_is_one_use(self):
  params={'project':'test','task':'check'};token=e.prepare('job.launch',params)['confirmation']
  with patch.object(e,'command',return_value={'id':'owned'}):self.assertEqual(e.invoke('job.launch',params,token)['id'],'owned')
  with self.assertRaises(ValueError):e.invoke('job.launch',params,token)
 def test_changed_task_invalidates_confirmation(self):
  params={'project':'test','task':'check'};token=e.prepare('job.launch',params)['confirmation']
  self.task['argv']=['false'];self.write()
  with self.assertRaises(ValueError):e.invoke('job.launch',params,token)
 def test_expired_confirmation_rejected(self):
  params={'project':'test','task':'check'};token=e.prepare('job.launch',params)['confirmation'];p=e.state()/'confirmations'/f'{token}.json';row=e.read(p);row['expires']=0;e.save(p,row)
  with self.assertRaises(ValueError):e.invoke('job.launch',params,token)
 def test_receipt_dedup_and_bound(self):
  first=e.receipt('job.done',{'outcome':'failed'});e.receipt('job.done',{},event_id=first['id'])
  self.assertEqual(len(e.read(e.state()/'receipts.json')['events']),1)
  for _ in range(135):e.receipt('job.done',{})
  self.assertEqual(len(e.read(e.state()/'receipts.json')['events']),128)
 def test_no_environment_values_in_preflight(self):
  self.p['required_environment']=['PRIVATE_TEST'];self.write()
  with patch.dict(os.environ,{'PRIVATE_TEST':'secret-value'}):self.assertNotIn('secret-value',json.dumps(e.preflight(self.p)))
 def test_relative_path_validation(self):
  for value in ('../secret','/etc/passwd','foo/../../x'):
   with self.assertRaises(ValueError):e.safe_relative(value)
 def test_duplicate_project_identity_rejected(self):
  e.save(e.config()/'projects.json',{'version':1,'projects':[self.p,self.p]})
  with self.assertRaises(ValueError):e.projects()
