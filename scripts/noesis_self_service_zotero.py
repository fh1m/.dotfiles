"""An isolated native Zotero source library for the empty-vault UI acceptance.

Only Zotero source fixtures are prepared here. No Noesis records are constructed.
"""
import json,os,socket,subprocess,time,signal
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from urllib.request import Request,build_opener,ProxyHandler
class SourceLibrary:
 def __init__(self,home,port=23119):
  self.base="http://127.0.0.1:"+str(port)+"/api/"
  with socket.socket() as check:
   if check.connect_ex(('127.0.0.1',port))==0:raise RuntimeError('Existing Zotero API is active; isolated source acceptance cannot own this port. No existing reader was stopped.')
  self.profile=home/'zotero-profile';self.profile.mkdir();data=self.profile/'data';data.mkdir()
  prefs={'extensions.zotero.useDataDir':True,'extensions.zotero.dataDir':str(data),'extensions.zotero.httpServer.enabled':True,'extensions.zotero.httpServer.port':port,'extensions.zotero.httpServer.localAPI.enabled':True,'extensions.zotero.firstRun.skipFirefoxProfileAccessCheck':True}
  (self.profile/'prefs.js').write_text('\n'.join('user_pref('+json.dumps(k)+', '+json.dumps(v)+');' for k,v in prefs.items()))
  self.log=(home/'zotero-source.log').open('w');self.process=subprocess.Popen([str(Path.home()/'.local/bin/zotero'),'--new-instance','--profile',str(self.profile)],stdout=self.log,stderr=self.log,start_new_session=True)
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
  except Exception:self.stop();raise
 def stop(self):
  if self.process.poll() is None:
   try:os.killpg(self.process.pid,signal.SIGTERM)
   except ProcessLookupError:pass
   self.process.wait(timeout=10)
  self.log.close()
