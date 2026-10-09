#!/usr/bin/env python3
"""Populated isolated Zotero 10 acceptance. Never use an existing API instance.
Requires native Hyprland/Zotero and network access to the genuine paper PDF.
The test authorizes writes only to its own temporary profile; Noesis remains read-only.
"""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import hashlib,json,os,re,signal,socket,subprocess,sys,tempfile,time
from urllib.parse import urlencode
from urllib.request import Request,build_opener,ProxyHandler
repo=Path(__file__).resolve().parents[1]
def stop_reader(process):
 # The launcher is a shell; wait for its native process, not only the shell PID.
 members=[]
 for entry in Path('/proc').iterdir():
  if not entry.name.isdigit():continue
  try:
   fields=(entry/'stat').read_text().rsplit(')',1)[1].split()
   if int(fields[2])==process.pid and fields[0]!='Z':members.append(int(entry.name))
  except (OSError,ValueError,IndexError):pass
 try:os.killpg(process.pid,signal.SIGTERM)
 except ProcessLookupError:pass
 deadline=time.monotonic()+10
 while time.monotonic()<deadline:
  alive=[]
  for pid in members:
   try:
    fields=Path(f'/proc/{pid}/stat').read_text().rsplit(')',1)[1].split()
    if int(fields[2])==process.pid and fields[0]!='Z':alive.append(pid)
   except (OSError,ValueError,IndexError):pass
  if not alive:break
  time.sleep(.05)
 else:
  try:os.killpg(process.pid,signal.SIGKILL)
  except ProcessLookupError:pass
 process.wait(timeout=5)
sys.path.insert(0,str(repo/'home/.local/share/sensei-learning'))
from noesis.persistence import migration,parse,publish,render,checksum
from noesis.zotero import import_item
from noesis.index import Index
opener=build_opener(ProxyHandler({}))
with socket.socket() as sock:
 if sock.connect_ex(('127.0.0.1',23119))==0:raise SystemExit('Existing Zotero API detected; close it deliberately before running this isolated test.')
with tempfile.TemporaryDirectory(prefix='noesis-zotero-acceptance-') as folder:
 profile=Path(folder);data=profile/'data';data.mkdir()
 preferences={'extensions.zotero.useDataDir':True,'extensions.zotero.dataDir':str(data),'extensions.zotero.httpServer.enabled':True,'extensions.zotero.httpServer.localAPI.enabled':True,'extensions.zotero.firstRun.skipFirefoxProfileAccessCheck':True}
 (profile/'prefs.js').write_text('\n'.join('user_pref('+json.dumps(k)+', '+json.dumps(v)+');' for k,v in preferences.items()))
 with (profile/'zotero.log').open('w') as log:
  process=subprocess.Popen([str(Path.home()/'.local/bin/zotero'),'--new-instance','--profile',str(profile)],stdout=log,stderr=log,start_new_session=True)
  try:
   deadline=time.monotonic()+30
   for _ in range(300):
    if time.monotonic()>deadline:break
    try:
     with opener.open('http://127.0.0.1:23119/api/',timeout=1) as r:server=r.headers['Zotero-Server-ID']
     break
    except OSError:time.sleep(.1)
   if time.monotonic()>deadline:raise RuntimeError('Isolated Zotero API startup timed out')
   def authorize():
    req=Request('http://127.0.0.1:23119/api/local/authorize',data=json.dumps({'appName':'Noesis disposable release acceptance'}).encode(),headers={'Zotero-Server-ID':server,'Content-Type':'application/json'},method='POST')
    with opener.open(req,timeout=30) as r:return json.loads(r.read())
   with ThreadPoolExecutor(max_workers=1) as pool:
    pending=pool.submit(authorize)
    for _ in range(300):
     clients=json.loads(subprocess.check_output(['hyprctl','clients','-j']))
     own=[c for c in clients if c['title']=='Local API Authorization' and os.getpgid(c['pid'])==process.pid]
     if own:break
     time.sleep(.1)
    else:raise RuntimeError('Owned authorization dialog unavailable')
    for key in ('Tab','Return'):
     subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods="",key='+json.dumps(key)+',window='+json.dumps('address:'+own[0]['address'])+'})'],check=True,capture_output=True)
    authorization=pending.result();assert authorization['remember'],'Disposable test requires the persistent choice inside its temporary profile'
   def request(endpoint,body=None,method='GET',headers=None):
    h={'Zotero-Server-ID':server,'Zotero-API-Key':authorization['key']};h.update(headers or {})
    if isinstance(body,(dict,list)):body=json.dumps(body).encode();h['Content-Type']='application/json'
    with opener.open(Request('http://127.0.0.1:23119/api/'+endpoint,data=body,method=method,headers=h),timeout=10) as r:
     raw=r.read();return json.loads(raw) if raw else None
   def create(item):
    response=request('users/0/items',[item],'POST');assert not response['failed'],response
    return response['success']['0']
   paper=create({'itemType':'journalArticle','title':'Attention Is All You Need','DOI':'10.48550/arXiv.1706.03762','url':'https://arxiv.org/abs/1706.03762','date':'2017','creators':[{'creatorType':'author','firstName':'Ashish','lastName':'Vaswani'}]})
   attachment=create({'itemType':'attachment','parentItem':paper,'linkMode':'imported_file','title':'Attention paper PDF','contentType':'application/pdf','filename':'attention.pdf'})
   with opener.open('https://arxiv.org/pdf/1706.03762',timeout=30) as r:pdf=r.read(10*1024*1024)
   assert pdf.startswith(b'%PDF') and len(pdf)<10*1024*1024
   fields={'md5':hashlib.md5(pdf).hexdigest(),'filename':'attention.pdf','filesize':len(pdf),'mtime':1770000000000}
   upload=request('users/0/items/'+attachment+'/file',urlencode(fields).encode(),'POST',{'If-None-Match':'*','Content-Type':'application/x-www-form-urlencoded'})
   if not upload.get('exists'):
    assert upload['url'].startswith(('http://127.0.0.1:23119/','http://localhost:23119/'))
    body=upload.get('prefix','').encode()+pdf+upload.get('suffix','').encode()
    with opener.open(Request(upload['url'],data=body,headers={'Content-Type':upload['contentType']},method='POST'),timeout=10) as r:assert r.status in (200,201,204)
    request('users/0/items/'+attachment+'/file',urlencode({'upload':upload['uploadKey']}).encode(),'POST',{'If-None-Match':'*','Content-Type':'application/x-www-form-urlencoded'})
   annotation=create({'itemType':'annotation','parentItem':attachment,'annotationType':'highlight','annotationText':'Scaled dot-product attention','annotationComment':'Why divide by the square root of the key dimension?','annotationColor':'#ffd400','annotationPageLabel':'3','annotationSortIndex':'00002|000100|00000','annotationPosition':json.dumps({'pageIndex':2,'rects':[[50,400,400,420]]})})
   vault=profile/'vault';(vault/'System').mkdir(parents=True);(vault/'System/System.json').write_text(json.dumps({'types':{},'directories':[]}));migration(vault,True)
   first=import_item(vault,paper);path=vault/(first['created']+first['existing'])[0];props,body=parse(path.read_text());analysis='\n## Independent analysis\n\nThe scaling factor remains an unresolved question.\n';publish(path,render(props,body+analysis),checksum(path.read_text()))
   assert annotation in (vault/first['projection']).read_text()
   for key,field,value in ((paper,'title','Attention Is All You Need — reviewed metadata'),(annotation,'annotationComment','Independently derive the variance scaling.')):
    item=request('users/0/items/'+key);changed=dict(item['data']);changed[field]=value
    request('users/0/items/'+key,changed,'PUT',{'If-Unmodified-Since-Version':str(item['version'])})
   second=import_item(vault,paper)
   # A genuine source annotation now leads to an authored, executed equation check.
   from noesis_attention_fixture import run as verify_attention
   paper_bytes=path.read_bytes()
   native_annotation=request('users/0/items/'+annotation)
   checked=verify_attention(vault,first['resource_id'],{'native_id':annotation,'attachment_key':attachment,'version':native_annotation['version'],'projection':second['projection'],'page_label':'3','pdf_sha256':hashlib.sha256(pdf).hexdigest()},profile)
   assert path.read_bytes()==paper_bytes
   moved=vault/'Moved paper.md';path.rename(moved);path=moved
   index=Index(vault)
   try:
    index.reconcile()
    assert index.relations(checked['question']['id'])[0]['other_id']==first['resource_id']
   finally:index.close()
   print('PASS: actual Zotero annotation → mathematical question/reconstruction → committed authored implementation → executed Eq. 1 checks; moved paper relationships survive. This is not full Transformer reproduction or independent learner evidence.')
   item=request('users/0/items/'+annotation);request('users/0/items/'+annotation,None,'DELETE',{'If-Unmodified-Since-Version':str(item['version'])})
   third=import_item(vault,paper)
   assert len({r['projection'] for r in (first,second,third)})==3
   assert len({r['resource_id'] for r in (first,second,third)})==1
   assert annotation not in (vault/third['projection']).read_text()
   assert parse(path.read_text())[1].endswith(analysis)
   index=Index(vault);index.reconcile();assert index.record(first['resource_id'])['props']['zotero_attachment_key']==attachment;index.close()
   print('PASS: genuine PDF, native annotation edits/deletion, three retained projections, stable resource UUID and preserved learner prose; production imports use GET only.')
   recovered_annotation=create({'itemType':'annotation','parentItem':attachment,'annotationType':'highlight','annotationText':'Restoration acceptance','annotationComment':'Recover the original question at page three.','annotationColor':'#ffd400','annotationPageLabel':'3','annotationSortIndex':'00002|000100|00000','annotationPosition':json.dumps({'pageIndex':2,'rects':[[50,400,400,420]]})})
   # Close only the isolated reader before the fresh consistent snapshot.
   stop_reader(process)
   import importlib.machinery,importlib.util
   from unittest.mock import patch
   from noesis.recovery import backup,restore
   loader=importlib.machinery.SourceFileLoader('reader_backup',str(repo/'home/.local/bin/sensei-learning-backup'))
   spec=importlib.util.spec_from_loader(loader.name,loader);reader_backup=importlib.util.module_from_spec(spec);loader.exec_module(reader_backup)
   with patch.object(reader_backup,'STATE',profile/'snapshots'):
    snapshot=reader_backup.backup_readers([data])[0]
   assert snapshot['database_sources']['zotero.sqlite']['mode']=='sqlite-online-backup'
   preserved=backup(vault,profile/'restic',[snapshot['snapshot']])
   result=restore(preserved['snapshot_id'],profile/'restored-vault',profile/'restic')
   restored_data=profile/'restored-data'
   reader_backup.restore_reader(Path(result['reader_states'][0]['path']),restored_data)
   preferences['extensions.zotero.dataDir']=str(restored_data)
   # The snapshot belongs to this fixture; never overwrite a live real reader.
   saved_prefs=(profile/'prefs.js').read_text()
   restored_pref='user_pref("extensions.zotero.dataDir", '+json.dumps(str(restored_data))+');'
   saved_prefs=re.sub(r'user_pref\("extensions\.zotero\.dataDir",.*?\);',lambda match:restored_pref,saved_prefs)
   (profile/'prefs.js').write_text(saved_prefs)
   process=subprocess.Popen([str(Path.home()/'.local/bin/zotero'),'--new-instance','--profile',str(profile)],stdout=log,stderr=log,start_new_session=True)
   deadline=time.monotonic()+30
   for _ in range(300):
    if time.monotonic()>deadline:break
    try:
     with opener.open('http://127.0.0.1:23119/api/',timeout=1) as r:server=r.headers['Zotero-Server-ID']
     break
    except OSError:time.sleep(.1)
   if time.monotonic()>deadline:raise RuntimeError('Restored reader startup timed out')
   native=request('users/0/items/'+recovered_annotation)['data']
   assert native['annotationPageLabel']=='3' and native['annotationComment']=='Recover the original question at page three.'
   native_pdf=request('users/0/items/'+attachment)['links']['enclosure']['href']
   from urllib.parse import urlsplit,unquote
   restored_pdf=Path(unquote(urlsplit(native_pdf).path));assert restored_pdf.is_relative_to(restored_data) and restored_pdf.read_bytes()==pdf
   print('PASS: encrypted Restic snapshot restored into a new reader directory; native Zotero restart recovered the annotation, page label, question and original PDF.')
   print('Reader page/annotation navigation is a separate native acceptance gate.')
  finally:
   diagnostic=Path('/tmp/noesis-zotero-last.log');diagnostic.write_text((profile/'zotero.log').read_text());diagnostic.chmod(0o600)
   stop_reader(process)
