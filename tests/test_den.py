"""Authentication, offline state and secret-free shared-storage invocation."""
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]


def module():
    loader=importlib.machinery.SourceFileLoader('den',str(ROOT/'home/.local/bin/den'))
    spec=importlib.util.spec_from_loader(loader.name,loader);m=importlib.util.module_from_spec(spec);loader.exec_module(m);return m


class Den(unittest.TestCase):
    def test_offline_is_not_reported_authenticated(self):
        m=module()
        with patch.object(m,'peer',side_effect=OSError('offline')),patch.object(m,'input_status',return_value='inactive'),patch.object(m,'settings',return_value={}):
            state=m.status();self.assertFalse(state['peer']['authenticated']);self.assertEqual(state['peer']['state'],'unavailable')

    def test_wrong_peer_identity_is_rejected(self):
        m=module()
        with patch.object(m,'peer',return_value=b'{"host":"unexpected","protocol":1}'),patch.object(m,'input_status',return_value='inactive'),patch.object(m,'settings',return_value={'peer':{'name':'homie'}}):
            self.assertFalse(m.status()['peer']['authenticated'])

    def test_storage_auth_stays_in_anonymous_fd_and_requires_encryption(self):
        m=module();secret=b'fixture-only-not-a-real-secret'
        def smb(argv,**kwargs):
            self.assertNotIn(secret.decode(),' '.join(argv));self.assertNotIn('env',kwargs)
            self.assertIn('--client-protection=encrypt',argv)
            self.assertIn('-m',argv);self.assertIn('SMB3',argv)
            fd=kwargs['pass_fds'][0];self.assertEqual(os.pread(fd,4096,0),b'username = test\npassword = '+secret+b'\n')
            put,get,_=argv[-1].split('; ')
            source=Path(put.split()[1]);dest=Path(get.split()[2]);dest.write_bytes(source.read_bytes())
            return subprocess.CompletedProcess(argv,0,b'',b'')
        with patch.object(m,'storage',return_value=('localhost','Den','test')),patch.object(m,'password',return_value=secret),patch.object(m,'run',side_effect=smb):
            value=m.storage_check();self.assertTrue(value['verified']);self.assertTrue(value['encrypted']);self.assertEqual(value['bytes'],65536)

    def test_bad_storage_content_fails_checksum(self):
        m=module()
        def smb(argv,**kwargs):
            get=argv[-1].split('; ')[1];Path(get.split()[2]).write_bytes(b'corrupted')
            return subprocess.CompletedProcess(argv,0,b'',b'')
        with patch.object(m,'storage',return_value=('localhost','Den','test')),patch.object(m,'password',return_value=b'fixture-only'),patch.object(m,'run',side_effect=smb):
            with self.assertRaisesRegex(ValueError,'checksum'):m.storage_check()

    def test_remote_path_traversal_does_not_contact_peer(self):
        m=module()
        with patch.object(sys,'argv',['den','peer-get','../escape']),patch.object(m,'peer') as peer:
            with self.assertRaises(ValueError):m.main()
            peer.assert_not_called()

    def test_input_service_rejects_command_text(self):
        m=module()
        with patch.object(m,'settings',return_value={'input':{'unit':'bad;command'}}):
            with self.assertRaises(ValueError):m.input_unit()

    def test_message_receipt_must_match_exact_bytes(self):
        m=module()
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'message.json';p.write_text('{"fixture":true}')
            with patch.object(sys,'argv',['den','send',str(p)]),patch.object(m.subprocess,'run'),patch.object(m,'peer',return_value=json.dumps({'sha256':'0'*64}).encode()):
                with self.assertRaisesRegex(ValueError,'hash mismatch'):m.main()


    def test_failed_input_start_revokes_only_den_consent(self):
        m=module()
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);phone=root/'sensei-phone-input-enabled';phone.write_text('existing phone consent')
            with patch.dict(os.environ,{'XDG_RUNTIME_DIR':tmp}),patch.object(sys,'argv',['den','input','start']),patch.object(m,'input_unit',return_value='fixture.service'),patch.object(m.subprocess,'run',side_effect=subprocess.CalledProcessError(1,['systemctl'])):
                with self.assertRaises(subprocess.CalledProcessError):m.main()
            self.assertFalse((root/'den-input-enabled').exists());self.assertTrue(phone.exists())

    def test_input_stop_revokes_consent_even_if_unit_stop_fails(self):
        m=module()
        with tempfile.TemporaryDirectory() as tmp:
            gate=Path(tmp)/'den-input-enabled';gate.write_text('fixture')
            with patch.dict(os.environ,{'XDG_RUNTIME_DIR':tmp}),patch.object(sys,'argv',['den','input','stop']),patch.object(m,'input_unit',return_value='fixture.service'),patch.object(m.subprocess,'run',side_effect=subprocess.CalledProcessError(1,['systemctl'])):
                with self.assertRaises(subprocess.CalledProcessError):m.main()
            self.assertFalse(gate.exists())


if __name__=='__main__':unittest.main()
