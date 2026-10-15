import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import json
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('den_layout',ROOT/'home/.local/share/sensei/den_layout.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Roles(unittest.TestCase):
    def setUp(self):
        self.t=tempfile.TemporaryDirectory();self.path=Path(self.t.name)/'layout.json';self.p=patch.object(m,'PATH',self.path);self.p.start()
    def tearDown(self):self.p.stop();self.t.cleanup()
    def test_pc_dp2_is_not_screenpad(self):
        r=m.roles([{'name':'DP-3','focused':True},{'name':'DP-2'}],host='homie',profile='pc')
        self.assertEqual(r['lower']['name'],'DP-2');self.assertNotIn('screenpad',r)
    def test_identity_survives_connector_change(self):
        self.path.write_text(json.dumps({'schema':1,'hosts':{'homie':{'displays':{'main':{'description':'LG original','connector':'DP-3'}}}}}))
        r=m.roles([{'name':'DP-1','description':'LG original'},{'name':'DP-3','description':'new','focused':True}],host='homie')
        self.assertEqual(r['main']['name'],'DP-1')
    def test_laptop_screenpad_not_external(self):
        r=m.roles([{'name':'eDP-1'},{'name':'DP-2','height':1100},{'name':'HDMI-A-1'}],host='arete')
        self.assertEqual(r['screenpad']['name'],'DP-2');self.assertEqual(r['lower']['name'],'HDMI-A-1')
    def test_unknown_schema_preserved(self):
        self.path.write_text('{"schema":99,"hosts":{}}')
        with self.assertRaises(ValueError):m.roles([])
if __name__=='__main__':unittest.main()
