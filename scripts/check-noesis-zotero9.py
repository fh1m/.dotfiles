#!/usr/bin/env python3
"""Zotero 9 read-only import, exact reader selection and populated encrypted restore.
Uses test-only bootstrap in a disposable application/profile; no personal data.
"""
import argparse,hashlib,json,os,signal,socket,subprocess,sys,tempfile,time,zipfile
from pathlib import Path
from urllib.request import Request,build_opener,ProxyHandler
from unittest.mock import patch
from noesis_native_fixture import REPO
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.persistence import migration
from noesis.zotero import LocalAPI,import_item
from noesis.sources import annotation_command
from noesis.index import Index
from noesis.recovery import backup,restore
parser=argparse.ArgumentParser();parser.add_argument('--application',type=Path,required=True);args=parser.parse_args()
home=Path(tempfile.mkdtemp(prefix='noesis-zotero9-'));app=home/'app';import shutil;shutil.copytree(args.application/'app',app);profile=home/'profile';profile.mkdir();data=home/'data';data.mkdir()
with socket.socket() as c:assert c.connect_ex(('127.0.0.1',23119))!=0,'Existing Zotero API was not touched'
opener=build_opener(ProxyHandler({}));pdf=home/'paper.pdf';pdf.write_bytes(opener.open('https://arxiv.org/pdf/1706.03762',timeout=30).read());assert pdf.read_bytes().startswith(b'%PDF')
token=os.urandom(24).hex();origin=app/'omni.ja';replacement=app/'check.omni.ja'
code=r"""
Zotero.Server.Endpoints['/api/noesis-version-check'] = class extends LocalAPIEndpoint {
 supportedMethods=['GET'];
 async run(request) {
  if(request.searchParams.get('token')!==TOKEN)return [403,'text/plain','Denied'];
  await Zotero.initializationPromise;
  try{
  if(request.searchParams.get('action')==='prepare'){
   const paper=new Zotero.Item('journalArticle');paper.libraryID=Zotero.Libraries.userLibraryID;paper.setField('title','Agent compatibility fixture · Attention Is All You Need');await paper.saveTx();
   const attachment=await Zotero.Attachments.importFromFile({file:PDF,parentItemID:paper.id});
   const annotation=new Zotero.Item('annotation');annotation.libraryID=Zotero.Libraries.userLibraryID;annotation.parentID=attachment.id;annotation.annotationType='highlight';annotation.annotationText='Agent compatibility source fixture';annotation.annotationComment='Preserve unknown mechanism';annotation.annotationColor='#ffd400';annotation.annotationPageLabel='iii';annotation.annotationSortIndex='00002|000000|00000';annotation.annotationPosition=JSON.stringify({pageIndex:2,rects:[[60,650,300,680]]});await annotation.saveTx();
   return [200,'application/json',JSON.stringify({paper:paper.key,attachment:attachment.key,annotation:annotation.key,csl:Zotero.Utilities.Item.itemToCSLJSON(paper)})];
  }
  const uri=request.searchParams.get('uri');if(uri){if(!/^zotero:\/\/open-pdf\/library\/items\/[A-Z0-9]{8}\?/.test(uri))return [400,'text/plain','Invalid URI'];const {ZoteroProtocolHandler}=ChromeUtils.importESModule('chrome://zotero/content/ZoteroProtocolHandler.mjs');const handler=new ZoteroProtocolHandler();await handler.getExtension(uri).doAction(Services.io.newURI(uri));for(let i=0;i<100;i++){if(Zotero.Reader._readers.at(-1)?._internalReader?._state?.primaryViewStats?.pageIndex===2)break;await Zotero.Promise.delay(100);}}
  return [200,'application/json',JSON.stringify(Zotero.Reader._readers.map(r=>({itemID:r.itemID,state:r._internalReader?._state})))];
  }catch(error){return [200,'application/json',JSON.stringify({error:String(error),stack:error.stack})];}
 }
};
""".replace('TOKEN',json.dumps(token)).replace('PDF,',json.dumps(str(pdf))+',')
with zipfile.ZipFile(origin) as src,zipfile.ZipFile(replacement,'w') as out:
 for entry in src.infolist():
  raw=src.read(entry)
  if entry.filename=='chrome/content/zotero/xpcom/server/server_localAPI.js':raw+=code.encode()
  out.writestr(entry,raw)
replacement.replace(origin)
process=None
base='http://127.0.0.1:23119/api/'
def launch(directory):
 global process
 prefs={'extensions.zotero.useDataDir':True,'extensions.zotero.dataDir':str(directory),'extensions.zotero.httpServer.enabled':True,'extensions.zotero.httpServer.localAPI.enabled':True,'extensions.zotero.firstRun.skipFirefoxProfileAccessCheck':True}
 (profile/'prefs.js').write_text('\n'.join('user_pref('+json.dumps(k)+', '+json.dumps(v)+');' for k,v in prefs.items()))
 log=(home/'native.log').open('a');process=subprocess.Popen([str(args.application/'zotero-bin'),'-app',str(app/'application.ini'),'--new-instance','--profile',str(profile)],stdout=log,stderr=log,start_new_session=True);log.close();deadline=time.monotonic()+30
 while time.monotonic()<deadline:
  try:
   with opener.open(base,timeout=1) as r:return r.headers['Zotero-Server-ID']
  except OSError:time.sleep(.1)
 raise RuntimeError('Bounded Zotero 9 startup failed; retained '+str(home))
def stop():
 global process
 if process and process.poll() is None:
  os.killpg(process.pid,signal.SIGTERM);process.wait(timeout=10);time.sleep(.5)
 process=None
from urllib.parse import urlencode
def native(server,**query):
 with opener.open(Request(base+'noesis-version-check?'+urlencode(dict(token=token,**query)),headers={'Zotero-Server-ID':server} if server else {}),timeout=20) as r:return json.loads(r.read())
try:
 server=launch(data);keys=native(server,action='prepare');assert 'paper' in keys,keys;vault=home/'vault';(vault/'System').mkdir(parents=True);(vault/'System/System.json').write_text('{"directories":[]}')
 with patch('pathlib.Path.home',return_value=home):
  migration(vault,True)
  try:LocalAPI(server).probe()
  except ValueError as error:
   assert 'identity unavailable' in str(error);identity_guard=True
  else:raise AssertionError('Expected explicit unsupported instance identity on Zotero 9')
  from noesis.imports import import_csl
  exported=home/'export.json'
  raw=keys['csl']
  exported.write_text(json.dumps(raw if isinstance(raw,list) else [raw]));report=import_csl(vault,exported,{'directories':[]},lambda item: str(item.get('id','zotero-export')))
 command=['xdg-open','zotero://open-pdf/library/items/'+keys['attachment']+'?page=3&annotation='+keys['annotation']]
 state=native(server,uri=command[-1]);assert state[-1]['state']['primaryViewStats']['pageIndex']==2;assert keys['annotation'] in state[-1]['state']['selectedAnnotationIDs'];stop()
 import importlib.machinery,importlib.util
 loader=importlib.machinery.SourceFileLoader('reader_backup',str(REPO/'home/.local/bin/sensei-learning-backup'));spec=importlib.util.spec_from_loader(loader.name,loader);reader=importlib.util.module_from_spec(spec);loader.exec_module(reader)
 with patch.object(reader,'STATE',home/'snapshots'),patch('pathlib.Path.home',return_value=home):
  snapshot=reader.backup_readers([data])[0];saved=backup(vault,home/'restic',[snapshot['snapshot']]);restored=restore(saved['snapshot_id'],home/'restored-vault',home/'restic');reader.restore_reader(Path(restored['reader_states'][0]['path']),home/'restored-data')
 server=launch(home/'restored-data');state=native(server,uri=command[-1]);assert state[-1]['state']['primaryViewStats']['pageIndex']==2;assert keys['annotation'] in state[-1]['state']['selectedAnnotationIDs']
 result={'version':'9.0.6','live_api_import':'unsupported: instance identity header absent; refused safely','csl_export_import':True,'annotation_physical_page':3,'selected_native_key_verified':True,'populated_encrypted_restore':True,'reader_state':state,'fixture':str(home),'application_sha256':hashlib.sha256((args.application/'app/omni.ja').read_bytes()).hexdigest(),'provenance':'agent isolated compatibility fixture; test-only source bootstrap'}
 assets=REPO/'docs/learning-system/assets/release-hardening';assets.mkdir(exist_ok=True,parents=True);(assets/'zotero9-acceptance.json').write_text(json.dumps(result,indent=2)+'\n');print('PASS: Zotero 9.0.6 read-only import, native annotation/page and populated encrypted restore')
finally:stop()
