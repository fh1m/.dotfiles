"""An isolated native Zotero source library for the empty-vault UI acceptance.

Only Zotero source fixtures are prepared here. No Noesis records are constructed.
"""
import json,os,socket,subprocess,time,signal
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from urllib.request import Request,build_opener,ProxyHandler
class SourceLibrary:
 def __init__(self,home,port=23119,native_probe=False):
  self.base="http://127.0.0.1:"+str(port)+"/api/"
  with socket.socket() as check:
   if check.connect_ex(('127.0.0.1',port))==0:raise RuntimeError('Existing Zotero API is active; isolated source acceptance cannot own this port. No existing reader was stopped.')
  self.profile=home/'zotero-profile';self.profile.mkdir();data=self.profile/'data';data.mkdir()
  prefs={'extensions.zotero.useDataDir':True,'extensions.zotero.dataDir':str(data),'extensions.zotero.httpServer.enabled':True,'extensions.zotero.httpServer.port':port,'extensions.zotero.httpServer.localAPI.enabled':True,'extensions.zotero.firstRun.skipFirefoxProfileAccessCheck':True}
  (self.profile/'prefs.js').write_text('\n'.join('user_pref('+json.dumps(k)+', '+json.dumps(v)+');' for k,v in prefs.items()))
  command=[str(Path.home()/'.local/bin/zotero'),'--new-instance','--profile',str(self.profile)]
  self.probe_token=None
  if native_probe:
   import shutil,zipfile,uuid
   self.probe_token=uuid.uuid4().hex
   app=home/'zotero-native-app';shutil.copytree(Path.home()/'.local/opt/zotero-10.0.6/app',app)
   original=app/'omni.ja';replacement=app/'probe.omni.ja'
   extension="\nZotero.Server.Endpoints['/api/noesis-native'] = class extends LocalAPIEndpoint { supportedMethods=['GET']; async run(request) { if(request.searchParams.get('token') !== "+json.dumps(self.probe_token)+") return [403,'text/plain','Denied']; const uri=request.searchParams.get('uri'); if(uri) {if(!/^zotero:\\/\\/open-pdf\\/library\\/items\\/[A-Z0-9]{8}\\?/.test(uri))return [400,'text/plain','Invalid URI']; const {ZoteroProtocolHandler}=ChromeUtils.importESModule('chrome://zotero/content/ZoteroProtocolHandler.mjs'); const handler=new ZoteroProtocolHandler(); await handler.getExtension(uri).doAction(Services.io.newURI(uri)); const wanted=Number(new URL(uri).searchParams.get('page'))-1; for(let i=0;i<100;i++){const reader=Zotero.Reader._readers.at(-1);if(reader?._internalReader?._state?.primaryViewStats?.pageIndex===wanted)break;await Zotero.Promise.delay(100);}} return [200,'application/json',JSON.stringify({readers:Zotero.Reader._readers.map(r=>({itemID:r.itemID,state:r._internalReader?._state,viewState:r._internalReader?._primaryView?._state}))})]; }};\n"
   with zipfile.ZipFile(original) as src,zipfile.ZipFile(replacement,'w') as dst:
    for info in src.infolist():
     raw=src.read(info.filename)
     if info.filename=='chrome/content/zotero/xpcom/server/server_localAPI.js':raw+=extension.encode()
     dst.writestr(info,raw)
   replacement.replace(original)
   command=[str(Path.home()/'.local/opt/zotero-10.0.6/zotero-bin'),'-app',str(app/'application.ini'),'--new-instance','--profile',str(self.profile)]
  self.log=(home/'zotero-source.log').open('w');self.process=subprocess.Popen(command,stdout=self.log,stderr=self.log,start_new_session=True)
  self.opener=build_opener(ProxyHandler({}))
  try:
   deadline=time.monotonic()+30
   while time.monotonic()<deadline:
    try:
     with self.opener.open(self.base,timeout=1) as response:self.server=response.headers['Zotero-Server-ID']
     break
    except OSError:time.sleep(.1)
   else:raise RuntimeError('Isolated native Zotero source startup failed within bounded 30-second check')
   def authorize():
    req=Request(self.base+'local/authorize',data=json.dumps({'appName':'Noesis disposable source fixture'}).encode(),headers={'Zotero-Server-ID':self.server,'Content-Type':'application/json'},method='POST')
    with self.opener.open(req,timeout=30) as response:return json.loads(response.read())
   with ThreadPoolExecutor(max_workers=1) as pool:
    pending=pool.submit(authorize);deadline=time.monotonic()+20
    while time.monotonic()<deadline:
     clients=json.loads(subprocess.check_output(['hyprctl','clients','-j']));owned=[c for c in clients if c['title']=='Local API Authorization' and os.getpgid(c['pid'])==self.process.pid]
     if owned:break
     time.sleep(.1)
    else:raise RuntimeError('Isolated source authorization dialog unavailable')
    for key in ('Tab','Return'):subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods="",key='+json.dumps(key)+',window='+json.dumps('address:'+owned[0]['address'])+'})'],check=True,capture_output=True)
    auth=pending.result()
   req=Request(self.base+'users/0/items',data=json.dumps([{'itemType':'journalArticle','title':'Attention Is All You Need - agent source fixture','url':'https://arxiv.org/abs/1706.03762','DOI':'10.48550/arXiv.1706.03762','date':'2017','creators':[{'creatorType':'author','firstName':'Ashish','lastName':'Vaswani'}]}]).encode(),headers={'Zotero-Server-ID':self.server,'Zotero-API-Key':auth['key'],'Content-Type':'application/json'},method='POST')
   with self.opener.open(req,timeout=10) as response:result=json.loads(response.read())
   assert not result['failed'],result
   self.key=result['success']['0'];self.authorization=auth['key']
  except Exception:self.stop();raise
 def stop(self):
  if self.process.poll() is None:
   try:os.killpg(self.process.pid,signal.SIGTERM)
   except ProcessLookupError:pass
   self.process.wait(timeout=10)
  self.log.close()

 def request(self,endpoint,body=None,method='GET',headers=None):
  headers=dict(headers or {},**{'Zotero-Server-ID':self.server,'Zotero-API-Key':self.authorization})
  if isinstance(body,(dict,list)):body=json.dumps(body).encode();headers['Content-Type']='application/json'
  with self.opener.open(Request(self.base+endpoint,data=body,method=method,headers=headers),timeout=15) as response:
   raw=response.read();return json.loads(raw) if raw else None
 def add_annotated_pdf(self):
  import hashlib
  from urllib.parse import urlencode
  def create(value):
   result=self.request('users/0/items',[value],'POST');assert not result['failed'],result;return result['success']['0']
  attachment=create({'itemType':'attachment','parentItem':self.key,'linkMode':'imported_file','title':'Attention PDF · isolated fixture','contentType':'application/pdf','filename':'attention.pdf'})
  with self.opener.open('https://arxiv.org/pdf/1706.03762',timeout=30) as response:pdf=response.read(10*1024*1024)
  assert pdf.startswith(b'%PDF') and len(pdf)<10*1024*1024
  fields={'md5':hashlib.md5(pdf).hexdigest(),'filename':'attention.pdf','filesize':len(pdf),'mtime':1770000000000}
  upload=self.request('users/0/items/'+attachment+'/file',urlencode(fields).encode(),'POST',{'If-None-Match':'*','Content-Type':'application/x-www-form-urlencoded'})
  if not upload.get('exists'):
   assert upload['url'].startswith(('http://127.0.0.1:','http://localhost:'))
   body=upload.get('prefix','').encode()+pdf+upload.get('suffix','').encode()
   with self.opener.open(Request(upload['url'],data=body,method='POST',headers={'Content-Type':upload['contentType']}),timeout=15) as response:assert response.status in (200,201,204)
   self.request('users/0/items/'+attachment+'/file',urlencode({'upload':upload['uploadKey']}).encode(),'POST',{'If-None-Match':'*','Content-Type':'application/x-www-form-urlencoded'})
  annotation=create({'itemType':'annotation','parentItem':attachment,'annotationType':'highlight','annotationText':'Scaled dot-product attention','annotationComment':'Agent validation question: why the square-root scaling?','annotationColor':'#ffd400','annotationPageLabel':'iii','annotationSortIndex':'00002|000100|00000','annotationPosition':json.dumps({'pageIndex':2,'rects':[[50,400,400,420]]})})
  return {'attachment':attachment,'annotation':annotation,'physical_page':3,'page_label':'iii'}
