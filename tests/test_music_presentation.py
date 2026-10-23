"""Exercise the actual palette helper and QML service logic without a desktop."""
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT/'home/.config/quickshell/sensei/services/SpotifyDesk.qml'
loader = importlib.machinery.SourceFileLoader('music_palette', str(ROOT/'home/.local/bin/sensei-music-palette'))
spec = importlib.util.spec_from_loader(loader.name, loader)
palette = importlib.util.module_from_spec(spec)
loader.exec_module(palette)


class Palette(unittest.TestCase):
    def test_colored_art_produces_dark_matching_wash(self):
        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory)/'red artwork.png'
            Image.new('RGB', (600, 600), (255, 0, 0)).save(image)
            result = palette.palette(image.as_uri())
        self.assertEqual(result['wash'], '#451818')
        self.assertTrue(all(int(result['wash'][i:i+2], 16) <= 69 for i in (1, 3, 5)))

    def test_neutral_cover_uses_its_visible_chromatic_accent(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'cover.png'
            image=Image.new('RGB',(100,100),(40,40,40))
            image.paste((0,0,255),(0,0,35,100));image.save(path)
            value=palette.palette(str(path))['wash']
        channels=[int(value[i:i+2],16) for i in (1,3,5)]
        self.assertGreater(channels[2],channels[0])

    def test_remote_address_cannot_trigger_network_access(self):
        with self.assertRaises(ValueError):
            palette.palette('https://attacker.invalid/cover.png')
        with self.assertRaises(ValueError):
            palette.palette('file://attacker.invalid/cover.png')

    def test_missing_art_has_valid_fallback(self):
        result = subprocess.check_output([str(ROOT/'home/.local/bin/sensei-music-palette'), '/does/not/exist'], text=True)
        self.assertEqual(json.loads(result)['wash'], '#402131')


class MusicService(unittest.TestCase):
    def test_lyrics_visibility_uses_actual_content_not_provider_success(self):
        expression=next(line.split('hasLyrics:',1)[1].strip() for line in SOURCE.read_text().splitlines() if 'readonly property bool hasLyrics:' in line)
        script="const assert=require('assert');let lyricsData;const has=()=>EXPR;".replace('EXPR',expression)+r"""
lyricsData={lines:[],plain:''};assert.equal(has(),false);
lyricsData={lines:[{time:0,text:'   '}],plain:' '};assert.equal(has(),false);
lyricsData={lines:[{time:1000,text:'A line'}]};assert.equal(has(),true);
lyricsData={plain:'Unsynced words'};assert.equal(has(),true);
lyricsData={instrumental:true,plain:'metadata'};assert.equal(has(),false);
"""
        subprocess.run(['node','-e',script],check=True,capture_output=True,text=True)

    def test_focus_art_centers_without_lyrics_on_each_display_shape(self):
        source=(ROOT/'home/.config/quickshell/sensei/modules/dropdowns/SpotifyFullscreen.qml').read_text()
        expression=next(line.strip()[2:] for line in source.splitlines() if line.strip().startswith('x:!window.showLyrics||focusRoom.stacked?'))
        script=r"""
const assert=require('assert');let window,focusRoom,parent,width;
const x=()=>EXPR;
for(const screen of [1920,1080,3840,720]){
 window={showLyrics:false};focusRoom={stacked:false,margin:60};parent={width:screen};width=300;
 assert.equal(x()+width/2,screen/2);
 window.showLyrics=true;assert.equal(x(),60);
 focusRoom.stacked=true;assert.equal(x()+width/2,screen/2);
}
""".replace('EXPR',expression)
        subprocess.run(['node','-e',script],check=True,capture_output=True,text=True)

    def test_pagination_identity_art_and_queue_selection(self):
        functions = '\n'.join(line.strip() for line in SOURCE.read_text().splitlines()
                              if line.strip().startswith(('function accept(', 'function uniqueRows(', 'function play(', 'function artworkUrl(')))
        script = r'''
const vm=require('vm'),assert=require('assert');
const c={YouTubeDesk:{ownsAudio:false,loading:false},playback:{backend:'native'},page:3,libraryKind:'albums',contextItem:{},contextRows:[],libraryRows:[{id:'saved'}],nextPage:'keep',error:'',warning:'',same:(a,b)=>JSON.stringify(a)===JSON.stringify(b)};
vm.createContext(c);vm.runInContext(FUNCTIONS,c);
c.accept('more',{target:'library',kind:'liked',rows:[{id:'wrong'}],next:'wrong'});
assert.equal(c.libraryRows[0].id,'saved');assert.equal(c.nextPage,'keep');
c.contextItem={id:'context',kind:'playlist'};c.contextRows=[{id:'same'}];
c.accept('more',{target:'context',contextId:'context',rows:[{id:'same'},{id:'new'}]});assert.equal(c.contextRows.length,3); // repeated playlist entries are intentional
c.action=(...args)=>c.last=args;c.visibleRows=[];
c.play({kind:'track',id:'a',uri:'spotify:track:a'},[{kind:'track',id:'a',uri:'spotify:track:a'},{kind:'track',id:'b',uri:'spotify:track:b'}]);
assert.equal(c.last[0],'play-list');assert.equal(JSON.parse(c.last[1][0]).uris.length,2);
const id='a'.repeat(40);assert.equal(c.artworkUrl('spotify:image:'+id),'https://i.scdn.co/image/'+id);
assert.equal(c.artworkUrl('spotify:mosaic:unsupported'),'');assert.equal(c.artworkUrl('javascript:bad'),'');
'''.replace('FUNCTIONS', json.dumps(functions))
        subprocess.run(['node', '-e', script], check=True, capture_output=True, text=True)



class NativeQueue(unittest.TestCase):
    def test_reordering_and_removal_preserve_the_current_item_identity(self):
        source=(ROOT/'home/.config/quickshell/sensei/services/YouTubeDesk.qml').read_text()
        functions='\n'.join(line.strip() for line in source.splitlines() if line.strip().startswith(('function removeQueued(', 'function moveQueued(', 'function enqueue(')))
        script=r'''
const vm=require('vm'),assert=require('assert');
const c={queue:[{id:'a'},{id:'b'},{id:'c'}],track:{id:'b'},index:1};vm.createContext(c);vm.runInContext(FUNCTIONS,c);
c.moveQueued({id:'b'},1);assert.deepEqual(c.queue.map(r=>r.id),['a','c','b']);assert.equal(c.index,2);
c.removeQueued({id:'a'});assert.equal(c.index,1);assert.equal(c.queue[c.index].id,'b');
c.enqueue({id:'b'});assert.equal(c.queue.length,2);c.enqueue({id:'d'});assert.equal(c.queue.length,3);
c.moveQueued({id:'c'},-1);assert.equal(c.queue[0].id,'c');
'''.replace('FUNCTIONS',json.dumps(functions))
        subprocess.run(['node','-e',script],check=True,capture_output=True,text=True)


class NativeHandoff(unittest.TestCase):
    def test_destination_starts_only_after_source_stops_and_preserves_position(self):
        source=(ROOT/'home/.config/quickshell/sensei/services/YouTubeDesk.qml').read_text()
        functions='\n'.join(line.strip() for line in source.splitlines() if line.strip().startswith(('function registerEngine(', 'function loadCurrent(', 'function selectEngine(')))
        script=r'''
const vm=require('vm'),assert=require('assert'),events=[];
const old={volume:82,stop:()=>events.push('old stopped')};
const next={load:(v,a,visual,start,paused)=>events.push({v,a,visual,start,paused})};
const c={engines:{old},engineOutput:'old',usedDisplays:['old'],currentMedia:{stream:'https://audio.invalid',video:'https://video.invalid'},pendingSeek:0,desiredVolume:65,speed:1.25};
Object.defineProperty(c,'audioPlayer',{get(){return c.engines[c.engineOutput]}});
vm.createContext(c);vm.runInContext(FUNCTIONS,c);
c.selectEngine('destination',12345,true);assert.equal(events[0],'old stopped');assert.equal(events.length,1);
assert.equal(c.pendingSeek,12345);assert.equal(c.desiredVolume,82);assert.equal(c.engineOutput,'destination');
c.registerEngine('destination',next);assert.equal(events.length,2);assert.equal(events[1].a,'https://audio.invalid');assert.equal(events[1].visual,true);assert.equal(next.volume,82);assert.equal(next.playbackRate,1.25);assert.equal(events[1].start,12345);assert.equal(c.pendingSeek,0);assert.equal(events[1].paused,true);
'''.replace('FUNCTIONS',json.dumps(functions))
        subprocess.run(['node','-e',script],check=True,capture_output=True,text=True)

if __name__ == '__main__':
    unittest.main()
