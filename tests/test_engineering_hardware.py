import importlib.machinery,importlib.util,json,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
loader=importlib.machinery.SourceFileLoader('passports',str(ROOT/'home/.local/bin/sensei-hardware'));spec=importlib.util.spec_from_loader(loader.name,loader);hw=importlib.util.module_from_spec(spec);loader.exec_module(hw)
class Passports(unittest.TestCase):
 def inventory(self,nodes,properties):
  profile={'id':'imu','match':{'ID_SERIAL_SHORT':'known','ID_VENDOR_ID':'1234'}}
  with patch.object(hw.e,'read',return_value={'devices':[profile]}),patch.object(hw.Path,'glob',side_effect=lambda pattern:nodes if pattern=='ttyACM*' else []),patch.object(hw,'properties',side_effect=lambda node:properties[str(node)]):return hw.inventory()['devices'][0]
 def test_same_identity_follows_new_node(self):
  for node in ['/dev/ttyACM0','/dev/ttyACM4']:
   row=self.inventory([Path(node)],{node:{'ID_SERIAL_SHORT':'known','ID_VENDOR_ID':'1234'}})
   self.assertTrue(row['connected']);self.assertEqual(row['nodes'][0]['node'],node)
 def test_duplicate_identity_is_ambiguous_not_connected(self):
  nodes=[Path('/dev/ttyACM0'),Path('/dev/ttyACM1')];row=self.inventory(nodes,{str(n):{'ID_SERIAL_SHORT':'known','ID_VENDOR_ID':'1234'} for n in nodes})
  self.assertTrue(row['ambiguous']);self.assertFalse(row['connected'])
 def test_other_vendor_does_not_match_same_serial(self):
  row=self.inventory([Path('/dev/ttyACM0')],{'/dev/ttyACM0':{'ID_SERIAL_SHORT':'known','ID_VENDOR_ID':'ffff'}})
  self.assertFalse(row['connected']);self.assertFalse(row['nodes'])
