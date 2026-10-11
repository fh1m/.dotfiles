#!/usr/bin/env python3
"""Native explicit replacement/fork of disposable conflicting copies."""
import json,subprocess,time,shutil
from pathlib import Path
from noesis_native_fixture import REPO
prefix=(REPO/'scripts/check-noesis-self-service.py').read_text().split('clipboard=subprocess.run')[0]
exec(compile(prefix,'native-vault-recovery','exec'))
# This gate provisions copied storage, not a prearranged learning journey.
(f.vault/'question.md').write_text('---\nnoesis_schema: 2\nid: '+f.record_id+'\ntype: question\ntitle: Agent recovery fixture\n---\nOriginal uncertainty, never an achievement.\n')
original={str(p.relative_to(f.vault)):p.read_bytes() for p in f.vault.rglob('*') if p.is_file()}
copy=f.home/'restored-copy';shutil.copytree(f.vault,copy);dest=f.home/'independent-copy';assets=REPO/'docs/learning-system/assets/release-hardening';assets.mkdir(parents=True,exist_ok=True)
clipboard=subprocess.run(['wl-paste','--no-newline'],capture_output=True)
def click(label):assert f.ipc('journey-fixture','click',label)=='clicked',label
def field(name,value):
 for attempt in range(4):
  assert f.ipc('journey-fixture','focusField',name)=='focused';subprocess.run(['wl-copy'],input=value,text=True,check=True);time.sleep(.3);f.ipc('journey-fixture','pasteField');time.sleep(.2)
  if f.ipc('journey-fixture','field',name)==value:return
 raise AssertionError(name)
def ready():f.wait(lambda s:not s['working'],seconds=20);time.sleep(.5);assert not f.state()['error'],f.state()['error']
def capture(name):
 path=assets/(name+'.png');path.unlink(missing_ok=True);f.ipc('journey-fixture','capture',str(path));time.sleep(.5);assert path.exists()
try:
 f.start(resume=True);f.ipc('journey-fixture','init');click('Settings');click('Resolve a restored or conflicting vault copy');field('recovery-source',str(copy));field('recovery-other',str(f.vault));capture('replace-location-review');click('Use restored location');ready();click('Select resolved vault');ready();assert f.state()['vault']==str(copy)
 assert original=={str(p.relative_to(f.vault)):p.read_bytes() for p in f.vault.rglob('*') if p.is_file()};registry=json.loads((f.home/'.local/state/noesis/vaults.json').read_text());assert str(f.vault) in registry['replacements']
 click('Settings');click('Resolve a restored or conflicting vault copy');assert f.ipc('journey-fixture','choose','recovery-mode','1')=='Fork an independent copy';field('recovery-source',str(copy));field('recovery-other',str(dest));capture('fork-location-review');click('Create independent copy');ready();click('Select resolved vault');ready();assert f.state()['vault']==str(dest)
 assert json.loads((dest/'System/System.json').read_text())['vault_id']!=f.vault_id;assert original=={str(p.relative_to(copy)):p.read_bytes() for p in copy.rglob('*') if p.is_file()}
 f.exit();f.start(resume=True);f.ipc('journey-fixture','init');assert f.state()['vault']==str(dest);capture('resolved-vault-restart')
 (assets/'vault-recovery-acceptance.json').write_text(json.dumps({'native_replace':True,'native_fork':True,'originals_byte_identical':True,'registry_backup':True,'new_owner_identity':True,'restart_resolved_owner':True,'provenance':'agent-owned disposable copies'},indent=2)+'\n');print('PASS: native conflict replacement/fork, original bytes, registry backup and restart')
finally:
 f.stop()
 if clipboard.returncode==0:subprocess.run(['wl-copy'],input=clipboard.stdout)
