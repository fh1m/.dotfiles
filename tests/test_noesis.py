import importlib.machinery
import importlib.util
import json
import os
import subprocess
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'home/.local/share/sensei-learning'))
from noesis.persistence import parse, render, migration, publish
from noesis.activities import record_activity, progress_state, validate_progress
from noesis.index import Index


class Core(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.home = Path(self.temp.name)
        self.patch = patch('pathlib.Path.home', return_value=self.home)
        self.patch.start()
        self.root = self.home / 'vault'
        (self.root / 'System').mkdir(parents=True)
        (self.root / 'System/System.json').write_text(json.dumps({'directories': ['Notes'], 'templates': 'Templates'}))
        self.note = self.root / 'target.md'
        self.note.write_text(render({'type': 'task', 'unknown_user_field': ['preserved'], 'progress_total': 10}, '\nMy original prediction.\n'))

    def tearDown(self):
        self.patch.stop()
        self.temp.cleanup()

    def migrate(self):
        migration(self.root, True)
        return parse(self.note.read_text())[0]['id']

    def test_migration_preserves_authored_line_endings_and_original_backup_bytes(self):
        before=b'---\r\ntype: task\r\n---\r\n\r\nPrediction and derivation.\r\nA preserved mistaken step.\r\n'
        self.note.write_bytes(before)
        original_body=parse(before.decode())[1]
        result=migration(self.root,True)
        self.assertEqual(parse(self.note.read_bytes().decode())[1],original_body)
        self.assertEqual((Path(result['backup'])/'target.md').read_bytes(),before)

    def test_future_schema_is_readable_without_silent_downgrade(self):
        import uuid
        identity=str(uuid.uuid4())
        self.note.write_text(render({'id':identity,'noesis_schema':99,'type':'future-kind'},'A future record remains mine.'))
        original=self.note.read_text()
        for apply in (False,True):
            with self.assertRaisesRegex(ValueError,'Unsupported Noesis schema'):migration(self.root,apply)
            self.assertEqual(self.note.read_text(),original)
        index=Index(self.root)
        try:
            index.reconcile();self.assertEqual(index.record(identity)['body'],'A future record remains mine.')
        finally:index.close()

    def test_malformed_frontmatter_is_never_rewritten(self):
        for text in ('---\na: 1\n---oops\nbody', '---\na: 1\na: 2\n---\nbody', '---\n[bad\n---\nbody'):
            self.note.write_text(text)
            with self.assertRaises(Exception):migration(self.root, True)
            self.assertEqual(self.note.read_text(), text)
        props, body = parse('---\na: 1\n---\n---oops\nbody')
        self.assertEqual(props, {'a': 1})
        self.assertTrue(body.startswith('---oops'))

    def test_migration_idempotent_preserves_prose_and_unknown_fields(self):
        before = self.note.read_text()
        dry = migration(self.root)
        self.assertEqual(self.note.read_text(), before)
        self.assertEqual(dry['changed'], ['target.md'])
        identity = self.migrate()
        migrated = self.note.read_text()
        self.assertEqual(migration(self.root, True)['changed'], [])
        self.assertEqual(self.note.read_text(), migrated)
        props, body = parse(migrated)
        self.assertEqual(props['unknown_user_field'], ['preserved'])
        self.assertEqual(body, '\nMy original prediction.\n')
        self.assertEqual(props['id'], identity)

    def test_merged_progress_and_preserved_note(self):
        identity = self.migrate()
        before = self.note.read_text()
        with self.assertRaises(ValueError):record_activity(self.root, 'target.md', 'study', state={'progress_current': 11})
        a = record_activity(self.root, 'target.md', 'study', state={'progress_current': 9})
        with self.assertRaises(ValueError):record_activity(self.root, 'target.md', 'study', state={'progress_total': 8})
        index = Index(self.root)
        try:
            index.reconcile()
            state, head = progress_state(parse(before)[0], index.timeline(identity))
            self.assertEqual(state['progress_current'], 9)
            self.assertEqual(head, a['id'])
        finally:index.close()
        self.assertEqual(self.note.read_text(), before)

    def test_unknown_and_invalid_counts(self):
        validate_progress(0, None)
        validate_progress(None, 1)
        for current, total in [(True, 2), (-1, 2), (1, 0), (1.1, 2), (1, '2'), (3, 2)]:
            with self.assertRaises(ValueError):validate_progress(current, total)

    def test_attempts_survive_move_and_cache_deletion(self):
        identity = self.migrate()
        for outcome, assistance in [('failed', ['none']), ('succeeded', ['reference']), ('succeeded', ['none'])]:
            record_activity(self.root, 'target.md', 'attempt', 'Observed result', outcome=outcome, assistance=assistance)
        self.note.rename(self.root / 'renamed.md')
        for _ in range(2):
            index = Index(self.root)
            try:
                index.reconcile()
                self.assertEqual(index.record(identity)['path'], 'renamed.md')
                events = index.timeline(identity)
                self.assertEqual([e['outcome'] for e in events], ['failed', 'succeeded', 'succeeded'])
                self.assertEqual(events[1]['assistance'], ['reference'])
            finally:index.close()
            for p in (self.home / '.cache/noesis').glob('*'):p.unlink()

    def test_duplicates_block_mutation(self):
        self.migrate()
        (self.root / 'duplicate.md').write_text(self.note.read_text())
        with self.assertRaises(ValueError):record_activity(self.root, 'target.md', 'attempt', 'Evidence', outcome='failed')
        self.assertFalse((self.root / 'Activity').exists())

    def test_conflicting_heads_are_explicit(self):
        identity = self.migrate()
        event = record_activity(self.root, 'target.md', 'study', state={'position': 'section 1'})
        raw = dict(event, id='00000000-0000-0000-0000-000000000001', previous=None)
        publish(self.root / 'Activity/divergence.md', render(raw, 'Divergent sync head'))
        with self.assertRaisesRegex(ValueError, 'Divergent'):
            record_activity(self.root, 'target.md', 'study', state={'position': 'section 3'})

    def test_exclusive_publication_and_query_bound(self):
        with self.assertRaises(FileExistsError):publish(self.note, 'overwritten')
        for i in range(101):publish(self.root / ('note' + str(i) + '.md'), 'searchable Unicode ঢাকা')
        index = Index(self.root)
        try:
            index.reconcile()
            first = index.query('ঢাকা')
            self.assertEqual(len(first['records']), 50)
            self.assertEqual(first['cursor'], 50)
            self.assertEqual(len(index.query('ঢাকা', cursor=50)['records']), 50)
            generation = index.generation
            index.reconcile()
            self.assertEqual(index.generation, generation)
        finally:index.close()

    def test_changed_file_update_does_not_walk_vault(self):
        self.migrate()
        index = Index(self.root)
        try:
            index.reconcile()
            self.note.write_text(self.note.read_text() + 'New phrase delta.\n')
            with patch('noesis.index.notes', side_effect=AssertionError('Full walk forbidden')):
                index.reconcile(['target.md'])
            self.assertEqual(len(index.query('delta')['records']), 1)
            self.note.unlink()
            index.reconcile(['target.md'])
            self.assertEqual(index.query('delta')['records'], [])
        finally:index.close()

    def test_core_cli_without_any_obsidian_executable(self):
        self.migrate()
        env = dict(os.environ, HOME=str(self.home), PATH='/nonexistent')
        executable = str(ROOT / 'home/.local/bin/sensei-learn')
        def run(*args):
            result = subprocess.run([sys.executable, executable, *args, '--vault', str(self.root)], env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout
        captured = run('capture', 'Unclassified observation')
        self.assertTrue(Path(captured.strip()).is_file())
        run('progress', 'target.md', '--position', 'page 9', '--current', '9')
        run('attempt', 'target.md', '--result', 'failed', '--evidence', 'Counterexample', '--assistance', 'none')
        self.assertEqual(len(json.loads(run('query', 'observation'))['records']), 1)
        self.assertEqual(len(json.loads(run('query', 'observ'))['records']), 1)
        self.assertIn('page 9', run('timeline', parse(self.note.read_text())[0]['id']))
        recording = self.home / 'measurements.mcap'
        with recording.open('wb') as handle:
            handle.truncate(26 * 1024 * 1024)
        original = self.note.read_text()
        attachment = json.loads(run('attach', str(recording), '--note', 'target.md'))
        self.assertTrue(attachment['referenced'])
        self.assertEqual(self.note.read_text(), original)
        self.assertFalse((self.root / 'Attachments' / recording.name).exists())
        self.assertTrue(recording.is_file())


if __name__ == '__main__':unittest.main()
