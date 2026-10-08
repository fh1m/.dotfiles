import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.persistence import migration
from noesis.models import create
from noesis.activities import record_activity
from noesis.scopes import register
from noesis.collection import project
from noesis.index import Index
from noesis.views import today,overview
from noesis.presentation import display_title


class Collection(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.home=Path(self.temp.name)
        self.patch=patch('pathlib.Path.home',return_value=self.home);self.patch.start();self.addCleanup(self.patch.stop);self.addCleanup(self.temp.cleanup)
        self.roots=[];self.indexes={}
        for name in ('CS','Robotics'):
            root=self.home/name;(root/'System').mkdir(parents=True)
            (root/'System/System.json').write_text(json.dumps({'directories':[],'types':{}}))
            migration(root,True);register(root);self.roots.append(root)
        self.addCleanup(lambda:[i.close() for i in self.indexes.values()])
    def index(self,root,reconcile=False):
        key=str(root)
        if key not in self.indexes:self.indexes[key]=Index(root);reconcile=True
        if reconcile:self.indexes[key].reconcile()
        return self.indexes[key]
    def request(self,action,**data):
        return dict({'action':action,'vaults':[str(r) for r in self.roots]},**data)
    def test_cross_vault_resume_preserves_owner_and_excludes_completed_material(self):
        lecture=create(self.roots[0],'resource','Lecture',fields={'source_kind':'lecture'})
        record_activity(self.roots[0],lecture['path'],'study',state={'locator':{'kind':'timestamp','value':'12:34'}})
        view=project(self.request('collection-today'),self.index)
        self.assertEqual(view['continue']['vault'],str(self.roots[0]));self.assertEqual(view['continue']['position'],'12:34')
        record_activity(self.roots[0],lecture['path'],'study',state={'status':'read'})
        view=project(self.request('collection-today'),self.index)
        self.assertIsNone(view['continue']);self.assertIsNone(overview(self.index(self.roots[0]),lecture['id']))
    def test_search_pagination_across_scope_boundaries_and_changed_scope(self):
        for root in self.roots:
            for n in range(31):create(root,'concept',f'Concept {n}')
        request=self.request('collection-query',query='Concept');page=project(request,self.index)
        self.assertEqual(len(page['records']),50);self.assertTrue(all(row['vault_id'] for row in page['records']))
        second=project(dict(request,cursor=page['cursor']),self.index)
        self.assertEqual(len(second['records']),12);self.assertIsNone(second['cursor'])
        ids=[(row['vault_id'],row['id']) for row in page['records']+second['records']]
        self.assertEqual(len(set(ids)),62)
        with self.assertRaisesRegex(ValueError,'scope changed'):
            project(dict(request,vaults=[str(self.roots[0])],cursor=page['cursor']),self.index)
    def test_unregistered_and_duplicate_scopes_refused(self):
        unknown=self.home/'Unknown';unknown.mkdir()
        with self.assertRaisesRegex(ValueError,'not registered'):project(self.request('collection-query',vaults=[str(unknown)]),self.index)
        meta=self.roots[1]/'System/System.json';meta.write_bytes((self.roots[0]/'System/System.json').read_bytes())
        with self.assertRaisesRegex(ValueError,'Duplicate vault'):project(self.request('collection-today'),self.index)
    def test_display_title_does_not_expose_storage_path(self):
        path='01 Foundations/Prerequisite - Truth table trace.md'
        self.assertEqual(display_title({'title':path,'type':'prerequisite'},path),'Truth table trace')
        self.assertEqual(display_title({'title':'Learner title'},path),'Learner title')

    def test_restore_replacement_and_fork_preserve_original_and_history(self):
        import shutil
        from noesis.identity_recovery import fork,replace_location
        task=create(self.roots[0],'task','Original reasoning','Wrong assumption preserved')
        record_activity(self.roots[0],task['path'],'attempt','Counterexample',outcome='failed',assistance=['none'])
        original=(self.roots[0]/task['path']).read_bytes()
        restored=self.home/'Restored';shutil.copytree(self.roots[0],restored)
        replace_location(restored,self.roots[0])
        from noesis.scopes import locations
        self.assertNotIn(self.roots[0],locations());self.assertIn(restored,locations())
        branched=self.home/'Fork';result=fork(restored,branched);register(branched)
        self.assertNotEqual(result['vault_id'],self.index(restored).manifest['vault_id'])
        index=self.index(branched);row=index.query(kind='task')['records'][0]
        self.assertNotEqual(row['id'],task['id']);self.assertEqual(index.timeline(row['id'])[0]['outcome'],'failed')
        self.assertEqual((self.roots[0]/task['path']).read_bytes(),original)
        self.assertIn('Wrong assumption preserved',index.record(row['id'])['body'])
    def test_fork_interruption_does_not_publish_partial_directory(self):
        from noesis.identity_recovery import fork
        create(self.roots[0],'task','Task')
        destination=self.home/'Interrupted'
        with patch('noesis.identity_recovery.os.rename',side_effect=OSError('Interrupted publication')):
            with self.assertRaises(OSError):fork(self.roots[0],destination)
        self.assertFalse(destination.exists());self.assertFalse(list(self.home.glob('.noesis-fork-*')))
    def test_preview_is_bounded_and_never_interprets_html_or_remote_embeds(self):
        from noesis.presentation import preview
        result=preview('# Title\n\n## Assumption\nText with [[Concept|useful concept]].\n\n<script>bad()</script>\n![Remote](https://example.invalid/pixel)\n','Title')
        self.assertNotIn('Title',[block['text'] for block in result['blocks']])
        self.assertIn('Text with useful concept.',[block['text'] for block in result['blocks']])
        self.assertIn('<script>bad()</script>',[block['text'] for block in result['blocks']])
        self.assertFalse(any('https://' in block['text'] for block in result['blocks']))
        self.assertIn('images or embeds',result['specialist_features'])
        self.assertTrue(preview('line\n'*1000)['truncated'])

    def test_reviewable_course_import_retries_after_partial_publication(self):
        import uuid
        from noesis.outlines import plan,apply
        from noesis.models import create as real_create
        source=self.home/'course.json'
        entries=[{'key':'module','kind':'unit','title':'Foundations','fields':{'unit_kind':'module'}}]
        entries += [{'key':'lecture'+str(n),'kind':'unit','title':'Lecture '+str(n),'parent':'module','fields':{'unit_kind':'lecture'}} for n in range(6)]
        entries += [{'key':'reading'+str(n),'kind':'unit','title':'Reading '+str(n),'fields':{'unit_kind':'reading'}} for n in range(2)]
        entries += [{'key':'assignment'+str(n),'kind':'task','title':'Assignment '+str(n)} for n in range(2)]
        entries += [{'key':'project','kind':'project','title':'Course project'}]
        source.write_text(json.dumps({'version':1,'title':'Realistic course','entries':entries}))
        review=plan(source);self.assertEqual(review['count'],12)
        self.assertEqual(self.index(self.roots[0]).query()['records'],[])
        calls=[]
        def interrupted(*args,**kwargs):
            calls.append(args)
            if len(calls)==4:raise OSError('Interrupted course import')
            return real_create(*args,**kwargs)
        operation=str(uuid.uuid4())
        with patch('noesis.outlines.create',side_effect=interrupted):
            with self.assertRaises(OSError):apply(self.roots[0],source,operation,review['digest'])
        result=apply(self.roots[0],source,str(uuid.uuid4()),review['digest'])
        again=apply(self.roots[0],source,str(uuid.uuid4()),review['digest'])
        self.assertEqual(result['course']['id'],again['course']['id'])
        index=self.index(self.roots[0],True)
        counts=overview(index,result['course']['id'])['counts']
        self.assertEqual(counts['lectures']['total'],6);self.assertEqual(counts['assignments']['total'],2)
        self.assertEqual(counts['projects']['total'],1)
        self.assertEqual(index.db.execute('SELECT count(*) FROM records').fetchone()[0],13)
        source.write_text(source.read_text()+' ')
        with self.assertRaisesRegex(ValueError,'changed since review'):apply(self.roots[0],source,str(uuid.uuid4()),review['digest'])

    def test_explicit_cross_vault_concept_connection_survives_move(self):
        from noesis.references import link,resolve
        path=create(self.roots[0],'path','CS foundations')
        concept=create(self.roots[1],'concept','Probability')
        original=(self.roots[1]/concept['path']).read_bytes()
        edge=link(self.roots[0],path['id'],concept['id'],'references',self.roots[1],'Reusable prerequisite knowledge')
        moved=self.roots[1]/'Moved concept.md';(self.roots[1]/concept['path']).rename(moved)
        index=self.index(self.roots[0],True);relation=index.relations(path['id'])[0]
        self.assertEqual(relation['other_vault'],str(self.roots[1]));self.assertEqual(relation['other_path'],'Moved concept.md')
        self.assertEqual(moved.read_bytes(),original)
        self.assertEqual(resolve(edge['target_ref'])['record_id'],concept['id'])
        with self.assertRaisesRegex(ValueError,'currently support'):link(self.roots[0],path['id'],concept['id'],'prerequisite',self.roots[1])

    def test_disconnected_registered_scope_preserves_other_results(self):
        import shutil
        task=create(self.roots[0],'task','Available work')
        shutil.rmtree(self.roots[1])
        result=project(self.request('collection-query'),self.index)
        self.assertEqual(result['availability'],'partial')
        self.assertEqual(result['records'][0]['id'],task['id'])
        self.assertEqual(result['scope_errors'][0]['vault'],str(self.roots[1]))

    def test_today_includes_course_resources_without_promoting_individual_lectures(self):
        course=create(self.roots[0],'resource','Course outline',fields={'source_kind':'course'})
        lecture=create(self.roots[0],'resource','One video',fields={'source_kind':'lecture'})
        result=today(self.index(self.roots[0],True))
        self.assertIn(course['id'],[r['id'] for r in result['paths']])
        self.assertNotIn(lecture['id'],[r['id'] for r in result['paths']])

    def test_invalid_active_vault_does_not_disable_other_collection_results(self):
        import io
        from contextlib import redirect_stdout
        from noesis.worker import serve
        task=create(self.roots[0],'task','Healthy context')
        (self.roots[1]/'System/System.json').write_text('{malformed')
        request=self.request('collection-query',version=1,request_id=7,vault=str(self.roots[1]))
        output=io.StringIO()
        with patch('sys.stdin',io.StringIO(json.dumps(request)+'\n')),redirect_stdout(output):serve(lambda path:Path(path))
        response=json.loads(output.getvalue())
        self.assertNotIn('error',response)
        self.assertEqual(response['result']['availability'],'partial')
        self.assertEqual(response['result']['records'][0]['id'],task['id'])

    def test_concurrent_attempt_start_publishes_one_durable_attempt(self):
        from concurrent.futures import ThreadPoolExecutor
        from threading import Barrier
        import uuid
        task=create(self.roots[0],'task','One independent attempt')
        barrier=Barrier(2)
        def start():
            barrier.wait()
            try:return record_activity(self.roots[0],task['path'],'attempt-start',operation_id=str(uuid.uuid4()),mode='derive')
            except ValueError as error:return str(error)
        with ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(lambda _:start(),range(2)))
        self.assertEqual(sum(isinstance(result,dict) for result in results),1)
        self.assertIn('durable unfinished attempt',next(result for result in results if isinstance(result,str)))
        index=self.index(self.roots[0],True)
        self.assertEqual(len(index.timeline(task['id'])),1)
        self.assertIsNotNone(index.record(task['id'])['attempt'])

    def test_collection_search_respects_research_source_filters(self):
        paper=create(self.roots[0],'resource','Shared source paper',fields={'source_kind':'paper'})
        create(self.roots[1],'resource','Shared source course',fields={'source_kind':'course'})
        result=project(self.request('collection-query',query='Shared source',kind=['resource'],resource_kinds=['paper']),self.index)
        self.assertEqual([r['id'] for r in result['records']],[paper['id']])
