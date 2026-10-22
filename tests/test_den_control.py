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
    def test_peer_uses_supported_ipv4_transport(self):
        import subprocess
        with patch.object(den,'run',return_value=subprocess.CompletedProcess([],0,'homie','')) as call:
            self.assertEqual(den.peer_command('hostname'),'homie')
        self.assertIn('-4',call.call_args.args[0])

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

    def test_audio_gateway_rejects_worker_and_shell_arguments(self):
        for command in ('den-audio worker lan output', 'den-audio start lan output;id', 'den-audio port output --help', 'den-audio start lan'):
            with self.subTest(command=command),patch.object(den.sys,'argv',['den-control','--serve']),patch.dict(den.os.environ,{'SSH_ORIGINAL_COMMAND':command}),patch.object(den,'run') as run:
                with self.assertRaises(ValueError):den.main()
                run.assert_not_called()

    def test_audio_gateway_passes_exact_validated_argv(self):
        import subprocess
        with patch.object(den.sys,'argv',['den-control','--serve']),patch.dict(den.os.environ,{'SSH_ORIGINAL_COMMAND':'den-audio start lan alsa_output.usb-device.analog-stereo'}),patch.object(den,'run',return_value=subprocess.CompletedProcess([],0,'{"active":true}')) as run,patch('builtins.print'):
            den.main()
            self.assertEqual(run.call_args.args[0][1:],['start','lan','alsa_output.usb-device.analog-stereo'])

    def test_receiver_storage_does_not_invoke_remote_shell(self):
        with patch.object(den, 'master', return_value=False), patch.object(den.subprocess, 'Popen') as open_path, patch.object(den, 'run') as run:
            den.dispatch('storage')
            self.assertEqual(open_path.call_args.args[0][0], 'xdg-open')
            run.assert_not_called()

    def test_receiver_companion_status_belongs_to_its_own_desktop(self):
        import json
        import subprocess
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            prefs = home/'.config/sensei-den/companion.json'
            prefs.parent.mkdir(parents=True)
            prefs.write_text(json.dumps({'enabled':False,'quiet':True,'reducedMotion':True}))
            response = subprocess.CompletedProcess([],0,json.dumps({'master':'arete','companion':True,'companionQuiet':False}))
            with patch.object(den,'master',return_value=False), patch.object(den.Path,'home',return_value=home), patch.object(den,'run',return_value=response):
                result = den.dispatch('status')
            self.assertFalse(result['companion'])
            self.assertTrue(result['companionQuiet'])
            self.assertTrue(result['companionReducedMotion'])
            self.assertEqual(result['peer']['host'],'arete')


class EngineeringGateway(unittest.TestCase):
    def test_catalog_edits_and_forwarding_are_not_remote_capabilities(self):
        for command in ('sensei-actions trust p task','sensei-actions register p /tmp','sensei-actions --host homie overview','sensei-actions overview --host=homie'):
            with patch.object(den.sys,'argv',['den-control','--serve']), patch.dict(den.os.environ,{'SSH_ORIGINAL_COMMAND':command}), patch.object(den,'run') as run:
                with self.assertRaises(ValueError):den.main()
                run.assert_not_called()
    def test_gateway_uses_exact_executable_without_shell(self):
        import subprocess
        with patch.object(den.sys,'argv',['den-control','--serve']), patch.dict(den.os.environ,{'SSH_ORIGINAL_COMMAND':'sensei-actions overview'}), patch.object(den,'run',return_value=subprocess.CompletedProcess([],0,'{}')) as run, patch('builtins.print'):
            den.main()
            self.assertEqual(run.call_args.args[0],[str(Path.home()/'.local/bin/sensei-actions'),'overview'])

if __name__ == '__main__':
    unittest.main()
