"""Bounded Notion adapter; cache/outbox are private, learning evidence is separate."""
import datetime,json,os,time,uuid,urllib.request,urllib.error
from pathlib import Path
from .persistence import publish,lock
COLLECTIONS=('Goals/Paths','Terms','Course Enrollments','Tasks','Schedule')
VERSION='2026-03-11'
def rich(text):return [{'type':'text','text':{'content':str(text)[:2000]}}]
class Planner:
 def __init__(self,home=None):
  self.home=Path(home or Path.home());self.root=self.home/'.local/state/noesis-planning';self.root.mkdir(parents=True,exist_ok=True,mode=0o700);self.root.chmod(0o700)
  self.config=self.home/'.config/noesis/notion.json'
 def read(self,path,default=None):
  return json.loads(path.read_text()) if path.exists() else (default if default is not None else {})
 def save(self,path,value):
  text=json.dumps(value,ensure_ascii=False,indent=2)+'\n';publish(path,text,expected=__import__('hashlib').sha256(path.read_bytes()).hexdigest() if path.exists() else None);path.chmod(0o600)
 def status(self):
  workspace=self.read(self.root/'workspace.json');config=self.read(self.config,workspace);cache=self.read(self.root/'cache.json')
  return {'connection':'connected' if config.get('token') else 'workspace_ready' if config.get('root_id') else 'needs_connection','root_url':config.get('root_url','https://www.notion.so'),'collections':list(config.get('collections',{})),'pending':len(self.pending()),'pending_records':self.pending(),'last_sync':cache.get('updated_at'),'cache_source':cache.get('source','notion-api'),'records':cache.get('records',[]),'message':('Workspace verified through the Notion connector; unattended desktop sync needs its scoped connection' if config.get('root_id') else 'Sign in to Notion and connect a private Noesis root') if not config.get('token') else 'Notion owns plans; Noesis owns learning evidence'}
 def connect(self,token,parent):
  uuid.UUID(parent);token=token.strip()
  if not token or any(c.isspace() for c in token):raise ValueError('Use a scoped Notion connection token')
  # Validate remotely before storing credentials; never print the token.
  self._token=token;self.api('GET','users/me');self.save(self.config,dict(self.read(self.root/'workspace.json'),version=1,token=token,parent_id=parent));del self._token
  return {'connection':'connected','setup_required':True}
 def api(self,method,path,body=None):
  token=getattr(self,'_token',None) or self.read(self.config).get('token')
  if not token:raise ValueError('Notion connection is not configured; local plans are preserved')
  if path.startswith('/') or '://' in path:raise ValueError('Invalid Notion API path')
  data=json.dumps(body).encode() if body is not None else None
  for attempt in range(4):
   req=urllib.request.Request('https://api.notion.com/v1/'+path,data=data,method=method,headers={'Authorization':'Bearer '+token,'Notion-Version':VERSION,'Content-Type':'application/json'})
   try:
    with urllib.request.urlopen(req,timeout=15) as response:
     raw=response.read(8*1024*1024+1)
     if len(raw)>8*1024*1024:raise ValueError('Notion response exceeds local limit')
     return json.loads(raw)
   except urllib.error.HTTPError as e:
    if e.code==429 and attempt<3:
     delay=e.headers.get('Retry-After','1')
     try:delay=float(delay)
     except ValueError:delay=1
     if delay>30:raise ValueError('Notion rate limited; queued work retained until a later sync') from None
     time.sleep(max(.5,delay));continue
    if e.code in (401,403):raise ValueError('Notion needs renewed authorization or access to this root; queued work retained') from None
    raise ValueError('Notion HTTP '+str(e.code)+'; inspect connection status before retrying') from None
   except (urllib.error.URLError,TimeoutError) as e:raise ValueError('Notion unavailable; offline work retained') from None
 def query(self,source,filters=None):
  rows=[];cursor=None
  for _ in range(100):
   body={'page_size':100}
   if cursor:body['start_cursor']=cursor
   if filters:body['filter']=filters
   data=self.api('POST','data_sources/'+source+'/query',body);rows.extend(data.get('results',[]))
   cursor=data.get('next_cursor')
   if not data.get('has_more'):return rows
  raise ValueError('Notion pagination limit reached; previous complete cache retained')
 def setup(self):
  with lock(self.root):
   config=self.read(self.config);config.setdefault('collections',{})
   if not config.get('token'):raise ValueError('Connect Notion first')
   if not config.get('root_id'):
    # Discovery protects retry after an uncertain create response.
    children=self.api('GET','blocks/'+config['parent_id']+'/children?page_size=100').get('results',[])
    existing=next((r for r in children if r.get('child_page',{}).get('title')=='Noesis'),None)
    row=existing or self.api('POST','pages',{'parent':{'page_id':config['parent_id']},'properties':{'title':{'title':rich('Noesis')}}})
    config.update(root_id=row['id'],root_url=row.get('url','https://www.notion.so/'+row['id'].replace('-','')));self.save(self.config,config)
   children=self.api('GET','blocks/'+config['root_id']+'/children?page_size=100').get('results',[])
   for name in COLLECTIONS:
    if name in config['collections']:continue
    existing=next((r for r in children if r.get('child_database',{}).get('title')==name),None)
    props={'Title':{'title':{}},'Noesis ID':{'rich_text':{}},'Area':{'select':{'options':[{'name':'Academic'},{'name':'Explore'}]}},'State':{'select':{'options':[{'name':n} for n in ('Planned','Active','Done','Parked','Abandoned')]}},'When':{'date':{}},'Noesis link':{'url':{}}}
    row=self.api('GET','databases/'+existing['id']) if existing else self.api('POST','databases',{'parent':{'type':'page_id','page_id':config['root_id']},'title':rich(name),'initial_data_source':{'properties':props}})
    sources=row.get('data_sources',[])
    if len(sources)!=1:raise ValueError('Choose the single managed data source for '+name)
    config['collections'][name]={'database_id':row['id'],'source_id':sources[0]['id']};self.save(self.config,config)
   return self.status()
 def pending(self):return [self.read(p) for p in sorted((self.root/'outbox').glob('*.json')) if not self.read(p).get('acknowledged')]
 def enqueue(self,collection,title,fields,operation,remote_id=None,base_revision=None):
  uuid.UUID(operation)
  if collection not in COLLECTIONS or not title.strip():raise ValueError('Choose a planning collection and title')
  if set(fields)-{'Area','State','When','Noesis link'}:raise ValueError('Only owned planning properties can be updated')
  if fields.get('Area') not in (None,'Academic','Explore'):raise ValueError('Area must be Academic or Explore')
  if fields.get('State') not in (None,'Planned','Active','Done','Parked','Abandoned'):raise ValueError('Choose a supported planning state')
  if fields.get('When') is not None:
   date=fields['When']
   if not isinstance(date,dict) or not isinstance(date.get('start'),str):raise ValueError('When requires a start date')
   datetime.datetime.fromisoformat(date['start'].replace('Z','+00:00'))
  row={'version':1,'id':operation,'collection':collection,'title':title,'fields':fields,'remote_id':remote_id,'base_revision':base_revision,'competence_awarded':False}
  with lock(self.root):
   path=self.root/'outbox'/(operation+'.json')
   if path.exists():
    old=self.read(path)
    if any(old.get(k)!=v for k,v in row.items()):raise ValueError('Planning operation ID reused with changed input')
    return old
   self.save(path,row)
  return row
 def properties(self,row):
  props={'Title':{'title':rich(row['title'])}}
  if not row.get('remote_id'):props['Noesis ID']={'rich_text':rich(row['id'])}
  for key,value in row['fields'].items():props[key]={'select':None if value is None else {'name':value}} if key in ('Area','State') else {'date':value} if key=='When' else {'url':value}
  return props
 def sync(self):
  with lock(self.root):
   config=self.read(self.config);conflicts=sent=0
   for row in self.pending():
    target=row.get('remote_id')
    if target:
     remote=self.api('GET','pages/'+target)
     if not row.get('base_revision') or remote.get('last_edited_time')!=row['base_revision']:
      row['conflict']='Remote revision differs; explicit resolution required';self.save(self.root/'outbox'/(row['id']+'.json'),row);conflicts+=1;continue
     result=self.api('PATCH','pages/'+target,{'properties':self.properties(row)})
    else:
     source=config.get('collections',{}).get(row['collection'],{}).get('source_id')
     if not source:raise ValueError('Set up Notion collections; offline work retained')
     matches=self.query(source,{'property':'Noesis ID','rich_text':{'equals':row['id']}})
     if len(matches)>1:raise ValueError('Duplicate remote operation identity; resolve before sync')
     result=matches[0] if matches else self.api('POST','pages',{'parent':{'type':'data_source_id','data_source_id':source},'properties':self.properties(row)})
    row.update(acknowledged=True,remote_id=result['id']);self.save(self.root/'outbox'/(row['id']+'.json'),row);sent+=1
   all_rows=[]
   for name,source in config.get('collections',{}).items():
    all_rows.extend(dict(row,collection=name) for row in self.query(source['source_id']))
   cache={'updated_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'records':all_rows};self.save(self.root/'cache.json',cache)
   return {'sent':sent,'conflicts':conflicts,'records':len(all_rows)}
