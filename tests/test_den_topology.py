import importlib.machinery
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
l=importlib.machinery.SourceFileLoader('topology',str(ROOT/'home/.local/bin/sensei-den'));s=importlib.util.spec_from_loader(l.name,l);m=importlib.util.module_from_spec(s);l.exec_module(m)
class Topology(unittest.TestCase):
 def test_startup_and_unchanged_do_not_restart(self):
  with patch.object(m,'run') as run:
   self.assertFalse(m.refresh_capture_routes(None,[1],True,True));self.assertFalse(m.refresh_capture_routes([1],[1],True,True));run.assert_not_called()
 def test_user_pause_survives_topology_update(self):
  with tempfile.TemporaryDirectory() as d,patch.object(m,'PRIVATE',Path(d)),patch.object(m,'run') as run:
   p=Path(d)/'input';p.mkdir();(p/'user-paused').touch();run.return_value.returncode=0
   self.assertTrue(m.refresh_capture_routes([1],[2],True,True));self.assertEqual(run.call_count,1);self.assertEqual(run.call_args.args[0][-1],'den-input')
 def test_release_precedes_resume(self):
  with tempfile.TemporaryDirectory() as d,patch.object(m,'PRIVATE',Path(d)),patch.object(m,'run') as run:
   run.return_value.returncode=0;m.refresh_capture_routes([1],[2],True,True)
   self.assertEqual(run.call_args_list[0].args[0][-2:],['stop','den-input']);self.assertEqual(run.call_args_list[1].args[0][-1],'start')
