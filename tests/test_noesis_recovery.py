import importlib.machinery
import importlib.util
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'home/.local/share/sensei-learning'))
from noesis import recovery

loader = importlib.machinery.SourceFileLoader('noesis_backup', str(ROOT / 'home/.local/bin/sensei-learning-backup'))
spec = importlib.util.spec_from_loader(loader.name, loader)
legacy = importlib.util.module_from_spec(spec);loader.exec_module(legacy)


class Recovery(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.home = Path(self.temp.name)
        self.patch = patch('pathlib.Path.home', return_value=self.home);self.patch.start()
        self.root = self.home / 'vault'
        (self.root / 'System').mkdir(parents=True)
        (self.root / 'System/System.json').write_text(json.dumps({'directories': ['Notes']}))
        (self.root / 'prediction.md').write_text('Prediction remains contradicted by observation.\n')

    def tearDown(self):
        self.patch.stop();self.temp.cleanup()

    def test_legacy_streaming_restore_and_malicious_directories(self):
        state = self.home / 'legacy'
        with patch.object(legacy, 'STATE', state):legacy.backup(self.root)
        archive = next(state.rglob('*.tar.gz'))
        restored = self.home / 'restored'
        legacy.restore(archive, restored)
        self.assertEqual((restored / 'prediction.md').read_text(), (self.root / 'prediction.md').read_text())
        with self.assertRaises(ValueError):legacy.restore(archive, restored)
        (self.root / 'System/System.json').write_text(json.dumps({'directories': ['../escaped']}))
        with patch.object(legacy, 'STATE', state):legacy.backup(self.root)
        archive = sorted(state.rglob('*.tar.gz'))[-1]
        with self.assertRaisesRegex(ValueError, 'Unsafe'):legacy.restore(archive, self.home / 'malicious')
        self.assertFalse((self.home / 'escaped').exists())
        self.assertFalse((self.home / 'malicious').exists())

    @unittest.skipUnless(shutil.which('restic'), 'Restic package is optional in test environments')
    def test_restic_integrity_restore_and_external_recording(self):
        data = self.root / 'sensor.mcap'
        with data.open('wb') as stream:stream.truncate(30 * 1024 * 1024)
        state = self.home / 'recovery'
        backup = recovery.backup(self.root, state)
        restored = self.home / 'restored'
        report = recovery.restore(backup['snapshot_id'], restored, state)
        self.assertEqual(report['verified_files'], 2)
        self.assertEqual((restored / 'prediction.md').read_text(), (self.root / 'prediction.md').read_text())
        self.assertFalse((restored / 'sensor.mcap').exists())
        self.assertIn('sensor.mcap', report['external'])
        self.assertFalse(backup['off_device'])
        with self.assertRaises(ValueError):recovery.restore(backup['snapshot_id'], restored, state)


if __name__ == '__main__':unittest.main()
