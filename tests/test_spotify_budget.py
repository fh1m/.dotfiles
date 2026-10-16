import importlib.util
from pathlib import Path
import tempfile
import unittest
ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('spotify_budget', ROOT/'home/.local/share/sensei/spotify_budget.py')
mod = importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)

class BudgetTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.now=10000
        self.b=mod.Budget(self.tmp.name,lambda:self.now)
    def tearDown(self): self.tmp.cleanup()
    def test_full_server_wait_survives_process_restart(self):
        self.b.transact('penalise',seconds=7200)
        self.now+=901
        other=mod.Budget(self.tmp.name,lambda:self.now)
        self.assertFalse(other.transact('acquire')['allowed'])
        self.now+=6301
        self.assertTrue(other.transact('acquire')['allowed'])
    def test_quota_does_not_invent_a_reset(self):
        self.b.transact('penalise',seconds=10,reason='QUOTA_EXCEEDED');self.now+=86400
        self.assertEqual(self.b.transact('acquire')['reason'],'quota')
        self.b.transact('reset');self.assertTrue(self.b.transact('acquire')['allowed'])
    def test_processes_share_budget(self):
        for _ in range(10):self.assertTrue(mod.Budget(self.tmp.name,lambda:self.now).transact('acquire')['allowed'])
        self.assertFalse(self.b.transact('acquire')['allowed'])
        self.now+=31;self.assertTrue(self.b.transact('acquire')['allowed'])
    def test_corrupt_state_fails_closed_without_overwrite(self):
        p=Path(self.tmp.name)/'web-api-budget.json';p.write_text('broken')
        self.assertEqual(self.b.transact('acquire')['reason'],'state_invalid')
        self.assertEqual(p.read_text(),'broken')

    def test_structurally_invalid_json_cannot_bypass_or_crash_gate(self):
        import json
        base={'schema':1,'until':0,'quota':False,'stamps':[],'counts':{}}
        for change in [{'stamps':['bad']},{'stamps':[float('nan')]},{'until':[]},
                       {'counts':[]},{'counts':{'player':-1}},{'quota':'false'},{'schema':2},{'until':10**1000}]:
            with self.subTest(change=change):
                path=Path(self.tmp.name)/'web-api-budget.json';raw=json.dumps(dict(base,**change));path.write_text(raw)
                self.assertEqual(self.b.transact('acquire')['reason'],'state_invalid')
                self.assertEqual(path.read_text(),raw)

if __name__=='__main__':unittest.main()
