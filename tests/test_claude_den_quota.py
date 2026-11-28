"""Cross-host subscription observations must not mix identities or activity totals."""
import runpy
import time
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
g=runpy.run_path(str(ROOT/'home/.local/bin/sensei-code'))

class Quotas(unittest.TestCase):
 def test_newest_same_account_native_observation_wins_without_adding_percentages(self):
  f=g['claude_limits'];ns=f.__globals__;now=time.time()
  local={'source':'native-claude-cli','measurementAt':now-20,'fiveHour':{'used_percentage':10}}
  remote={'source':'native-claude-cli','measurementAt':now-10,'fiveHour':{'used_percentage':22}}
  unrelated=dict(remote,measurementAt=now,fiveHour={'used_percentage':99})
  with patch.dict(ns,{'claude_quota_key':lambda **kw:'same','peer_claude_quotas':lambda:{'host':'homie','available':True,'rows':[{'key':'other','snapshot':unrelated},{'key':'same','snapshot':remote}]}}):
   result=f('/tmp/account',{'email':'learner@example.invalid'},local)
  self.assertEqual(result['sourceHost'],'homie')
  self.assertEqual(result['fiveHour']['used_percentage'],22)

 def test_identityless_profile_never_imports_another_accounts_quota(self):
  f=g['claude_limits'];ns=f.__globals__
  with patch.dict(ns,{'claude_quota_key':lambda **kw:None,'peer_claude_quotas':lambda:self.fail('must not query peer')}):
   self.assertIsNone(f('/tmp/account',{'state':'needs-sign-in'},{}))

 def test_legacy_statusline_or_newer_wrong_identity_cannot_replace_native_measurement(self):
  f=g['claude_limits'];ns=f.__globals__;now=time.time()
  local={'source':'native-claude-cli','measurementAt':now-20,'fiveHour':{'used_percentage':17}}
  with patch.dict(ns,{'claude_quota_key':lambda **kw:'same','peer_claude_quotas':lambda:{'host':'homie','rows':[{'key':'same','snapshot':{'updated_at':'later','five_hour':{'used_percentage':99}}}]}}):
   self.assertEqual(f('/tmp/account',{'email':'learner@example.invalid'},local)['fiveHour']['used_percentage'],17)

 def test_organization_is_part_of_subscription_identity(self):
  key=g['claude_quota_key']
  self.assertNotEqual(key(identity={'email':'a@example.invalid','organizationId':'one'}),key(identity={'email':'a@example.invalid','organizationId':'two'}))
  self.assertEqual(key(identity={'email':'A@EXAMPLE.INVALID','organizationId':'one'}),key(identity={'email':'a@example.invalid','organizationId':'one'}))

if __name__=='__main__':unittest.main()
