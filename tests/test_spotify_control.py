import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('control',ROOT/'home/.local/share/sensei/spotify_control.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Fake(m.OfficialPlayer):
 def __init__(self):self.calls=[]
 def properties(self):return {'CanControl':True,'CanGoNext':True,'CanGoPrevious':True,'PlaybackStatus':'Playing','Metadata':{'mpris:length':120000000,'xesam:artist':['a'],'xesam:title':'t'},'Position':3000000}
 def call(self,*a):self.calls.append(a)
class Controls(unittest.TestCase):
 def test_skip_single_shot(self):
  for name in ('next','previous'):
   p=Fake();p.action(name,[]);self.assertEqual(len(p.calls),1)
 def test_unsupported_queue_never_falls_back(self):
  p=Fake()
  with self.assertRaises(ValueError):p.action('play-list',['[]'])
  self.assertEqual(p.calls,[])
 def test_status_units(self):
  p=Fake().status();self.assertEqual(p['progress'],3000);self.assertEqual(p['track']['duration'],120000)
 def test_selection_rejects_corruption_without_replacing(self):
  with tempfile.TemporaryDirectory() as d,patch.object(m,'settings_path',return_value=Path(d)/'music.json'):
   self.assertEqual(m.selection(),'native');m.select('official');self.assertEqual(m.selection(),'official')
   m.settings_path().write_text('{bad')
   with self.assertRaises(ValueError):m.selection()
   self.assertEqual(m.settings_path().read_text(),'{bad')

class Startup(unittest.TestCase):
 def test_missing_install_bootstraps_instead_of_skip_update(self):
  with tempfile.TemporaryDirectory() as d,patch.object(m,'selection',return_value='official'),patch.object(m.Path,'home',return_value=Path(d)),patch.object(m.subprocess,'Popen') as spawn:
   m.main(['autostart']);self.assertEqual(spawn.call_args.args[0],['spotify-launcher'])
 def test_native_selection_does_not_launch_official_client(self):
  with patch.object(m,'selection',return_value='native'),patch.object(m.subprocess,'Popen') as spawn:
   self.assertTrue(m.main(['autostart'])['skipped']);spawn.assert_not_called()
