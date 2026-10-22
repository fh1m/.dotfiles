#!/usr/bin/env python3
"""Disposable real Xournal++ -> Noesis -> PDF -> moved-vault round trip."""
import argparse,gzip,hashlib,json,shutil,subprocess,sys,tempfile,uuid
from pathlib import Path
import xml.etree.ElementTree as ET
REPO=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.persistence import migration
from noesis.models import create
from noesis.ink import prepare,publish_preview
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=False)
with tempfile.TemporaryDirectory(prefix='noesis-ink-roundtrip-') as folder:
 root=Path(folder)/'vault';(root/'System').mkdir(parents=True);(root/'System/System.json').write_text(json.dumps({'directories':['Notes']}));migration(root,True)
 origin=create(root,'question','Disposable ink validation','This is synthetic software validation, not learner evidence.')
 first=prepare(root,origin['id'],'Synthetic graph',str(uuid.uuid4()),'graph');file=root/first['local_file']
 xml=ET.fromstring(gzip.decompress(file.read_bytes()));layer=xml.find('page/layer')
 ET.SubElement(layer,'text',{'font':'Sans','size':'18','x':'48','y':'30','color':'black'}).text='NOESIS / INK ROUND-TRIP FIXTURE'
 ET.SubElement(layer,'stroke',{'tool':'pen','color':'#ff0077ff','width':'2.5'}).text='60 450 60 150 60 450 650 450'
 ET.SubElement(layer,'stroke',{'tool':'pen','color':'#202020ff','width':'2.0'}).text='60 430 120 390 180 400 240 300 300 320 360 230 420 260 480 160 540 180 600 90'
 file.write_bytes(gzip.compress(ET.tostring(xml)));r=publish_preview(root,first['id']);pdf=Path(r['preview']);original=hashlib.sha256(pdf.read_bytes()).hexdigest()
 op=str(uuid.uuid4());second=prepare(root,origin['id'],'Synthetic PDF annotation',op,pdf_file=str(pdf));second_file=root/second['local_file']
 backgrounds=ET.fromstring(gzip.decompress(second_file.read_bytes())).findall('page/background')
 assert backgrounds and all(not Path(b.get('filename','')).is_absolute() for b in backgrounds)
 assert hashlib.sha256(pdf.read_bytes()).hexdigest()==original
 moved=Path(folder)/'moved-vault';shutil.move(root,moved)
 # The original PDF path is gone; idempotent recovery uses the owned background.
 resumed=prepare(moved,origin['id'],'Synthetic PDF annotation',op,pdf_file=str(pdf));assert resumed['id']==second['id']
 result=publish_preview(moved,second['id']);shutil.copy2(result['preview'],a.output/'ink-roundtrip.pdf')
 subprocess.run(['pdftoppm','-scale-to','1400','-png','-singlefile',str(a.output/'ink-roundtrip.pdf'),str(a.output/'ink-roundtrip')],check=True,capture_output=True)
 report={'ok':True,'original_unchanged':True,'relative_background':True,'stable_identity_after_move':True,'real_xournal_pdf_export':True,'source_format':'xopp','preview_format':'pdf','learner_evidence':False}
 (a.output/'result.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
