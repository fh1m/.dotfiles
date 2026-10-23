"""Loopback go-librespot adapter. No developer Web API, no browser credentials."""
import json,os,re,time,urllib.request,urllib.parse,urllib.error,http.client
from pathlib import Path
BASE='http://127.0.0.1:3678'
STORE=Path.home()/'.cache/sensei-spotify/headless'
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None
HTTP=urllib.request.build_opener(urllib.request.ProxyHandler({}),NoRedirect)
def request(path,body=None,_recover=True):
 if not path.startswith('/') or path.startswith('//'):raise ValueError('Invalid local music endpoint')
 read=body is None and path.startswith(('/library/','/context/'))
 if read:
  try:until=json.loads((STORE/'backoff.json').read_text()).get('until',0)
  except (OSError,ValueError):until=0
  if until>time.time():raise ValueError('Spotify library is cooling down for '+str(int(until-time.time())+1)+' seconds.')
 req=urllib.request.Request(BASE+path,data=json.dumps(body).encode() if body is not None else None,headers={'Content-Type':'application/json'})
 try:
  with HTTP.open(req,timeout=4 if path=='/status' else 12) as r:
   if r.status==204:
    if path=='/auth/code':return {}
    raise ValueError('Music is reconnecting; saved login and playback are preserved.')
   raw=r.read(8*1024*1024+1)
   if len(raw)>8*1024*1024:raise ValueError('Music response exceeded the local limit')
   return json.loads(raw) if raw else {}
 except urllib.error.HTTPError as ex:
  if ex.code==204:
   if path=='/auth/code':return {}
   raise ValueError('Music is reconnecting; saved login and playback are preserved.')
  if path=='/status' and body is None and ex.code>=500 and _recover and recover_service():return recovered_status()
  if ex.code==429:
   try:delay=max(1,int(ex.headers.get('Retry-After','60')))
   except (ValueError,TypeError):delay=60
   STORE.mkdir(parents=True,exist_ok=True,mode=0o700)
   temp=STORE/('backoff.'+str(os.getpid())+'.tmp')
   with temp.open('w') as file:os.chmod(temp,0o600);json.dump({'until':time.time()+delay},file)
   temp.replace(STORE/'backoff.json')
   raise ValueError('Spotify requested a '+str(delay)+'-second pause; saved library data is still available.')
  raise ValueError('Music request was rejected ('+str(ex.code)+'). Playback was not retried.') from None
 except (urllib.error.URLError,TimeoutError,ConnectionError,http.client.HTTPException):
  # Retry only the read, never an uncertain playback/queue mutation.
  if path=='/status' and body is None and _recover and recover_service():
   return recovered_status()
  raise ValueError('Music connection is recovering. Your saved playback is preserved; try Play shortly.') from None

def recovered_status():
 for attempt in range(6):
  try:return request('/status',_recover=False)
  except ValueError as ex:
   if not any(word in str(ex) for word in ('sign-in','recovering','reconnecting')):raise
   time.sleep(.5)
 raise ValueError('Music is reconnecting to Spotify; saved playback remains available.')

def recover_service():
 import fcntl,subprocess
 STORE.mkdir(parents=True,exist_ok=True,mode=0o700)
 with (STORE/'recovery.lock').open('a') as lock:
  try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
  except BlockingIOError:return False
  try:last=float((STORE/'recovery-at').read_text())
  except (OSError,ValueError):last=0
  if time.time()-last<120:return False
  (STORE/'recovery-at').write_text(str(time.time()))
  try:
   result=subprocess.run(['systemctl','--user','restart','sensei-go-spotify.service'],capture_output=True,timeout=5)
   if result.returncode:return False
   time.sleep(.5)
   return True
  except (OSError,subprocess.TimeoutExpired):return False

def saved_login():
 try:
  value=json.loads((Path.home()/'.config/sensei-go-spotify/state.json').read_text()).get('credentials',{})
  return {'username':value.get('username','')} if value.get('data') and value.get('username') else {}
 except (OSError,ValueError,AttributeError):return {}

def _configured_bitrate():
 try:
  text=(Path.home()/'.config/sensei-go-spotify/config.yml').read_text()
  match=re.search(r'^bitrate:\s*(96|160|320)\s*(?:#.*)?$',text,re.M)
  return int(match.group(1)) if match else 160
 except OSError:return 160

def remembered_playback():
 try:return json.loads((STORE/'playback.json').read_text())
 except (OSError,ValueError):return {}

def remember_playback(d):
 if d.get('stopped',True) or d.get('buffering') or not (d.get('track') or {}).get('uri'):return
 STORE.mkdir(parents=True,exist_ok=True,mode=0o700)
 # Private playback metadata only. Never save login/session credentials.
 data={k:d.get(k) for k in ('track','queue','context_uri','paused','volume','volume_steps','shuffle_context','repeat_context','repeat_track')}
 tmp=STORE/('playback.'+str(os.getpid())+'.tmp')
 with tmp.open('w') as f:os.chmod(tmp,0o600);json.dump(data,f)
 tmp.replace(STORE/'playback.json')

def resume_saved(d):
 saved=remembered_playback();track=saved.get('track') or {}
 if not track.get('uri'):raise ValueError('Choose a track to start playback; no saved session exists yet.')
 checked=uri('track',track['uri'].rsplit(':',1)[-1])
 # One atomic context+queue load, not a series of racing add-to-queue calls.
 upcoming=[uri('track',t['uri'].rsplit(':',1)[-1]) for t in saved.get('queue') or [] if t.get('uri')][:50]
 request('/player/play',{'uri':checked,'position':max(0,int(track.get('position',0))),'queued':upcoming})
 mark_intent(d,'start',track['uri'],track.get('position',0))


def uri(kind,identity):
 if kind=='collection' and identity=='tracks':return 'spotify:collection:tracks'
 if kind not in ('track','album','artist','playlist') or not re.fullmatch(r'[A-Za-z0-9]{22}',str(identity)):raise ValueError('Invalid Spotify identity')
 # Go's 128-bit Spotify ID decoder must never receive an overflowing number.
 alphabet='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';value=0
 for ch in identity:value=value*62+alphabet.index(ch)
 if value>=1<<128:raise ValueError('Invalid Spotify identity: exceeds 128 bits')
 return 'spotify:'+kind+':'+identity

def row(t,kind='track'):
 t=t or {};u=t.get('uri','');typ=u.split(':')[1] if u.count(':')>=2 else kind
 return {'id':u.rsplit(':',1)[-1],'uri':u,'kind':typ,'title':t.get('name') or u.rsplit(':',1)[-1], 'artist':', '.join(t.get('artist_names') or t.get('artists') or []) or t.get('owner_username') or typ.title(),'album':t.get('album_name',''),'albumId':(t.get('album_uri') or '').rsplit(':',1)[-1],'art':t.get('album_cover_url') or t.get('image_url') or '', 'duration':t.get('duration',0),'count':t.get('length',0),'description':re.sub('<[^>]+>','',t.get('description',''))}

def raw_status():
 try:d=request('/status')
 except ValueError as ex:
  if 'reconnecting' not in str(ex):raise
  d=recovered_status()
 if not d:raise ValueError('Music is reconnecting; saved login and playback are preserved.')
 remember_playback(d)
 return d

def mark_intent(before,action,context=None,position=0):
 STORE.mkdir(parents=True,exist_ok=True,mode=0o700)
 temp=STORE/('intent.'+str(os.getpid())+'.tmp')
 with temp.open('w') as f:os.chmod(temp,0o600);json.dump({'before':(before.get('track') or {}).get('uri'),'action':action,'context':context,'position':position,'at':time.time()},f)
 temp.replace(STORE/'intent.json')

def transitioning(d):
 try:p=json.loads((STORE/'intent.json').read_text())
 except (OSError,ValueError):return False
 if time.time()-p.get('at',0)>12:return False
 t=d.get('track') or {};changed=bool(t.get('uri')) and (t['uri']!=p.get('before') or (p.get('action') in ('previous','start') and abs(t.get('position',99999)-p.get('position',0))<5000))
 if p.get('context') and d.get('context_uri')!=p['context']:changed=False
 if changed and not d.get('buffering'):
  (STORE/'intent.json').unlink(missing_ok=True);return False
 return True

def status():
 try:d=raw_status()
 except ValueError:
  saved=remembered_playback();track=saved.get('track') or {}
  if not track.get('uri'):raise
  uri('track',track['uri'].rsplit(':',1)[-1])
  return {'ready':False,'backend':'headless','playing':False,'loading':True,'track':row(track),'progress':track.get('position',0),'warning':'Music is reconnecting. Saved login, artwork and queue are preserved.'}
 t=d.get('track') or {};pending=transitioning(d)
 if not t and d.get('stopped'):t=remembered_playback().get('track') or {}
 return {'ready':True,'backend':'headless','owner':'headless-client' if not d.get('stopped') else 'inactive','playing':bool(t) and not d.get('stopped',True) and not d.get('paused',True),'loading':pending or d.get('buffering',False) or (not d.get('stopped',True) and not t),'track':row(t) if t else {},'progress':t.get('position',0),'volume':round(d.get('volume',0)*100/max(1,d.get('volume_steps',100))),'shuffle':d.get('shuffle_context',False),'repeat':'track' if d.get('repeat_track') else 'context' if d.get('repeat_context') else 'off','device':d.get('device_name'),'deviceId':d.get('device_id'),'context':d.get('context_uri'),'eventUri':t.get('uri',''),'eventTime':time.time()*1000}

def cache(key,load,ttl=300,force=False):
 STORE.mkdir(parents=True,exist_ok=True,mode=0o700)
 import hashlib,fcntl
 p=STORE/(hashlib.sha256(key.encode()).hexdigest()+'.json');old={}
 try:old=json.loads(p.read_text())
 except (OSError,ValueError):pass
 if old and not force and time.time()-old.get('at',0)<ttl:return old['data']
 # One reader per key; private files are atomically replaced.
 with (STORE/'read.lock').open('a') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX)
  try:d=load()
  except ValueError as ex:
   if old:return dict(old['data'],stale=True,warning=str(ex)+' Showing saved library data.')
   raise
  tmp=p.with_name(p.name+'.'+str(os.getpid())+'.tmp')
  with tmp.open('w') as f:os.chmod(tmp,0o600);json.dump({'at':time.time(),'data':d},f)
  tmp.replace(p);return d

def page_token(data):return 'headless:'+json.dumps(data,separators=(',',':'))

def listing(context,offset=0,kind=''):
 if context!='spotify:collection:tracks' and not re.fullmatch(r'spotify:(playlist|album|artist):[A-Za-z0-9]{22}',context):raise ValueError('Invalid collection')
 d=request('/context/tracks?'+urllib.parse.urlencode({'uri':context,'offset':offset,'limit':50}));rows=[]
 for t in d.get('tracks',[]):rows.append(row(t.get('track') or {'uri':t['uri']}))
 pending=not d.get('ready') or d.get('cached',0)<len(rows)
 total=d.get('total',d.get('length',0));end=offset+len(rows)
 nxt=page_token({'type':'context','uri':context,'offset':end,'kind':kind}) if end<total and rows else ''
 return {'rows':rows,'total':total,'next':nxt,'partial':pending,'warning':'Loading track names in the background…' if pending else ''}

def library(kind,offset=0,force=False):
 if kind in ('liked','recent','top'):
  d=cache('liked:'+str(offset),lambda:listing('spotify:collection:tracks',offset,kind),ttl=3,force=force)
  return dict(d,kind=kind,warning=d.get('warning') or ('Showing Liked Songs; this backend does not infer listening history.' if kind!='liked' else ''))
 if kind not in ('playlists','albums','artists'):raise ValueError('Unknown music library')
 def load():
  d=request('/library/'+kind+'?'+urllib.parse.urlencode({'offset':offset,'limit':100}));rows=[row(t,kind[:-1]) for t in d.get('items',[])];end=offset+len(rows)
  nxt=page_token({'type':'library','kind':kind,'offset':end}) if end<d.get('total',0) and rows else ''
  return {'rows':rows,'total':d.get('total',0),'next':nxt,'kind':kind}
 return cache('library:'+kind+':'+str(offset),load,force=force)

def catalogue_search(query,kind):
 import subprocess
 binary=Path.home()/'.local/opt/spotatui-catalog/spotatui';root=Path.home()/'.local/share/sensei-spotify/catalog-helper'
 if kind not in ('tracks','albums','artists','playlists'):raise ValueError('Invalid search category')
 if not binary.is_file():raise ValueError('Install the catalogue helper to search beyond saved library matches.')
 env=dict(os.environ,NO_COLOR='1',XDG_CONFIG_HOME=str(root/'config'),XDG_CACHE_HOME=str(root/'cache'),XDG_STATE_HOME=str(root/'state'))
 try:result=subprocess.run([str(binary),'--no-update','search',query,'--'+kind,'--limit','10','--format','%u\x1f%t\x1f%a\x1f%b\x1f%p'],env=env,capture_output=True,text=True,timeout=25)
 except (OSError,subprocess.TimeoutExpired):raise ValueError('Search unavailable; showing saved library matches.') from None
 if result.returncode:raise ValueError('Search could not connect; showing saved library matches.')
 rows=[]
 for line in result.stdout[:262144].splitlines():
  fields=line.strip().split('\x1f')
  if len(fields)!=5:continue
  u,title,artist,album,playlist=fields
  if not re.fullmatch(r'spotify:(track|album|artist|playlist):[A-Za-z0-9]{22}',u):continue
  title={'tracks':title,'albums':album,'artists':artist,'playlists':playlist}[kind]
  rows.append(row({'uri':u,'name':title,'artist_names':[artist] if artist else []}))
 return {'rows':rows}

def dispatch(args):
 name=args[0];a=args[1:];force=a[-1:]==['refresh']
 if name in ('moment-save','moment-resume'):
  saved=Path.home()/'.local/share/sensei-spotify/moments.json'
  try:moments=json.loads(saved.read_text())
  except (OSError,ValueError):moments=[]
  if name=='moment-save':
   d=raw_status();track=d.get('track') or {}
   if not track.get('uri'):raise ValueError('Play a song before saving a listening moment.')
   saved.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
   moments=([{'uri':track['uri'],'context':d.get('context_uri'),'position':track.get('position',0),'title':track.get('name'),'at':time.time()}]+moments)[:20]
   temp=saved.with_name('moments.'+str(os.getpid())+'.tmp')
   with temp.open('w') as f:os.chmod(temp,0o600);json.dump(moments,f)
   temp.replace(saved);return {'ok':True,'warning':'Listening moment saved privately · '+str(len(moments))+' kept'}
  if not moments:raise ValueError('Save a listening moment first.')
  m=moments[0];target=uri('track',m['uri'].rsplit(':',1)[-1]);context=m.get('context')
  if context!='spotify:collection:tracks' and not re.fullmatch(r'spotify:(album|playlist|artist):[A-Za-z0-9]{22}',context or ''):context=target
  before=raw_status();request('/player/play',{'uri':context,'skip_to_uri':target,'position':max(0,int(m['position']))});mark_intent(before,'start',context,max(0,int(m['position'])))
  return {'ok':True}
 if name=='surprise':
  import secrets
  d=listing('spotify:collection:tracks');total=d['total']
  if not total:raise ValueError('Liked songs are still loading; try again shortly.')
  offset=secrets.randbelow(total);page=listing('spotify:collection:tracks',offset)
  if not page['rows']:raise ValueError('That library page is still loading; try again shortly.')
  return dispatch(['liked-play',page['rows'][0]['id']])
 if name=='signin':
  import subprocess
  for attempt in range(5):
   try:d=request('/auth/code')
   except ValueError:d={}
   url=d.get('url','') if isinstance(d,dict) else ''
   if url:
    parsed=urllib.parse.urlsplit(url)
    if parsed.scheme!='https' or parsed.hostname not in ('spotify.com','accounts.spotify.com','www.spotify.com') or parsed.username or parsed.password or parsed.port not in (None,443):
     raise ValueError('Spotify returned an untrusted pairing link; nothing was opened.')
    result={'ok':True,'authorizationPending':True,'loginUrl':url,'pairingCode':str(d.get('code',''))[:40],'warning':'Approve this device in Spotify, then return here. Your connection will refresh automatically.'}
    break
   try:s=raw_status()
   except ValueError:s={}
   if s.get('username'):
    url='https://www.spotify.com/account/overview/'
    result={'ok':True,'connected':True,'loginUrl':url,'warning':'Spotify is already connected. Your Account page is opening so you can verify your subscription.'}
    break
   if attempt==0:
    subprocess.run(['systemctl','--user','start','sensei-go-spotify.service'],capture_output=True,timeout=5)
   time.sleep(.4)
  else:raise ValueError('Spotify pairing is not ready. Check the music service and connection, then retry Sign in.')
  try:
   browser=subprocess.run(['xdg-open',url],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=8)
   if browser.returncode:result['warning']='The browser could not open. Use the account link or pairing code shown below.'
  except (OSError,subprocess.TimeoutExpired):result['warning']='The browser could not open. Use the account link or pairing code shown below.'
  return result
 if name=='status':return status()
 if name=='account':
  try:s=raw_status();ready=True
  except ValueError:s=saved_login();ready=False
  t=s.get('track') or {};quality=' · '.join(x for x in [str(t.get('codec') or '').title(),str(t['bitrate'])+' kb/s' if t.get('bitrate') else '',str(round(t['sample_rate']/1000,1))+' kHz' if t.get('sample_rate') else ''] if x)
  return {'quality':quality,'backend':'headless','service':'connected' if ready else 'reconnecting' if s.get('username') else 'sign-in required','cachedLogin':ready or bool(s.get('username')),'username':s.get('username',''),'requestedQuality':'320 kb/s' if _configured_bitrate()==320 else str(_configured_bitrate())+' kb/s','deviceName':s.get('device_name','Den'),'version':'go-librespot · bd3fa740','catalogue':'Connect session · no public Web API'}
 if name=='library':return library(a[0],force=force)
 if name=='more':
  if not a[0].startswith('headless:'):raise ValueError('Refresh this library before loading another page')
  token=json.loads(a[0][9:]);offset=token.get('offset')
  if type(offset) is not int or not 0<=offset<100000:raise ValueError('Invalid music page')
  if token.get('type')=='library':d=library(token['kind'],offset)
  elif token.get('type')=='context':d=cache(token['uri']+':'+str(offset),lambda:listing(token['uri'],offset,token.get('kind','')),ttl=3);d['kind']=token.get('kind','')
  else:raise ValueError('Invalid music page type')
  return dict(d,target=a[2] if len(a)>2 else 'library',contextId=a[3] if len(a)>3 else '')
 if name=='home':return dict(dispatch(['library','liked']),kind='recent')
 if name=='context':
  context=uri(a[0],a[1]);d=cache(context,lambda:listing(context),ttl=3,force=force)
  return dict(d,item={'kind':a[0],'id':a[1],'uri':context})
 if name=='queue':
  d=raw_status();saved=d.get('buffering') or d.get('stopped');q=(remembered_playback().get('queue') if saved else d.get('queue')) or [];rows=[row(t.get('track') or {'uri':t['uri']}) for t in q]
  return {'rows':rows,'total':len(rows),'stale':bool(saved),'warning':'Saved queue · press Play to resume' if saved and rows else 'Upcoming playback window · up to 50 tracks' if rows else ''}
 if name=='devices':
  d=raw_status();return {'rows':[{'id':d['device_id'],'name':d['device_name'],'active':not d['stopped'],'is_active':not d['stopped'],'type':'Headless Connect','volume_percent':round(d.get('volume',0)*100/max(1,d.get('volume_steps',100)))}],'warning':'This headless player is local. Choose remote devices from a Spotify Connect controller.'}
 if name=='search':
  kind=a[1] if len(a)>1 and a[1] in ('tracks','albums','artists','playlists') else 'tracks'
  query=a[0].strip()[:240] if a else ''
  from spotify_control import canonical_uri
  linked=canonical_uri(query.strip())
  q=query.casefold();out={'tracks':[],'albums':[],'artists':[],'playlists':[]}
  if re.fullmatch(r'spotify:(track|album|playlist|artist):[A-Za-z0-9]{22}',linked):
   k=linked.split(':')[1];out[{'track':'tracks','album':'albums','artist':'artists','playlist':'playlists'}[k]].append(row({'uri':linked,'name':'Open Spotify '+k+' link'}))
  for p in STORE.glob('*.json'):
   try:items=json.loads(p.read_text())['data'].get('rows',[])
   except (OSError,ValueError,KeyError):continue
   for r in items:
    k={'track':'tracks','album':'albums','artist':'artists','playlist':'playlists'}.get(r.get('kind'))
    if k and q in (r.get('title','')+' '+r.get('artist','')).casefold() and not any(x['uri']==r['uri'] for x in out[k]):out[k].append(r)
  try:
   found=cache('search:'+kind+':'+query,lambda:catalogue_search(query,kind),ttl=600,force=force)
   for r in found['rows']:
    if not any(x['uri']==r['uri'] for x in out[kind]):out[kind].append(r)
   return dict(out,warning=found.get('warning',''))
  except ValueError as ex:return dict(out,warning=str(ex))
 if name=='connect':
  d=raw_status()
  if not a or a[0]!=d['device_id']:raise ValueError('Choose remote devices from a Spotify Connect controller.')
  request('/player/resume',{});return {'ok':True}
 if name in ('like','unlike'):
  u=a[0] if a[0].startswith('spotify:') else uri('track',a[0]);request('/library/liked',{'uris':[u],'liked':name=='like'})
 elif name in ('queue-add','enqueue'):
  u=a[0] if a[0].startswith('spotify:') else uri('track',a[0]);request('/player/add_to_queue',{'uri':u})
 elif name=='playlist-add':request('/library/playlists/add_tracks',{'playlist_uri':uri('playlist',a[0]),'uris':[a[1] if a[1].startswith('spotify:') else uri('track',a[1])]})
 elif name in ('play','pause','toggle','next','previous'):
  before=raw_status()
  if before.get('stopped') and name in ('play','toggle'):
   resume_saved(before);return {'ok':True,'backend':'headless','restored':True}
  request('/player/'+{'play':'resume','pause':'pause','toggle':'playpause','next':'next','previous':'prev'}[name],{})
  if name in ('next','previous'):mark_intent(before,name)
 elif name=='volume':request('/player/volume',{'volume':max(0,min(100,int(float(a[0]))))})
 elif name in ('seek','seek-to'):request('/player/seek',{'position':int(float(a[0])),'relative':name=='seek'})
 elif name=='shuffle':request('/player/shuffle_context',{'shuffle_context':not raw_status().get('shuffle_context',False)})
 elif name=='repeat':
  d=raw_status();current='track' if d.get('repeat_track') else 'context' if d.get('repeat_context') else 'off';nxt={'off':'context','context':'track','track':'off'}[current]
  request('/player/repeat_context',{'repeat_context':nxt=='context'});request('/player/repeat_track',{'repeat_track':nxt=='track'})
 elif name in ('play-track','play-context','play-context-track','play-list','liked-play'):
  if name=='play-track':body={'uri':uri('track',a[0])}
  elif name=='liked-play':body={'uri':'spotify:collection:tracks','skip_to_uri':uri('track',a[0])} if a else {'uri':'spotify:collection:tracks'}
  elif name in ('play-context','play-context-track'):body={'uri':uri(a[0],a[1])};body.update({'skip_to_uri':uri('track',a[2].rsplit(':',1)[-1])} if len(a)>2 else {})
  else:
   payload=json.loads(a[0]);values=payload.get('uris',[]) if isinstance(payload,dict) else payload
   if not isinstance(values,list) or not 1<=len(values)<=90:raise ValueError('Choose 1–90 tracks')
   values=[uri('track',str(x).rsplit(':',1)[-1]) for x in values]
   offset=payload.get('offset',0) if isinstance(payload,dict) else 0
   if type(offset) is not int or not 0<=offset<len(values):raise ValueError('Invalid queue offset')
   values=values[offset:];request('/player/play',{'uri':values[0],'queued':values[1:]})
   return {'ok':True,'backend':'headless'}
  before=raw_status();request('/player/play',body);mark_intent(before,'start',body['uri'])
 else:raise ValueError('This operation is not available in the headless backend. Your library was not modified.')
 return {'ok':True,'backend':'headless'}
