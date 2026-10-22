import gzip,json,shutil,tempfile,unittest,uuid,sys
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.persistence import migration
from noesis.models import create
from noesis import ink
class Ink(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name);(self.root/'System').mkdir();(self.root/'System/System.json').write_text(json.dumps({'directories':['Notes']}));migration(self.root,True);self.origin=create(self.root,'concept','Coordinate transform')
 def tearDown(self):self.tmp.cleanup()
 def make(self,operation=None,paper='plain'):
  return ink.prepare(self.root,self.origin['id'],'My derivation',operation or str(uuid.uuid4()),paper)
 def test_retry_preserves_strokes_and_linked_identity(self):
  op=str(uuid.uuid4());a=self.make(op,'graph');p=self.root/a['local_file'];data=gzip.decompress(p.read_bytes()).replace(b'<layer />',b'<layer><text font="Sans" size="12" x="20" y="20" color="black">My reasoning</text></layer>');p.write_bytes(gzip.compress(data));b=self.make(op,'graph')
  self.assertEqual(a['id'],b['id']);self.assertIn(b'My reasoning',gzip.decompress(p.read_bytes()));self.assertEqual(a['origin_ref']['record_id'],self.origin['id']);self.assertIn('![[',a.get('body','') or (self.root/a['path']).read_text())
 def fake_export(self,args,**kwargs):
  from types import SimpleNamespace
  Path(args[2]).write_bytes(b'%PDF-1.4\nfixture');return SimpleNamespace(returncode=0)
 def test_export_is_derived_and_idempotent(self):
  a=self.make()
  with patch.object(ink.shutil,'which',return_value='/usr/bin/xournalpp'),patch.object(ink.subprocess,'run',side_effect=self.fake_export) as run:
   r=ink.publish_preview(self.root,a['id']);self.assertTrue(r['published']);self.assertFalse(ink.publish_preview(self.root,a['id'])['published']);self.assertEqual(run.call_count,1)
  self.assertEqual((self.root/a['preview_file']).read_bytes(),b'%PDF-1.4\nfixture')
 def test_failed_export_keeps_previous_preview(self):
  a=self.make();out=self.root/a['preview_file'];out.write_bytes(b'%PDF-old')
  with patch.object(ink.shutil,'which',return_value='xournalpp'),patch.object(ink.subprocess,'run',side_effect=OSError('offline')):
   with self.assertRaises(ValueError):ink.publish_preview(self.root,a['id'])
  self.assertEqual(out.read_bytes(),b'%PDF-old')
 def test_source_changed_during_export_does_not_publish(self):
  a=self.make();source=self.root/a['local_file'];out=self.root/a['preview_file'];out.write_bytes(b'%PDF-old')
  def race(args,**kw):
   result=self.fake_export(args,**kw);source.write_bytes(source.read_bytes()+b'changed');return result
  with patch.object(ink.shutil,'which',return_value='xournalpp'),patch.object(ink.subprocess,'run',side_effect=race):
   with self.assertRaisesRegex(ValueError,'changed'):ink.publish_preview(self.root,a['id'])
  self.assertEqual(out.read_bytes(),b'%PDF-old')
 def test_wrong_type_and_bad_paper_leave_no_journal(self):
  with self.assertRaises(ValueError):self.make(paper='run shell')
  with self.assertRaises(ValueError):ink.publish_preview(self.root,self.origin['id'])
  self.assertFalse((self.root/'Explorations').exists())
 def test_paths_are_relative_for_portability(self):
  a=self.make();self.assertFalse(Path(a['local_file']).is_absolute());self.assertFalse(Path(a['preview_file']).is_absolute());self.assertNotIn(str(self.root),gzip.decompress((self.root/a['local_file']).read_bytes()).decode())
class InkBackup(unittest.TestCase):
 def test_owned_notebooks_and_backgrounds_have_matching_backup_cap(self):
  import runpy
  g=runpy.run_path(str(Path(__file__).resolve().parents[1]/'home/.local/bin/sensei-learning-backup'))
  root=Path('/vault');folder=root/'Explorations'/str(uuid.uuid4())
  self.assertEqual(g['snapshot_limit'](folder/'notebook.xopp',root),64*1024*1024)
  self.assertEqual(g['snapshot_limit'](folder/'background.pdf',root),64*1024*1024)
  self.assertEqual(g['snapshot_limit'](root/'Attachments'/'ordinary.pdf',root),25*1024*1024)
  self.assertFalse(g['eligible'](folder/'.ink-export.xopp',root))
if __name__=='__main__':unittest.main()
