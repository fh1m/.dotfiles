import sys
from pathlib import Path
import tempfile
import json
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'home/.local/lib'))
import sensei_knowledge as k

class Knowledge(unittest.TestCase):
    def test_unlimited_discovery_and_preserved_notes(self):
        with tempfile.TemporaryDirectory() as d:
            h = Path(d); vaults = {}
            for n in range(12):
                p = h / str(n) / 'Notes'; p.mkdir(parents=True)
                vaults[str(n)] = {'path': str(p)}
            app = h / '.config/obsidian/obsidian.json'; app.parent.mkdir(parents=True)
            app.write_text(json.dumps({'vaults': vaults}))
            self.assertEqual(len(k.configuration(h)['vaults']), 12)
            p = {'root': str(h / 'robot'), 'container': 'any-future-container'}
            v = vaults['7']['path']
            root, rel, folder = k.project(h, p, v)
            note = folder / 'Scratchpad.md'; note.write_text('My existing work')
            k.project(h, p, v)
            self.assertEqual(note.read_text(), 'My existing work')
            canvas = json.loads((folder / 'Map.canvas').read_text())
            self.assertEqual(len(canvas['edges']), 2)
            drawing, gui = k.action(h, p, 'draw', v)
            self.assertTrue(gui); self.assertIn('excalidraw-plugin: parsed', drawing.read_text())
            review, gui = k.action(h, p, 'review', v, source_file=str(h / 'robot/a.py'), excerpt='unsaved_code()', filetype='python')
            self.assertFalse(gui); self.assertIn('unsaved_code()', review.read_text())
            self.assertIn('sensei-dev://open?', review.read_text())

if __name__ == '__main__': unittest.main()
