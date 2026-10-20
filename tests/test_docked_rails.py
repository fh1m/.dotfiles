"""Evaluate the deployed QML's routing expressions without a live compositor."""
import json,re,shutil,subprocess,unittest
from pathlib import Path
QML=(Path(__file__).resolve().parents[1]/'home/.config/quickshell/sensei/services/ShellState.qml').read_text()
@unittest.skipUnless(shutil.which('node'),'Node needed for QML-JS routing checks')
class Rails(unittest.TestCase):
 def route(self,names,desktop=False):
  dock=re.search(r'readonly property bool dockedRails: (.*)',QML)[1]
  top=re.search(r'readonly property var barScreens: \{(.*?)\n    \}',QML,re.S)[1]
  bottom=re.search(r'readonly property var bottomBarScreens: (.*)',QML)[1]
  code='''const screens=NAMES.map(name=>({name}));const MachineProfile={desktop:DESKTOP,primaryOutput:DESKTOP?'DP-3':'eDP-1',role:n=>({'DP-1':'upper','HDMI-A-1':'lower','DP-2':'screenpad'})[n]};const externalScreens=screens.filter(s=>['DP-1','HDMI-A-1'].includes(s.name));const dockedRails=DOCK;const barScreens=(()=>{TOP})();const bottomBarScreens=BOTTOM;console.log(JSON.stringify([barScreens.map(s=>s.name),bottomBarScreens.map(s=>s.name)]));'''.replace('NAMES',json.dumps(names)).replace('DESKTOP',json.dumps(desktop)).replace('DOCK',dock).replace('TOP',top).replace('BOTTOM',bottom)
  return json.loads(subprocess.check_output(['node','-e',code],text=True))
 def test_docked_uses_only_upper_and_lower(self):
  self.assertEqual(self.route(['eDP-1','DP-2','DP-1','HDMI-A-1']),[['DP-1'],['HDMI-A-1']])
 def test_unplug_restores_laptop_controls(self):
  self.assertEqual(self.route(['eDP-1','DP-2']),[['eDP-1'],['DP-2']])
 def test_partial_dock_keeps_main_controls(self):
  self.assertEqual(self.route(['eDP-1','DP-2','HDMI-A-1']),[['eDP-1'],['DP-2','HDMI-A-1']])
 def test_homie_keeps_pc_bars(self):
  self.assertEqual(self.route(['DP-3'],True),[['DP-3'],['DP-3']])
