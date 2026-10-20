import importlib.util,unittest,tempfile,json
from unittest.mock import patch
from pathlib import Path
from evdev import ecodes as E
p=Path(__file__).resolve().parents[1]/'home/.local/share/sensei/controllers.py'
s=importlib.util.spec_from_file_location('controllers',p);c=importlib.util.module_from_spec(s);s.loader.exec_module(c)
class ControllerPolicy(unittest.TestCase):
 def test_center_and_asymmetric_endpoints(self):
  self.assertEqual(c.normalized(100,0,255,100),0)
  self.assertEqual(c.normalized(255,0,255,100),1)
  self.assertEqual(c.normalized(0,0,255,100),-1)
 def test_deadzone_and_invalid_range(self):
  self.assertEqual(c.normalized(103,0,200,100,deadzone=.04),0)
  self.assertEqual(c.normalized(3,5,5),0)
 def test_triggers_are_unipolar(self):
  self.assertEqual(c.normalized(0,0,255,trigger=True),0)
  self.assertEqual(c.normalized(255,0,255,trigger=True),1)
 def test_values_are_clamped(self):
  self.assertEqual(c.normalized(999,0,255),1)
  self.assertEqual(c.normalized(-99,0,255),-1)
 def test_only_actual_gamepads_are_sampled(self):
  self.assertTrue(c.gamepad({E.EV_KEY:[E.BTN_GAMEPAD],E.EV_ABS:[E.ABS_X,E.ABS_Y]}))
  self.assertFalse(c.gamepad({E.EV_KEY:[E.BTN_TOOL_PEN],E.EV_ABS:[E.ABS_X,E.ABS_Y]}))
  self.assertFalse(c.gamepad({E.EV_KEY:[E.KEY_A]}))
 def test_identical_models_on_different_ports_stay_separate(self):
  class D:
   name='Gamepad';uniq=''
   class info:vendor=1;product=2
  a=D();b=D();a.phys='usb-a';b.phys='usb-b'
  self.assertNotEqual(c.identity(a),c.identity(b))
 def test_serial_identity_survives_port_change(self):
  class D:
   name='Gamepad';uniq='serial';phys='usb-a'
   class info:vendor=1;product=2
  a=D();before=c.identity(a);a.phys='usb-b';self.assertEqual(c.identity(a),before)

class DiscoveryAndLayout(unittest.TestCase):
 def test_discovery_requests_numeric_capabilities(self):
  class D:
   def capabilities(self,verbose=False,absinfo=True):
    return {E.EV_KEY:[E.BTN_GAMEPAD],E.EV_ABS:[(E.ABS_X,None),(E.ABS_Y,None)] if absinfo else [E.ABS_X,E.ABS_Y]}
   def close(self):pass
  with patch.object(c.evdev,'list_devices',return_value=['fake']),patch.object(c.evdev,'InputDevice',return_value=D()):self.assertEqual(len(c.devices()),1)
 def test_standard_and_legacy_stick_axes(self):
  standard=c.layout([E.ABS_X,E.ABS_Y,E.ABS_Z,E.ABS_RX,E.ABS_RY,E.ABS_RZ])
  legacy=c.layout([E.ABS_X,E.ABS_Y,E.ABS_Z,E.ABS_RZ])
  self.assertEqual(standard['sticks'][1]['x'],E.ABS_RX)
  self.assertEqual(standard['triggers'],[E.ABS_Z,E.ABS_RZ])
  self.assertEqual(legacy['sticks'][1]['x'],E.ABS_Z)
  self.assertEqual(legacy['triggers'],[])
 def test_malformed_profile_does_not_crash_discovery(self):
  with tempfile.TemporaryDirectory() as tmp:
   path=Path(tmp)/'profiles.json';path.write_text('[]')
   with patch.object(c,'CONFIG',path):self.assertEqual(c.profiles(),{})
 def test_profile_values_are_validated(self):
  with tempfile.TemporaryDirectory() as tmp:
   path=Path(tmp)/'profiles.json';path.write_text(json.dumps({'pad':{'deadzone':'bad','axes':{'0':{'min':5,'max':1,'center':3}},'enabled':'no'}}))
   with patch.object(c,'CONFIG',path):p=c.profiles()['pad']
   self.assertEqual(p['deadzone'],.04);self.assertEqual(p['axes'],{});self.assertTrue(p['enabled'])

class SavedProfiles(unittest.TestCase):
 def test_settings_persist_independently_and_export_is_input_only(self):
  import tempfile,os
  from types import SimpleNamespace
  class D:
   def close(self):pass
  with tempfile.TemporaryDirectory() as tmp,patch.object(c,'CONFIG',Path(tmp)/'profiles.json'),patch.object(c,'find',return_value=D()),patch.dict(os.environ,{'XDG_DATA_HOME':tmp}):
   c.setting('one','ros-rate','50');c.setting('one','ros-deadzone','.08');c.setting('one','ros-node','game_controller_node');c.setting('one','ros-coalesce','2');c.setting('two','ros-rate','10')
   a=c.profiles();self.assertEqual(a['one']['ros']['rate'],50);self.assertEqual(a['two']['ros']['rate'],10)
   row={'id':'one','name':'Pad','rawName':'Pad','vendor':'0001','product':'0002','physical':'test','layout':{},'driver':'test','ros':dict(a['one']['ros'],device_name='Raw joystick',controller_name='Mapped controller')}
   with patch.object(c,'snapshot',return_value=row):
    first=c.export_ros('one');second=c.export_ros('one')
   text=(Path(first['path'])/'joy.yaml').read_text();self.assertIn('device_name: "Mapped controller"',text);self.assertIn('autorepeat_rate: 50.0',text);self.assertIn('deadzone: 0.08',text);self.assertIn('coalesce_interval_ms: 2',text);self.assertNotIn('cmd_vel',text);self.assertNotIn('teleop',first['command']);self.assertNotEqual(first['path'],second['path']);self.assertTrue(Path(first['path']).exists())
 def test_invalid_settings_never_write(self):
  for name,value in [('deadzone','nan'),('ros-rate','inf'),('ros-rate','-1'),('ros-coalesce','1.5'),('ros-node','shell'),('ros-sticky','maybe')]:
   with patch.object(c,'save') as save:
    with self.assertRaises(ValueError):c.setting('pad',name,value)
    save.assert_not_called()

class RosIdentity(unittest.TestCase):
 def test_sdl_guid_matches_usb_identity_not_display_name(self):
  text=' 0 : 030000006d0400001dc2000014400000 : true : true : Logitech F310 Gamepad (XInput)\n 1 : 030000005e0400008e02000011010000 : true : false : Xbox 360 Controller'
  rows=c.parse_ros_devices(text);self.assertEqual(rows[0]['vendor'],0x046d);self.assertEqual(rows[0]['product'],0xc21d);self.assertTrue(rows[0]['mapped']);self.assertFalse(rows[1]['mapped'])
 def test_probe_rejects_unknown_environment_before_docker_exec(self):
  with patch.object(c,'environments',return_value={'environments':['host']}),patch.object(c.subprocess,'run') as run:
   with self.assertRaises(ValueError):c.probe_ros('pad','--privileged')
   run.assert_not_called()
