"""Workspace placement and connected-device battery regression fixtures."""
import json
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class WorkspaceDevices(unittest.TestCase):
    def test_requested_app_placement(self):
        source = (ROOT/'home/.config/hypr/workspace-apps.lua').read_text()
        routes = [(int(n), re.compile(json.loads(pattern))) for n, pattern in
                  re.findall(r'\{(\d),("(?:\\.|[^"\\])*")\}', source)]
        expected = {'kitty':1, 'Alacritty':1, 'firefox':2, 'Google-chrome':2,
                    'Code':3, 'Cursor':3, 'org.fh1m.Noesis':4, 'obsidian':4,
                    'Notion':4, 'Zotero':4, 'gazebo':5, 'rviz2':5,
                    'org.gnome.Nautilus':6, 'discord':6, 'Spotify':7}
        for app, workspace in expected.items():
            with self.subTest(app=app):
                self.assertEqual([n for n, pattern in routes if pattern.fullmatch(app)], [workspace])

    def test_connected_reports_and_provider_deduplication(self):
        source = (ROOT/'home/.config/quickshell/sensei/services/DeviceBatteries.js').read_text().replace('.pragma library', '')
        fixture = r'''
const assert=require('node:assert/strict');
const phone={id:'p',name:'Phone',isPaired:true,isReachable:true,battery:{charge:0,isCharging:false}};
const bt={name:'Headset',address:'AA:BB:CC:DD:EE:FF',connected:true,batteryAvailable:true,battery:.9};
const up={ready:true,type:6,isLaptopBattery:false,isPresent:true,nativePath:'dev_AA_BB_CC_DD_EE_FF',model:'Headset',percentage:1,iconName:'battery-full'};
const keyboard={...up,nativePath:'keyboard',model:'Keyboard',percentage:.55};
let r=rows([phone],[bt],[up,keyboard]);
assert.equal(r.length,3);assert.deepEqual(r.map(x=>Math.round(x.percent)),[0,90,55]);
assert.equal(rows([{...phone,isReachable:false}],[{...bt,connected:false}],[up]).length,0);
assert.equal(rows([],[],[{...up,iconName:'battery-missing-symbolic'}]).length,0);
assert.equal(rows([],[],[{...up,isLaptopBattery:true}]).length,0);
assert.equal(rows([phone],[{...bt,name:'Phone',icon:'phone'}],[]).length,1);
assert.equal(rows([],[],[{...up,isPresent:false}]).length,0);
assert.equal(rows([],[],[{...keyboard,isPresent:false}]).length,1);
assert.equal(rows([],[],[{...keyboard,type:2,isPresent:false}]).length,0);
assert.deepEqual(rows([],[],[]),[]);
'''
        subprocess.run(['node','-e',source+fixture],check=True,capture_output=True,text=True)

    def test_shared_workspace_identity_uses_current_ipc_not_stale_object(self):
        source=(ROOT/'home/.config/quickshell/sensei/services/Spaces.qml').read_text()
        functions='\n'.join(re.findall(r'    function (?:logicalId|windowWorkspace)\([^\n]+',source)).replace(':int','')
        self.assertTrue(functions)
        subprocess.run(['node','-e',functions+"""
const assert=require('node:assert/strict');
const main={workspace:{id:1},lastIpcObject:{workspace:{id:6}}};
const ext={workspace:{id:1},lastIpcObject:{workspace:{id:106}}};
assert.equal(logicalId(windowWorkspace(main)),6);
assert.equal(logicalId(windowWorkspace(ext)),6);
assert.equal([main,ext].filter(w=>logicalId(windowWorkspace(w))===6).length,2);
assert.equal(logicalId(windowWorkspace({workspace:{id:7}})),7);
assert.equal(logicalId(-98),-98);
"""],check=True,capture_output=True,text=True)

    def test_attention_address_normalization_and_acknowledgement(self):
        source = (ROOT/'home/.config/quickshell/sensei/services/Spaces.qml').read_text()
        functions = '\n'.join(re.findall(r'    function (?:attention|acknowledge)\(address\):void \{[^\n]+',source))
        functions = functions.replace(":void", "")
        self.assertTrue(functions)
        subprocess.run(['node','-e','let attentionAddresses=[];\n'+functions+'''
const assert=require('node:assert/strict');
attention('0xabc');attention('abc');attention('0xdef');
assert.deepEqual(attentionAddresses,['abc','def']);
acknowledge('0xabc');assert.deepEqual(attentionAddresses,['def']);
acknowledge('def');assert.deepEqual(attentionAddresses,[]);
'''],check=True,capture_output=True,text=True)

if __name__ == '__main__':
    unittest.main()
