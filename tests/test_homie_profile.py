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
 def test_external_stack_aligns_upper_with_homie_not_above_it(self):
  m=module();rows=[{'name':'DP-3','width':1920,'height':1080,'scale':1,'x':0,'y':0},*({'name':name,'width':1920,'height':1080,'scale':1,'x':0,'y':0,'refreshRate':100,'availableModes':['1920x1080@100Hz']} for name in ['DP-2','DP-1'])]
  m._role_monitors=rows
  def role(name,*args):return {'DP-3':'main','DP-2':'lower','DP-1':'upper'}[name]
  with patch.object(m,'role_for',side_effect=role),patch.object(m,'run') as call:
   m.configure(rows);commands=[x.args[0][-1] for x in call.call_args_list]
   self.assertTrue(any('output="DP-1"' in x and 'position="-1920x0"' in x for x in commands))
   self.assertTrue(any('output="DP-2"' in x and 'position="-1920x1080"' in x for x in commands))
   self.assertEqual(m.bar_edge('DP-2'),'bottom');self.assertEqual(m.bar_edge('DP-1'),'top')
 def test_dp2_is_a_full_workspace_participant_on_pc(self):
  m=module();rows=[{'name':'DP-3','focused':True},{'name':'DP-2'}];m._role_monitors=rows
  with patch.object(m,'role_for',side_effect=lambda name,*a:'main' if name=='DP-3' else 'lower'),patch.object(m,'monitors',return_value=rows),patch.object(m,'known_workspaces',return_value=[]),patch.object(m,'workspace_slots',return_value={'DP-2':1}),patch.object(m,'dispatch') as call:
   m.workspace(2,'DP-2');command=call.call_args.args[0]
   self.assertIn('workspace="102"',command);self.assertIn('monitor="DP-2"',command)
