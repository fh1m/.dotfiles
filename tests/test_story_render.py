import concurrent.futures,json,subprocess,sys,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'home/.local/share/sensei'))
from story_render import render
class Story(unittest.TestCase):
 def test_invalid_output_rejected(self):
  with self.assertRaises(ValueError):render('injected',320,200,Path('/missing'),Path('/tmp'))
 def test_native_dimensions_animation_and_concurrent_cache(self):
  assets=ROOT/'home/.local/share/sensei-den/story'
  with tempfile.TemporaryDirectory() as d:
   def run():return render('main',640,360,assets,Path(d),seconds=2)
   with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(lambda _:run(),range(2)))
   self.assertEqual(results[0],results[1]);mtime=results[0].stat().st_mtime_ns;self.assertEqual(run().stat().st_mtime_ns,mtime)
   report=json.loads(subprocess.check_output(['ffprobe','-v','error','-count_frames','-select_streams','v:0','-show_entries','stream=width,height,nb_read_frames','-of','json',str(results[0])]))['streams'][0]
   self.assertEqual((report['width'],report['height']),(640,360));self.assertEqual(int(report['nb_read_frames']),16)
   self.assertFalse((results[0].parent/'story.partial.gif').exists());self.assertTrue((results[0].parent/'complete.json').exists())
if __name__=='__main__':unittest.main()
