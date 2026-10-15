import importlib.machinery
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

path = Path(__file__).resolve().parents[1]/'home/.local/bin/den-control'
loader = importlib.machinery.SourceFileLoader('den_control', str(path))
spec = importlib.util.spec_from_loader(loader.name, loader)
den = importlib.util.module_from_spec(spec)
loader.exec_module(den)


class DenControl(unittest.TestCase):
    def test_offline_receiver_never_starts_local_capture(self):
        with patch.object(den, 'peer_command', side_effect=RuntimeError('offline')), patch.object(den, 'run') as run:
            with self.assertRaises(RuntimeError):
                den.start()
            run.assert_not_called()

    def test_stop_is_independent_of_peer(self):
        with patch.object(den, 'send') as send, patch.object(den, 'wait_input') as wait, patch.object(den, 'peer_command') as peer:
            den.pause()
            send.assert_called_once_with('recover')
            wait.assert_called_once_with(False)
            peer.assert_not_called()

    def test_stop_waits_until_deactivation_finishes(self):
        with patch.object(den, 'unit', side_effect=['deactivating', 'inactive']) as unit, patch.object(den.time, 'sleep'):
            den.wait_input(False)
            self.assertEqual(unit.call_count, 2)

    def test_toggle_uses_actual_service_state(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(den, 'ROOT', Path(directory)), patch.object(den, 'pause') as pause, patch.object(den, 'start') as start:
            with patch.object(den, 'unit', return_value='active'):
                den.local_action('toggle')
            pause.assert_called_once()
            start.assert_not_called()
            with patch.object(den, 'unit', return_value='inactive'):
                den.local_action('toggle')
            start.assert_called_once()

    def test_restricted_command_cannot_execute_a_shell(self):
        with patch.object(den.sys, 'argv', ['den-control', '--serve']), patch.dict(den.os.environ, {'SSH_ORIGINAL_COMMAND': 'den-control toggle; touch /tmp/not-allowed'}), patch.object(den, 'local_action') as action:
            with self.assertRaises(ValueError):
                den.main()
            action.assert_not_called()

    def test_receiver_storage_does_not_invoke_remote_shell(self):
        with patch.object(den, 'master', return_value=False), patch.object(den.subprocess, 'Popen') as open_path, patch.object(den, 'run') as run:
            den.dispatch('storage')
            self.assertEqual(open_path.call_args.args[0][0], 'xdg-open')
            run.assert_not_called()


if __name__ == '__main__':
    unittest.main()
