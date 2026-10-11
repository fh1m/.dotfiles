"""Bounded release fault matrix, using disposable owners and real crash processes."""
import json,os,subprocess,sys,tempfile,unittest,uuid
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
MODULES=ROOT/'home/.local/share/sensei-learning';sys.path.insert(0,str(MODULES))
from noesis.persistence import migration,publish,checksum
from noesis.models import create
from noesis.index import Index
from noesis.activities import operation_status
from noesis import recovery
class ReleaseFaults(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.home=Path(self.tmp.name);self.root=self.home/'vault';(self.root/'System').mkdir(parents=True);(self.root/'System/System.json').write_text('{"directories":[]}');self.home_patch=patch('pathlib.Path.home',return_value=self.home);self.home_patch.start();migration(self.root,True)
 def tearDown(self):self.home_patch.stop();self.tmp.cleanup()
 def test_unavailable_storage_does_not_turn_into_deletion_and_reappears(self):
  record=create(self.root,'question','Preserved uncertainty');index=Index(self.root)
  try:
   index.reconcile();generation=index.generation;offline=self.home/'offline';self.root.rename(offline)
   with self.assertRaisesRegex(ValueError,'storage is unavailable'):index.reconcile()
   self.assertEqual(index.generation,generation);self.assertEqual(index.record(record['id'])['props']['id'],record['id'])
   offline.rename(self.root);index.reconcile();self.assertEqual(index.record(record['id'])['props']['id'],record['id'])
   meta=self.root/'System/System.json';value=json.loads(meta.read_text());value['vault_id']=str(uuid.uuid4());meta.write_text(json.dumps(value))
   with self.assertRaisesRegex(ValueError,'identity changed'):index.reconcile()
   self.assertEqual(index.generation,generation)
  finally:index.close()
 def test_cli_stale_owner_fails_before_any_publication(self):
  old=json.loads((self.root/'System/System.json').read_text())['vault_id'];meta=self.root/'System/System.json';value=json.loads(meta.read_text());value['vault_id']=str(uuid.uuid4());meta.write_text(json.dumps(value))
  before={str(p):p.read_bytes() for p in self.root.rglob('*') if p.is_file()}
  env=dict(os.environ,HOME=str(self.home),PYTHONPATH=str(MODULES))
  result=subprocess.run([sys.executable,str(ROOT/'home/.local/bin/sensei-learn'),'record','--vault',str(self.root),'--expect-vault-id',old,'question','Do not misattribute'],env=env,capture_output=True,text=True)
  self.assertNotEqual(result.returncode,0);self.assertIn('Vault identity changed',result.stderr);self.assertEqual(before,{str(p):p.read_bytes() for p in self.root.rglob('*') if p.is_file()})
 def test_fsync_fault_before_and_after_atomic_publication(self):
  path=self.root/'atomic.txt';publish(path,'original');real=os.fsync
  with patch('noesis.persistence.os.fsync',side_effect=OSError('injected file flush failure')):
   with self.assertRaises(OSError):publish(path,'new',checksum('original'))
  self.assertEqual(path.read_text(),'original');calls=[]
  def after(fd):
   calls.append(fd)
   if len(calls)==2:raise OSError('directory durability uncertain')
   return real(fd)
  with patch('noesis.persistence.os.fsync',side_effect=after):
   with self.assertRaises(OSError):publish(path,'new',checksum('original'))
  self.assertEqual(path.read_text(),'new');self.assertFalse(list(self.root.glob('.noesis-*')))
  with self.assertRaisesRegex(ValueError,'conflicting'):publish(path,'stale overwrite',checksum('original'))
 def test_forced_crash_after_record_publication_recovers_receipt_without_duplicate(self):
  operation=str(uuid.uuid4());script='''import os,sys
from pathlib import Path
from noesis import models
original=models.publish
def crash(path,*args,**kwargs):
 original(path,*args,**kwargs)
 if path.suffix=='.md':os._exit(97)
models.publish=crash
models.create(Path(sys.argv[1]),'question','Agent crash fixture',operation_id=sys.argv[2])
'''
  env=dict(os.environ,HOME=str(self.home),PYTHONPATH=str(MODULES));result=subprocess.run([sys.executable,'-c',script,str(self.root),operation],env=env)
  self.assertEqual(result.returncode,97);receipt=operation_status(self.root,operation);self.assertEqual(receipt['status'],'committed');a=create(self.root,'question','Agent crash fixture',operation_id=operation);self.assertEqual(a['id'],receipt['records'][0]['id']);self.assertEqual(len(list(self.root.rglob('*.md'))),1)
 def test_concurrent_same_operation_publishes_one_record(self):
  operation=str(uuid.uuid4());env=dict(os.environ,HOME=str(self.home),PYTHONPATH=str(MODULES));script="import sys,json;from pathlib import Path;from noesis.models import create;print(json.dumps(create(Path(sys.argv[1]),'question','Concurrent fixture',operation_id=sys.argv[2])))"
  processes=[subprocess.Popen([sys.executable,'-c',script,str(self.root),operation],env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True) for _ in range(6)];ids=[]
  for p in processes:
   out,err=p.communicate(timeout=20);self.assertEqual(p.returncode,0,err);ids.append(json.loads(out)['id'])
  self.assertEqual(len(set(ids)),1);self.assertEqual(len(list(self.root.rglob('*.md'))),1)
 def test_interrupted_restore_never_publishes_partial_destination_and_retry_verifies(self):
  create(self.root,'question','Recovery remains a question');state=self.home/'restic';backup=recovery.backup(self.root,state);dest=self.home/'restored'
  with patch('pathlib.Path.rename',side_effect=OSError('injected publication fault')):
   with self.assertRaises(OSError):recovery.restore(backup['snapshot_id'],dest,state)
  self.assertFalse(dest.exists());report=recovery.restore(backup['snapshot_id'],dest,state);self.assertGreater(report['verified_files'],0);self.assertEqual((dest/'System/System.json').read_bytes(),(self.root/'System/System.json').read_bytes())
 def test_reader_snapshot_tampering_preserves_prior_verified_backup(self):
  create(self.root,'question','Protected original');state=self.home/'restic';first=recovery.backup(self.root,state);reader=self.home/'reader';reader.mkdir();(reader/'prefs.js').write_text('changed after snapshot');(reader/'manifest.json').write_text(json.dumps({'source':str(self.home/'Zotero'),'files':{'prefs.js':'0'*64},'database_sources':{}}))
  with self.assertRaisesRegex(ValueError,'changed'):recovery.backup(self.root,state,[reader])
  self.assertGreater(recovery.restore(first['snapshot_id'],self.home/'verified',state)['verified_files'],0)
if __name__=='__main__':unittest.main()
