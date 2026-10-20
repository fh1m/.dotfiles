"""Recovery tests never call a compositor or systemd."""
import importlib.util,json,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
spec=importlib.util.spec_from_file_location("den_cursor",Path(__file__).with_name("den-cursor.py"))
cursor=importlib.util.module_from_spec(spec);spec.loader.exec_module(cursor)
class Safety(unittest.TestCase):
    def test_recovery_stops_without_restarting_capture(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);(root/"input").mkdir();(root/"input/active").write_text("1")
            monitors=[{"name":"eDP-1","x":0,"y":0,"width":3840,"height":2160,"scale":2}]
            with patch.object(cursor,"ROOT",root),patch.object(cursor.subprocess,"run") as run,patch.object(cursor,"hypr",side_effect=[json.dumps(monitors).encode(),b"ok",b"ok",b"ok"]) as hypr,patch.object(cursor,"pulse"):
                cursor.recover()
            self.assertEqual((root/"input/active").read_text(),"0")
            self.assertEqual(run.call_count,1)
            self.assertEqual(run.call_args.args[0],["systemctl","--user","stop","den-input"])
            self.assertIn("x=960,y=540",hypr.call_args_list[2].args[1])
    def test_no_input_service_autostart_in_installer(self):
        # Cursor recovery is a separate service, never an input-session dependency.
        service=Path(__file__).with_name("den-cursor.service").read_text()
        self.assertNotIn("Requires=den-input",service)
        self.assertNotIn("Wants=den-input",service)
    def test_session_teardown_clears_capture_and_nonmodal_marker(self):
        import runpy,sys
        sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'home/.local/share/sensei'))
        with tempfile.TemporaryDirectory() as d:
            home=Path(d);state=home/'.local/state/homie-control/input';state.mkdir(parents=True)
            for name in ('active','return-armed','running'):(state/name).write_text('1')
            with patch('pathlib.Path.home',return_value=home),patch.object(sys,'argv',['den-session.py','reset']):
                with self.assertRaises(SystemExit):runpy.run_path(str(Path(__file__).with_name('den-session.py')),run_name='__main__')
            self.assertEqual([(state/n).read_text() for n in ('active','return-armed','running')],['0','0','0'])
if __name__=="__main__":unittest.main()
