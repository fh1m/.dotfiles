"""Bounded, on-demand Twitch reads and native playback. No browser token is exported.

The website GraphQL adapter is deliberately isolated: it is not a supported Helix
API. Failure leaves local bookmarks and public channel URLs usable.
"""
import json,re,subprocess,time,urllib.parse,urllib.request
from pathlib import Path
from youtube_music import account as browser_account,atomic
CACHE=Path.home()/'.cache/sensei-spotify/twitch'
LIBRARY=Path.home()/'.local/share/sensei-spotify/twitch-library.json'
CLIENT='kimne78kx3ncx6brgo4mv6wki5h1ko' # Public Twitch website client, also used by yt-dlp.
USER_FIELDS='login displayName description profileImageURL(width: 150) stream { title viewersCount game { name } }'

def identity(value):
 value=value.strip()
 if value.startswith('https://'):
  p=urllib.parse.urlsplit(value)
  if p.hostname not in ('twitch.tv','www.twitch.tv'):raise ValueError('Use a Twitch channel or video URL')
  value=p.path.strip('/')
 if re.fullmatch(r'videos/[0-9]{1,20}',value):return value
 if not re.fullmatch(r'[A-Za-z0-9_]{3,25}',value) or value in ('directory','settings','login','subscriptions'):raise ValueError('Use a Twitch channel name or video URL')
 return value.lower()

def session():
 try:
  from yt_dlp.cookies import extract_cookies_from_browser
  jar=extract_cookies_from_browser('chrome',profile=browser_account()['profile'],keyring='GNOMEKEYRING')
  return next((c.value for c in jar if c.name=='auth-token' and c.domain.lstrip('.')=='twitch.tv'),None)
 except Exception:return None

def account_status():
 token=session()
 if not token:return {'connected':False,'warning':'Sign in to Twitch in the selected Chrome profile, then refresh. Public playback works without an account.'}
 try:
  req=urllib.request.Request('https://id.twitch.tv/oauth2/validate',headers={'Authorization':'OAuth '+token})
  with urllib.request.urlopen(req,timeout=10) as response:data=json.loads(response.read(65536))
  scopes=data.get('scopes') or []
  return {'connected':True,'login':data.get('login',''),'following':'user:read:follows' in scopes,'chatRead':'chat:read' in scopes,'chatWrite':'chat:edit' in scopes,'warning':'Signed in · '+('follow permission available' if 'user:read:follows' in scopes else 'this browser session does not grant the followed-channel API permission')+'. Public video, search and local saved channels work. Chat and paid account actions remain on Twitch.'}
 except (OSError,ValueError):return {'connected':False,'warning':'Twitch session expired or validation is unavailable. Sign in again in Chrome, then refresh.'}

def gql(query,variables=None,private=False):
 headers={'Client-ID':CLIENT,'Content-Type':'application/json'}
 if private:
  token=session()
  if not token:raise ValueError('Sign in to Twitch in the selected Chrome profile, unlock the login keyring, then refresh.')
  headers['Authorization']='OAuth '+token
 req=urllib.request.Request('https://gql.twitch.tv/gql',data=json.dumps({'query':query,'variables':variables or {}}).encode(),headers=headers)
 try:
  with urllib.request.urlopen(req,timeout=12) as r:raw=r.read(2*1024*1024+1)
  if len(raw)>2*1024*1024:raise ValueError('response too large')
  data=json.loads(raw)
 except (OSError,ValueError):raise ValueError('Twitch is temporarily unavailable. Your saved channels remain available.') from None
 if data.get('errors'):raise ValueError('Twitch is signed in but did not authorize this account view. Public discovery, saved channels and playback are still available.' if private else 'The Twitch website interface changed or denied this view. Public channel playback is still available.')
 return data.get('data') or {}

def row(user):
 login=identity(user['login']);stream=user.get('stream') or {};game=stream.get('game') or {}
 return {'id':login,'kind':'twitch','uri':'twitch:'+login,'title':stream.get('title') or user.get('displayName') or login,'artist':user.get('displayName') or login,'album':game.get('name') or 'Twitch','art':user.get('profileImageURL') or '', 'duration':0,'live':bool(stream),'viewers':stream.get('viewersCount',0),'url':'https://www.twitch.tv/'+login}

def browse(kind,query=''):
 key=kind+'-'+str(query)[:100];path=CACHE/( __import__('hashlib').sha256(key.encode()).hexdigest()+'.json')
 if kind=='following':
  data=gql('query { currentUser { login follows(first: 50) { edges { node { '+USER_FIELDS+' } } } } }',private=True)
  current=data.get('currentUser') or {};users=[e['node'] for e in (current.get('follows') or {}).get('edges',[])];warning='Your followed channels · first 50 · live channels first'
 elif kind=='search':
  if len(query.strip())<2:raise ValueError('Enter a channel, topic or Twitch URL')
  if query.startswith('https://') or re.fullmatch(r'videos/[0-9]+',query):
   ident=identity(query)
   if ident.startswith('videos/'):return {'rows':[{'id':ident,'kind':'twitch','title':'Twitch recording','artist':'Twitch','art':'','duration':0,'url':'https://www.twitch.tv/'+ident}],'warning':'Recording ready to open'}
   data=gql('query($name: String!) { user(login: $name) { '+USER_FIELDS+' } }',{'name':ident});users=[data['user']] if data.get('user') else []
  else:
   data=gql('query($q: String!) { searchFor(userQuery: $q, platform: "web") { channels { edges { item { ... on User { '+USER_FIELDS+' } } } } } }',{'q':query[:150]})
   users=[e['item'] for e in ((data.get('searchFor') or {}).get('channels') or {}).get('edges',[])];
  warning='Channel search · choose a live channel or paste a recording URL'
 elif kind=='discover':
  data=gql('query { streams(first: 24) { edges { node { title viewersCount broadcaster { '+USER_FIELDS+' } } } } }')
  users=[e['node']['broadcaster'] for e in (data.get('streams') or {}).get('edges',[])];warning='Live now · refresh on demand'
 else:raise ValueError('Unknown Twitch view')
 rows=[]
 for user in users[:50]:
  try:rows.append(row(user))
  except (ValueError,KeyError,TypeError):continue
 if kind=='following':rows.sort(key=lambda r:(not r['live'],-r['viewers']))
 result={'rows':rows,'warning':warning};atomic(path,result);return result

def stream(value,quality=720,authenticated=False):
 ident=identity(value)
 if quality not in (360,480,720,1080):raise ValueError('Invalid video quality')
 options=['--cookies-from-browser','chrome+gnomekeyring:'+browser_account()['profile']] if authenticated else []
 try:
  r=subprocess.run(['yt-dlp','--ignore-config','--no-warnings','--socket-timeout','8','--retries','0']+options+['--no-playlist','--dump-single-json','--skip-download','-f',f'best[height<={quality}]/best','https://www.twitch.tv/'+ident],capture_output=True,text=True,timeout=35)
  if r.returncode or len(r.stdout)>8*1024*1024:raise ValueError('unavailable')
  d=json.loads(r.stdout)
 except (OSError,ValueError,subprocess.TimeoutExpired):raise ValueError('This Twitch stream is offline, restricted or temporarily unavailable. Refresh or choose another channel.') from None
 url=d.get('url','');p=urllib.parse.urlsplit(url);host=p.hostname or ''
 if p.scheme!='https' or not any(host==h or host.endswith('.'+h) for h in ('ttvnw.net','twitch.tv','twitchcdn.net','cloudfront.net')):raise ValueError('Twitch returned an unsupported stream host')
 track={'id':ident,'kind':'twitch','uri':'twitch:'+ident,'title':d.get('title') or ident,'artist':d.get('uploader') or ident,'album':'Twitch live' if d.get('is_live') else 'Twitch recording','art':(d.get('thumbnail') or '').replace('-0x0.', '-640x360.'), 'duration':round(float(d.get('duration') or 0)*1000),'live':bool(d.get('is_live')),'url':'https://www.twitch.tv/'+ident}
 return {'track':track,'stream':url,'video':url,'combined':True,'chapters':[],'captionLanguages':[]}

def saved(item=None,remove=False):
 try:rows=json.loads(LIBRARY.read_text()).get('rows',[])
 except (OSError,ValueError):rows=[]
 if item is None:return {'rows':rows,'warning':'Local saved channels and recordings'}
 ident=identity(item.get('id',''));rows=[r for r in rows if r.get('id')!=ident]
 if not remove:rows.insert(0,{'id':ident,'kind':'twitch','uri':'twitch:'+ident,'title':str(item.get('title',ident))[:400],'artist':str(item.get('artist',ident))[:200],'art':str(item.get('art',''))[:1000],'url':'https://www.twitch.tv/'+ident,'duration':0})
 atomic(LIBRARY,{'rows':rows[:1000]});return {'ok':True}

def dispatch(args):
 name=args[0]
 if name=='twitch-account':return account_status()
 if name=='twitch-watch':return stream(args[1],int(args[2]) if len(args)>2 else 720,'private' in args[3:])
 if name=='twitch-browse':return browse(args[1],args[2] if len(args)>2 else '')
 if name=='twitch-saved':return saved()
 if name=='twitch-save':return saved(json.loads(args[1]))
 if name=='twitch-remove':return saved({'id':args[1]},True)
 raise ValueError('Unknown Twitch action')
