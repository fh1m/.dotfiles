import json,os,shutil,subprocess,sys,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'home/.local/share/sensei-learning'))
from noesis.scopes import register,locations,conflicts
from noesis.persistence import migration
from noesis.captures import capture
from noesis.models import create
from noesis.activities import record_activity

class Scopes(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.home=Path(self.temp.name)
  self.patch=patch('pathlib.Path.home',return_value=self.home);self.patch.start()
  self.root=self.home/'original';(self.root/'System').mkdir(parents=True)
  (self.root/'System/System.json').write_text(json.dumps({'layout':'network'}));migration(self.root,True)
 def tearDown(self):self.patch.stop();self.temp.cleanup()
 def test_own_registration_preserves_native_registry_and_unknown_fields(self):
  native=self.home/'.config/obsidian/obsidian.json';native.parent.mkdir(parents=True)
  text=json.dumps({'vaults':{},'unknown_setting':'preserved'});native.write_text(text)
  first=register(self.root);second=register(self.root)
  self.assertEqual(first,second);self.assertEqual(native.read_text(),text)
  self.assertIn(self.root,locations());self.assertEqual((self.home/'.local/state/noesis/vaults.json').stat().st_mode&0o777,0o600)
 def test_restored_duplicate_stops_mutations_without_reassigning_identity(self):
  target=create(self.root,'task','Independent task');register(self.root)
  restored=self.home/'restored';shutil.copytree(self.root,restored)
  before={str(p.relative_to(restored)):p.read_bytes() for p in restored.rglob('*') if p.is_file()}
  self.assertEqual(conflicts(restored),[str(self.root)])
  for action in (lambda:register(restored),lambda:capture(restored,'A thought'),lambda:create(restored,'concept','Concept'),lambda:record_activity(restored,target['path'],'attempt','Reasoning',outcome='failed',assistance=['none'])):
   with self.assertRaisesRegex(ValueError,'replacement or fork'):action()
  self.assertEqual(before,{str(p.relative_to(restored)):p.read_bytes() for p in restored.rglob('*') if p.is_file()})
 def test_corrupt_native_registry_does_not_block_independent_capture(self):
  native=self.home/'.config/obsidian/obsidian.json';native.parent.mkdir(parents=True);native.write_text('{bad')
  register(self.root);self.assertTrue(capture(self.root,'Keep learning offline').is_file());self.assertEqual(native.read_text(),'{bad')
 def test_native_detection_handles_supported_installation_shapes(self):
  from noesis.obsidian import app_running
  proc=self.home/'proc';(proc/'123').mkdir(parents=True);cmdline=proc/'123/cmdline'
  for args in (["/usr/lib/electron42/electron","/usr/lib/obsidian/app.asar"],["/opt/Obsidian/obsidian"],["/opt/Obsidian.AppImage"]):
   cmdline.write_bytes(('\0'.join(args)+'\0').encode());self.assertTrue(app_running(proc))
  cmdline.write_bytes(b'/usr/bin/browser\0obsidian://open?vault=test\0');self.assertFalse(app_running(proc))
 def test_factory_and_capture_work_without_obsidian_registration(self):
  env=dict(os.environ,HOME=str(self.home),PATH='/usr/bin:/bin');destination=self.home/'new'
  result=subprocess.run([sys.executable,str(ROOT/'home/.local/bin/sensei-learn'),'init','Mathematics','--dest',str(destination),'--no-git'],env=env,capture_output=True,text=True)
  self.assertEqual(result.returncode,0,result.stderr)
  result=subprocess.run([sys.executable,str(ROOT/'home/.local/bin/sensei-learn'),'capture','A prediction'],env=env,capture_output=True,text=True)
  self.assertEqual(result.returncode,0,result.stderr);self.assertTrue(Path(result.stdout.strip()).is_file())
  self.assertFalse((self.home/'.config/obsidian/obsidian.json').exists())
if __name__=='__main__':unittest.main()
