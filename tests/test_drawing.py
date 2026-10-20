import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei'))
import drawing as d
class Drawing(unittest.TestCase):
 def test_aspect_and_rotation(self):
  m={'width':1920,'height':1080};p=dict(d.DEFAULT)
  a=d.area(p,m);self.assertAlmostEqual(a['Width']/a['Height'],16/9,places=4)
  p['rotation']=90;a=d.area(p,m);self.assertAlmostEqual(a['Height']/a['Width'],16/9,places=4)
 def test_invalid_preferences(self):
  for v in [{'output':'DP-1;rm'},{'aspect':'false'},{'threshold':float('nan')},{'threshold':21},{'buttons':['undo']},{'program':'sh'}]:
   with self.subTest(v=v),self.assertRaises(ValueError):d.validate(v)
 def test_shortcuts_never_reach_terminal(self):
  for app in ('alacritty','org.wezfurlong.wezterm','chromium',''):
   self.assertIsNone(d.binding('undo',app))
  b=d.binding('undo','krita');self.assertEqual(b['Settings'][0]['Value'],'Control+Z')
 def test_missing_upper_falls_back(self):
  m={'name':'eDP-1','width':3840,'height':2160,'scale':2,'x':0,'y':0}
  target,fallback=d.target(dict(d.DEFAULT),[m]);self.assertEqual(target['name'],'eDP-1');self.assertTrue(fallback)
 def test_paper_geometry_excludes_margins(self):
  from PIL import Image,ImageDraw
  im=Image.new('RGB',(1000,600),'#dddddd');ImageDraw.Draw(im).rectangle((200,80,800,520),fill='white')
  x,y,w,h=d.paper_bounds(im)
  self.assertGreater(x,200);self.assertGreater(y,80);self.assertLess(x+w,802);self.assertLess(y+h,522)
  self.assertIsNone(d.paper_bounds(Image.new('RGB',(1000,600),'#222222')))
 def test_reconnect_with_identical_profile_reapplies_mapping(self):
  import runpy,json
  from unittest.mock import patch
  script=Path(__file__).resolve().parents[1]/'home/.local/bin/sensei-draw'
  # Each watch pass samples USB presence three times; a true/false/true
  # sequence must reconcile twice even though prefs/monitor/app are identical.
  with patch.object(sys,'argv',[str(script),'watch']),patch.object(d,'monitors',return_value=[]),patch.object(d,'call',return_value=json.dumps({'class':''})),patch.object(d,'prefs',return_value={}),patch.object(d,'connected',side_effect=[True,True,True,False,False,False,True,True,True]),patch.object(d,'reconcile') as reconcile,patch('time.sleep',side_effect=[None,None,KeyboardInterrupt]):
   with self.assertRaises(KeyboardInterrupt):runpy.run_path(str(script),run_name='__main__')
   self.assertEqual(reconcile.call_count,2)
 def test_recreated_virtual_pen_reapplies_identical_usb_profile(self):
  import runpy,json
  from unittest.mock import patch
  script=Path(__file__).resolve().parents[1]/'home/.local/bin/sensei-draw'
  identities=iter(['old','new'])
  def call(args):
   if 'devices' in args:return json.dumps({'tablets':[{'name':'opentabletdriver-virtual-artist-tablet','address':next(identities)}]})
   return json.dumps({'class':''})
  with patch.object(sys,'argv',[str(script),'watch']),patch.object(d,'monitors',return_value=[]),patch.object(d,'call',side_effect=call),patch.object(d,'prefs',return_value={}),patch.object(d,'connected',return_value=True),patch.object(d,'reconcile') as reconcile,patch('time.sleep',side_effect=[None,KeyboardInterrupt]):
   with self.assertRaises(KeyboardInterrupt):runpy.run_path(str(script),run_name='__main__')
   self.assertEqual(reconcile.call_count,2)
if __name__=='__main__':unittest.main()
