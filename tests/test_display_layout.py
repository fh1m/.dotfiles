import importlib.util,sys,unittest
from pathlib import Path
base=Path(__file__).resolve().parents[1]/'home/.local/share/sensei';sys.path.insert(0,str(base));import display_layout as d
class DisplayLayout(unittest.TestCase):
 def setUp(self):
  self.actual=[dict(name='TEST',width=1920,height=1080,refreshRate=60,availableModes=['1920x1080@60.00Hz'])];self.plan=d.snapshot(self.actual)
 def test_valid_snapshot(self):self.assertEqual(d.validate(self.plan,self.actual),self.plan)
 def test_disabling_last_output_rejected(self):
  self.plan[0]['enabled']=False
  with self.assertRaises(ValueError):d.validate(self.plan,self.actual)
 def test_injected_mode_or_name_rejected(self):
  self.plan[0]['mode']='1920x1080; rm -rf x'
  with self.assertRaises(ValueError):d.validate(self.plan,self.actual)
 def test_topology_change_rejected(self):
  with self.assertRaises(ValueError):d.validate(self.plan,[])
 def test_code_generation_quotes_names(self):self.assertIn('"TEST"',d.expression(self.plan[0]))
 def test_invalid_scale_rejected(self):
  self.plan[0]['scale']=float('nan')
  with self.assertRaises(ValueError):d.validate(self.plan,self.actual)

class TransactionSafety(unittest.TestCase):
 def setUp(self):
  import tempfile,os
  from unittest.mock import patch
  self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.home=Path(self.tmp.name)
  self.env=patch.dict(os.environ,{'SENSEI_ENGINEERING_HOME':str(self.home)});self.env.start();self.addCleanup(self.env.stop)
  self.actual=[dict(name='TEST',width=1920,height=1080,refreshRate=60,availableModes=['1920x1080@60.00Hz'])]
 def test_rollback_is_armed_before_applying(self):
  from unittest.mock import patch,Mock
  sequence=[]
  def arm(*a,**k):sequence.append('armed');return Mock(returncode=0)
  with patch.object(d,'outputs',return_value=self.actual),patch.object(d.subprocess,'run',side_effect=arm),patch.object(d,'apply_rows',side_effect=lambda rows:sequence.append('applied')):
   result=d.begin(d.snapshot(self.actual),Path('/owned/helper'));self.assertTrue(result['token'])
  self.assertEqual(sequence,['armed','applied'])
 def test_failed_watchdog_does_not_touch_outputs(self):
  from unittest.mock import patch,Mock
  with patch.object(d,'outputs',return_value=self.actual),patch.object(d.subprocess,'run',return_value=Mock(returncode=1)),patch.object(d,'apply_rows') as apply:
   with self.assertRaises(ValueError):d.begin(d.snapshot(self.actual),Path('/owned/helper'))
   apply.assert_not_called()
 def test_expired_confirmation_cannot_persist(self):
  d.save(d.state()/'display-pending.json',{'token':'owned','expires':0})
  with self.assertRaises(ValueError):d.confirm('owned')
  self.assertFalse((self.home/'.config/hypr/monitors-user.lua').exists())
