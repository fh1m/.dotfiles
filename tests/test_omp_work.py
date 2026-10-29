import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('omp_work', ROOT/'home/.local/share/omp-den/work.py')
work = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(work)


class WorkTests(unittest.TestCase):
    def test_container_command_preserves_literal_arguments(self):
        p = {'cwd': '/work/a b', 'environment': 'auv-ros2', 'ros': 'humble'}
        argv = work.execution(p, ['printf', '%s', '$(touch /tmp/unsafe)'], interactive=False)
        self.assertEqual(argv[:2], ['docker', 'exec'])
        self.assertIn('/work/a b', argv)
        self.assertEqual(argv[-3:], ['printf', '%s', '$(touch /tmp/unsafe)'])
        self.assertIn('exec "$@"', argv[argv.index('-c')+1])

    def test_host_execution_does_not_route_to_container(self):
        argv = work.execution({'cwd': '/tmp', 'environment': 'host', 'ros': None}, ['git', 'status'])
        self.assertEqual(argv, ['git', 'status'])

    def test_rupsha_has_own_runtime(self):
        config = work.load_config(ROOT/'home/.local/share/omp-den/projects.json')
        self.assertEqual(config['projects']['rupsha']['environment'], 'rupsha_dev')
        self.assertEqual(work.project(config, 'megdhut')[0], 'meghdhut')

    def test_unknown_project_is_rejected(self):
        with self.assertRaises(ValueError): work.project({'projects': {}, 'aliases': {}}, 'unknown')

    def test_handoff_retains_last_task_state_and_assistance(self):
        rows = [
            {'type':'session','id':'one','cwd':'/work'},
            {'type':'message','message':{'role':'user','content':[{'type':'text','text':'Fix estimator'}]}},
            {'type':'message','message':{'role':'assistant','content':[{'type':'toolCall','name':'todo','arguments':{'op':'init','items':['Measure drift','Check frames']}}]}},
            {'type':'message','message':{'role':'assistant','content':[{'type':'toolCall','name':'todo','arguments':{'op':'done','task':'Measure drift'}}]}},
            {'type':'message','message':{'role':'assistant','content':[{'type':'text','text':'Hint-assisted derivation; check actual hardware later.'}]}}
        ]
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp)/'session.jsonl'; p.write_text('\n'.join(json.dumps(x) for x in rows))
            result = work.handoff(p)
        self.assertEqual(result['last_request'], 'Fix estimator')
        self.assertEqual(result['last_task_event']['task'], 'Measure drift')
        self.assertIn('Hint-assisted', result['last_reply'])
        self.assertFalse(result['verified_current'])
        self.assertEqual(result['historical_tasks'], [
            {'task':'Measure drift','status':'completed'},
            {'task':'Check frames','status':'pending'}])

    def test_title_prefers_original_metadata(self):
        self.assertEqual(work.title_candidate('Real source title', ['continue']), 'Real source title')

    def test_title_skips_context_and_continuations(self):
        self.assertEqual(work.title_candidate('', ['<environment_context>stuff</environment_context>', 'continue', 'Repair sensor timestamp alignment']), 'Repair sensor timestamp alignment')

    def test_title_never_invents_subject_for_empty_transcript(self):
        self.assertIsNone(work.title_candidate('', ['continue', 'ok']))

    def test_native_custom_title_detected(self):
        self.assertEqual(work.header([{'type':'title','title':'My own title'},{'type':'session','id':'s'}])['title'], 'My own title')

    def test_safe_scope_handles_similarly_named_sibling(self):
        self.assertTrue(work.in_project('/work/mongla/src', '/work/mongla'))
        self.assertFalse(work.in_project('/work/mongla-old', '/work/mongla'))

if __name__ == '__main__': unittest.main()
