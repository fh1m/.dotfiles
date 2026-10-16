import importlib.util
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('leases',ROOT/'home/.local/share/sensei/companion_roam.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Leases(unittest.TestCase):
 def test_stale_journeys_cannot_revive(self):
  a=m.grant({},'DP-1',2,now=10)
  with self.assertRaises(ValueError):m.grant(a,'DP-2',1,now=12)
 def test_expired_or_hidden_lease_is_not_visible(self):
  a=m.grant({},'DP-1',1,ttl=10,now=10);self.assertTrue(m.valid(a,19));self.assertFalse(m.valid(a,20));self.assertFalse(m.valid(m.grant(a,'',2,now=11),12))
 def test_unbounded_lease_is_rejected(self):
  with self.assertRaises(ValueError):m.grant({},'DP-1',1,ttl=10000)
