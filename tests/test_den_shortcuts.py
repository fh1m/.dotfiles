import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
loader=importlib.machinery.SourceFileLoader('shortcuts',str(Path(__file__).resolve().parents[1]/'home/.local/bin/sensei-shortcuts'))
spec=importlib.util.spec_from_loader(loader.name,loader);m=importlib.util.module_from_spec(spec);loader.exec_module(m)
class Guide(unittest.TestCase):
    def test_live_binding_survives_without_manual_catalog_entry(self):
        binding={'modmask':65,'key':'F8','keycode':0,'description':'A new action','dispatcher':'__lua','arg':'31'}
        with patch.object(m,'source_bindings',return_value={}),patch.object(m,'run',return_value=json.dumps([binding])):
            row=m.desktop()[0]
        self.assertEqual(row['key'],'Super+Shift+F8');self.assertEqual(row['title'],'A new action')
    def test_terminal_inventory_never_executes_configured_command(self):
        with tempfile.TemporaryDirectory() as d:
            h=Path(d);p=h/'.config/alacritty/alacritty.toml';p.parent.mkdir(parents=True)
            p.write_text('[[keyboard.bindings]]\nkey="F9"\nmods="Control|Shift"\ncommand={program="dangerous-command",args=["--do-not-run"]}\n')
            with patch.object(m,'HOME',h),patch.object(m,'run') as call:rows=m.terminal()
            call.assert_not_called();self.assertEqual(rows[0]['key'],'Ctrl+Shift+F9')
            self.assertIn('dangerous-command',rows[0]['title'])
    def test_copy_mode_and_prefix_bindings_remain_distinct(self):
        with patch.object(m,'run',return_value='bind-key -T copy-mode-vi y send-keys -X copy-selection\nbind-key -T prefix y display-message hello\n'):
            rows=m.multiplexer()
        self.assertNotEqual(rows[0]['group'],rows[1]['group']);self.assertEqual(rows[1]['key'],'` then y')
