import array, runpy, unittest
from pathlib import Path
from unittest.mock import patch
v=runpy.run_path(str(Path(__file__).resolve().parents[1]/"home/.local/bin/sensei-voice"))
class Voice(unittest.TestCase):
 def test_route_preserves_monitor_and_mute(self):
  data={"default":"usb","sources":[{"index":63,"name":"usb","label":"USB"},{"index":70,"name":"builtin"}],"streams":[{"index":1,"sourceIndex":70,"muted":True},{"index":2,"sourceIndex":69,"muted":False}]}
  with patch.dict(v["route_default"].__globals__,doctor=lambda:data,call=lambda *args:calls.append(args)):
   calls=[];result=v["route_default"]()
  self.assertEqual(calls,[("move-source-output","1","usb")]);self.assertEqual(result["routed"],1)
 def test_clipping_is_measured(self):
  result=v["metrics"](array.array("f",[0.0,1.0,-1.0,0.5]).tobytes())
  self.assertEqual(result["clippedPercent"],50.0);self.assertTrue(result["signalDetected"])
 def test_dc_offset_is_not_speech(self):
  result=v["metrics"](array.array("f",[0.06]*4800).tobytes())
  self.assertFalse(result["signalDetected"]);self.assertTrue(result["dcOffsetWarning"])
  self.assertLess(result["acRmsDbFS"],-100)
 def test_silence_is_not_success(self):
  self.assertFalse(v["metrics"](array.array("f",[0.0]*100).tobytes())["signalDetected"])
if __name__=="__main__":unittest.main()
