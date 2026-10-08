import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import uuid
import math
import hashlib

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'home/.local/share/sensei-learning'))
from noesis.persistence import migration, parse, publish, render
from noesis.models import create, relationship
from noesis.activities import record_activity, progress_state, operation_status
from noesis.index import Index
from noesis.imports import import_csl
from noesis.policies import next_actions, agent_context
from noesis.views import overview
from noesis.artifacts import inspect as inspect_artifact
import noesis.imports as import_module


class Workflows(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.home = Path(self.temp.name)
        self.patch = patch('pathlib.Path.home', return_value=self.home);self.patch.start()
        self.root = self.home / 'vault'
        (self.root / 'System').mkdir(parents=True)
        (self.root / 'System/System.json').write_text(json.dumps({'directories': [], 'types': {'paper': 'Resources'}}))
        migration(self.root, True)

    def test_parking_context_suppresses_descendants_but_preserves_shared_work(self):
        first=create(self.root,'resource','First course',fields={'source_kind':'course'})
        second=create(self.root,'resource','Second course',fields={'source_kind':'course'})
        unit=create(self.root,'unit','Shared lecture',parent_id=first['id'])
        relationship(self.root,second['id'],unit['id'],'contains')
        task=create(self.root,'task','Outstanding problem',parent_id=unit['id'],relation='assigns')
        record_activity(self.root,task['path'],'attempt','Failed independently',outcome='failed',assistance=['none'],retry_requested=True)
        record_activity(self.root,first['path'],'disposition',state='parked')
        index=self.index();self.assertIn(task['id'],{row['id'] for row in next_actions(index)})
        record_activity(self.root,second['path'],'disposition',state='parked')
        index=self.index();self.assertNotIn(task['id'],{row['id'] for row in next_actions(index)})
        self.assertEqual(index.query('Outstanding')['records'][0]['status'],None)
        self.assertEqual(len(index.timeline(task['id'])),1)
        record_activity(self.root,first['path'],'disposition',state='active')
        index=self.index();self.assertIn(task['id'],{row['id'] for row in next_actions(index)})

    def test_record_receipt_recovers_publication_before_acknowledgement_and_move(self):
        import noesis.models as model_module
        operation=str(uuid.uuid4())
        real_publish=model_module.publish
        def interrupted(path,text,expected=None):
            if path.suffix=='.json' and json.loads(text).get('status')=='committed':
                raise OSError('Interrupted after record publication')
            return real_publish(path,text,expected)
        with patch.object(model_module,'publish',side_effect=interrupted):
            with self.assertRaises(OSError):create(self.root,'question','A durable question','Why?',operation_id=operation)
        receipt=operation_status(self.root,operation)
        self.assertEqual(receipt['status'],'committed');self.assertEqual(len(receipt['records']),1)
        record=receipt['records'][0];moved=self.root/'Moved question.md'
        (self.root/record['path']).rename(moved)
        retry=create(self.root,'question','A durable question','Why?',operation_id=operation)
        self.assertEqual(retry['id'],record['id']);self.assertEqual(retry['path'],'Moved question.md')
        with self.assertRaisesRegex(ValueError,'changed record content'):
            create(self.root,'question','A durable question','Changed explanation',operation_id=operation)
        moved.unlink()
        self.assertTrue(operation_status(self.root,operation)['record_unavailable'])
        with self.assertRaisesRegex(ValueError,'inspect recovery'):
            create(self.root,'question','A durable question','Why?',operation_id=operation)

    def test_record_receipt_recovers_before_publication_without_changing_parent_order(self):
        import noesis.models as model_module
        parent=create(self.root,'resource','Ordered course',fields={'source_kind':'course'})
        operation=str(uuid.uuid4());real_publish=model_module.publish
        def interrupted(path,text,expected=None):
            if path.suffix=='.md':raise OSError('Interrupted before record publication')
            return real_publish(path,text,expected)
        with patch.object(model_module,'publish',side_effect=interrupted):
            with self.assertRaises(OSError):create(self.root,'unit','First lesson',parent_id=parent['id'],operation_id=operation)
        self.assertEqual(operation_status(self.root,operation)['status'],'uncertain')
        create(self.root,'unit','Another lesson',parent_id=parent['id'],order=10)
        retry=create(self.root,'unit','First lesson',parent_id=parent['id'],operation_id=operation)
        self.assertEqual(retry['parent_ref']['order'],0)
        self.assertEqual(operation_status(self.root,operation)['status'],'committed')

    def test_problem_statement_projection_does_not_expose_reference(self):
        task=create(self.root,'task','Reconstruct equation','## Problem statement\n\nDerive the expression independently.\n\n## Reference\n\nThe saved solution.')
        view=overview(self.index(),task['id'])
        self.assertEqual(view['statement'],'Derive the expression independently.')
        legacy=create(self.root,'task','Legacy problem','A prior explanation without an explicit statement section.')
        self.assertIsNone(overview(self.index(),legacy['id'])['statement'])

    def test_search_resolves_external_identity_without_serializing_metadata(self):
        resource=create(self.root,'resource','Readable research title',fields={'source_kind':'paper','source':'https://doi.org/10.1234/example','external_aliases':['doi:10.1234/example']})
        study=record_activity(self.root,resource['path'],'study',state={'locator':{'kind':'page','value':2}})
        self.assertEqual(study['source_snapshot']['source'],'https://doi.org/10.1234/example')
        index=self.index()
        for query in ('10.1234/example','https://doi.org/10.1234/example','doi:10.1234/example',resource['id']):
            rows=index.query(query)['records'];self.assertEqual([row['id'] for row in rows],[resource['id']]);self.assertNotIn('props',rows[0])

    def tearDown(self):
        self.patch.stop();self.temp.cleanup()

    def index(self):
        index = Index(self.root);self.addCleanup(index.close);index.reconcile();return index

    def test_course_material_never_completes_assignments(self):
        course = create(self.root, 'resource', 'Six lecture course', fields={'medium': 'course'})
        units = [create(self.root, 'unit', 'Lecture ' + str(i), fields={'unit_kind': 'lecture'}) for i in range(6)]
        tasks = [create(self.root, 'task', 'Problem set ' + str(i)) for i in range(2)]
        project = create(self.root, 'project', 'Course project')
        for i, unit in enumerate(units):
            relationship(self.root, course['id'], unit['id'], 'contains', order=i)
            record_activity(self.root, unit['path'], 'study', state={'position': 'timestamp 12:30', 'status': 'read'})
        for task in tasks:relationship(self.root, units[-1]['id'], task['id'], 'assigns')
        relationship(self.root, course['id'], project['id'], 'references')
        index = self.index()
        self.assertEqual(index.record(units[-1]['id'])['state']['position'], 'timestamp 12:30')
        self.assertEqual([index.timeline(task['id']) for task in tasks], [[], []])
        self.assertEqual(index.timeline(project['id']), [])
        counts=overview(index,course['id'])['counts']
        self.assertEqual((counts['lectures']['consumed'],counts['lectures']['total']),(6,6))
        self.assertEqual((counts['assignments']['reported_success'],counts['assignments']['total']),(0,2))
        self.assertEqual((counts['projects']['reported_success'],counts['projects']['total']),(0,1))
        relationship(self.root, course['id'], units[-1]['id'], 'orders', order=0)
        self.assertEqual(len(index.timeline(units[-1]['id'])), 1)

    def test_import_metadata_change_and_new_doi_keep_analysis(self):
        source = self.home / 'export.json'
        key = lambda item: str(item.get('DOI') or item['id'])
        source.write_text(json.dumps([{'id': 'zotero:ABC', 'title': 'Original paper'}]))
        first = import_csl(self.root, source, {'types': {'paper': 'Resources'}}, key)
        path = self.root / first['created'][0]
        props, body = parse(path.read_text());identity = props['id']
        body += '\nMy independently written criticism.\n'
        path.write_text(render(props, body))
        source.write_text(json.dumps([{'id': 'zotero:ABC', 'DOI': '10.example/new', 'title': 'Corrected bibliography'}]))
        second = import_csl(self.root, source, {'types': {'paper': 'Resources'}}, key)
        updated, updated_body = parse(path.read_text())
        self.assertEqual(second['created'], [])
        self.assertEqual(updated['id'], identity)
        self.assertEqual(updated_body, body)
        self.assertEqual(updated['doi'], '10.example/new')
        self.assertEqual(updated['imported_title'], 'Corrected bibliography')
        self.assertEqual(len(list((self.root / 'Imports' / identity / 'bibliography').glob('*.md'))), 2)

    def test_derive_build_transfer_and_capability_are_explicit(self):
        task = create(self.root, 'task', 'Independent derivation', 'Assumption: smooth scalar function.')
        session = create(self.root, 'session', 'Derive session', fields={'status': 'active'})
        attempt = record_activity(self.root, task['path'], 'attempt', 'Counterexample rejects my first step.',
                                  outcome='failed', assistance=['none'], mode='derive', session=session['id'])
        assisted = record_activity(self.root, task['path'], 'attempt', 'Reference supplied missing chain rule.', outcome='succeeded', assistance=['reference'])
        independent = record_activity(self.root, task['path'], 'attempt', 'Reconstructed without reference.', outcome='succeeded', assistance=['none'])
        transfer = create(self.root, 'task', 'Changed function')
        relationship(self.root, task['id'], transfer['id'], 'references')
        record_activity(self.root, transfer['path'], 'attempt', 'Changed case passed numerical check.', outcome='succeeded', assistance=['none'], mode='transfer')
        capability = create(self.root, 'capability', 'Differentiate this function family', fields={'criteria': ['explain chain rule']})
        with self.assertRaises(ValueError):record_activity(self.root, capability['path'], 'capability-decision', 'Agent proposal', criterion='explain chain rule', evidence_id=independent['id'], decision='accept')
        decision = record_activity(self.root, capability['path'], 'capability-decision', 'Accepted only for scalar smooth functions.', criterion='explain chain rule', evidence_id=independent['id'], decision='accept', actor='learner')
        index = self.index()
        self.assertEqual([a['assistance'] for a in index.timeline(task['id'])], [['none'], ['reference'], ['none']])
        self.assertNotIn('mastery', index.record(capability['id'])['props'])
        self.assertEqual(index.timeline(capability['id'])[0]['evidence_id'], independent['id'])
        self.assertIn('Agent output is unverified material.', agent_context(index, task['id'])['rules'])

    def test_experiment_preserves_prediction_and_missing_artifact(self):
        experiment = create(self.root, 'experiment', 'Sensor baseline', 'Prediction: noise falls with speed.',
                            {'commit': 'synthetic-commit', 'units': 'm/s', 'configuration': {'rate': 100}})
        artifact = create(self.root, 'artifact', 'Raw measurements', fields={'location': str(self.home / 'missing-disk/data.mcap'), 'ownership': 'external'})
        relationship(self.root, experiment['id'], artifact['id'], 'produces')
        record_activity(self.root, experiment['path'], 'comparison', 'Measured noise increased; hypothesis contradicted.', artifact_id=artifact['id'], execution='succeeded', hypothesis='contradicted')
        index = self.index()
        self.assertEqual(index.record(artifact['id'])['artifact']['availability'], 'artifact unavailable')
        self.assertIn('noise falls', index.record(experiment['id'])['body'])
        self.assertEqual(index.timeline(experiment['id'])[0]['hypothesis'], 'contradicted')

    def test_explicit_artifact_checks_preserve_prediction_and_reference(self):
        file=self.home/'sensor.dat';file.write_bytes(b'synthetic measurement')
        artifact=create(self.root,'artifact','Sensor data',fields={'location':str(file),'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
        original=(self.root/artifact['path']).read_text()
        first=inspect_artifact(self.root,artifact['id'])
        self.assertEqual(first['integrity'],'matches expected checksum')
        file.write_bytes(b'changed measurement')
        self.assertEqual(inspect_artifact(self.root,artifact['id'])['integrity'],'checksum mismatch')
        file.unlink()
        self.assertEqual(inspect_artifact(self.root,artifact['id'])['availability'],'artifact unavailable')
        self.assertEqual((self.root/artifact['path']).read_text(),original)

    def test_gate_cycles_context_and_manual_parking(self):
        a, b = create(self.root, 'concept', 'A'), create(self.root, 'concept', 'B')
        relationship(self.root, a['id'], b['id'], 'prerequisite', role='parallel')
        relationship(self.root, b['id'], a['id'], 'prerequisite', role='parallel')
        gate = relationship(self.root, a['id'], b['id'], 'prerequisite', role='gate', reason='Required for this derivation')
        with self.assertRaisesRegex(ValueError, 'cycle'):relationship(self.root, b['id'], a['id'], 'prerequisite', role='gate')
        record_activity(self.root, gate['path'], 'disposition', 'Intentionally parked this path.', state='parked')
        index = self.index()
        self.assertEqual(next_actions(index), [])
        self.assertEqual(next_actions(index, quiet=True), [])

    def test_retry_idempotency_and_resolution_preserve_both_heads(self):
        task = create(self.root, 'task', 'Target')
        operation = str(uuid.uuid4())
        first = record_activity(self.root, task['path'], 'study', operation_id=operation, state={'position': 'page 1'})
        retry = record_activity(self.root, task['path'], 'study', operation_id=operation, state={'position': 'page 1'})
        self.assertEqual(first['id'], retry['id'])
        with self.assertRaises(ValueError):record_activity(self.root, task['path'], 'study', operation_id=operation, state={'position': 'page 2'})
        branch = dict(first, id=str(uuid.uuid4()), state={'position': 'page 3'}, timestamp=first['timestamp'] + '1')
        publish(self.root / 'Activity/branch.md', render(branch, 'Sync branch'))
        resolved = record_activity(self.root, task['path'], 'resolution', 'Selected page 3 after reviewing both histories.',
                                   previous=branch['id'], resolves=[first['id'], branch['id']], state={'position': 'page 3'})
        index = self.index()
        self.assertEqual(len(index.timeline(task['id'])), 3)
        self.assertEqual(index.record(task['id'])['state']['position'], 'page 3')
        self.assertEqual(index.record(task['id'])['activity_head'], resolved['id'])

    def test_commit_receipts_and_scoped_recommendations(self):
        path = create(self.root, 'path', 'Selected path')
        other = create(self.root, 'path', 'Other path')
        unit = create(self.root, 'unit', 'Selected lecture')
        unrelated = create(self.root, 'unit', 'Unrelated lecture')
        task = create(self.root, 'task', 'Assignment')
        relationship(self.root, path['id'], unit['id'], 'orders', order=0)
        relationship(self.root, other['id'], unrelated['id'], 'orders', order=0)
        relationship(self.root, unit['id'], task['id'], 'assigns')
        operation = str(uuid.uuid4())
        self.assertEqual(operation_status(self.root, operation)['status'], 'not-committed')
        recorded = record_activity(self.root, unit['path'], 'study', operation_id=operation,
                                   state={'status': 'read', 'position': 'timestamp 12:30'})
        self.assertEqual(operation_status(self.root, operation)['records'][0]['id'], recorded['id'])
        retry = record_activity(self.root, task['path'], 'attempt', 'Needs an independent retry.',
                                assistance=['reference'], outcome='succeeded', retry_requested=True)
        index = self.index()
        scoped = next_actions(index, path_id=path['id'])
        self.assertEqual([row['id'] for row in scoped], [task['id']])
        self.assertEqual(scoped[0]['evidence_id'], retry['id'])
        self.assertIn(unrelated['id'], [row['id'] for row in next_actions(index)])
        self.assertEqual(next_actions(index, quiet=True, path_id=path['id']), [])
        with self.assertRaisesRegex(ValueError, 'path'):next_actions(index, path_id=unit['id'])

    def test_interrupted_bibliography_pointer_reuses_projected_identity(self):
        source=self.home/'export.json';source.write_text(json.dumps([{'id':'synthetic-source','title':'Paper'}]))
        actual=import_module.publish
        def interrupt(path,*args,**kwargs):
            if path.parent.name=='Resources':raise OSError('Injected interruption before resource pointer')
            return actual(path,*args,**kwargs)
        with patch.object(import_module,'publish',side_effect=interrupt):
            with self.assertRaises(OSError):import_csl(self.root,source,{'types':{'paper':'Resources'}},lambda item:item['id'])
        projection=next((self.root/'Imports').rglob('*.md'))
        expected=parse(projection.read_text())[0]['resource_id']
        meta=json.loads((self.root/'System/System.json').read_text())
        result=import_csl(self.root,source,dict(meta,types={'paper':'Resources'}),lambda item:item['id'])
        self.assertEqual(parse((self.root/result['created'][0]).read_text())[0]['id'],expected)
        self.assertEqual(len(list((self.root/'Imports').rglob('*.md'))),1)
        self.assertEqual(json.loads(next((self.root/'Imports/Transactions').glob('*.json')).read_text())['status'],'committed')

    def test_connected_units_and_specific_resume_locations_rebuild(self):
        course=create(self.root,'resource','Linear algebra',fields={'source_kind':'course'})
        unit=create(self.root,'unit','Lecture 1',fields={'unit_kind':'lecture'},parent_id=course['id'],order=0)
        task=create(self.root,'task','Problem set 1',parent_id=unit['id'],relation='assigns')
        record_activity(self.root,unit['path'],'study',state={'locator':{'kind':'timestamp','value':'1:12:30'}})
        index=self.index()
        self.assertEqual(index.record(unit['id'])['state']['locator']['seconds'],4350)
        self.assertEqual(index.relations(course['id'])[0]['other_id'],unit['id'])
        self.assertEqual(overview(index,course['id'])['counts']['assignments']['total'],1)
        self.assertEqual(index.timeline(task['id']),[])
        with self.assertRaises(ValueError):record_activity(self.root,unit['path'],'study',state={'locator':{'kind':'timestamp','value':'12:99'}})
        with self.assertRaises(ValueError):record_activity(self.root,unit['path'],'study',state={'locator':{'kind':'page','value':0}})
        with self.assertRaises(ValueError):create(self.root,'unit','Invalid child',parent_id=str(uuid.uuid4()))
        self.assertFalse(list((self.root/'Records/unit').glob('Invalid*')))
        moved=self.root/'Moved lecture.md';(self.root/unit['path']).rename(moved)
        with index.db:
            for table in ('records','relationships','activities','search'):index.db.execute('DELETE FROM '+table)
        index.reconcile()
        self.assertEqual(index.relations(course['id'])[0]['other_path'],'Moved lecture.md')

    def test_review_planning_snooze_retirement_and_ordered_next_unit(self):
        course=create(self.root,'resource','Course')
        first=create(self.root,'unit','First unit',parent_id=course['id'])
        second=create(self.root,'unit','Second unit',parent_id=course['id'])
        task=create(self.root,'task','Retry this task')
        record_activity(self.root,task['path'],'attempt','Assisted result needs a retry.',outcome='succeeded',assistance=['reference'],retry_requested=True)
        index=self.index()
        self.assertEqual([r['id'] for r in next_actions(index) if r['type']=='unit'],[first['id']])
        operation=str(uuid.uuid4())
        planned=record_activity(self.root,task['path'],'review-plan','Reconstruct before opening the editorial.',operation,action='schedule',stage='retry')
        self.assertEqual(planned['interval_days'],1)
        self.assertEqual(record_activity(self.root,task['path'],'review-plan','Reconstruct before opening the editorial.',operation,action='schedule',stage='retry')['id'],planned['id'])
        later=record_activity(self.root,task['path'],'review-plan','Choose a quieter day.',action='snooze',stage='later')
        self.assertEqual(later['interval_days'],7)
        self.assertEqual(later['previous_plan'],planned['id'])
        retired=record_activity(self.root,task['path'],'review-plan','Intentionally retire this check.',action='retire',stage='maintenance')
        self.assertIsNone(retired['due'])
        with self.assertRaises(ValueError):record_activity(self.root,task['path'],'review-plan','Invalid interval',action='schedule',days=0)
        record_activity(self.root,first['path'],'study',state={'status':'read'})
        index.reconcile()
        self.assertEqual([r['id'] for r in next_actions(index) if r['type']=='unit'],[second['id']])
        self.assertNotIn(task['id'],[r['id'] for r in next_actions(index)])
        self.assertEqual(index.timeline(task['id'])[0]['assistance'],['reference'])

    def test_reveal_is_retained_and_independent_retry_gets_new_identity(self):
        task = create(self.root, 'task', 'Protected problem')
        started = record_activity(self.root, task['path'], 'attempt-start', mode='derive')
        restarted=self.index()
        self.assertEqual(restarted.record(task['id'])['attempt']['id'],started['id'])
        with self.assertRaisesRegex(ValueError,'unfinished'):record_activity(self.root,task['path'],'attempt-start',mode='derive')
        record_activity(self.root, task['path'], 'assistance', attempt_id=started['id'], assistance=['reference'])
        operation = str(uuid.uuid4())
        result = record_activity(self.root, task['path'], 'attempt', 'Corrected reasoning', operation_id=operation,
                                 attempt_id=started['id'], outcome='succeeded', assistance=['none'])
        self.assertEqual(result['assistance'], ['reference'])
        self.assertEqual(record_activity(self.root, task['path'], 'attempt', 'Corrected reasoning', operation_id=operation,
                                        attempt_id=started['id'], outcome='succeeded', assistance=['none'])['id'], result['id'])
        with self.assertRaises(ValueError):record_activity(self.root, task['path'], 'attempt', 'Overwrite claim', attempt_id=started['id'], outcome='succeeded')
        retry = record_activity(self.root, task['path'], 'attempt-start', mode='derive')
        independent = record_activity(self.root, task['path'], 'attempt', 'Later independent reconstruction',
                                      attempt_id=retry['id'], outcome='succeeded', assistance=['none'])
        self.assertEqual(independent['assistance'], ['none'])
        self.assertNotEqual(independent['attempt_id'], result['attempt_id'])

    def test_neural_network_gradient_bug_checks_survive_restart_and_move(self):
        x, weight, bias, target = 2.0, .3, -.1, .5
        def loss(w):return (math.tanh(w*x+bias)-target)**2
        epsilon = 1e-6
        numeric = (loss(weight+epsilon)-loss(weight-epsilon))/(2*epsilon)
        output = math.tanh(weight*x+bias)
        mistaken = 2*(output-target)*(1-output**2)
        corrected = mistaken*x
        self.assertGreater(abs(mistaken-numeric), 1e-3)
        self.assertAlmostEqual(corrected, numeric, places=7)
        project = create(self.root, 'project', 'Tiny network from scratch', 'Prediction: the implemented gradient matches finite differences.',
                         {'environment': 'synthetic Python fixture', 'data': {'x': x, 'target': target}, 'configuration': {'weight': weight, 'bias': bias}})
        task = create(self.root, 'task', 'Derive and implement weight gradient', 'Assumption: smooth tanh and squared error.')
        relationship(self.root, project['id'], task['id'], 'references')
        failed = record_activity(self.root, task['path'], 'attempt', f'Missing x factor: implemented {mistaken}, numerical {numeric}.',
                                 outcome='failed', assistance=['none'], mode='build', assessment='synthetic numerical check')
        record_activity(self.root, task['path'], 'correction', 'Chain rule contributes the input multiplier.', supersedes=failed['id'], assistance=['reference'])
        record_activity(self.root, task['path'], 'attempt', f'Corrected {corrected} matches {numeric} within 1e-7.',
                        outcome='succeeded', assistance=['reference'], mode='build', assessment='synthetic numerical check')
        before = self.index().relations(project['id'])
        moved = self.root / 'moved-task.md';(self.root / task['path']).rename(moved)
        for file in (self.home / '.cache/noesis').glob('*.sqlite'):file.unlink()
        rebuilt = self.index()
        self.assertEqual(rebuilt.record(task['id'])['path'], 'moved-task.md')
        self.assertEqual(rebuilt.relations(project['id'])[0]['other_path'], 'moved-task.md')
        self.assertEqual(len(rebuilt.timeline(task['id'])), 3)
        self.assertIn('Prediction:', rebuilt.record(project['id'])['body'])


if __name__ == '__main__':unittest.main()
