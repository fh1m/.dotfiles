"""Exercise actual placement/message policy without a compositor or user data."""
from pathlib import Path
import json
import shutil
import subprocess
import unittest

ROOT=Path(__file__).resolve().parents[1]
JS=ROOT/'home/.local/share/sensei-companion/CompanionLogic.js'
@unittest.skipUnless(shutil.which('node'),'Node needed for pure QML-JS policy checks')
class CompanionPolicy(unittest.TestCase):
    def js(self, expression):
        code="const vm=require('vm'),fs=require('fs');let c={};vm.createContext(c);vm.runInContext(fs.readFileSync(process.argv[1],'utf8'),c);c.notes=JSON.parse(fs.readFileSync(process.argv[1].replace('CompanionLogic.js','notes.json'),'utf8'));console.log(JSON.stringify(vm.runInContext(process.argv[2],c)));"
        return json.loads(subprocess.check_output(['node','-e',code,str(JS),expression],text=True))
    def test_full_window_has_no_safe_spot(self):
        self.assertFalse(self.js('place(1920,1080,96,96,[{x:0,y:0,w:1920,h:1080}],0)')['available'])
    def test_window_occlusion_avoided_on_scaled_and_small_displays(self):
        self.assertTrue(self.js('(()=>{for(const [w,h] of [[1920,1080],[1920,550],[1280,720]]){const win={x:w/2,y:0,w:w/2,h:h};for(let i=0;i<12;i++){const p=place(w,h,256,208,[win],i);if(!p.available||intersects({x:p.x,y:p.y,w:256,h:208},win))return false;}}return true;})()'))
    def test_floating_window_and_bubble_both_respected(self):
        self.assertTrue(self.js('(()=>{const wins=[{x:1500,y:650,w:420,h:430},{x:0,y:0,w:600,h:400}];return Array.from({length:10},(_,i)=>place(1920,1080,256,208,wins,i)).every(p=>p.available&&!wins.some(w=>intersects({x:p.x,y:p.y,w:256,h:208},w)));})()'))
    def test_recent_messages_do_not_repeat_and_context_stays_relevant(self):
        self.assertTrue(self.js('(()=>{let recent=[];for(let t=0;t<20;t++){const n=nextNote("Alacritty",recent,t,.42);if(recent.includes(n.id))return false;if(notes[n.id].contexts.length&&!notes[n.id].contexts.includes("terminal"))return false;recent=recent.concat(n.id).slice(-8);}return true;})()'))
    def test_small_display_does_not_put_bubble_offscreen(self):
        self.assertFalse(self.js('place(200,150,256,208,[],0)')['available'])
    def test_humour_is_not_fake_status(self):
        self.assertTrue(self.js('notes.filter(n=>n.kind==="wit").every(n=>!n.text.toLowerCase().includes("tests passed"))'))
    def test_walking_never_flies_to_a_different_edge(self):
        self.assertTrue(self.js('canWalk({available:true,x:400,y:900},{available:true,x:540,y:900})'))
        self.assertFalse(self.js('canWalk({available:true,x:400,y:900},{available:true,x:540,y:50})'))
        self.assertFalse(self.js('canWalk({available:true,x:400,y:900},{available:true,x:1700,y:900})'))
if __name__=='__main__':unittest.main()
