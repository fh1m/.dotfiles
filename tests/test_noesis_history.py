import json,sys,tempfile,unittest,uuid
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.index import Index
class HistoryPages(unittest.TestCase):
 def test_every_older_event_reachable_and_cursors_reject_changed_scope(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory)/'vault';(root/'System').mkdir(parents=True)
   (root/'System/System.json').write_text(json.dumps({'vault_id':str(uuid.uuid4())}))
   index=Index(root,Path(directory)/'cache');identity=str(uuid.uuid4())
   with index.db:
    for n in range(123):
     event={'id':str(uuid.uuid4()),'event':'attempt','timestamp':f'2026-01-01T00:{n//60:02}:{n%60:02}Z'}
     index.db.execute('INSERT INTO activities VALUES(?,?,?,?)',(f'event-{n:03}.md',identity,event['timestamp'],json.dumps(event)))
   first=index.timeline_page(identity);self.assertEqual(len(first['activities']),50)
   page=first;all_events=page['activities']
   while page['cursor']:
    page=index.timeline_page(identity,page['cursor']);all_events=page['activities']+all_events
   self.assertEqual(len(index.timeline_page(identity,page['newer_cursor'])['activities']),50)
   self.assertEqual([event['path'] for event in all_events],[f'event-{n:03}.md' for n in range(123)])
   with self.assertRaises(ValueError):index.timeline_page(str(uuid.uuid4()),first['cursor'])
   index.cache_identity=str(uuid.uuid4())
   with self.assertRaises(ValueError):index.timeline_page(identity,first['cursor'])
   index.cache_identity=json.loads(__import__('base64').b64decode(first['cursor']))['cache']
   index.db.execute('UPDATE meta SET generation=generation+1')
   with self.assertRaises(ValueError):index.timeline_page(identity,first['cursor'])
   for invalid in ['not-json','@@@@']:
    with self.assertRaises(ValueError):index.timeline_page(identity,invalid)
   index.close()
