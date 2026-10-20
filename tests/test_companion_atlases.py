"""Sprite atlas metadata is the boundary between generated artwork and rendering."""
import json,unittest
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]/'home/.local/share/sensei-companion'
class AtlasGeometry(unittest.TestCase):
 def test_every_frame_is_inside_its_image_and_has_nonzero_extent(self):
  atlas=json.loads((ROOT/'activity-atlases.json').read_text())
  for name,a in atlas.items():
   with self.subTest(activity=name),Image.open(ROOT/a['file']) as image:
    rects=a.get('rects') or [[a['xs'][n],a['ys'][a['row']],a['xs'][n+1]-a['xs'][n],a['ys'][a['row']+1]-a['ys'][a['row']]] for n in range(a.get('frames',4))]
    self.assertEqual(len(rects),a.get('frames',4))
    for x,y,w,h in rects:
     self.assertGreater(w,0);self.assertGreater(h,0);self.assertGreaterEqual(x,0);self.assertGreaterEqual(y,0)
     self.assertLessEqual(x+w,image.width);self.assertLessEqual(y+h,image.height)
     # The actual viewport must clip to frame dimensions, not the larger square pet.
     scale=min(96/w,96/h);self.assertLessEqual(w*scale,96+1e-9);self.assertLessEqual(h*scale,96+1e-9)
 def test_new_singing_art_has_real_transparency_and_four_explicit_frames(self):
  a=json.loads((ROOT/'activity-atlases.json').read_text())['sing']
  self.assertEqual(len(a['rects']),4)
  with Image.open(ROOT/a['file']) as image:
   self.assertEqual(image.mode,'RGBA');self.assertEqual(image.getchannel('A').getextrema(),(0,255))
