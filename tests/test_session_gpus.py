"""Resolve both scanout devices while preserving an Intel-only recovery path."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1]/'home/.local/bin/hyprland-repair-session'


class SessionGPUs(unittest.TestCase):
    def test_both_devices_and_recovery_without_starting_a_compositor(self):
        with tempfile.TemporaryDirectory() as directory:
            fake = Path(directory)/'readlink'
            fake.write_text('#!/bin/sh\ncase "$2" in\n *00:02.0-card) echo /dev/null ;;\n *) if [ "${TEST_NO_NVIDIA:-0}" = 1 ]; then exit 1; else echo /dev/zero; fi ;;\nesac\n')
            fake.chmod(0o755)
            env = dict(os.environ, PATH=directory+':'+os.environ['PATH'])
            for key in ('SENSEI_INTEL_ONLY','SENSEI_INTEL_PCI','SENSEI_NVIDIA_PCI'):env.pop(key,None)
            def check(args, expected, **extra):
                actual = subprocess.check_output(['sh',str(SCRIPT),*args],env=dict(env,**extra),text=True).strip()
                self.assertEqual(actual,expected)
            check(['--print-devices'],'/dev/null:/dev/zero')
            check(['--intel-only','--print-devices'],'/dev/null')
            check(['--print-devices'],'/dev/null',SENSEI_INTEL_ONLY='1')
            check(['--print-devices'],'/dev/null',TEST_NO_NVIDIA='1')


if __name__ == '__main__':unittest.main()
