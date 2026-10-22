"""Execute the QML action serializer without touching NetworkManager."""
import subprocess,shutil,unittest
from pathlib import Path
SOURCE=Path(__file__).resolve().parents[1]/'home/.config/quickshell/sensei/services/Wifi.qml'
class WifiActions(unittest.TestCase):
 @unittest.skipUnless(shutil.which('node'),'node required')
 def test_rapid_actions_leave_running_argv_and_secret_untouched(self):
  source=SOURCE.read_text();start=source.index('    function runConnection(');end=source.index('    function connect(',start)
  function=source[start:end].replace(': void','')
  code='''const assert=require('assert');let Machine={wifiInterface:'wlan0'},error='',pendingConnection=null,_pendingSecret='',connectProc={running:false},root={};function begin(s){root.linking=s;}
'''+function+'''
runConnection(['connect','first'],'first-secret','first');
runConnection(['disconnect'],'','Disconnecting');
runConnection(['connect','last'],'last-secret','last');
assert.deepStrictEqual(connectProc.command,['connect','first']);
assert.equal(_pendingSecret,'first-secret');
assert.deepStrictEqual(pendingConnection.command,['connect','last']);
assert.equal(pendingConnection.secret,'last-secret');
connectProc.running=false;let next=pendingConnection;pendingConnection=null;
runConnection(next.command,next.secret,next.ssid);
assert.deepStrictEqual(connectProc.command,['connect','last']);assert.equal(root.linking,'last');
Machine.wifiInterface='';connectProc.running=false;runConnection(['bad'],'','bad');assert.equal(error,'No wireless adapter is available');assert.deepStrictEqual(connectProc.command,['connect','last']);
'''
  subprocess.run(['node','-e',code],check=True)
if __name__=='__main__':unittest.main()
