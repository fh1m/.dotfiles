#!/usr/bin/env python3
"""Owned disposable Research composition; synthetic annotations are labelled fixtures."""
import json,subprocess,time,sys,uuid
from pathlib import Path
from noesis_native_fixture import Fixture,REPO
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.persistence import render,checksum
f=Fixture();evidence=Path('/tmp/noesis-research-layout-evidence');evidence.mkdir(exist_ok=True)
identity=str(uuid.uuid4());title='You Only Look Once: Unified, Real-Time Object Detection'
paper={'id':identity,'noesis_schema':2,'type':'paper','title':title,'source_kind':'paper',
       'source':'https://arxiv.org/abs/1506.02640','bibliography_projection':'bib.md',
       'zotero_projection':'snapshot.md','zotero_key':'PAPER001','zotero_server_id':'fixture-library'}
(f.vault/'paper.md').write_text(render(paper,'\n## Why this paper?\n\nDisposable UI fixture, not learner work.\n\n## My reconstruction\n\nA learner-authored explanation will be preserved here during the real trial.\n\n## Questions and limitations\n\nSynthetic UI content does not establish an understanding of the paper.\n'))
def projection(path,kind,payload,**props):
 raw=json.dumps(payload,sort_keys=True)
 (f.vault/path).write_text(render(dict(id=str(uuid.uuid4()),noesis_schema=2,type=kind,resource_id=identity,source_sha256=checksum(raw),**props),'\n```json\n'+raw+'\n```\n'))
projection('bib.md','imported-bibliography',{'title':title,'URL':paper['source'],'author':[{'given':'Joseph','family':'Redmon'},{'given':'Santosh','family':'Divvala'},{'given':'Ross','family':'Girshick'},{'given':'Ali','family':'Farhadi'}],'issued':{'date-parts':[[2015,6,8]]}})
projection('snapshot.md','imported-zotero',{'server_id':'fixture-library','item':{'key':'PAPER001','version':4},'children':[{'key':'ATTACH01','data':{'itemType':'attachment','parentItem':'PAPER001'}}]+[{'key':f'ANNOT{i:03}','version':1,'data':{'itemType':'annotation','parentItem':'ATTACH01','annotationPageLabel':str(i%9+1),'annotationText':f'Synthetic annotation {i}: long imported source text to exercise wrapping and notebook scrolling.','annotationComment':'Synthetic source comment; independent learner questions remain separate.'}} for i in range(123)]},zotero_key='PAPER001',zotero_server_id='fixture-library',source_version=4)
from noesis.persistence import parse
old_props,old_body=parse((f.vault/'snapshot.md').read_text());old_payload=json.loads(old_body.split('```json\n',1)[1].split('\n```',1)[0]);old_payload['item']['version']=3
projection('snapshot-old.md','imported-zotero',old_payload,zotero_key='PAPER001',zotero_server_id='fixture-library',source_version=3)
shell=f.config/'shell.qml';s=shell.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:fixtureWindow}')
s=s.replace('ShellRoot {','ShellRoot {\n IpcHandler {target:"research-fixture";function revisions():void{fixtureWindow.focusSourceRevision();}function page(cursor:string):void{fixtureWindow.pageAnnotations(cursor);}function presentation(value:string):void{LearningUi.NoesisController.presentationMode=value;LearningUi.NoesisController.savePreferences();}function scales(ui:real,reading:real):void{LearningUi.NoesisStyle.interfaceScale=ui;LearningUi.NoesisStyle.readingScale=reading;LearningUi.NoesisController.savePreferences();}function scale(value:real):void{fixtureWindow.openSettings();LearningUi.NoesisStyle.interfaceScale=value;LearningUi.NoesisStyle.readingScale=value;LearningUi.NoesisController.savePreferences();}}')
shell.write_text(s)
try:
 f.start();f.ipc('noesis-window','section','Research');f.wait(lambda state:state['rows']>0);f.ipc('noesis-window','select','paper.md');f.wait(lambda state:state['annotation_count']==123)
 f.wait(lambda state:len(state['source_revisions'])==2);f.ipc('research-fixture','revisions');f.key('Down');f.key('Return');f.wait(lambda state:state['historical_snapshot'] and state['source_revision']==3)
 f.ipc('research-fixture','revisions');f.key('Up');f.key('Return');f.wait(lambda state:not state['historical_snapshot'] and state['source_revision']==4)
 ids=f.state()['annotation_ids']
 while f.state()['annotation_cursor']:
  before=ids[-1];f.ipc('research-fixture','page',f.state()['annotation_cursor']);f.wait(lambda state:state['annotation_ids'] and state['annotation_ids'][0]!=before and state['annotation_ids'][0] not in ids);ids.extend(f.state()['annotation_ids'])
 assert ids==[f'ANNOT{i:03}' for i in range(123)]
 f.ipc('research-fixture','page',f.state()['annotation_newer_cursor']);f.wait(lambda state:state['annotation_ids'][0]=='ANNOT050')
 f.ipc('research-fixture','page','');f.wait(lambda state:state['annotation_ids'][0]=='ANNOT000')
 for width,height in [(1920,1080),(1440,880),(1000,650),(500,650)]:
  for scale in [1,1.25,1.5,2]:
   f.ipc('research-fixture','scale',str(scale));time.sleep(.2);f.key('Escape');f.ipc('research-fixture','presentation','workspace' if width==1920 else 'normal');time.sleep(.5)
   if width!=1920:subprocess.run(['hyprctl','dispatch','hl.dsp.window.resize({x='+str(width)+',y='+str(height)+',relative=false,window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True)
   time.sleep(1)
   state=f.state();assert state['read_viewport_height']>100,state
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid);x,y=client['at'];w,h=client['size'];name=f'research-{width}-{scale}'
   subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(evidence/(name+'.png'))],check=True,timeout=10);(evidence/(name+'.json')).write_text(json.dumps(state,indent=2))
 for ui,reading in [(1,2),(2,1)]:
  f.ipc('research-fixture','scales',str(ui),str(reading));time.sleep(.7)
  state=f.state();assert state['interface_scale']==ui and state['reading_scale']==reading,state
  client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid);x,y=client['at'];w,h=client['size']
  subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(evidence/f'research-500-ui{ui}-reading{reading}.png')],check=True,timeout=10)
 f.ipc('research-fixture','scales','2','2');time.sleep(.5)
 f.key('Next','CTRL');time.sleep(.5)
 client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid);x,y=client['at'];w,h=client['size']
 subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(evidence/'research-500-2-scrolled.png')],check=True,timeout=10)
 warnings=[line for line in (f.home/'qml.log').read_text().splitlines() if ('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line];assert not warnings,warnings
 print('PASS: all 123 source annotations reachable; sixteen Research size/scale states and two independent scale combinations loaded. Inspect:',evidence)
finally:f.stop()
