import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('dev', str(ROOT / 'home/.local/bin/sensei-dev'))
spec = importlib.util.spec_from_loader(loader.name, loader)
dev = importlib.util.module_from_spec(spec); loader.exec_module(dev)

class Launcher(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        self.host = patch.object(dev, 'HOST', self.home); self.host.start()
        self.state = patch.object(dev, 'STATE', self.home / 'state.json'); self.state.start()
    def tearDown(self):
        self.host.stop(); self.state.stop(); self.tmp.cleanup()
    def test_nested_profile_and_container_override(self):
        root = self.home / 'project'; nested = root / 'web'; nested.mkdir(parents=True)
        dev.write({'version': 1, 'projects': [
            {'root': str(root), 'container': 'auv-ros2'}, {'root': str(nested), 'container': 'frontend'}]})
        self.assertEqual(dev.profile(nested)['container'], 'frontend')
        self.assertEqual(dev.profile(root)['container'], 'auv-ros2')
    def test_container_inference_is_not_auv_specific(self):
        root = self.home / 'Envs/dockers/drone-ros2/Ros_workspaces/nav'; root.mkdir(parents=True)
        with patch.object(dev, 'containers', return_value=['drone-ros2']):
            self.assertEqual(dev.profile(root)['container'], 'drone-ros2')
    def test_arguments_are_not_shell_interpolation(self):
        p = {'root': "/tmp/project ' $(touch /tmp/not-executed)", 'container': 'box'}
        cmd = dev.command(p, ['nvim', 'x; echo unsafe'])
        self.assertEqual(cmd[:5], ['distrobox', 'enter', '--name', 'box', '--'])
        self.assertIn(p['root'], cmd)
        self.assertEqual(cmd[-1], 'x; echo unsafe')
        self.assertNotIn(p['root'], cmd[8])
    def test_malformed_registry_is_preserved(self):
        dev.STATE.write_text('{bad')
        with self.assertRaises(SystemExit): dev.read()
        self.assertEqual(dev.STATE.read_text(), '{bad')
    def test_atomic_write_and_permissions(self):
        dev.write({'version': 1, 'projects': []})
        self.assertEqual(dev.STATE.stat().st_mode & 0o777, 0o600)
        self.assertEqual(json.loads(dev.STATE.read_text())['version'], 1)

if __name__ == '__main__': unittest.main()
