import json, runpy, unittest, tempfile
from pathlib import Path
from unittest.mock import patch
v=runpy.run_path(str(Path(__file__).resolve().parents[1]/"home/.local/bin/sensei-voice-effects"))
class VoiceEffects(unittest.TestCase):
 def test_screen_capture_is_never_selected(self):
  sources=[{"index":1,"name":"usb"},{"index":2,"name":"speaker.monitor"}]
  stream={"source":1,"properties":{"application.name":"vesktop"}}
  self.assertTrue(v["eligible"](stream,sources))
  stream["source"]=2;self.assertFalse(v["eligible"](stream,sources))
  stream["source"]=1;stream["properties"]["stream.capture.sink"]="true"
  self.assertFalse(v["eligible"](stream,sources))
 def test_unrelated_app_is_never_selected(self):
  self.assertFalse(v["eligible"]({"source":1,"properties":{"application.name":"recorder"}},[{"index":1,"name":"usb"}]))
 def test_restore_does_not_override_later_user_routing(self):
  with tempfile.TemporaryDirectory() as tmp:
   state=Path(tmp)/"receipt.json";state.write_text(json.dumps({"target":"effects","streams":[{"index":9,"original":"usb"}]}))
   sources=[{"index":1,"name":"usb"},{"index":2,"name":"effects"},{"index":3,"name":"other"}]
   streams=[{"index":9,"source":3,"properties":{"application.name":"vesktop"}}]
   calls=[]
   with patch.dict(v["disable"].__globals__,STATE=state,items=lambda k:sources if k=="sources" else streams,run=lambda *a:calls.append(a)):
    result=v["disable"]()
   self.assertEqual(result["restoredStreams"],0);self.assertEqual(calls,[])
 def test_missing_microphone_preserves_restore_receipt(self):
  with tempfile.TemporaryDirectory() as tmp:
   state=Path(tmp)/"receipt.json";state.write_text(json.dumps({"target":"effects","streams":[{"index":9,"original":"disconnected"}]}))
   sources=[{"index":2,"name":"effects"}];streams=[{"index":9,"source":2,"properties":{"application.name":"vesktop"}}]
   with patch.dict(v["disable"].__globals__,STATE=state,items=lambda k:sources if k=="sources" else streams):
    result=v["disable"]()
   self.assertTrue(state.exists());self.assertEqual(result["restoredStreams"],0)
 def test_restore_changes_only_route(self):
  with tempfile.TemporaryDirectory() as tmp:
   state=Path(tmp)/"receipt.json";state.write_text(json.dumps({"target":"effects","streams":[{"index":9,"original":"usb"}]}))
   sources=[{"index":1,"name":"usb"},{"index":2,"name":"effects"}];streams=[{"index":9,"source":2,"mute":True,"properties":{"application.name":"vesktop"}}];calls=[]
   with patch.dict(v["disable"].__globals__,STATE=state,items=lambda k:sources if k=="sources" else streams,run=lambda *a:calls.append(a)):
    self.assertEqual(v["disable"]()["restoredStreams"],1)
   self.assertEqual(calls,[("pactl","move-source-output","9","usb")]);self.assertFalse(state.exists())
 def test_preset_protects_peaks_without_gate(self):
  root=Path(__file__).resolve().parents[1]
  d=json.loads((root/"home/.local/share/easyeffects/input/Den Voice.json").read_text())["input"]
  self.assertEqual(d["plugins_order"],["filter#0","autogain#0","compressor#0","limiter#0"])
  self.assertLessEqual(d["compressor#0"]["makeup"],6)
  self.assertLessEqual(d["limiter#0"]["threshold"],-3)
  self.assertFalse(d["limiter#0"]["gain-boost"])
  self.assertEqual(d["filter#0"]["type"],"High-pass")
  self.assertEqual(d["filter#0"]["frequency"],80.0)
  self.assertFalse(d["autogain#0"]["force-silence"])
if __name__=="__main__":unittest.main()
