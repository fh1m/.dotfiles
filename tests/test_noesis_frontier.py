import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'home/.local/share/sensei-learning'))
from noesis.activities import record_activity
from noesis.frontier import claims, claim_page, frontier
from noesis.index import Index
from noesis.models import create
from noesis.persistence import migration, publish, render


class Frontier(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.home = Path(self.temp.name)
        self.patch = patch('pathlib.Path.home', return_value=self.home)
        self.patch.start()
        self.root = self.home / 'vault'
        (self.root / 'System').mkdir(parents=True)
        (self.root / 'System/System.json').write_text(json.dumps({'directories': ['Notes']}))
        migration(self.root, True)
        self.concept = create(self.root, 'concept', 'Convolution')
        self.question = create(self.root, 'question', 'What changes at the boundary?', parent_id=self.concept['id'])
        self.capability = create(self.root, 'capability', 'Explain convolution', parent_id=self.concept['id'])
        start = record_activity(self.root, self.question['path'], 'attempt-start', 'Predict zero padding changes edge values', assistance=['none'])
        self.assessment = record_activity(self.root, self.question['path'], 'attempt', 'Hand calculation matched the oracle',
                                          attempt_id=start['id'], outcome='succeeded', assistance=['none'])

    def tearDown(self):
        self.patch.stop()
        self.temp.cleanup()

    def decision(self, **extra):
        fields = dict(actor='learner', criterion='Explain boundary behavior', dimension='explain',
                      scope='A three-element signal with zero padding', evidence_kind='explanation',
                      evidence_id=self.assessment['id'], decision='accept', confidence='low', independent=True)
        fields.update(extra)
        return record_activity(self.root, self.capability['path'], 'capability-decision', 'Scoped learner judgment', **fields)

    def test_complete_history_preserves_old_dimension_and_withdrawal(self):
        first = self.decision()
        for i in range(55):
            self.decision(criterion='Other criterion ' + str(i), independent=False)
        self.decision(decision='withdraw', supersedes=first['id'])
        index = Index(self.root)
        try:
            index.reconcile()
            row = next(row for row in claims(index, self.capability['id']) if row['criterion'] == first['criterion'])
            self.assertEqual(row['decision'], 'withdraw')
            self.assertEqual(row['decision_count'], 2)
            self.assertEqual(len(claims(index, self.capability['id'])), 56)
        finally:
            index.close()

    def test_competing_claims_are_not_resolved_by_timestamp(self):
        self.decision()
        self.decision(decision='reject')
        index = Index(self.root)
        try:
            index.reconcile()
            row = claims(index, self.capability['id'])[0]
            self.assertEqual(row['decision'], 'conflict')
            self.assertFalse(row['independent'])
        finally:
            index.close()

    def test_exposure_cannot_be_washed_away_by_claim(self):
        self.decision()
        record_activity(self.root, self.question['path'], 'assistance', 'Reference consulted',
                        attempt_id=self.assessment['attempt_id'], assistance=['reference'])
        with self.assertRaisesRegex(ValueError, 'without recorded exposure'):
            self.decision()
        index = Index(self.root)
        try:
            index.reconcile()
            self.assertFalse(claims(index, self.capability['id'])[0]['independent'])
        finally:
            index.close()

    def test_conflict_resolution_must_name_all_current_heads(self):
        first = self.decision()
        second = self.decision(decision='reject')
        with self.assertRaisesRegex(ValueError, 'all current conflicting'):
            self.decision(resolves=[first['id']])
        resolved = self.decision(resolves=[first['id'], second['id']], independent=False)
        index = Index(self.root)
        try:
            index.reconcile()
            row = claims(index, self.capability['id'])[0]
            self.assertEqual(row['decision'], 'accept')
            self.assertEqual(row['head_ids'], [resolved['id']])
            self.assertEqual(row['decision_count'], 3)
            self.assertFalse(row['independent'])
        finally:
            index.close()

    def test_foreign_identity_and_wrong_supersession_rejected(self):
        import uuid
        with self.assertRaisesRegex(ValueError, 'unavailable'):
            self.decision(evidence_id=None, evidence_refs=[{'vault_id': str(uuid.uuid4()), 'record_id': self.assessment['id']}])
        first = self.decision()
        with self.assertRaisesRegex(ValueError, 'same criterion'):
            self.decision(criterion='Another ability', supersedes=first['id'])

    def test_frontier_paging_is_owner_generation_and_record_bound(self):
        for i in range(52):
            create(self.root, 'question', 'Unanswered mechanism ' + str(i), parent_id=self.concept['id'])
        index = Index(self.root)
        try:
            index.reconcile()
            first = frontier(index, self.concept['id'])
            second = frontier(index, self.concept['id'], first['cursor'])
            self.assertTrue(first['cursor'])
            self.assertFalse(set(row['id'] for row in first['items']) & set(row['id'] for row in second['items']))
            with self.assertRaisesRegex(ValueError, 'another context'):
                frontier(index, self.question['id'], first['cursor'])
            publish(self.root / 'new.md', render({'type': 'concept'}, 'Changed generation'))
            index.reconcile()
            with self.assertRaisesRegex(ValueError, 'changed'):
                frontier(index, self.concept['id'], first['cursor'])
        finally:
            index.close()

    def test_depth_and_attempt_survive_move_and_cache_rebuild(self):
        record_activity(self.root, self.question['path'], 'disposition', 'Deeper reconstruction', state={'depth': 'deep'})
        (self.root / self.question['path']).rename(self.root / 'moved-question.md')
        index = Index(self.root)
        try:
            index.reconcile()
            projection = frontier(index, self.concept['id'])
            question = next(row for row in projection['items'] if row['id'] == self.question['id'])
            self.assertEqual(question['depth'], 'deep')
            self.assertEqual(question['path'], 'moved-question.md')
            self.assertEqual(len(index.timeline(self.question['id'])), 3)
        finally:
            index.close()

    def test_motivation_is_reachable_on_every_frontier_page(self):
        for number in range(52):
            create(self.root, 'question', 'Child inquiry ' + str(number), parent_id=self.question['id'])
        index = Index(self.root)
        try:
            index.reconcile()
            first = frontier(index, self.question['id'])
            second = frontier(index, self.question['id'], first['cursor'])
            for page in (first, second):
                self.assertEqual(page['origin']['id'], self.concept['id'])
                self.assertEqual(page['origin']['vault_id'], index.manifest['vault_id'])
                self.assertEqual(page['origin']['path'], self.concept['path'])
        finally:
            index.close()

    def test_criteria_beyond_first_page_remain_reachable(self):
        for number in range(24):
            self.decision(criterion='Specific mechanism ' + str(number))
        index = Index(self.root)
        try:
            index.reconcile()
            seen = []
            cursor = None
            while True:
                page = claim_page(index, self.capability['id'], cursor)
                seen.extend(row['criterion'] for row in page['evidence'])
                cursor = page['claim_cursor']
                if not cursor:
                    break
            self.assertEqual(len(set(seen)), 24)
        finally:
            index.close()

    def test_retention_requires_performed_later_assessment_not_schedule(self):
        from datetime import datetime, timezone, timedelta
        first = self.decision()
        with self.assertRaisesRegex(ValueError, 'successful later assessment'):
            self.decision(dimension='retained', retained_from=first['id'], interval_days=1)
        future = datetime.now(timezone.utc) + timedelta(days=2)
        with patch('noesis.activities.datetime') as clock:
            clock.now.return_value = future
            later = record_activity(self.root, self.question['path'], 'review', 'Later assessment in a simulated unit-test clock',
                                    outcome='succeeded', assistance=['unknown'])
            self.decision(dimension='retained', retained_from=first['id'], interval_days=1,
                          evidence_id=later['id'], independent=False)
        index = Index(self.root)
        try:
            index.reconcile()
            retained = next(row for row in claims(index, self.capability['id']) if row['dimension'] == 'retained')
            self.assertEqual(retained['decision'], 'accept')
            self.assertFalse(retained['independent'])
        finally:
            index.close()

    def test_withdrawn_or_conflicted_ability_cannot_support_retention(self):
        first = self.decision()
        withdrawn = self.decision(decision='withdraw', supersedes=first['id'])
        with self.assertRaisesRegex(ValueError, 'unwithdrawn'):
            self.decision(dimension='retained', retained_from=first['id'], interval_days=1)
        index = Index(self.root)
        try:
            index.reconcile()
            row = claims(index, self.capability['id'])[0]
            self.assertEqual(row['decision_id'], withdrawn['id'])
            self.assertFalse(row['independent'])
        finally:
            index.close()
