import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import uuid

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'home/.local/share/sensei-learning'))
from noesis.persistence import migration, parse, publish, render
from noesis.models import create, relationship
from noesis.activities import record_activity, progress_state
from noesis.index import Index
from noesis.imports import import_csl
from noesis.policies import next_actions, agent_context


class Workflows(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.home = Path(self.temp.name)
        self.patch = patch('pathlib.Path.home', return_value=self.home);self.patch.start()
        self.root = self.home / 'vault'
        (self.root / 'System').mkdir(parents=True)
        (self.root / 'System/System.json').write_text(json.dumps({'directories': [], 'types': {'paper': 'Resources'}}))
        migration(self.root, True)

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

    def test_reveal_is_retained_and_independent_retry_gets_new_identity(self):
        task = create(self.root, 'task', 'Protected problem')
        started = record_activity(self.root, task['path'], 'attempt-start', mode='derive')
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


if __name__ == '__main__':unittest.main()
