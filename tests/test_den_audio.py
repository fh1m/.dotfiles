import json,sys,tempfile,unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei'))
import den_audio as d
class AudioRoutes(unittest.TestCase):
 def test_invalid_route_never_stops_current_playback(self):
  with patch.object(d,'nodes',return_value=[]),patch.object(d,'command') as cmd:
   for mode,sink in [('invalid','output'),('lan','missing')]:
    with self.assertRaises(ValueError):d.start(mode,sink)
   cmd.assert_not_called()
 def test_status_exposes_mute_and_missing_destination(self):
  sink={'name':'headphones','index':3,'mute':True,'volume':{'left':{'value':65536}},'ports':[]}
  def nodes(kind):return [sink] if kind=='sinks' else []
  with patch.object(d,'nodes',side_effect=nodes),patch.object(d,'read',return_value={'output':'headphones'}),patch.object(d,'command',return_value=SimpleNamespace(stdout='active')),patch.object(d,'remote',return_value={}):
   result=d.status();self.assertTrue(result['destination']['muted']);self.assertFalse(result['linked']);self.assertIn('disconnected',result['error'])
 def test_port_validation_does_not_execute_unknown_name(self):
  with patch.object(d,'nodes',return_value=[{'name':'output','ports':[]}]),patch.object(d,'command') as cmd:
   with self.assertRaises(ValueError):d.port('output','injected')
   cmd.assert_not_called()
 def test_peer_uses_playback_monitor_never_microphone(self):
  with patch.object(d,'command',return_value=SimpleNamespace(stdout='speaker')),patch.object(d,'nodes',side_effect=lambda kind:[{'name':'speaker'}] if kind=='sinks' else []),patch.object(d,'signal_probe',return_value={'detected':True}) as probe:
   result=d.peer(True);probe.assert_called_once_with('speaker');self.assertTrue(result['signal']['detected'])
 def test_snapshot_atomic_and_private(self):
  with tempfile.TemporaryDirectory() as tmp:
   path=Path(tmp)/'state.json';d.write(path,{'active':True});self.assertEqual(d.read(path),{'active':True});self.assertEqual(path.stat().st_mode&0o777,0o600);self.assertFalse(path.with_suffix('.tmp').exists())
 def test_homie_routes_through_restricted_control(self):
  with patch.object(d,'command',return_value=SimpleNamespace(returncode=0,stdout='{"active":true}')) as cmd:
   self.assertTrue(d.forward(['status'])['active']);self.assertEqual(cmd.call_args.args[0][-1],'den-audio status')
if __name__=='__main__':unittest.main()
