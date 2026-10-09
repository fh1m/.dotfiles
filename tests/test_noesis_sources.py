import json
import sys
import tempfile
import unittest
import uuid
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.index import Index
from noesis.persistence import checksum, render
from noesis.sources import annotations, annotation_revisions, bibliography
from noesis.views import overview


class SourcePages(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)/'vault'
        (self.root/'System').mkdir(parents=True)
        (self.root/'System/System.json').write_text(json.dumps({'vault_id':str(uuid.uuid4())}))
        self.identity=str(uuid.uuid4())
        self.props={'id':self.identity,'noesis_schema':2,'type':'paper','title':'Fixture paper',
                    'zotero_key':'PAPER001','zotero_server_id':'fixture-library','zotero_projection':'snapshot.md',
                    'bibliography_projection':'bibliography.md'}
        (self.root/'paper.md').write_text(render(self.props,''))
        self.payload={'server_id':'fixture-library','item':{'key':'PAPER001','version':9},
                      'children':[{'key':'ATTACH01','data':{'itemType':'attachment','parentItem':'PAPER001'}}]+
                      [{'key':f'ANNOT{i:03}','version':2,'data':{'itemType':'annotation','parentItem':'ATTACH01',
                         'annotationText':f'Quote {i}','annotationComment':f'Question {i}'}} for i in range(123)]}
        self.metadata={'id':str(uuid.uuid4()),'noesis_schema':2,'type':'imported-zotero','resource_id':self.identity,
                       'zotero_key':'PAPER001','zotero_server_id':'fixture-library'}
        self.write_snapshot()
        raw=json.dumps({'title':'Fixture paper','author':[{'family':'Author'}]},sort_keys=True)
        (self.root/'bibliography.md').write_text(render({'id':str(uuid.uuid4()),'type':'imported-bibliography',
             'resource_id':self.identity,'source_sha256':checksum(raw)},'\n```json\n'+raw+'\n```\n'))
        self.index=Index(self.root,Path(self.temp.name)/'cache');self.index.reconcile()

    def tearDown(self):self.index.close();self.temp.cleanup()

    def write_snapshot(self):
        raw=json.dumps(self.payload,sort_keys=True)
        (self.root/'snapshot.md').write_text(render(dict(self.metadata,source_sha256=checksum(raw)),'\n```json\n'+raw+'\n```\n'))

    def test_all_annotations_reachable_and_bibliography_owned(self):
        first=annotations(self.index,self.identity);page=first;rows=list(first['annotations'])
        while page['cursor']:
            page=annotations(self.index,self.identity,page['cursor']);rows.extend(page['annotations'])
        self.assertEqual([row['text'] for row in rows],[f'Quote {i}' for i in range(123)])
        self.assertEqual(len(annotations(self.index,self.identity,page['newer_cursor'])['annotations']),50)
        self.assertEqual(rows[-1]['attachment_key'],'ATTACH01')
        self.assertEqual(bibliography(self.index,self.index.record(self.identity))['title'],'Fixture paper')
        self.assertEqual(overview(self.index,self.identity)['annotation_count'],123)
        self.payload['children'][-1]['data']['parentItem']='MISSING1';self.write_snapshot()
        page=annotations(self.index,self.identity)
        while page['cursor']:page=annotations(self.index,self.identity,page['cursor'])
        self.assertIsNone(page['annotations'][-1]['attachment_key'])
        self.assertIn('unavailable',page['annotations'][-1]['availability'])

    def test_cursors_reject_changed_snapshot_owner_cache_and_generation(self):
        first=annotations(self.index,self.identity)
        self.payload['children'][1]['data']['annotationText']='Revision';self.write_snapshot()
        with self.assertRaises(ValueError):annotations(self.index,self.identity,first['cursor'])
        first=annotations(self.index,self.identity)
        self.index.cache_identity=str(uuid.uuid4())
        with self.assertRaises(ValueError):annotations(self.index,self.identity,first['cursor'])
        first=annotations(self.index,self.identity)
        self.index.db.execute('UPDATE meta SET generation=generation+1')
        with self.assertRaises(ValueError):annotations(self.index,self.identity,first['cursor'])
        self.metadata['resource_id']=str(uuid.uuid4());self.write_snapshot()
        self.assertTrue(overview(self.index,self.identity)['projection_unavailable'])

    def test_corrupt_and_wrong_library_projections_are_explicit(self):
        self.payload['server_id']='another-library';self.write_snapshot()
        with self.assertRaises(ValueError):annotations(self.index,self.identity)
        self.payload['server_id']='fixture-library';self.write_snapshot()
        path=self.root/'snapshot.md';path.write_text(path.read_text().replace('Quote 0','Changed quote'))
        with self.assertRaises(ValueError):annotations(self.index,self.identity)
        for cursor in ('@@@@','not-json'):
            self.write_snapshot()
            with self.assertRaises(ValueError):annotations(self.index,self.identity,cursor)

    def test_historical_annotations_remain_owned_and_reachable(self):
        for version in range(52):
            self.payload['item']['version']=version
            raw=json.dumps(self.payload,sort_keys=True)
            metadata=dict(self.metadata,id=str(uuid.uuid4()),source_version=version,source_sha256=checksum(raw))
            (self.root/f'version-{version}.md').write_text(render(metadata,'\n```json\n'+raw+'\n```\n'))
        self.index.reconcile()
        page=annotation_revisions(self.index,self.identity);rows=page['revisions']
        while page['cursor']:
            page=annotation_revisions(self.index,self.identity,page['cursor']);rows+=page['revisions']
        self.assertEqual(len(rows),53)
        old=annotations(self.index,self.identity,projection_path='version-0.md')
        self.assertTrue(old['historical_snapshot']);self.assertEqual(old['source_version'],0)
        with self.assertRaises(ValueError):annotations(self.index,self.identity,old['cursor'],'version-1.md')
        with self.assertRaises(ValueError):annotations(self.index,self.identity,projection_path='bibliography.md')
