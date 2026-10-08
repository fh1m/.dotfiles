import argparse
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('learning',str(ROOT/'home/.local/bin/sensei-learn'))
spec=importlib.util.spec_from_loader(loader.name,loader);m=importlib.util.module_from_spec(spec);loader.exec_module(m)
class Learning(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.h=Path(self.temp.name)
  self.patches=[patch.object(m,'register',lambda root: None),patch.object(m,'HOME',self.h),patch.object(m,'CONFIG',self.h/'config.json'),patch.object(m,'TEMPLATE',ROOT/'home/.local/share/sensei-learning/template')]
  for p in self.patches:p.start()
 def tearDown(self):
  for p in self.patches:p.stop()
  self.temp.cleanup()
 def create(self,title='Classical Mechanics',dry=False):
  a=argparse.Namespace(subject=title,dest=str(self.h/'vault'),goal='Predict a pendulum period and measure disagreement',dry_run=dry,no_git=True)
  m.initialize(a);return self.h/'vault'
 def test_practice_modes_preserve_source_and_do_not_award_mastery(self):
  r=self.create();source=m.new_note(r,'concept','Useful mechanism');original=source.read_text()
  sessions=[]
  for mode in m.PRACTICE_MODES:
   p=m.practice_session(r,str(source.relative_to(r)),mode,'Test a changed input');props,body=m.note_text(p.read_text())
   self.assertEqual(props['mode'],mode);self.assertNotIn('confidence',props);self.assertIn('Before feedback',body);sessions.append(p)
  self.assertEqual(source.read_text(),original);self.assertEqual(len(set(sessions)),5)
  with self.assertRaises(ValueError):m.practice_session(r,'../outside.md','derive','Goal')
  with self.assertRaises(ValueError):m.practice_session(r,str(source.relative_to(r)),'derive',' ')
  self.assertTrue(m.doctor(r,True)['ok'])
 def test_cli_retries_only_readonly_startup_handshake(self):
  from types import SimpleNamespace
  r=self.create();responses=[SimpleNamespace(stdout='Error: Command "vault" not found.',stderr='',returncode=1),SimpleNamespace(stdout=str(r),stderr='',returncode=0),SimpleNamespace(stdout='mutation completed',stderr='',returncode=0)]
  with patch.object(m,'ensure_app'),patch.object(m.time,'sleep'),patch.object(m.subprocess,'run',side_effect=responses) as run:
   self.assertEqual(m.cli(r,'append','path=example.md','content=test'),'mutation completed')
   self.assertEqual(sum(call.args[0][2]=='append' for call in run.call_args_list),1)
 def test_subject_vault_and_refusal(self):
  r=self.create();self.assertTrue(m.doctor(r,True)['ok'])
  self.assertEqual(m.system(r)['template_version'],2)
  with self.assertRaises(ValueError):self.create()
  self.assertIn('{{title}}',(r/'92 Templates/Template - Concept.md').read_text())
 def test_dry_run_writes_nothing(self):
  self.create(dry=True);self.assertEqual(list(self.h.iterdir()),[])
 def test_unicode_and_quotes(self):
  r=self.create('Dynamics "থেকে"');self.assertTrue(m.doctor(r,True)['ok'])
 def test_empty_destination_refused(self):
  (self.h/'vault').mkdir()
  with self.assertRaises(ValueError):self.create()
 def test_new_note_no_overwrite_and_date(self):
  r=self.create();p=m.new_note(r,'concept','State transition');self.assertNotIn('{{date',p.read_text())
  with self.assertRaises(FileExistsError):m.new_note(r,'concept','State transition')
 def test_missing_dependency_and_cycle(self):
  r=self.create();a=m.new_note(r,'prerequisite','A');b=m.new_note(r,'prerequisite','B')
  a.write_text(a.read_text().replace('depends_on: []','depends_on: ["[[B]]"]'))
  b.write_text(b.read_text().replace('depends_on: []','depends_on: ["[[A]]"]'))
  self.assertTrue(any('cycle' in e for e in m.doctor(r,True)['errors']))
 def test_broken_critical_navigation(self):
  r=self.create();p=r/'00 Home/Home.md';p.write_text(p.read_text()+'\n[[missing home target]]\n')
  self.assertFalse(m.doctor(r,True)['ok'])
 def test_no_workspace_state_in_template(self):
  self.assertFalse(list((ROOT/'home/.local/share/sensei-learning/template').rglob('workspace*.json')))
 def test_invalid_confidence_and_missing_dependency(self):
  r=self.create();p=m.new_note(r,'concept','Bad state')
  p.write_text(p.read_text().replace('confidence: 0','confidence: 7'))
  self.assertTrue(any('confidence' in e for e in m.doctor(r,True)['errors']))
  p=m.new_note(r,'prerequisite','Missing dependency')
  p.write_text(p.read_text().replace('depends_on: []','depends_on: ["[[Absent]]"]'))
  self.assertTrue(any('missing dependency' in e for e in m.doctor(r,True)['errors']))
 def test_adopt_preserves_notes_and_template_preference(self):
  r=self.h/'old-vault';(r/'.obsidian').mkdir(parents=True)
  (r/'My note.md').write_text('My actual prediction.\n')
  (r/'.obsidian/templates.json').write_text(json.dumps({'folder':'My Templates'}))
  m.adopt(r)
  self.assertEqual((r/'My note.md').read_text(),'My actual prediction.\n')
  self.assertEqual(m.system(r)['templates'],'My Templates')
  self.assertTrue(m.doctor(r,True)['ok'])
  self.assertIn('My Templates',(r/'93 Bases/Labs.base').read_text())
  with self.assertRaises(ValueError):m.adopt(r)
 def test_network_factory_and_flexible_paths(self):
  a=argparse.Namespace(subject='Knowledge',dest=str(self.h/'network'),goal='Build and explain',dry_run=False,no_git=True,layout='network')
  m.initialize(a);root=self.h/'network'
  self.assertTrue(m.doctor(root,True)['ok'],m.doctor(root,True))
  self.assertTrue((root/'System/System.json').is_file());self.assertFalse((root/'94 Meta').exists())
  self.assertEqual(m.system(root)['types']['paper'],'Notes')
  self.assertTrue((root/'Views/Study.base').is_file())
  with self.assertRaises(ValueError):m.checked_path(root,'../outside.md')
  (root/'escape').symlink_to(self.h,target_is_directory=True)
  with self.assertRaises(ValueError):m.checked_path(root,'escape/x.md')
 def test_csl_import_dedupe_rename_and_preservation(self):
  root=self.create();source=self.h/'refs.json'
  source.write_text(json.dumps([{'title':'A paper','DOI':'10.1/example'},{'title':'Duplicate','DOI':'10.1/example'}]))
  self.assertEqual(len(m.import_csl(root,source,True)['created']),1)
  self.assertFalse(list((root/'07 Sources').glob('*[[]*.md')))
  result=m.import_csl(root,source);note=root/result['created'][0]
  note.write_text(note.read_text()+'Learner reasoning stays.\n')
  moved=root/'My free structure/Renamed.md';moved.parent.mkdir();note.rename(moved)
  result=m.import_csl(root,source)
  self.assertEqual(result['created'],[]);self.assertIn('Learner reasoning stays.',moved.read_text())
 def test_import_annotations_preserves_synthesis_and_history(self):
  root=self.create();note=root/'07 Sources/Paper.md'
  note.write_text('---\nid: stable-test-id\ntype: paper\n---\nMy original understanding.\n')
  original=note.read_bytes();source=self.h/'export.md';source.write_text('A quotation [page](zotero://open-pdf/library/items/TEST?page=2)\n')
  result=m.import_notes(root,source,'07 Sources/Paper.md');excerpt=root/result['excerpt']
  self.assertEqual(note.read_bytes(),original);self.assertIn('zotero://open-pdf',excerpt.read_text())
  self.assertTrue(m.import_notes(root,source,'07 Sources/Paper.md')['unchanged'])
  source.write_text('New exported annotation.\n');m.import_notes(root,source,'07 Sources/Paper.md')
  self.assertEqual(len(list((excerpt.parent/'history').glob('*.md'))),1)
  self.assertEqual(note.read_bytes(),original)
 def test_import_image_cannot_escape_export(self):
  root=self.create();note=root/'07 Sources/Paper.md';note.write_text('---\nid: test-id\n---\n')
  folder=self.h/'export';folder.mkdir();source=folder/'notes.md';source.write_text('![bad](../config.json)')
  with self.assertRaises(ValueError):m.import_notes(root,source,'07 Sources/Paper.md')
if __name__=='__main__':unittest.main()
