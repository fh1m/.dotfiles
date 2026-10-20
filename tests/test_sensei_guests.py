"""Guest policy: attribution, pacing, safe placement and nonrepeating selection."""
import json,subprocess,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
JS=ROOT/'home/.local/share/sensei-companion/GuestLogic.js'
class Guests(unittest.TestCase):
 def js(self,expression):
  code="const fs=require('fs'),vm=require('vm'),c={};vm.createContext(c);vm.runInContext(fs.readFileSync(process.argv[1],'utf8'),c);console.log(JSON.stringify(vm.runInContext(process.argv[2],c)));"
  return json.loads(subprocess.check_output(['node','-e',code,str(JS),expression],text=True))
 def test_paginate_preserves_words_and_bounds(self):
  self.assertTrue(self.js("(()=>{let s=Array(80).fill('mechanism').join(' '),p=paginate(s,120);return p.join(' ')===s&&p.every(x=>x.length<=120);})()"))
 def test_introduction_is_explicitly_staged_and_quote_is_distinct(self):
  self.assertTrue(self.js("(()=>{let p=pages({name:'A',story:'Made a tool.'},{text:'Check the data.',context:'Inspect before training.',question:'What did we actually inspect?',source:'a'});return p[0].text==='Zondo as Sensei of fh1m, I have a message for Him'&&p[0].kind==='staged dialogue'&&p.some(x=>x.kind==='quotation'&&x.source==='a')&&p[p.length-1].speaker==='Zondo'&&p[p.length-1].text.endsWith('?');})()"))
 def test_last_guest_and_recent_quotes_do_not_repeat(self):
  self.assertEqual(self.js("choose([{id:'a',quotes:[{id:'a1'}]},{id:'b',quotes:[{id:'b1'},{id:'b2'}]}],{guest:'a',quotes:['b1']},'',0)"),{'guest':1,'quote':1})
 def test_invalid_requested_guest_is_not_randomly_substituted(self):
  self.assertIsNone(self.js("choose([{id:'a',quotes:[{id:'a1'}]}],{},'unknown',0)"))
 def test_whole_scene_avoids_windows_on_all_display_sizes(self):
  self.assertTrue(self.js("(()=>{for(let [w,h] of [[1920,1080],[1280,720],[1920,550],[960,540]]){let obstacles=[{x:0,y:0,w:w/2,h:h}];let p=place(w,h,420,390,obstacles,0);if(p.available&&(p.x<12||p.y<52||p.x+420>w-12||p.y+390>h-48||intersects({...p,w:420,h:390},obstacles[0])))return false;}return !place(300,300,420,390,[],0).available;})()"))
 def test_fullscreen_has_no_place(self):
  self.assertFalse(self.js('place(1920,1080,420,390,[{x:0,y:0,w:1920,h:1080}],0).available'))
 def test_reading_time_is_bounded_but_not_a_two_second_flash(self):
  self.assertEqual(self.js("duration({text:'Hello',kind:'staged dialogue'})"),7000)
  self.assertGreaterEqual(self.js("duration({text:Array(40).fill('word').join(' '),kind:'context'})"),14000)
