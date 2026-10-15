import importlib.machinery
import importlib.util
import json
from pathlib import Path
import shutil
import sys
import sqlite3
from contextlib import closing
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
    def test_portable_reader_discovery_and_same_name_profiles_keep_ownership(self):
        with patch.object(legacy,'HOME',self.home),patch.dict('os.environ',{'XDG_CONFIG_HOME':str(self.home/'.config'),'XDG_DATA_HOME':str(self.home/'.local/share')}):
            original=self.home/'.local/share/Sioyek';portable=self.home/'.config/.local/share/Sioyek'
            self.assertIn(original,legacy.reader_roots());self.assertIn(portable,legacy.reader_roots())
            for root in (original,portable):root.mkdir(parents=True);(root/'prefs_user.config').write_text('A synthetic preference')
            with patch.object(legacy,'STATE',self.home/'snapshots'):
                reports=legacy.backup_readers([original,portable])
            self.assertEqual([report['source'] for report in reports],[str(original),str(portable)])
            self.assertNotEqual(reports[0]['snapshot'],reports[1]['snapshot'])

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

    def test_reader_restore_preserves_bookmarks_positions_annotations(self):
        snapshot=self.home/'reader-snapshot';snapshot.mkdir()
        database=snapshot/'shared.db'
        with closing(sqlite3.connect(database)) as db, db:
            db.execute('CREATE TABLE bookmarks(document TEXT,page INTEGER,description TEXT)')
            db.execute('INSERT INTO bookmarks VALUES(?,?,?)',('synthetic-paper',7,'Reconstruct this derivation'))
            db.execute('CREATE TABLE positions(document TEXT,page INTEGER,offset REAL)')
            db.execute('INSERT INTO positions VALUES(?,?,?)',('synthetic-paper',9,.3))
            db.execute('CREATE TABLE annotations(id TEXT,page INTEGER,text TEXT)')
            db.execute('INSERT INTO annotations VALUES(?,?,?)',('native-annotation',8,'Check the hidden assumption'))
        metadata={'files':{'shared.db':legacy.sha(database)},'database_sources':{'shared.db':{'mode':'sqlite-online-backup'}}}
        (snapshot/'manifest.json').write_text(json.dumps(metadata))
        destination=self.home/'new-profile'
        result=legacy.restore_reader(snapshot,destination)
        self.assertEqual(result['databases']['shared.db']['tables']['annotations'],1)
        with closing(sqlite3.connect(destination/'shared.db')) as db:
            self.assertEqual(db.execute('SELECT * FROM bookmarks').fetchone(),('synthetic-paper',7,'Reconstruct this derivation'))
            self.assertEqual(db.execute('SELECT * FROM positions').fetchone(),('synthetic-paper',9,.3))
            self.assertEqual(db.execute('SELECT id FROM annotations').fetchone()[0],'native-annotation')
        with self.assertRaises(ValueError):legacy.restore_reader(snapshot,destination)
        metadata['files']['../escaped.db']=legacy.sha(database)
        (snapshot/'manifest.json').write_text(json.dumps(metadata))
        with self.assertRaisesRegex(ValueError,'Unsafe'):legacy.restore_reader(snapshot,self.home/'malicious')
        self.assertFalse((self.home/'malicious').exists())

    @unittest.skipUnless(shutil.which('restic'), 'Restic package required')
    def test_reader_snapshot_encrypted_restore_and_repeated_backup(self):
        reader=self.home/'Zotero';reader.mkdir()
        with closing(sqlite3.connect(reader/'zotero.sqlite')) as db,db:
            db.execute('CREATE TABLE annotations(id TEXT,page INTEGER,comment TEXT)')
            db.execute('INSERT INTO annotations VALUES(?,?,?)',('native-key',3,'Reconstruct independently'))
        (reader/'paper.pdf').write_bytes(b'%PDF-1.4 synthetic fixture')
        (reader/'recording.mcap').write_bytes(b'external recording')
        with patch.object(legacy,'STATE',self.home/'snapshots'):
            snapshot=legacy.backup_readers([reader])[0]
        self.assertNotIn('recording.mcap',snapshot['files'])
        self.assertIn('recording.mcap',snapshot['external'])
        report=recovery.backup(self.root,self.home/'restic',[snapshot['snapshot']])
        restored=self.home/'recovered'
        result=recovery.restore(report['snapshot_id'],restored,self.home/'restic')
        reader_copy=self.home/'reader-copy'
        legacy.restore_reader(Path(result['reader_states'][0]['path']),reader_copy)
        with closing(sqlite3.connect(reader_copy/'zotero.sqlite')) as db:
            self.assertEqual(db.execute('SELECT * FROM annotations').fetchone(),('native-key',3,'Reconstruct independently'))
        second=recovery.backup(restored,self.home/'restic')
        second_copy=self.home/'second-recovery';again=recovery.restore(second['snapshot_id'],second_copy,self.home/'restic')
        self.assertEqual(len(again['reader_states']),1)
        with closing(sqlite3.connect(Path(again['reader_states'][0]['path'])/'zotero.sqlite')) as db:
            self.assertEqual(db.execute('SELECT page FROM annotations').fetchone()[0],3)
        self.assertEqual((second_copy/'prediction.md').read_text(),(self.root/'prediction.md').read_text())



if __name__ == '__main__':unittest.main()
