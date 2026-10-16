import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
spec=importlib.util.spec_from_file_location('den_storage',Path(__file__).resolve().parents[1]/'pc/tools/check-homie-storage.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Storage(unittest.TestCase):
    def test_autofs_placeholder_is_not_a_working_disk(self):
        with tempfile.TemporaryDirectory() as d:
            result=subprocess.CompletedProcess([],0,json.dumps({'filesystems':[{'target':d,'fstype':'autofs','options':'rw'}]}),'')
            with patch.object(m.subprocess,'run',return_value=result):
                state=m.inspect(d,True)
            self.assertFalse(state['mounted']);self.assertFalse(state['protectionOkay'])
    def test_underlying_protected_disk_must_be_read_only(self):
        with tempfile.TemporaryDirectory() as d:
            for mode in ['rw','ro']:
                result=subprocess.CompletedProcess([],0,json.dumps({'filesystems':[{'target':d,'fstype':'ext4','options':mode}]}),'')
                with patch.object(m.subprocess,'run',return_value=result):state=m.inspect(d,True)
                self.assertTrue(state['mounted']);self.assertEqual(state['protectionOkay'],mode=='ro')
