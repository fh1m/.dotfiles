import json,sys,tempfile,unittest,struct,uuid
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.persistence import migration
from noesis.models import create
from noesis.activities import record_activity
from noesis.index import Index
from noesis.views import overview

class ExperimentContext(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.home=Path(self.temp.name)
  self.mock=patch('pathlib.Path.home',return_value=self.home);self.mock.start();self.addCleanup(self.temp.cleanup);self.addCleanup(self.mock.stop)
  self.root=self.home/'vault';(self.root/'System').mkdir(parents=True);(self.root/'System/System.json').write_text('{}');migration(self.root,True)
  self.run=create(self.root,'experiment','Zero bias test',fields={'hypothesis':'Mean is zero','configuration':{'samples':1000,'units':'rad/s'}})
 def index(self):
  index=Index(self.root);index.reconcile();self.addCleanup(index.close);return index
 def test_original_prediction_comparison_and_unavailable_data_remain_distinct(self):
  record_activity(self.root,self.run['path'],'comparison','Mean contradicts zero',predicted='0',observed='0.12',units='rad/s',conclusion='Contradiction',next_experiment='Calibrate bias',execution={'returncode':0})
  create(self.root,'artifact','Missing data',parent_id=self.run['id'],fields={'location':str(self.home/'missing.csv')})
  view=overview(self.index(),self.run['id'])
  self.assertEqual(view['hypothesis'],'Mean is zero');self.assertEqual(view['latest_comparison']['observed'],'0.12')
  self.assertEqual(view['comparison_count'],1);self.assertEqual(view['artifacts'][0]['availability'],'artifact unavailable')
  self.assertEqual(view['latest_comparison']['execution']['returncode'],0)
 def test_only_bounded_local_png_figures_are_previewed(self):
  for name,width,height in [('figure',700,300),('oversize',10000,10000)]:
   file=self.root/(name+'.png');file.write_bytes(b'\x89PNG\r\n\x1a\n'+struct.pack('>I',13)+b'IHDR'+struct.pack('>II',width,height))
   create(self.root,'artifact',name,parent_id=self.run['id'],fields={'local_file':name+'.png'})
  create(self.root,'artifact','Remote image',parent_id=self.run['id'],fields={'location':'https://example.invalid/remote.png'})
  create(self.root,'artifact','SVG script',parent_id=self.run['id'],fields={'location':str(self.root/'script.svg')})
  view=overview(self.index(),self.run['id']);figures=[row for row in view['artifacts'] if row['figure_url']]
  self.assertEqual(len(figures),1);self.assertEqual(figures[0]['title'],'figure');self.assertTrue(figures[0]['figure_url'].startswith('file:'))
  self.assertEqual(self.index().record(figures[0]['id'])['artifact']['availability'],'available')
 def test_foreign_uuid_collision_cannot_preview_local_file(self):
  file=self.root/'private.png';file.write_bytes(b'not a public figure')
  artifact=create(self.root,'artifact','Private artifact',fields={'location':str(file)})
  owner=self.index().manifest['vault_id']
  create(self.root,'relationship','Foreign output',fields={'relation':'produces','source':self.run['id'],'target':artifact['id'],'source_ref':{'vault_id':owner,'record_id':self.run['id']},'target_ref':{'vault_id':str(uuid.uuid4()),'record_id':artifact['id']}})
  self.assertEqual(overview(self.index(),self.run['id'])['artifacts'],[])
