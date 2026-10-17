import importlib.util,sys,unittest,runpy,subprocess,json
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'home/.local/share/sensei'))
import den_geometry as g
import network_audit as network
class Geometry(unittest.TestCase):
 def test_half_width_overlap(self):self.assertEqual(g.ranges(g.DEFAULT,(0,0,1920,1080)),{'top':(.5,1.0),'bottom':(0.0,.5)})
 def test_non_adjacent_has_no_capture(self):self.assertEqual(g.ranges(dict(version=1,homie=dict(g.DEFAULT['homie'],y=-1400)),(0,0,1920,1080)),{})
 def test_roundtrip(self):
  for x in (960,1200,1800):self.assertEqual(g.return_coordinate(g.DEFAULT,g.enter_ratio(g.DEFAULT,x,'x')*1920,'x'),x)
 def test_reject_invalid_geometry(self):
  for x in (float('nan'),True,999999,'960'):
   with self.assertRaises(ValueError):g.validate(dict(version=1,homie=dict(g.DEFAULT['homie'],x=x)))
class Voice(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.v=runpy.run_path(str(ROOT/'home/.local/bin/sensei-voice'))
 def test_empty_audio_is_not_success(self):
  with self.assertRaises(ValueError):self.v['metrics'](b'')
 def test_silence_and_clipping_are_distinct(self):
  import array
  silent=self.v['metrics'](array.array('f',[0.0]*480).tobytes());clipped=self.v['metrics'](array.array('f',[1.0]*480).tobytes())
  self.assertFalse(silent['signalDetected']);self.assertEqual(clipped['clippedPercent'],100)
 def test_muted_source_rejected(self):
  with patch.dict(self.v['source'].__globals__,doctor=lambda:{'default':'mic','sources':[{'name':'mic','muted':True}]}):
   with self.assertRaises(ValueError):self.v['source']()
class Network(unittest.TestCase):
 def test_malformed_report_is_recoverable(self):
  with patch.object(network,'scope',return_value='192.168.0.0/24'),patch.object(network,'command',return_value='<incomplete'):
   with self.assertRaisesRegex(ValueError,'incomplete'):network.scan('eth0')
class Games(unittest.TestCase):
 def test_rules(self):
  js=ROOT/'home/.config/quickshell/sensei/modules/dropdowns/ZondoGames.js'
  script="const vm=require('vm'),fs=require('fs'),assert=require('assert');let c={};vm.createContext(c);vm.runInContext(fs.readFileSync(process.argv[1],'utf8'),c);assert.equal(c.rps('rock','scissors'),'win');assert.equal(c.rps('paper','scissors'),'loss');assert.equal(c.winner(['X','X','X','','','','','','']),'X');let b=c.reply(['X','X','','O','','','','','']);assert.equal(b[2],'O');assert.equal(b.filter(x=>x==='O').length,2);"
  subprocess.run(['node','-e',script,str(js)],check=True)
if __name__=='__main__':unittest.main()
