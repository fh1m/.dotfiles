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
if __name__=="__main__":unittest.main()
