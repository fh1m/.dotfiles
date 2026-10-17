import importlib.util,unittest
from pathlib import Path
s=importlib.util.spec_from_file_location('network',Path(__file__).resolve().parents[1]/'home/.local/share/sensei/network_audit.py');n=importlib.util.module_from_spec(s);s.loader.exec_module(n)
class Scope(unittest.TestCase):
 def rows(self,address='192.168.0.103',prefix=24):return [{'ifname':'eth0','operstate':'UP','addr_info':[{'family':'inet','local':address,'prefixlen':prefix}]}]
 def test_discovery_never_expands_beyond_local_24(self):self.assertEqual(n.scope('eth0',self.rows('10.4.2.5',8)),'10.4.2.0/24')
 def test_public_down_and_unknown_interfaces_rejected(self):
  for name,rows in [('other',self.rows()),('eth0',self.rows('8.8.8.8')),('eth0',[dict(self.rows()[0],operstate='DOWN')])]:
   with self.assertRaises(ValueError):n.scope(name,rows)
 def test_outside_broadcast_network_and_injected_targets_rejected(self):
  for target in ('192.168.1.2','192.168.0.255','192.168.0.0','8.8.8.8','192.168.0.1;id'):
   with self.assertRaises(ValueError):n.target('eth0',target,self.rows())
  self.assertEqual(n.target('eth0','192.168.0.104',self.rows()),'192.168.0.104')
