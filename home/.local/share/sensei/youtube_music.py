"""On-demand YouTube media; selected browser session stays in memory, never exported."""
import hashlib,html,json,os,re,shutil,subprocess,time,urllib.parse,urllib.request
from pathlib import Path
CACHE=Path.home()/'.cache/sensei-spotify/youtube'
LIBRARY=Path.home()/'.local/share/sensei-spotify/youtube-library.json'
ACCOUNT=Path.home()/'.config/sensei-den/youtube.json'
def identity(value):
 if re.fullmatch(r'[A-Za-z0-9_-]{11}',value):return value
 p=urllib.parse.urlsplit(value)
 if p.scheme!='https' or p.hostname not in ('youtube.com','www.youtube.com','music.youtube.com','youtu.be'):raise ValueError('Use a YouTube link or video ID')
 v=p.path.strip('/').split('/')[0] if p.hostname=='youtu.be' else urllib.parse.parse_qs(p.query).get('v',[''])[0]
 if not re.fullmatch(r'[A-Za-z0-9_-]{11}',v):raise ValueError('Invalid YouTube video identity')
 return v

def account():
 try:d=json.loads(ACCOUNT.read_text())
 except (OSError,ValueError):raise ValueError('Connect your browser profile to load private YouTube collections.')
 if d.get('browser')!='chrome' or not re.fullmatch(r'Default|Profile [0-9]+',d.get('profile','')):raise ValueError('The selected browser profile is not supported.')
 if not (Path.home()/'.config/google-chrome'/d['profile']).is_dir():raise ValueError('The selected Chrome profile is not available on this machine.')
 return d

def run(args,authenticated=False):
 if not authenticated:
  try:authenticated=time.time()-json.loads((CACHE/'auth-required.json').read_text()).get('at',0)<900;account() if authenticated else None
  except (OSError,ValueError,TypeError):authenticated=False
 runtime=['--js-runtimes','node'] if not shutil.which('deno') and shutil.which('node') else []
 options=['--cookies-from-browser','chrome+gnomekeyring:'+account()['profile']] if authenticated else []
 try:r=subprocess.run(['yt-dlp','--ignore-config','--no-warnings','--extractor-args','youtube:skip=translated_subs','--socket-timeout','6','--retries','0']+runtime+options+args,capture_output=True,text=True,timeout=35)
 except (OSError,subprocess.TimeoutExpired):raise ValueError('YouTube is temporarily unavailable. Saved items remain available.') from None
 if r.returncode:
  challenge=any(marker in r.stderr.lower() for marker in ("sign in to confirm","sign in to verify","confirm you’re not a bot","confirm you're not a bot"))
  if challenge and not authenticated:
   account() # Only the explicitly selected local account may answer this challenge.
   result=run(args,True);atomic(CACHE/'auth-required.json',{'at':time.time()});return result
  if authenticated:raise ValueError('YouTube account access failed. Unlock your login keyring, sign in in the selected Chrome profile, then refresh. Public search still works.')
  raise ValueError('YouTube could not provide this item. Try another result or open it in your browser.')
 if len(r.stdout)>8*1024*1024:raise ValueError('YouTube response is too large')
 try:
  data=json.loads(r.stdout)
  if not isinstance(data,dict):raise ValueError()
  if authenticated:data['_authenticated']=True
  return data
 except ValueError:raise ValueError('YouTube returned an unreadable response') from None

def row(item):
 vid=identity(item.get('id',''));artist=item.get('artist') or item.get('channel') or item.get('uploader') or 'YouTube'
 return {'id':vid,'uri':'youtube:'+vid,'kind':'youtube','title':item.get('track') or item.get('title') or 'YouTube music','artist':artist,'album':'YouTube','duration':round(float(item.get('duration') or 0)*1000),'art':'https://i.ytimg.com/vi/'+vid+'/hqdefault.jpg','url':'https://www.youtube.com/watch?v='+vid}

def collection_row(item,private=False):
 try:d=row(item)
 except ValueError:
  ident=item.get('id','');url=item.get('url','')
  if re.fullmatch(r'UC[A-Za-z0-9_-]{22}',ident):kind='channel';url='https://www.youtube.com/channel/'+ident+'/videos'
  elif re.fullmatch(r'[A-Za-z0-9_-]{10,100}',ident):kind='playlist';url='https://www.youtube.com/playlist?list='+ident
  else:raise ValueError('Unrecognized YouTube entry')
  art=next((t.get('url','') for t in reversed(item.get('thumbnails') or []) if urllib.parse.urlsplit(t.get('url','')).hostname in ('i.ytimg.com','yt3.ggpht.com','yt3.googleusercontent.com')),'')
  d={'id':ident,'uri':'youtube:'+ident,'kind':kind,'title':item.get('title') or item.get('channel') or kind.title(),'artist':item.get('channel') or item.get('uploader') or 'YouTube collection','art':art,'url':url,'duration':0}
 return dict(d,private=private)

def collections(section,offset=0):
 endpoints={'playlists':'https://www.youtube.com/feed/playlists','watchlater':'https://www.youtube.com/playlist?list=WL','subscriptions':'https://www.youtube.com/feed/subscriptions','channels':'https://www.youtube.com/feed/channels','history':'https://www.youtube.com/feed/history'}
 if section not in endpoints or type(offset) is not int or not 0<=offset<10000:raise ValueError('Invalid YouTube collection page')
 data=run(['--flat-playlist','--dump-single-json','--playlist-start',str(offset+1),'--playlist-end',str(offset+50),endpoints[section]],True);rows=[]
 for item in data.get('entries') or []:
  try:rows.append(collection_row(item,True))
  except (ValueError,TypeError,AttributeError):continue
 result={'rows':rows,'section':section,'next':offset+50 if len(rows)>=50 else -1,'warning':'Your YouTube collection · read-only account access'}
 atomic(CACHE/('account-'+section+'.json'),result);atomic(CACHE/'account-status.json',{'verified':time.time()});return result

def search(query,refresh=False,authenticated=False,offset=0):
 if type(offset) is not int or not 0<=offset<10000:raise ValueError('Invalid collection page')
 query=query.strip()[:450]
 if len(query)<2:return {'rows':[],'warning':'Search for music or paste a public YouTube playlist.'}
 key=hashlib.sha256((query+':'+str(offset)+(':'+account()['profile'] if authenticated else '')).encode()).hexdigest();path=CACHE/(key+'.json');old={}
 try:old=json.loads(path.read_text())
 except (OSError,ValueError):pass
 if old and not refresh and time.time()-path.stat().st_mtime<3600:return old
 target='ytsearch10:'+query;limit=10
 if query.startswith(('https://','http://')):
  p=urllib.parse.urlsplit(query)
  if p.scheme!='https' or p.hostname not in ('youtube.com','www.youtube.com','music.youtube.com','youtu.be'):raise ValueError('Only public YouTube links are supported')
  playlist=urllib.parse.parse_qs(p.query).get('list',[''])[0]
  if playlist:
   if not re.fullmatch(r'[A-Za-z0-9_-]{10,100}',playlist):raise ValueError('Invalid playlist identity')
   target='https://www.youtube.com/playlist?list='+playlist;limit=50
  elif re.fullmatch(r'/(?:channel/UC[A-Za-z0-9_-]{22}|@[A-Za-z0-9_.-]+)(?:/videos)?/?',p.path):target='https://www.youtube.com'+p.path.rstrip('/').removesuffix('/videos')+'/videos';limit=50
  else:target='https://www.youtube.com/watch?v='+identity(query)
 try:
  data=run(['--flat-playlist','--dump-single-json','--playlist-start',str(offset+1),'--playlist-end',str(offset+limit),target],authenticated);rows=[]
  for item in (data.get('entries') or [data])[:limit]:
   try:rows.append(collection_row(item,authenticated))
   except (ValueError,TypeError,AttributeError):continue
  result={'rows':rows,'next':offset+limit if limit==50 and len(rows)>=limit else -1,'warning':'50 entries per collection page · save individual videos for quick access.' if limit==50 else 'YouTube results · availability can vary by region.','title':data.get('title','')}
  atomic(path,result);return result
 except ValueError as ex:
  if old:return dict(old,warning=str(ex)+' Showing saved search results.')
  raise

def atomic(path,data):
 path.parent.mkdir(parents=True,exist_ok=True,mode=0o700);temp=path.with_name(path.name+'.'+str(os.getpid())+'.tmp')
 with temp.open('w') as f:os.chmod(temp,0o600);json.dump(data,f,ensure_ascii=False)
 temp.replace(path)
def audio(value,watch=False,quality=1080,authenticated=False):
 vid=identity(value)
 if quality not in (360,480,720,1080):raise ValueError('Choose 360p, 480p, 720p or 1080p')
 format=f'bestvideo[ext=mp4][vcodec^=avc1][height<={quality}]+bestaudio[ext=m4a]/best[ext=mp4][vcodec^=avc1][height<={quality}]' if watch else 'bestaudio[ext=m4a]/bestaudio'
 d=run(['--no-playlist','--check-formats','--dump-single-json','--skip-download','-f',format,'https://www.youtube.com/watch?v='+vid],authenticated);parts=d.get('requested_formats') or [d]
 sound=next((p for p in parts if p.get('acodec','none')!='none'),None);picture=next((p for p in parts if p.get('vcodec','none')!='none'),None)
 url=(sound or d).get('url','');host=urllib.parse.urlsplit(url).hostname or ''
 if not url.startswith('https://') or not host.endswith('.googlevideo.com'):raise ValueError('No safe audio stream was returned')
 result={'track':dict(row(d),private=authenticated or bool(d.get('_authenticated'))),'stream':url,'chapters':[{'title':c.get('title','Chapter'),'time':round(float(c.get('start_time',0))*1000)} for c in d.get('chapters') or []],'captionLanguages':sorted(set((d.get('subtitles') or {}).keys())|set((d.get('automatic_captions') or {}).keys()))}
 if watch:
  video=(picture or {}).get('url','');host=urllib.parse.urlsplit(video).hostname or ''
  if not video.startswith('https://') or not host.endswith('.googlevideo.com'):raise ValueError('No safe video stream was returned')
  result['video']=video
 return result
def parse_vtt(raw):
 lines=[]
 for block in re.split(r'\n\s*\n',raw.replace('\r','')):
  rows=block.splitlines();stamp=next((i for i,r in enumerate(rows) if '-->' in r),-1)
  if stamp<0:continue
  match=re.search(r'(?:(\d+):)?(\d{2}):(\d{2})[.,](\d{3})',rows[stamp])
  if not match:continue
  h,m,s,ms=match.groups();text=html.unescape(re.sub(r'<[^>]*>','', ' '.join(rows[stamp+1:]))).strip()
  if text and (not lines or lines[-1]['text']!=text):lines.append({'time':((int(h or 0)*60+int(m))*60+int(s))*1000+int(ms),'text':text})
 return lines

def transcript(value,language='en',authenticated=False):
 vid=identity(value)
 if not re.fullmatch(r'[A-Za-z0-9_-]{2,25}',language):raise ValueError('Invalid caption language')
 path=CACHE/('transcript-'+vid+'-'+language+'.json')
 try:
  old=json.loads(path.read_text())
  if time.time()-path.stat().st_mtime<7*86400:return old
 except (OSError,ValueError):pass
 data=run(['--no-playlist','--dump-single-json','--skip-download','https://www.youtube.com/watch?v='+vid],authenticated)
 manual=data.get('subtitles') or {};automatic=data.get('automatic_captions') or {};all_langs=sorted(set(manual)|set(automatic))
 selected=language if language in manual or language in automatic else next((k for k in all_langs if k.startswith(language+'-')),None)
 if not selected:return {'lines':[],'languages':all_langs,'warning':'No captions are published in this language. Choose another language; local transcription can be used separately.'}
 formats=manual.get(selected) or automatic.get(selected) or []
 choice=next((f for f in formats if f.get('ext')=='json3'),None) or next((f for f in formats if f.get('ext')=='vtt'),None)
 if not choice:return {'lines':[],'languages':all_langs,'warning':'This caption format is not supported by the native transcript viewer.'}
 url=choice.get('url','');parsed=urllib.parse.urlsplit(url)
 if parsed.scheme!='https' or parsed.hostname not in ('www.youtube.com','youtube.com'):raise ValueError('Invalid caption endpoint')
 try:
  with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=12) as response:raw=response.read(4*1024*1024+1)
  if len(raw)>4*1024*1024:raise ValueError('Transcript exceeds the local size limit')
  document=json.loads(raw) if choice['ext']=='json3' else {};lines=parse_vtt(raw.decode('utf-8')) if choice['ext']=='vtt' else []
  for event in document.get('events',[]):
   text=' '.join(''.join(s.get('utf8','') for s in event.get('segs',[])).split())
   if not text or lines and lines[-1]['text']==text:continue
   lines.append({'time':int(event.get('tStartMs',0)),'text':text})
  result={'lines':lines,'languages':all_langs,'language':selected,'automatic':selected not in manual,'warning':'Automatic captions may contain mistakes.' if selected not in manual else ''}
  if lines:atomic(path,result)
  return result
 except (OSError,ValueError,TimeoutError):return {'lines':[],'languages':all_langs,'warning':'Caption provider is unavailable. Playback is unaffected; retry later.'}

def save(item,remove=False):
 vid=identity(item.get('id',''))
 try:items=json.loads(LIBRARY.read_text()).get('rows',[])
 except (OSError,ValueError,AttributeError):items=[]
 items=[x for x in items if x.get('id')!=vid]
 if not remove:
  safe={'id':vid,'uri':'youtube:'+vid,'kind':'youtube','title':str(item.get('title','YouTube music'))[:400],'artist':str(item.get('artist','YouTube'))[:200],'album':'YouTube','private':bool(item.get('private')),'duration':max(0,int(item.get('duration') or 0)),'art':'https://i.ytimg.com/vi/'+vid+'/hqdefault.jpg','url':'https://www.youtube.com/watch?v='+vid}
  items.insert(0,safe)
 if len(items)>2000:raise ValueError('Saved collection is full; remove an item before adding more.')
 atomic(LIBRARY,{'rows':items});return {'ok':True}
def dispatch(args):
 name=args[0]
 if name=='youtube-account':
  try:d=account();return {'configured':True,'browser':'Chrome','profile':d['profile']}
  except ValueError:return {'configured':False}
 if name=='youtube-library':return collections(args[1],int(args[2]) if len(args)>2 else 0)
 if name=='youtube-search':return search(args[1],'refresh' in args[2:],'private' in args[2:],int(next((a.split('=',1)[1] for a in args[2:] if a.startswith('offset=')),0)))
 if name=='youtube-audio':return audio(args[1],authenticated='private' in args[2:])
 if name=='youtube-watch':return audio(args[1],True,int(args[2]) if len(args)>2 else 1080,'private' in args[3:])
 if name=='youtube-transcript':return transcript(args[1],args[2] if len(args)>2 else 'en','private' in args[3:])
 if name=='youtube-save':return save(json.loads(args[1]))
 if name=='youtube-remove':return save({'id':args[1]},True)
 raise ValueError('Unknown YouTube action')
