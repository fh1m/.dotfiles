import importlib.machinery
import importlib.util
from pathlib import Path
import unittest
import json
import re
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
loader=importlib.machinery.SourceFileLoader('routing',str(ROOT/'home/.local/bin/sensei-displays'))
spec=importlib.util.spec_from_loader(loader.name,loader);m=importlib.util.module_from_spec(spec);loader.exec_module(m)
class Routing(unittest.TestCase):
 def test_lua_names_match_the_shared_contract(self):
  contract=json.loads((ROOT/'home/.local/share/sensei/workspaces.json').read_text())
  expected=[x['name'] for x in contract['subjects']]
  for file in ('home/.config/hypr/oasis.lua','profiles/pc/home/.config/hypr/oasis.lua'):
   text=(ROOT/file).read_text();block=text.split('local noesis_workspace_names = {',1)[1].split('}',1)[0]
   self.assertEqual(re.findall(r'"([^"\n]+)"',block),expected)

 def test_all_seven_roundtrip_on_each_external(self):
  with patch.object(m,'external',return_value=True):
   for slot in range(1,33):
    for subject in range(1,8):self.assertEqual(m.logical(m.physical(subject,'DP-X',{'DP-X':slot})),subject)
 def test_pc_only_dp2_is_main(self):
  self.assertEqual(m.main_display([{'name':'DP-2','focused':True}])['name'],'DP-2')
 def test_misc_joins_all_displays_without_screenpad(self):
  monitors=[{'name':'eDP-1','activeWorkspace':{'id':1}}, {'name':'HDMI-A-1','activeWorkspace':{'id':101}}, {'name':'DP-2','height':1100,'activeWorkspace':{'id':90}}]
  calls=[]
  with patch.object(m,'monitors',return_value=monitors),patch.object(m,'main_display',return_value=monitors[0]),patch.object(m,'external',side_effect=lambda n:n=='HDMI-A-1'),patch.object(m,'known_workspaces',return_value=[]),patch.object(m,'workspace_slots',return_value={'HDMI-A-1':1}),patch.object(m,'dispatch',side_effect=calls.append):
   m.workspace(7,'HDMI-A-1')
  self.assertEqual(len(calls),1);self.assertIn('workspace="107"',calls[0]);self.assertIn('workspace="7"',calls[0]);self.assertNotIn('workspace="90"',calls[0])
 def test_utility_is_not_a_subject(self):self.assertEqual(m.logical(90),90)
