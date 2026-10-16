import importlib.util,tempfile,unittest,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'pc/den'
sys.path.insert(0,str(ROOT.parents[1]/'home/.local/share/sensei'))
def load(name,file):
 s=importlib.util.spec_from_file_location(name,ROOT/file);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
edge=load('edge','den-edge-return.py');place=load('place','den-entry-place.py')
class Generation(unittest.TestCase):
 def test_stale_and_released_entries_rejected(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);(p/'input').mkdir();(p/'input/active').write_text('1');(p/'input/active.session').write_text('0:20:100')
   self.assertTrue(edge.current_entry(p,'0:20:100'));self.assertFalse(edge.current_entry(p,'0:20:99'))
   (p/'input/active').write_text('0');self.assertFalse(edge.current_entry(p,'0:20:100'))
   self.assertTrue(edge.current_return(p,'0:20:100'));self.assertFalse(edge.current_return(p,'0:20:99'))
 def test_receiver_rejects_duplicate_and_older_placement(self):
  self.assertTrue(place.newer('1:4:101','0:4:100'));self.assertFalse(place.newer('0:4:100','1:4:101'));self.assertFalse(place.newer('0:4:100','0:4:100'))
 def test_old_helper_cannot_clear_a_new_return_guard(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d);(root/'input').mkdir();guard=root/'input/active.returning';guard.write_text('1:2:300')
   edge.clear_return(root,'1:2:200');self.assertTrue(guard.exists())
   edge.clear_return(root,'1:2:300');self.assertFalse(guard.exists())
 def test_invalid_token_fails_closed(self):
  with self.assertRaises(ValueError):place.newer('touch anything','')
if __name__=='__main__':unittest.main()


class PaletteTemplateContract(__import__('unittest').TestCase):
    def test_both_host_generators_understand_every_theme_token(self):
        import ast,re
        from pathlib import Path
        root=Path(__file__).resolve().parents[1]
        tokens=set(re.findall(r'@[A-Z]+@',(root/'home/.config/tmux/sensei-theme.template.conf').read_text()))
        for source in ['home/.local/bin/sensei-palette','profiles/pc/home/.local/bin/sensei-palette']:
            tree=ast.parse((root/source).read_text())
            mappings=[n.value for n in ast.walk(tree) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='replacements' for t in n.targets)]
            keys={k.value for d in mappings if isinstance(d,ast.Dict) for k in d.keys if isinstance(k,ast.Constant)}
            self.assertFalse(tokens-keys,source+' lacks '+str(tokens-keys))
