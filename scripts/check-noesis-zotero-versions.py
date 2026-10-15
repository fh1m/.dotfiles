import sys,tempfile,json
from pathlib import Path
from urllib.parse import urlencode
sys.path.insert(0,str(Path(__file__).resolve().parent))
from noesis_self_service_zotero import SourceLibrary
out=[]
import argparse
parser=argparse.ArgumentParser();parser.add_argument('--previous-application',type=Path,required=True);parser.add_argument('--current-application',type=Path,default=Path.home()/'.local/opt/zotero-10.0.6');args=parser.parse_args()
for version,app in [('10.0.5',args.previous_application),('10.0.6',args.current_application)]:
 home=Path(tempfile.mkdtemp(prefix='noesis-version-reader-'));s=SourceLibrary(home,native_probe=True,application=app)
 try:
  keys=s.add_annotated_pdf();uri='zotero://open-pdf/library/items/'+keys['attachment']+'?page=3&annotation='+keys['annotation'];result=s.request('noesis-native?'+urlencode({'token':s.probe_token,'uri':uri}));state=result['readers'][-1]['state'];assert state['primaryViewStats']['pageIndex']==2;assert keys['annotation'] in state['selectedAnnotationIDs'];out.append({'version':version,'physical_page':3,'exact_annotation_selected':True,'fixture':str(home),'provenance':'agent isolated source fixture'})
 finally:s.stop()
p=Path(__file__).resolve().parents[1]/'docs/learning-system/assets/release-hardening/zotero10-navigation.json';p.write_text(json.dumps(out,indent=2)+'\n');print('PASS',out)
