import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('codex_accounts', ROOT/'home/.local/share/sensei/codex_accounts.py')
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)

class CodexAccountStateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.path = Path(self.tmp.name)/'accounts.json'
    def tearDown(self): self.tmp.cleanup()
    def test_ids_bind_account_identity_and_source_not_rename(self):
        original=mod.stable_id('profile','/profiles/a')
        self.assertEqual(original,mod.stable_id('profile','/profiles/a'))
        self.assertNotEqual(original,mod.stable_id('omp','/profiles/a'))
        self.assertNotEqual(original,mod.stable_id('profile','/profiles/b'))
    def test_cache_identity_isolation_and_stale_failure_preserves_measurement_time(self):
        state=mod.empty_state(); measurement={'rateLimits':{'primary':{'resetsAt':5000}},'fetchedAt':1000,'source':'native'}
        mod.save_measurement(state,'account-a','omp','identity-a',measurement,now=1100)
        self.assertIsNone(mod.cached(state,'account-a','omp','identity-b',now=1200))
        stale=mod.failed_result(state,'account-a','omp','identity-a','network',now=1600)
        self.assertEqual(stale['fetchedAt'],1000); self.assertTrue(stale['stale']); self.assertEqual(stale['error'],'network')
    def test_expired_quota_is_not_reported_as_current(self):
        state=mod.empty_state(); mod.save_measurement(state,'a','omp','i',{'rateLimits':{'primary':{'resetsAt':999}},'fetchedAt':900},now=950)
        result=mod.cached(state,'a','omp','i',now=1000)
        self.assertEqual(result['state'],'expired'); self.assertTrue(result['stale'])
    def test_malformed_response_does_not_replace_last_good_cache(self):
        state=mod.empty_state(); good={'rateLimits':{},'fetchedAt':900}
        mod.save_measurement(state,'a','omp','i',good,now=950)
        with self.assertRaises(ValueError): mod.save_measurement(state,'a','omp','i',{'rateLimits':None,'fetchedAt':999},now=1000)
        self.assertEqual(mod.cached(state,'a','omp','i',now=1000)['fetchedAt'],900)
    def test_remove_only_unmonitors_and_preserves_credentials(self):
        state=mod.empty_state(); credentials={'auth.json':b'unchanged'}
        mod.monitor(state,{'id':'a','source':'profile','identity':'/existing','name':'Mine'})
        mod.save_measurement(state,'a','profile','/existing',{'rateLimits':{},'fetchedAt':900},now=950)
        mod.unmonitor(state,'a')
        self.assertEqual(credentials['auth.json'],b'unchanged')
        self.assertNotIn('a',state['monitored']); self.assertNotIn('a',state['cache'])
        mod.monitor(state,{'id':'a','source':'profile','identity':'/existing','name':'Renamed'})
        self.assertEqual(state['monitored']['a']['identity'],'/existing')
    def test_state_file_is_private_and_round_trips(self):
        state=mod.empty_state(); mod.monitor(state,{'id':'x','source':'omp','identity':'abc','name':'A'})
        mod.write_state(self.path,state)
        self.assertEqual(self.path.stat().st_mode & 0o777,0o600)
        self.assertEqual(mod.read_state(self.path)['monitored']['x']['identity'],'abc')

if __name__=='__main__': unittest.main()
