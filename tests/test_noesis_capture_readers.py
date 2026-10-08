import json
from pathlib import Path
import sys,tempfile,unittest,uuid
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.persistence import migration,parse
from noesis.captures import capture
from noesis.activities import operation_status,progress_state,review_heads
from noesis.readers import command

class CaptureReaders(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)/'vault';(self.root/'System').mkdir(parents=True)
  (self.root/'System/System.json').write_text(json.dumps({'layout':'network'}));migration(self.root,True)
 def tearDown(self):self.temp.cleanup()
 def test_capture_retry_after_publication_failure_move_and_missing_record(self):
  import noesis.captures as module
  original=module.publish;op=str(uuid.uuid4())
  def fail_receipt(path,text,*args):
   if path.suffix=='.json' and 'committed' in text:raise OSError('injected receipt failure')
   return original(path,text,*args)
  with patch.object(module,'publish',side_effect=fail_receipt):
   with self.assertRaises(OSError):capture(self.root,'A prediction\nReasoning',operation_id=op)
  first=next((self.root/'Inbox').glob('*.md'));identity=parse(first.read_text())[0]['id'];moved=self.root/'moved.md';first.rename(moved)
  self.assertEqual(capture(self.root,'A prediction\nReasoning',operation_id=op),moved)
  self.assertEqual(parse(moved.read_text())[0]['id'],identity)
  self.assertEqual(operation_status(self.root,op)['status'],'committed')
  with self.assertRaises(ValueError):capture(self.root,'Changed',operation_id=op)
  # A successful receipt witnesses commit even when a user removes the file.
  other=str(uuid.uuid4());path=capture(self.root,'Another prediction',operation_id=other);path.unlink()
  self.assertTrue(operation_status(self.root,other)['record_unavailable'])
  with self.assertRaises(ValueError):capture(self.root,'Another prediction',operation_id=other)
 def test_reader_locations_and_missing_artifact(self):
  pdf=self.root/'paper.pdf';pdf.write_bytes(b'synthetic')
  args=command(self.root,{'local_file':'paper.pdf'},{'locator':{'kind':'page','value':8}})
  self.assertEqual(args[-3:],['--page','8',str(pdf)])
  args=command(self.root,{'zotero_attachment_key':'ATTACH01'},{'locator':{'kind':'page','value':8}},'zotero')
  self.assertEqual(args,['xdg-open','zotero://open-pdf/library/items/ATTACH01?page=8'])
  args=command(self.root,{'source':'https://www.youtube.com/watch?v=synthetic&list=course'},{'locator':{'kind':'timestamp','seconds':3723}})
  self.assertIn('list=course&t=3723s',args[1])
  pdf.unlink()
  with self.assertRaisesRegex(ValueError,'unavailable'):command(self.root,{'local_file':'paper.pdf'}, {})
 def test_chapter_reuses_book_source_and_generic_position_clears_page(self):
  from noesis.models import create
  from noesis.activities import record_activity
  from noesis.index import Index
  from noesis.readers import resource_props
  book=create(self.root,'resource','Book',fields={'source_kind':'book','local_file':'book.pdf'})
  chapter=create(self.root,'unit','Chapter',parent_id=book['id'])
  record_activity(self.root,chapter['path'],'study',state={'locator':{'kind':'page','value':17}})
  index=Index(self.root)
  try:
   index.reconcile();self.assertEqual(resource_props(index,chapter['id'])['local_file'],'book.pdf')
  finally:index.close()
  record_activity(self.root,chapter['path'],'study',state={'position':'Appendix, theorem 2'})
  index=Index(self.root)
  try:
   index.reconcile();state=index.record(chapter['id'])['state'];self.assertIsNone(state.get('locator'));self.assertEqual(state['position'],'Appendix, theorem 2')
  finally:index.close()
 def test_causal_history_survives_clock_skew_and_rejects_cycles(self):
  events=[{'id':'second','event':'study','previous':'first','timestamp':'2020','state':{'position':'page 8'}},{'id':'first','event':'study','timestamp':'2030','state':{'position':'page 2'}}]
  self.assertEqual(progress_state({},events)[0]['position'],'page 8')
  events[1]['previous']='second'
  with self.assertRaisesRegex(ValueError,'Cyclic'):progress_state({},events)
  with self.assertRaisesRegex(ValueError,'Missing'):review_heads([{'id':'review','event':'review-plan','resolves_plans':['missing']}])
if __name__=='__main__':unittest.main()
