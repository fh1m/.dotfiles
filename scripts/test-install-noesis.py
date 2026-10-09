#!/usr/bin/env python3
import importlib.util,tempfile
from pathlib import Path
spec=importlib.util.spec_from_file_location('deploy',Path(__file__).with_name('install-noesis.py'));deploy=importlib.util.module_from_spec(spec);spec.loader.exec_module(deploy)
for bridge in (False,True):
 with tempfile.TemporaryDirectory() as directory:
  home=Path(directory);unrelated=home/'.config/keep-personal';unrelated.parent.mkdir();unrelated.write_text('personal setting\n')
  old=home/'.local/bin/sensei-learn';old.parent.mkdir(parents=True);old.write_text('previous launcher\n');old.chmod(0o755)
  assert deploy.install(home,False,bridge)['changed'] and old.read_text()=='previous launcher\n'
  result=deploy.install(home,True,bridge);assert not deploy.install(home,True,bridge)['changed']
  manifest=Path(result['manifest']);old.write_text('later edit')
  try:deploy.rollback(manifest,True)
  except ValueError:pass
  else:raise AssertionError('Rollback discarded later changes')
  old.write_bytes(deploy.installer.render((deploy.ROOT/'home/.local/bin/sensei-learn').read_bytes(),home,'zenbook'))
  deploy.rollback(manifest,True);assert old.read_text()=='previous launcher\n' and unrelated.read_text()=='personal setting\n'
  assert not (home/'.config/quickshell/noesis/shell.qml').exists()
print('PASS: scoped dry run, two idempotent installations, rollback, later-edit protection, unrelated files retained')
