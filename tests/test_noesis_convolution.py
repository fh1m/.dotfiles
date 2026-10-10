import json, sys, tempfile, unittest, uuid
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"scripts"))
from noesis_authored_examples import CONVOLUTION
from noesis import convolution as c
from noesis.activities import record_activity,operation_status
from noesis.models import create
from noesis.persistence import migration

class Convolution(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.home=Path(self.tmp.name);self.p=patch('pathlib.Path.home',return_value=self.home);self.p.start();self.root=self.home/'vault';(self.root/'System').mkdir(parents=True);(self.root/'System/System.json').write_text(json.dumps({'directories':['Notes']}));migration(self.root,True);self.concept=create(self.root,'concept','Convolution')
  self.config={'signal':[1,2,3],'kernel':[2,1,-1],'boundary':'zero','stride':1,'convention':'convolution'}
 def tearDown(self):self.p.stop();self.tmp.cleanup()
 def test_boundaries_reversal_and_stride(self):
  self.assertEqual(c.calculate(self.config)['outputs'],[5,7,1]);self.assertEqual(c.calculate(dict(self.config,boundary='edge'))['outputs'],[4,7,7]);self.assertEqual(c.calculate(dict(self.config,convention='correlation'))['outputs'],[-1,1,7]);self.assertEqual(c.calculate(dict(self.config,stride=2))['outputs'],[5,1])
 def test_starter_is_unaided(self):
  self.assertIn("NotImplementedError",c.TEMPLATE)
  self.assertNotIn("weights =",c.TEMPLATE)
 def test_invalid_inputs(self):
  for change in ({'kernel':[1,2]},{'stride':True},{'signal':[1,2,float('nan')]},{'boundary':'reflect'},{'kernel':[1000]}):
   with self.assertRaises(ValueError):c.calculate(dict(self.config,**change))
 def test_prediction_receipt_and_protected_parent(self):
  op=str(uuid.uuid4());a=c.observe(self.root,self.concept['id'],self.config,'I predict 0 at the edge',op);self.assertEqual(a['prediction'],'I predict 0 at the edge');self.assertFalse(a['learner_achievement']);self.assertEqual(c.observe(self.root,self.concept['id'],self.config,'I predict 0 at the edge',op)['id'],a['id'])
  build=c.prepare(self.root,self.concept['id'],self.config,'Predict matched conventions',str(uuid.uuid4()));record_activity(self.root,self.concept['path'],'attempt-start',assistance=['none'])
  with self.assertRaisesRegex(ValueError,'protected'):c.check(self.root,build['id'],self.config,'Predict match',str(uuid.uuid4()))
 def test_execution_is_actual_and_never_replays(self):
  build_op=str(uuid.uuid4());build=c.prepare(self.root,self.concept['id'],self.config,'Predict matched conventions',build_op);self.assertEqual(c.prepare(self.root,self.concept['id'],self.config,'Predict matched conventions',build_op)['id'],build['id']);script=Path(build["repository"])/"convolution.py";script.write_text(CONVOLUTION);
  import subprocess
  subprocess.run(["git","-C",build["repository"],"add","convolution.py"],check=True);subprocess.run(["git","-C",build["repository"],"-c","user.name=Agent validation","-c","user.email=test@invalid.example","commit","-qm","Agent-authored reconstruction"],check=True);op=str(uuid.uuid4());a=c.check(self.root,build['id'],self.config,'Predict match',op);self.assertTrue(a['observed']['agrees']);self.assertEqual(a['observed']['actual'],[5,7,1]);self.assertEqual(a['observed']['oracle'],[5,7,1]);self.assertFalse(a['observed']['code_snapshot']['dirty']);self.assertEqual(operation_status(self.root,op)['status'],'committed')
  with self.assertRaisesRegex(ValueError,'already committed'):c.check(self.root,build['id'],self.config,'Predict match',op)
  script=Path(build['repository'])/'convolution.py';script.write_text('def convolve(*args): return [0,0,0]\n');a=c.check(self.root,build['id'],self.config,'Predict mismatch',str(uuid.uuid4()));self.assertFalse(a['observed']['agrees']);self.assertTrue(a['observed']['code_snapshot']['dirty'])
 def test_interrupted_reservation_stays_uncertain(self):
  from noesis.persistence import publish
  op=str(uuid.uuid4());publish(self.root/'.Noesis/Executions'/ (op+'.json'),json.dumps({'status':'started'}));self.assertEqual(operation_status(self.root,op)['status'],'uncertain')

 def test_failed_execution_keeps_prediction_and_revision(self):
  build=c.prepare(self.root,self.concept['id'],self.config,'Predict valid shape',str(uuid.uuid4()));script=Path(build['repository'])/'convolution.py';script.write_text('def convolve(*args): raise ValueError("example failure")\n');op=str(uuid.uuid4())
  with self.assertRaisesRegex(ValueError,'Implementation failed'):c.check(self.root,build['id'],self.config,'Predict failure separately',op)
  witness=json.loads((self.root/'.Noesis/Executions'/(op+'.json')).read_text());self.assertEqual(witness['prediction'],'Predict failure separately');self.assertEqual(witness['configuration'],self.config);self.assertTrue(witness['code_snapshot']['dirty']);self.assertEqual(operation_status(self.root,op)['status'],'not-committed')
 def test_build_replay_rejects_changed_request(self):
  op=str(uuid.uuid4());c.prepare(self.root,self.concept['id'],self.config,'Original prediction',op)
  with self.assertRaisesRegex(ValueError,'different request'):c.prepare(self.root,self.concept['id'],dict(self.config,stride=2),'Original prediction',op)
