import json
from pathlib import Path
import subprocess
import os
import shutil
import sys
import tempfile
import unittest
import uuid
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.development import snapshot, command
from noesis.models import create
from noesis.persistence import migration
from noesis.index import Index
from noesis.captures import capture


class Development(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.home=Path(self.temp.name)
        self.home_patch=patch('pathlib.Path.home',return_value=self.home);self.home_patch.start()
        self.repo=self.home/'implementation with spaces';self.repo.mkdir()
        self.git('init','-q');self.git('config','user.name','Synthetic learner');self.git('config','user.email','synthetic@example.invalid')
        (self.repo/'model.py').write_text('prediction = 1\n');self.git('add','model.py');self.git('commit','-qm','Synthetic initial model')
        self.root=self.home/'vault';(self.root/'System').mkdir(parents=True)
        (self.root/'System/System.json').write_text(json.dumps({'directories':[],'types':{}}));migration(self.root,True)

    def tearDown(self):self.home_patch.stop();self.temp.cleanup()
    def git(self,*args):return subprocess.check_output(['git','-C',str(self.repo),*args],text=True).strip()

    def test_paper_implementation_runs_preserve_observed_versions_and_missing_storage(self):
        paper=create(self.root,'resource','Synthetic estimator paper',fields={'source_kind':'paper'})
        project=create(self.root,'project','Reproduce estimator',fields={'repository':str(self.repo)},parent_id=paper['id'])
        original=self.git('rev-parse','HEAD');self.assertEqual(project['code_snapshot']['commit'],original)
        (self.repo/'model.py').write_text('prediction = 2\n')
        first=create(self.root,'experiment','Contradictory run',parent_id=project['id'])
        self.assertTrue(first['code_snapshot']['dirty']);self.assertEqual(first['code_snapshot']['commit'],original)
        self.git('add','model.py');self.git('commit','-qm','Synthetic corrected model')
        second=create(self.root,'experiment','Independent check',parent_id=project['id'])
        self.assertNotEqual(second['code_snapshot']['commit'],original);self.assertFalse(second['code_snapshot']['dirty'])
        self.repo.rename(self.home/'disconnected storage')
        missing=create(self.root,'experiment','Preserve planned test',parent_id=project['id'])
        self.assertEqual(missing['code_snapshot']['availability'],'unavailable')
        index=Index(self.root)
        try:
            index.reconcile();self.assertEqual(index.record(first['id'])['props']['code_snapshot']['commit'],original)
            self.assertEqual(index.relations(paper['id'])[0]['other_id'],project['id'])
        finally:index.close()

    def test_handoff_uses_existing_terminal_without_shell_or_repository_changes(self):
        helper=self.home/'.local/bin/sensei-terminal';helper.parent.mkdir(parents=True);helper.write_text('synthetic helper')
        before=self.git('status','--porcelain')
        with patch('noesis.development.shutil.which',return_value='/usr/bin/nvim'):
            argv=command({'repository':str(self.repo),'title':'Quoted $(text) project'})
        self.assertEqual(argv[-3:],['-e','nvim','.']);self.assertIn(str(self.repo),argv)
        self.assertEqual(self.git('status','--porcelain'),before)
        with patch('noesis.development.shutil.which',return_value=None):
            with self.assertRaisesRegex(ValueError,'Neovim is unavailable'):command({'repository':str(self.repo)})
        with self.assertRaisesRegex(ValueError,'Connect an implementation'):command({})

    def test_creation_receipt_survives_repository_disconnect(self):
        operation=str(uuid.uuid4());fields={'repository':str(self.repo)}
        project=create(self.root,'project','Durable implementation',fields=fields,operation_id=operation)
        self.repo.rename(self.home/'unavailable implementation')
        retry=create(self.root,'project','Durable implementation',fields=fields,operation_id=operation)
        self.assertEqual(retry['id'],project['id']);self.assertEqual(retry['code_snapshot'],project['code_snapshot'])

    def test_editor_capture_references_implementation_identity_after_move(self):
        project=create(self.root,'project','Linked implementation',fields={'repository':str(self.repo)})
        (self.root/project['path']).rename(self.root/'Moved implementation.md')
        observation=capture(self.root,'Observed a contradictory gradient',context_id=project['id'])
        index=Index(self.root)
        try:
            index.reconcile();related=index.relations(project['id'])
            self.assertEqual(related[0]['other_path'],str(observation.relative_to(self.root)))
        finally:index.close()
        with self.assertRaises(ValueError):capture(self.root,'Must not land in another scope',context_id=str(uuid.uuid4()))

    def test_workspace_source_filters_preserve_universal_library_and_concepts(self):
        paper=create(self.root,'resource','Research material',fields={'source_kind':'paper'})
        book=create(self.root,'resource','Learn material',fields={'source_kind':'book'})
        concept=create(self.root,'concept','Reusable concept')
        index=Index(self.root)
        try:
            index.reconcile()
            research=index.query(kind=['paper','resource','question'],resource_kinds=['paper'])['records']
            self.assertEqual([row['id'] for row in research],[paper['id']]);self.assertEqual(research[0]['source_kind'],'paper')
            learn=index.query(kind=['resource','concept'],resource_kinds=['book','course'])['records']
            self.assertEqual({row['id'] for row in learn},{book['id'],concept['id']})
            self.assertEqual(len(index.query()['records']),3)
        finally:index.close()

    def test_reader_cli_refuses_a_path_that_no_longer_names_the_initiating_target(self):
        paper=create(self.root,'resource','Moved reader target',fields={'source_kind':'paper','source':'https://example.invalid/paper'})
        executable=Path(__file__).resolve().parents[1]/'home/.local/bin/sensei-learn'
        result=subprocess.run([sys.executable,str(executable),'read-resource',paper['path'],'--vault',str(self.root),
                               '--target-id',str(uuid.uuid4())],env=dict(os.environ,HOME=str(self.home)),capture_output=True,text=True)
        self.assertNotEqual(result.returncode,0)
        self.assertIn('Resource identity changed',result.stderr)

    @unittest.skipUnless(shutil.which('nvim'),'Native Neovim unavailable')
    def test_native_editor_bridge_keeps_initiating_vault_when_global_scope_changes(self):
        helper=self.home/'.local/bin/noesis';helper.parent.mkdir(parents=True);helper.write_text('#!/bin/sh\n');helper.chmod(0o755)
        config=self.home/'.config/sensei-learning/config.json';config.parent.mkdir(parents=True)
        config.write_text(json.dumps({'active_vault':str(self.home/'another vault')}))
        result=self.home/'bridge.json';script=self.home/'bridge.lua'
        plugin=Path(__file__).resolve().parents[1]/'home/.config/nvim/after/plugin/sensei-learning.lua'
        script.write_text('''vim.system=function(argv,options,callback)
  vim.fn.writefile({vim.json.encode(argv)},'''+json.dumps(str(result))+''')
  callback({code=0})
end
vim.ui.input=function(options,callback) callback('Synthetic observation') end
dofile('''+json.dumps(str(plugin))+''')
for _,mapping in ipairs(vim.api.nvim_get_keymap('n')) do
  if mapping.desc=='Noesis: capture with code context' then mapping.callback() end
end
vim.cmd('qa!')
''')
        identity=str(uuid.uuid4())
        subprocess.run([shutil.which('nvim'),'--headless','-u','NONE','-l',str(script)],cwd=self.repo,
                       env=dict(os.environ,HOME=str(self.home),NOESIS_VAULT=str(self.root),NOESIS_RECORD_ID=identity),
                       check=True,capture_output=True,timeout=10)
        argv=json.loads(result.read_text())
        self.assertEqual(argv[argv.index('--vault')+1],str(self.root))
        self.assertEqual(argv[argv.index('--context-id')+1],identity)
        self.assertNotIn(str(self.home/'another vault'),argv)

    def test_uncommitted_repository_is_readable_without_fabricating_revision(self):
        empty=self.home/'new implementation';empty.mkdir()
        subprocess.run(['git','-C',str(empty),'init','-q'],check=True)
        (empty/'first.py').write_text('prediction = 0\n')
        state=snapshot(empty)
        self.assertIsNone(state['commit']);self.assertTrue(state['dirty'])

    def test_invalid_repository_does_not_publish_a_partial_project(self):
        with self.assertRaisesRegex(ValueError,'existing Git repository'):
            create(self.root,'project','Not a repository',fields={'repository':str(self.home)})
        self.assertFalse((self.root/'Records/project').exists())
