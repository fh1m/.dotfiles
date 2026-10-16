import importlib.machinery
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
l=importlib.machinery.SourceFileLoader('continuity',str(ROOT/'home/.local/bin/sensei-den'));s=importlib.util.spec_from_loader(l.name,l);m=importlib.util.module_from_spec(s);l.exec_module(m)
class Continuity(unittest.TestCase):
    def setUp(self):
        self.t=tempfile.TemporaryDirectory();self.root=Path(self.t.name)
        self.p=patch.object(m,'CONFIG',self.root/'config');self.p.start()
    def tearDown(self):self.p.stop();self.t.cleanup()
    def test_offline_modes_keep_local_host_usable(self):
        with patch.object(m,'host',return_value='homie'):self.assertEqual(m.current_mode(False)['effective'],'homie')
        with patch.object(m,'host',return_value='arete'):self.assertEqual(m.current_mode(False)['effective'],'away')
    def test_explicit_override_survives_peer_presence(self):
        m.write(m.CONFIG/'continuity.json',{'mode':'away'})
        self.assertEqual(m.current_mode(True)['effective'],'away')
    def test_corrupt_config_is_not_silently_replaced(self):
        m.CONFIG.mkdir();p=m.CONFIG/'companion.json';p.write_text('{broken')
        with self.assertRaises(ValueError):m.companion('toggle')
        self.assertEqual(p.read_text(),'{broken')
    def test_quiet_is_independent_of_visibility(self):
        m.companion('hide');m.companion('quiet','on');m.companion('show')
        self.assertTrue(m.companion('status')['quiet']);self.assertTrue(m.companion('status')['enabled'])
    def test_owned_job_identifiers_cannot_be_paths(self):
        from argparse import Namespace
        a=Namespace(host=None,action='cancel',id='../other',project=None,command=[])
        with patch.object(m,'STATE',self.root/'state'),self.assertRaises(ValueError):m.job(a)
    def test_malformed_state_is_preserved(self):
        p=self.root/'state';p.write_text('[')
        with self.assertRaises(ValueError):m.read(p)
        self.assertEqual(p.read_text(),'[')
    def test_missing_backup_mount_never_writes_to_root(self):
        with patch.object(m.os.path,'ismount',return_value=False):
            with self.assertRaisesRegex(ValueError,'not mounted'):
                m.backup_reserve({'repository':'/mnt/not-there/repo','requiredMount':'/mnt/not-there'})
    def test_remote_backup_requires_explicit_target(self):
        with self.assertRaisesRegex(ValueError,'explicitly configured'):
            m.backup_reserve({'repository':'sftp:homie:/some/path'})
    def test_remote_backup_reserve_is_enforced(self):
        with patch.object(m,'remote',return_value='{"free":1073741824}'):
            with self.assertRaisesRegex(ValueError,'reserve reached'):
                m.backup_reserve({'repository':'sftp:homie:/disk/repo','remoteTarget':'/disk/repo','requiredMount':'/disk','remoteMinimumFreeGiB':20})
    def test_private_job_uses_fallback_before_sending_and_never_replays(self):
        import subprocess
        m.write(m.CONFIG/'access.json',{'lanAddress':'192.0.2.1','privateAlias':'homie-remote'})
        with patch.object(m,'host',return_value='arete'),patch.object(m,'connectivity',return_value=False),patch.object(m,'run',return_value=subprocess.CompletedProcess([],255,'','')) as call:
            with self.assertRaises(ValueError):m.remote(['job','run'],private=True)
            self.assertEqual(call.call_count,1)
            self.assertIn('homie-remote',call.call_args.args[0])
    def test_motion_control_rejects_ambiguous_input(self):
        m.companion('motion','off');self.assertTrue(m.companion('status')['reducedMotion'])
        with self.assertRaises(ValueError):m.companion('motion','maybe')

    def test_companion_text_is_bounded_plain_content(self):
        self.assertEqual(len(m.companion('say','x'*200)['message']),160)
        m.companion('chatter','off');self.assertFalse(m.companion('status')['chatter'])
class ServiceHealth(unittest.TestCase):
    def test_failed_system_unit_and_restart_loop_are_reported(self):
        import subprocess,json
        rows=[[{'unit':'den-mailbox-ssh.service','active':'activating','sub':'auto-restart','load':'loaded'},
               {'unit':'den-backup.service','active':'inactive','sub':'dead','load':'loaded'}],
              [{'unit':'homie-boot-order.service','active':'failed','sub':'failed','load':'loaded'}]]
        with patch.object(m,'run',side_effect=[subprocess.CompletedProcess([],0,json.dumps(x),'') for x in rows]):
            health=m.service_health()
        self.assertFalse(health['ok']);self.assertEqual(len(health['issues']),2)
        self.assertEqual(health['issues'][0]['scope'],'user')
        self.assertEqual(health['issues'][1]['scope'],'system')
    def test_unavailable_query_cannot_be_reported_as_healthy(self):
        import subprocess
        with patch.object(m,'run',return_value=subprocess.CompletedProcess([],1,'','unavailable')):
            health=m.service_health()
        self.assertFalse(health['ok']);self.assertTrue(all(x['state']=='diagnostics unavailable' for x in health['issues']))

if __name__=='__main__':unittest.main()
