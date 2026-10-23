"""Artwork palettes remain local, readable and derived from actual cover hues."""
import importlib.machinery,importlib.util,tempfile,unittest
from pathlib import Path
from PIL import Image
loader=importlib.machinery.SourceFileLoader('music_palette',str(Path(__file__).resolve().parents[1]/'home/.local/bin/sensei-music-palette'))
spec=importlib.util.spec_from_loader(loader.name,loader);module=importlib.util.module_from_spec(spec);loader.exec_module(module)
class Palette(unittest.TestCase):
 def test_two_hue_cover_keeps_distinct_dark_colors(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'art.png';im=Image.new('RGB',(400,400),'red');im.paste('blue',(200,0,400,400));im.save(p)
   result=module.palette(str(p));self.assertNotEqual(result['wash'],result['accent'])
   for color in result.values():self.assertLessEqual(max(bytes.fromhex(color[1:])),70)
 def test_monochrome_is_valid(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'art.png';Image.new('RGB',(20,20),'black').save(p)
   self.assertEqual(set(module.palette(p.as_uri())),{'wash','edge','accent'})
 def test_remote_art_cannot_trigger_network_io(self):
  with self.assertRaises(ValueError):module.palette('https://example.com/art.jpg')
if __name__=='__main__':unittest.main()
