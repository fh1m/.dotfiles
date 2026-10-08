import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.zotero import LocalAPI, import_item
from noesis.persistence import migration, parse

class Response(io.BytesIO):
    def __init__(self,data,server='synthetic-instance',version='3'):
        super().__init__(json.dumps(data).encode())
        self.headers={'Zotero-API-Version':version,'Zotero-Server-ID':server,'Last-Modified-Version':'7'}

class Opener:
    def __init__(self):
        self.title='Original paper';self.annotations=[{'key':'ANNOT001','version':3,'data':{'itemType':'annotation','annotationText':'Check the assumption','annotationPosition':'{"pageIndex":7}'}}]
        self.server='synthetic-instance';self.requests=[];self.error=None
    def open(self,request,timeout):
        self.requests.append(request)
        if self.error:raise HTTPError(request.full_url,self.error,'refused',{},None)
        endpoint=request.full_url.split('/api/')[1]
        if endpoint=='':data={'version':3}
        elif endpoint=='users/0/items?limit=1':data=[]
        elif endpoint.startswith('users/0/items?itemType=annotation'):data=[dict(x,data=dict(x['data'],parentItem='ATTACH01')) for x in self.annotations]
        elif endpoint=='users/0/items/PAPER001':data={'key':'PAPER001','version':7,'data':{'title':self.title,'itemType':'journalArticle','DOI':'10.synthetic/paper'}}
        elif endpoint.startswith('users/0/items/top?'):data=[{'key':f'ITEM{i:04}','version':7,'data':{'title':f'Paper {i}','itemType':'journalArticle'}} for i in range(50)]
        elif endpoint.startswith('users/0/items/PAPER001/children'):data=[{'key':'ATTACH01','version':2,'data':{'itemType':'attachment','contentType':'application/pdf'}}]
        elif endpoint.startswith('users/0/items/ATTACH01/children'):data=self.annotations
        else:raise AssertionError(endpoint)
        return Response(data,self.server)

class Zotero(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.home=Path(self.temp.name)
        self.patch=patch('pathlib.Path.home',return_value=self.home);self.patch.start()
        self.root=self.home/'vault';(self.root/'System').mkdir(parents=True)
        (self.root/'System/System.json').write_text(json.dumps({'types':{'paper':'Resources'}}));migration(self.root,True)
    def tearDown(self):self.patch.stop();self.temp.cleanup()
    def test_native_annotation_revisions_identity_and_learner_prose(self):
        opener=Opener();api=LocalAPI(opener=opener)
        first=import_item(self.root,'PAPER001',api);path=self.root/first['created'][0]
        path.write_text(path.read_text()+'\nMy independent reconstruction stays mine.\n')
        opener.title='Corrected metadata';opener.annotations=[]
        second=import_item(self.root,'PAPER001',api)
        self.assertEqual(parse(path.read_text())[0]['zotero_attachment_key'],'ATTACH01')
        self.assertEqual(first['resource_id'],second['resource_id'])
        self.assertNotEqual(first['projection'],second['projection'])
        self.assertIn('ANNOT001',(self.root/first['projection']).read_text())
        self.assertNotIn('ANNOT001',(self.root/second['projection']).read_text())
        self.assertIn('independent reconstruction',path.read_text())
        self.assertEqual(parse(path.read_text())[0]['imported_title'],'Corrected metadata')
        self.assertTrue(all(r.get_method()=='GET' for r in opener.requests))
        self.assertTrue(all(r.full_url.startswith('http://127.0.0.1:23119/api/') for r in opener.requests))
    def test_item_and_library_versions_are_distinct(self):
        opener=Opener();original=opener.open
        def open_response(request,timeout):
            response=original(request,timeout)
            if request.full_url.endswith('/items/PAPER001'):response.headers['Last-Modified-Version']='1'
            return response
        opener.open=open_response
        self.assertEqual(LocalAPI(opener=opener).item('PAPER001')[0]['key'],'PAPER001')
        checkpoints=[r for r in opener.requests if r.full_url.endswith('/items?limit=1')]
        self.assertEqual(len(checkpoints),2)

    def test_local_attachment_children_omission_does_not_lose_annotations(self):
        opener=Opener();original=opener.open
        def open_response(request,timeout):
            if '/items/ATTACH01/children?' in request.full_url:return Response([],opener.server)
            return original(request,timeout)
        opener.open=open_response
        children=LocalAPI(opener=opener).item('PAPER001')[1]
        self.assertIn('ANNOT001',[child['key'] for child in children])

    def test_search_pages_are_bounded_encoded_and_instance_bound(self):
        opener=Opener();result=LocalAPI(opener=opener).search('matrix & calculus',50)
        self.assertEqual(len(result['records']),50);self.assertEqual(result['cursor'],100)
        self.assertIn('q=matrix+%26+calculus',opener.requests[-1].full_url)
        self.assertIn('start=50',opener.requests[-1].full_url)
        with self.assertRaisesRegex(ValueError,'instance changed'):LocalAPI(server_id='previous-instance',opener=opener).search()
        with self.assertRaises(ValueError):LocalAPI(opener=opener).search(start=-1)
    def test_permissions_and_instance_preconditions_fail_before_import(self):
        opener=Opener();opener.error=403
        with self.assertRaisesRegex(ValueError,'settings'):LocalAPI(opener=opener).probe()
        opener.error=None
        with self.assertRaisesRegex(ValueError,'instance changed'):import_item(self.root,'PAPER001',LocalAPI(server_id='other-instance',opener=opener))
        self.assertFalse((self.root/'Resources').exists())
        with self.assertRaises(ValueError):LocalAPI(opener=opener).item('../escape')

if __name__=='__main__':unittest.main()
