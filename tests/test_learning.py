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
 def test_subject_vault_and_refusal(self):
  r=self.create();self.assertTrue(m.doctor(r,True)['ok'])
  self.assertEqual(m.system(r)['template_version'],1)
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
if __name__=='__main__':unittest.main()
