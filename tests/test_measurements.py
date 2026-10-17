import importlib.util,unittest
from pathlib import Path
p=Path(__file__).resolve().parents[1]/'home/.local/share/sensei/measurements.py';s=importlib.util.spec_from_file_location('measurements',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
class Measurements(unittest.TestCase):
 def test_units_are_not_silently_compared(self):self.assertEqual(m.compare([dict(name='error',value=1,unit='m')],[dict(name='error',value=10,unit='cm')])[0]['state'],'incompatible-units')
 def test_no_baseline_is_not_success(self):self.assertEqual(m.compare([dict(name='error',value=1,unit='m')],[])[0]['state'],'missing-baseline')
 def test_delta_does_not_imply_better(self):self.assertEqual(m.compare([dict(name='error',value=1,unit='m')],[dict(name='error',value=2,unit='m')])[0]['delta'],-1)
 def test_nonfinite_and_ambiguous_values_rejected(self):
  for value in (float('nan'),float('inf'),True,'1'):
   with self.assertRaises(ValueError):m.validate([dict(name='a',value=value,unit='m')])
 def test_duplicates_rejected(self):
  with self.assertRaises(ValueError):m.validate([dict(name='a',value=1,unit='m')]*2)
