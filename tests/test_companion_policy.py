"""Exercise actual placement/message policy without a compositor or user data."""
from pathlib import Path
import json
import shutil
import subprocess
import unittest

ROOT=Path(__file__).resolve().parents[1]
JS=ROOT/'home/.local/share/sensei-companion/ZondoLogic.js'
@unittest.skipUnless(shutil.which('node'),'Node needed for pure QML-JS policy checks')
class CompanionPolicy(unittest.TestCase):
    def js(self, expression):
        code="const vm=require('vm'),fs=require('fs');let c={};vm.createContext(c);vm.runInContext(fs.readFileSync(process.argv[1],'utf8'),c);c.notes=JSON.parse(fs.readFileSync(process.argv[1].replace('ZondoLogic.js','notes.json'),'utf8'));console.log(JSON.stringify(vm.runInContext(process.argv[2],c)));"
        return json.loads(subprocess.check_output(['node','-e',code,str(JS),expression],text=True))
    def test_singing_only_uses_fresh_playing_short_nonrepeated_lyrics(self):
        self.assertEqual(self.js("singLine({playing:true,at:1000,line:'one two three four five six seven eight nine'},2000,'',.1)"), 'one two three four five six seven eight nine')
        for receipt, now, last, random in [({'playing':False,'at':1000,'line':'hello'},2000,'',.1), ({'playing':True,'at':1000,'line':'hello'},32000,'',.1), ({'playing':True,'at':3000,'line':'hello'},2000,'',.1), ({'playing':True,'at':1000,'line':'hello'},2000,'hello',.1), ({'playing':True,'at':1000,'line':'hello'},2000,'',.8)]:
            self.assertEqual(self.js(f'singLine({json.dumps(receipt)},{now},{json.dumps(last)},{random})'), '')
    def test_expired_current_line_cannot_be_sung_from_a_recent_receipt(self):
        self.assertEqual(self.js("singLine({playing:true,at:1000,until:1500,line:'hello'},1600,'',0)"), '')
        self.assertEqual(self.js("singLine({playing:true,at:1000,until:2500,line:'hello'},1600,'',0)"), 'hello')
    def test_notification_content_is_not_repeated_or_prefixed_by_app(self):
        self.assertEqual(self.js("noticeTitle({phone:true,app:'KDE Connect',summary:'Alice',body:'Hello'})"),'Alice')
        self.assertEqual(self.js("noticeText({phone:true,app:'KDE Connect',summary:'Alice',body:'Hello'})"),'Hello')
        self.assertEqual(self.js("noticeText({app:'Build',summary:'Failed',body:'Failed'})"),'')
    def test_singing_survives_short_gaps_but_honours_pause_dnd_and_end(self):
        self.assertTrue(self.js('singingContinues(true,false,6000,75000,1000)'))
        for args in ['false,false,6000,75000,1000','true,true,6000,75000,1000','true,false,75000,75000,74000','true,false,10000,75000,1000']:
            self.assertFalse(self.js('singingContinues('+args+')'))
    def test_notification_queue_preserves_order_deduplicates_and_honours_dnd(self):
        expression="(()=>{Array.prototype.flatMap=undefined;return nextNotice([{unread:2,entries:[{id:'b',at:20},{id:'a',at:10}]}],['a']);})()"
        self.assertEqual(self.js(expression),{'id':'b','at':20})
        self.assertIsNone(self.js("nextNotice([{unread:1,dnd:true,entries:[{id:'a',at:10}]}],[])"))
        self.assertIsNone(self.js("nextNotice([{unread:0,entries:[{id:'a',at:10}]}],[])"))
    def test_link_notices_follow_latest_transition_and_live_presence(self):
        down={'id':'down','at':100000,'app':'Digital Den','summary':'Den peer unavailable'}
        up={'id':'up','at':110000,'app':'Digital Den','summary':'Homie connected'}
        sources=[{'host':'arete','unread':2,'entries':[down,up]}]
        expr=f'nextNotice({json.dumps(sources)},[],120000,{{peer:true,time:119}})'
        self.assertEqual(self.js(expr),up)
        # A resolved outage is not spoken even if the recovery was acknowledged.
        self.assertIsNone(self.js(expr.replace('[],120000', '["up"],120000')))
        self.assertIsNone(self.js(f'nextNotice({json.dumps(sources)},[],300000,{{}})'))
        only=[{'unread':1,'entries':[down]}]
        self.assertIsNone(self.js(f'nextNotice({json.dumps(only)},[],120000,{{peer:true,time:119}})'))
        self.assertEqual(self.js(f'nextNotice({json.dumps(only)},[],120000,{{peer:false,time:119}})'),down)
        self.assertEqual(self.js(f'nextNotice({json.dumps(only)},[],120000,{{peer:true,time:1}})'),down)
    def test_ordinary_notifications_are_not_expired_by_link_policy(self):
        entry={'id':'phone','at':10,'phone':True,'app':'KDE Connect','summary':'Message'}
        self.assertEqual(self.js(f'nextNotice([{{unread:1,entries:[{json.dumps(entry)}]}}],[],999999,{{peer:true,time:999}})'),entry)
    def test_rooftops_require_known_wallpaper_and_clear_space(self):
        self.assertIsNone(self.js("roofPlace('/unknown.png',1920,1080,256,208,[],1)"))
        self.assertIsNone(self.js("roofPlace('/wallhaven-1q2p3v.png',1920,550,256,208,[],1)"))
        self.assertIsNone(self.js("roofPlace('/wallhaven-1q2p3v.png',1920,1080,256,208,[{x:0,y:0,w:1920,h:1080}],1)"))
        self.assertEqual(self.js("roofPlace('/wallhaven-1q2p3v.png',1920,1080,256,208,[],1)")['scene'],'roof')
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
    def test_non_corner_positions_are_available(self):
        self.assertTrue(self.js('(()=>{const p=place(1920,1080,96,96,[],0);return p.available&&p.x>500&&p.y>200&&p.y<800;})()'))
    def test_activities_vary_and_music_uses_dance_family(self):
        self.assertTrue(self.js("(()=>{let a='read',seen=new Set();for(let i=0;i<100;i++){let n=nextActivity(a,false,i/100);if(n===a)return false;seen.add(n);a=n;}return seen.size>=12;})()"))
        self.assertTrue(self.js("Array.from({length:100},(_,i)=>nextActivity('read',true,i/100)).every(x=>['dance','guitar','stretch'].includes(x))"))
    def test_retired_lines_never_reappear(self):
        self.assertIsNone(self.js("nextNote('terminal',[],0,.5,notes.map((_,i)=>i),[])"))
    def test_personal_lines_have_provenance(self):
        self.assertTrue(self.js("notes.filter(n=>n.kind==='memory').every(n=>n.source==='https://fh1m.github.io/about/')"))
    def test_travel_uses_a_clear_corridor(self):
        self.assertTrue(self.js("canTravel({available:true,x:50,y:60},{available:true,x:800,y:600},96,96,[])"))
        self.assertFalse(self.js("canTravel({available:true,x:50,y:60},{available:true,x:800,y:600},96,96,[{x:400,y:200,w:200,h:300}])"))
class SpeechLayout(unittest.TestCase):
    @unittest.skipUnless(shutil.which('node'),'Node needed for pure speech geometry checks')
    def test_bubble_never_covers_character_or_windows(self):
        source=ROOT/'home/.local/share/sensei-companion/SpeechLayout.js'
        code="const vm=require('vm'),fs=require('fs');let c={};vm.createContext(c);vm.runInContext(fs.readFileSync(process.argv[1],'utf8'),c);for(let x of [12,300,1750])for(let y of [55,400,900])for(let h of [64,90,130]){let p={x,y},a=c.place(1920,1080,256,h,p,96,96,[]);if(a.available&&(c.intersects({...a,w:256,h},{...p,w:96,h:96})||a.x<0||a.y<0||a.x+256>1920||a.y+h>1080))process.exit(1);}let a=c.place(1920,1080,256,120,{x:400,y:400},96,96,[{x:0,y:0,w:1920,h:1080}]);if(a.available)process.exit(2);"
        subprocess.check_call(['node','-e',code,str(source)])
    @unittest.skipUnless(shutil.which('node'),'Node needed for pure speech geometry checks')
    def test_enlarged_singing_card_respects_small_and_large_outputs(self):
        source=ROOT/'home/.local/share/sensei-companion/SpeechLayout.js'
        code="""const vm=require('vm'),fs=require('fs');let c={};vm.createContext(c);
        vm.runInContext(fs.readFileSync(process.argv[1],'utf8'),c);
        let count=0;
        for(const [sw,sh] of [[1920,1080],[1920,550],[1280,720]])
        for(const w of [300,420]) for(const h of [100,160,260])
        for(const size of [96,160,200]) for(const x of [12,600,sw-size-12]) {
          const pet={x,y:sh-size-60};
          const a=c.place(sw,sh,w,h,pet,size,size,[]);
          if(a.available){count++;if(a.x<12||a.y<52||a.x+w>sw-12||a.y+h>sh-52||
            c.intersects({...a,w,h},{...pet,w:size,h:size}))process.exit(1);}
        }
        if(count<50)process.exit(2);"""
        subprocess.check_call(['node','-e',code,str(source)])

if __name__=='__main__':unittest.main()
