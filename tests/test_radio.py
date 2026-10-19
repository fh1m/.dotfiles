import json,sys,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei'))
import radio
class Receiver(unittest.TestCase):
 def test_tuning_rejects_nonfinite_and_outside_broadcast(self):
  for frequency,gain in [(float('nan'),20),(98.4,float('nan')),(10,20),(109,20),(98.4,100)]:
   with self.assertRaises(ValueError):radio.tune(frequency,gain)
 def test_unknown_band_never_starts_a_process(self):
  with patch.object(radio.subprocess,'run') as run:
   with self.assertRaises(ValueError):radio.scan('--exec=anything')
   run.assert_not_called()
 def test_power_integrations_keep_frequency_and_strongest_measured_sample(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'bins.csv';p.write_text('2026-10-20, 03:00:00, 88000000, 88200000, 100000, 256, -60, -40\n2026-10-20, 03:00:01, 88000000, 88200000, 100000, 256, -55, -42\n')
   self.assertEqual(radio.parse_power(p),[{'hz':88050000,'db':-55.0},{'hz':88150000,'db':-40.0}])
 def test_receiver_lock_rejects_overlapping_owned_actions(self):
  with tempfile.TemporaryDirectory() as d,patch.object(radio,'ROOT',Path(d)),patch.object(radio,'devices',return_value=[{}]):
   with radio.receiver():
    with self.assertRaises(ValueError):
     with radio.receiver():pass
 def test_missing_receiver_fails_without_tools(self):
  with patch.object(radio,'devices',return_value=[]),patch.object(radio.subprocess,'run') as run:
   with self.assertRaises(ValueError):radio.fm(98.4)
   run.assert_not_called()
 def test_gqrx_profile_is_seed_only_and_selects_real_receiver(self):
  with tempfile.TemporaryDirectory() as d,patch.object(radio.Path,'home',return_value=Path(d)):
   p=radio.gqrx_config();self.assertIn('device=rtl=0',p.read_text());self.assertIn('sample_rate=2048000',p.read_text())
   p.write_text('personal settings');self.assertEqual(radio.gqrx_config().read_text(),'personal settings')
 def test_fm_start_reports_early_receiver_failure(self):
  from types import SimpleNamespace
  with patch.object(radio,'devices',return_value=[{}]),patch.object(radio.time,'sleep'),patch.object(radio.subprocess,'run',side_effect=[SimpleNamespace(returncode=0),SimpleNamespace(returncode=0),SimpleNamespace(returncode=3)]):
   with self.assertRaisesRegex(ValueError,'FM could not open'):radio.fm(98.4)
 def test_partial_iq_is_removed_and_not_awarded_a_receipt(self):
  def short_capture(argv,seconds):Path(argv[-1]).write_bytes(b'partial');return '', ''
  with tempfile.TemporaryDirectory() as d,patch.object(radio,'ROOT',Path(d)),patch.object(radio,'devices',return_value=[{}]),patch.object(radio,'bounded',side_effect=short_capture):
   with self.assertRaises(ValueError):radio.record_iq(98.4)
   self.assertFalse(list(Path(d).glob('*.sigmf-*')));self.assertFalse((Path(d)/'latest.json').exists())
 def test_comparison_preserves_run_identities_and_measured_differences(self):
  with tempfile.TemporaryDirectory() as d,patch.object(radio,'ROOT',Path(d)):
   a=radio.receipt({'kind':'spectrum','at':1,'band':'fm','bins':[{'hz':1,'db':-60}]})
   b=radio.receipt({'kind':'spectrum','at':2,'band':'fm','bins':[{'hz':1,'db':-55}]})
   c=radio.compare();self.assertEqual(c['meanDeltaDb'],5);self.assertEqual(set(c['references']),{a['id'],b['id']});self.assertIn('not calibrated',c['note'])
if __name__=='__main__':unittest.main()
