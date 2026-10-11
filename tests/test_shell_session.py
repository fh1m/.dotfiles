"""A shell supervisor must not carry a dead compositor into the next login."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1]/'home/.local/bin/sensei-shell'


class ShellSession(unittest.TestCase):
    def test_supervisor_stops_after_its_compositor_disappears(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);bin_dir=root/'bin';bin_dir.mkdir()
            hypr=bin_dir/'hyprctl'
            hypr.write_text('#!/bin/sh\ncase "$1" in\n version) test ! -e "$HOME/ended" ;;\n locked) echo false ;;\n *) exit 1 ;;\nesac\n')
            qs=bin_dir/'qs'
            qs.write_text('#!/bin/sh\ncase "$*" in *"ipc show"*) exit 1 ;; esac\necho launched >> "$HOME/launches"\ntouch "$HOME/ended"\nexit 1\n')
            hypr.chmod(0o755);qs.chmod(0o755)
            env=dict(os.environ,HOME=directory,XDG_RUNTIME_DIR=directory,XDG_STATE_HOME=directory,PATH=str(bin_dir)+':'+os.environ['PATH'],SENSEI_QS_BIN=str(qs),HYPRLAND_INSTANCE_SIGNATURE='fixture')
            subprocess.run(['bash',str(SCRIPT)],env=env,check=True,timeout=5)
            self.assertEqual((root/'launches').read_text().splitlines(),['launched'])
            self.assertIn('Compositor session ended',(root/'sensei/shell.log').read_text())


if __name__=='__main__':unittest.main()
