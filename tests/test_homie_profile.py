import importlib.machinery, importlib.util, json, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
def module():
 loader=importlib.machinery.SourceFileLoader("homie_displays",str(ROOT/"profiles/pc/home/.local/bin/sensei-displays"));spec=importlib.util.spec_from_loader(loader.name,loader);m=importlib.util.module_from_spec(spec);loader.exec_module(m);m.MACHINE={"profile":"pc","primaryOutput":"DP-3"};m.PRIMARY="DP-3";return m
class HomieProfile(unittest.TestCase):
 def test_misc_is_not_reconciled_to_terminal(self):
  m=module()
  with patch.object(m,"dispatch") as dispatch,patch.object(m,"monitors") as monitors:
   m.reconcile();dispatch.assert_not_called();monitors.assert_not_called()
 def test_primary_connector_keeps_conventional_workspace_ids(self):
  m=module()
  for n in range(1,8):self.assertEqual(m.physical(n,"DP-3"),n)
 def test_primary_brightness_is_discovered_without_external_workspace(self):
  m=module();self.assertFalse(m.external("DP-3"));self.assertEqual(m.ddc_devices("Display 1\n I2C bus: /dev/i2c-4\n DRM connector: card0-DP-3\n"),{"DP-3":4})
 def test_missing_primary_falls_back_to_connected_monitor(self):
  m=module();rows=[{"name":"HDMI-A-1","focused":True}]
  with patch.object(m,"run",return_value=json.dumps(rows)):
   self.assertEqual(m.monitors(),rows);self.assertEqual(m.PRIMARY,"HDMI-A-1");self.assertFalse(m.external("HDMI-A-1"))
