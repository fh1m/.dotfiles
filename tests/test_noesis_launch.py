import base64,json,tempfile,unittest,subprocess
from pathlib import Path
from unittest.mock import patch
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.hosting import launch
class LaunchPlacement(unittest.TestCase):
 def request(self,placement="current",monitor=None):
  with tempfile.TemporaryDirectory() as d:
   home=Path(d);config=home/'.config/quickshell/noesis';config.mkdir(parents=True);(config/'shell.qml').write_text('fixture')
   state=home/'.local/state/sensei-learning';state.mkdir(parents=True);(state/'window.json').write_text(json.dumps({'version':3,'placement':placement,'monitor':'eDP-1'}));requests=[]
   def run(argv,**kwargs):
    method=argv[-1] if argv[-1]=='hello' else argv[-2]
    if method=='hello':result={'version':1,'host_ready':True}
    elif method=='request':
     requests.append(json.loads(base64.b64decode(argv[-1])));result={'version':1,'status':'ready'}
    else:raise AssertionError(argv)
    return subprocess.CompletedProcess(argv,0,json.dumps(result),'')
   with patch.dict('os.environ',{'HYPRLAND_INSTANCE_SIGNATURE':'fixture'}),patch('subprocess.run',side_effect=run),patch('subprocess.check_output',return_value=json.dumps([{'name':'HDMI-A-1','focused':True}])):
    launch(home,monitor=monitor)
   return requests[0]
 def test_reopen_current_uses_invoking_monitor_instead_of_old_study_screen(self):
  self.assertEqual(self.request().get('monitor'),'HDMI-A-1')
 def test_explicit_button_display_wins_over_cursor_monitor(self):
  self.assertEqual(self.request(monitor='DP-1').get('monitor'),'DP-1')
 def test_dedicated_preference_does_not_drag_existing_window(self):
  self.assertNotIn('monitor',self.request(placement='dedicated'))
