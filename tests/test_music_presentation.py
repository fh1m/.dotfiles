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

    def test_remote_address_cannot_trigger_network_access(self):
        with self.assertRaises(ValueError):
            palette.palette('https://attacker.invalid/cover.png')
        with self.assertRaises(ValueError):
            palette.palette('file://attacker.invalid/cover.png')

    def test_missing_art_has_valid_fallback(self):
        result = subprocess.check_output([str(ROOT/'home/.local/bin/sensei-music-palette'), '/does/not/exist'], text=True)
        self.assertEqual(json.loads(result)['wash'], '#402131')


class MusicService(unittest.TestCase):
    def test_pagination_identity_art_and_queue_selection(self):
        functions = '\n'.join(line.strip() for line in SOURCE.read_text().splitlines()
                              if line.strip().startswith(('function accept(', 'function uniqueRows(', 'function play(', 'function artworkUrl(')))
        script = r'''
const vm=require('vm'),assert=require('assert');
const c={page:3,libraryKind:'albums',contextItem:{},contextRows:[],libraryRows:[{id:'saved'}],nextPage:'keep',error:'',warning:'',same:(a,b)=>JSON.stringify(a)===JSON.stringify(b)};
vm.createContext(c);vm.runInContext(FUNCTIONS,c);
c.accept('more',{target:'library',kind:'liked',rows:[{id:'wrong'}],next:'wrong'});
assert.equal(c.libraryRows[0].id,'saved');assert.equal(c.nextPage,'keep');
c.contextItem={id:'context',kind:'playlist'};c.contextRows=[{id:'same'}];
c.accept('more',{target:'context',contextId:'context',rows:[{id:'same'},{id:'new'}]});assert.equal(c.contextRows.length,2);
c.action=(...args)=>c.last=args;c.visibleRows=[];
c.play({kind:'track',id:'a',uri:'spotify:track:a'},[{kind:'track',id:'a',uri:'spotify:track:a'},{kind:'track',id:'b',uri:'spotify:track:b'}]);
assert.equal(c.last[0],'play-list');assert.equal(JSON.parse(c.last[1][0]).uris.length,2);
const id='a'.repeat(40);assert.equal(c.artworkUrl('spotify:image:'+id),'https://i.scdn.co/image/'+id);
assert.equal(c.artworkUrl('spotify:mosaic:unsupported'),'');assert.equal(c.artworkUrl('javascript:bad'),'');
'''.replace('FUNCTIONS', json.dumps(functions))
        subprocess.run(['node', '-e', script], check=True, capture_output=True, text=True)


if __name__ == '__main__':
    unittest.main()
