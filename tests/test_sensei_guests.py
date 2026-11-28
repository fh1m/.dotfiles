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
  self.assertTrue(self.js("(()=>{let p=pages({name:'A'},{text:'Check the data.',context:'Inspect before training.',question:'What did we actually inspect?',source:'a'});return p[0].speaker==='Zondo'&&p[0].kind==='staged dialogue'&&p.filter(x=>x.kind==='quotation').every(x=>x.speaker==='A'&&x.source==='a')&&p.some(x=>x.kind==='quotation')&&p.at(-1).speaker==='Zondo';})()"))
 def test_last_guest_and_recent_quotes_do_not_repeat(self):
  self.assertEqual(self.js("choose([{id:'a',quotes:[{id:'a1'}]},{id:'b',quotes:[{id:'b1'},{id:'b2'}]}],{guest:'a',quotes:['b1']},'',()=>0)"),{'guest':1,'quote':1})
 def test_invalid_requested_guest_is_not_randomly_substituted(self):
  self.assertIsNone(self.js("choose([{id:'a',quotes:[{id:'a1'}]}],{},'unknown',()=>0)"))
 def test_rotation_finishes_the_family_before_repeating_and_keeps_other_guests_history(self):
  self.assertTrue(self.js(r"""(()=>{
    let g={id:'a',quotes:Array.from({length:80},(_,i)=>({id:'q'+i}))};
    let history={quotes:['other-guest']}, visited=new Set(), last;
    for(let i=0;i<80;i++){
      const choice=choose([g],history,'a',()=>0,'quotes'), item=entries(g)[choice.quote];
      if(visited.has(item.id))return false;
      visited.add(item.id);last=item.id;
      history.quotes=remember(g,item,history.quotes);
    }
    const next=entries(g)[choose([g],history,'a',()=>0,'quotes').quote];
    return next.id!==last&&remember(g,next,history.quotes).join(',')==='other-guest,'+next.id;
  })()"""))
 def test_whole_scene_avoids_windows_on_all_display_sizes(self):
  self.assertTrue(self.js("(()=>{for(let [w,h] of [[1920,1080],[1280,720],[1920,550],[960,540]]){let obstacles=[{x:0,y:0,w:w/2,h:h}];let p=place(w,h,420,390,obstacles,0);if(p.available&&(p.x<12||p.y<52||p.x+420>w-12||p.y+390>h-48||intersects({...p,w:420,h:390},obstacles[0])))return false;}return !place(300,300,420,390,[],0).available;})()"))
 def test_fullscreen_has_no_place(self):
  self.assertFalse(self.js('place(1920,1080,420,390,[{x:0,y:0,w:1920,h:1080}],0).available'))
 def test_reading_time_is_bounded_but_not_a_two_second_flash(self):
  self.assertEqual(self.js("duration({text:'Hello',kind:'staged dialogue'})"),7000)
  self.assertGreaterEqual(self.js("duration({text:Array(40).fill('word').join(' '),kind:'context'})"),14000)
 def test_expanded_library_has_100_plus_entries_per_guest_without_fake_quotes(self):
  data=json.loads((JS.parent/'guests/catalog.json').read_text())
  for guest in data['guests']:
   e=self.js('entries('+json.dumps(guest)+')')
   self.assertGreaterEqual(len(e),110,guest['id'])
   self.assertEqual(len({x['id'] for x in e}),len(e))
   self.assertEqual(sum(not x.get('kind') for x in e),len(guest['quotes']))
   self.assertEqual(sum(x.get('kind')=='story' for x in e),len(guest['topics']))
   self.assertEqual(sum(x.get('kind')=='workshop' for x in e),len(guest['topics'])*9)
   self.assertTrue(all(x.get('source') in data['sources'] for x in e))
 def test_workshop_is_never_attributed_as_a_historical_quotation(self):
  p=self.js("pages({name:'A'},{kind:'workshop',text:'Try an independent example.',context:'The source describes a test.',question:'What would fail?',source:'a'})")
  self.assertFalse(any(x['kind']=='quotation' for x in p))
  self.assertTrue(any(x['speaker']=='Zondo' and 'original exercise' in x['kind'] for x in p))
 def test_explicit_family_selection_is_honored(self):
  guest={'id':'a','quotes':[{'id':'q'}],'topics':[{'id':'t','title':'Topic','source':'s','story':'Fact','task':'Try it.','question':'Why?'}]}
  for mode,kind in [('quotes',None),('stories','story'),('workshop','workshop')]:
   expression='(()=>{let g='+json.dumps(guest)+';let c=choose([g],{},"a",()=>0.9,"'+mode+'");return entries(g)[c.quote].kind||null;})()'
   self.assertEqual(self.js(expression),kind)
 def test_mixed_rotation_uses_distinct_topics_before_repeating_one(self):
  self.assertTrue(self.js(r"""(()=>{
    let g={id:'a',quotes:[{id:'q1'},{id:'q2'}],
           topics:Array.from({length:8},(_,i)=>({id:'t'+i}))};
    let old=[], topics=[], items=entries(g), visited=new Set();
    for(let i=0;i<items.length;i++){
      const q=items[choose([g],{quotes:old},'a',()=>0).quote];
      if(visited.has(q.id)||(i<10&&topics.includes(q.topic||q.id)))return false;
      visited.add(q.id);topics.push(q.topic||q.id);old=remember(g,q,old);
    }
    return visited.size===items.length;
  })()"""))
 def test_every_generated_visit_paginates_and_ends_with_zondo_question(self):
  data=json.loads((JS.parent/'guests/catalog.json').read_text())
  for guest in data['guests']:
   self.assertTrue(self.js('(()=>{let g='+json.dumps(guest)+';return entries(g).every(q=>{let p=pages(g,q);return p.every(c=>c.text.length<=220)&&p[p.length-1].speaker==="Zondo"&&p[p.length-1].text.endsWith("?");});})()'))
