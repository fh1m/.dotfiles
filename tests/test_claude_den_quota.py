import runpy,unittest,tempfile,json
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
g=runpy.run_path(str(ROOT/'home/.local/bin/sensei-code'))
class Quotas(unittest.TestCase):
 def test_newest_same_account_receipt_wins_without_adding_percentages(self):
  f=g['claude_limits'];ns=f.__globals__
  with patch.dict(ns,{'cached':lambda p:{'updated_at':'2026-10-22T10:00:00Z','five_hour':{'used_percentage':10}},'claude_quota_key':lambda d:'same','peer_claude_quotas':lambda:{'host':'homie','rows':[{'key':'other','snapshot':{'updated_at':'2026-10-22T12:00:00Z'}},{'key':'same','snapshot':{'updated_at':'2026-10-22T11:00:00Z','five_hour':{'used_percentage':22}}}]}}):
   result=f('/tmp/account');self.assertEqual(result['sourceHost'],'homie');self.assertEqual(result['fiveHour']['used_percentage'],22)
 def test_no_identity_never_imports_another_accounts_quota(self):
  f=g['claude_limits'];ns=f.__globals__
  with patch.dict(ns,{'cached':lambda p:{},'claude_quota_key':lambda d:None,'peer_claude_quotas':lambda:self.fail('must not query peer')}):self.assertIsNone(f('/tmp/account'))
 def test_export_contains_only_hash_and_receipt(self):
  f=g['claude_quota_export'];ns=f.__globals__
  with patch.dict(ns,{'claude_accounts':lambda:[{'configDir':'/tmp/account'}],'claude_quota_key':lambda d:'hash','claude_identity':lambda d:{'signedIn':True},'cached':lambda p:{'updated_at':'now','five_hour':{'used_percentage':20}}}):
   row=f()['rows'][0];self.assertEqual(set(row),{'key','snapshot','identity'});self.assertEqual(row['key'],'hash')
if __name__=='__main__':unittest.main()
