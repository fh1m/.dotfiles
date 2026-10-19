"""Bounded lyrics lookup with local overrides, conservative matching and stale fallback."""
import hashlib,json,os,re,time,unicodedata,urllib.request,urllib.parse,urllib.error
from pathlib import Path
from difflib import SequenceMatcher
CACHE=Path.home()/'.cache/sensei-spotify/lyrics-v2'
LOCAL=Path.home()/'.local/share/sensei-spotify/lyrics'

def identity(track):
 return hashlib.sha256((str(track.get('title','')).strip()+'|'+str(track.get('artist','')).split(',')[0].strip()+'|'+str(round(float(track.get('duration') or 0)/1000))).encode()).hexdigest()
def atomic(path,data):
 path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
 temp=path.with_name(path.name+'.'+str(os.getpid())+'.tmp')
 with temp.open('w') as f:os.chmod(temp,0o600);json.dump(data,f,ensure_ascii=False)
 temp.replace(path)
def normalized(value):
 return ' '.join(re.findall(r'\w+',unicodedata.normalize('NFKC',str(value)).casefold()))
def clean_title(value):
 return re.sub(r'\s*[-–]\s*(?:\d{4}\s*)?(?:remaster(?:ed)?|radio edit).*$','',re.sub(r'\s*[\[(](?:feat\.?|ft\.?|remaster(?:ed)?)[^\])]*[\])]','',value,flags=re.I),flags=re.I).strip()
def parse(data,provider='LRCLIB'):
 if not isinstance(data,dict):data={}
 raw=data.get('syncedLyrics') or '';raw=raw if isinstance(raw,str) else '';lines=[]
 offset=re.search(r'\[offset:([+-]?\d+)\]',raw);shift=int(offset.group(1)) if offset else 0
 for line in raw.splitlines():
  words=re.sub(r'\[[^]]*\]','',line).strip()
  for minute,second in re.findall(r'\[(\d+):(\d+(?:\.\d+)?)\]',line):
   lines.append({'time':max(0,round((int(minute)*60+float(second))*1000)+shift),'text':words})
 lines.sort(key=lambda v:v['time'])
 return {'lines':lines,'plain':data.get('plainLyrics') or '', 'synced':bool(lines),'instrumental':bool(data.get('instrumental')),'provider':provider,'notice':'Instrumental · no sung lyrics' if data.get('instrumental') else ''}
def fetch(url):
 req=urllib.request.Request(url,headers={'User-Agent':'SenseiDen/2.0 (personal lyrics viewer)','Accept':'application/json'})
 try:
  with urllib.request.urlopen(req,timeout=6) as response:
   data=response.read(2*1024*1024+1)
   if len(data)>2*1024*1024:raise ValueError('Lyrics response too large')
   return json.loads(data)
 except urllib.error.HTTPError as ex:
  if ex.code==404:return None
  raise

def choose(items,title,artist,duration):
 matches=[]
 for item in items if isinstance(items,list) else []:
  if not isinstance(item,dict):continue
  ts=SequenceMatcher(None,normalized(clean_title(title)),normalized(clean_title(item.get('trackName','')))).ratio()
  ar=SequenceMatcher(None,normalized(artist),normalized(item.get('artistName',''))).ratio()
  delta=abs(float(item.get('duration') or 0)-duration) if duration else 0
  if ts<.83 or ar<.6 or (duration and delta>max(8,duration*.04)):continue
  if item.get('syncedLyrics') or item.get('plainLyrics') or item.get('instrumental'):matches.append((ts+ar+(0.15 if item.get('syncedLyrics') else 0)-delta/100,item))
 return max(matches,key=lambda x:x[0])[1] if matches else None

def lookup(track,refresh=False):
 title=str(track.get('title','')).strip()[:250];artist=str(track.get('artist','')).split(',')[0].strip()[:200]
 empty={'lines':[],'plain':'','synced':False,'provider':'','notice':'Start a song to follow its lyrics.'}
 if not title or not artist:return empty
 key=identity(track);path=CACHE/(key+'.json');offset_path=LOCAL/(key+'.offset.json');offset=0
 try:offset=max(-60000,min(60000,int(json.loads(offset_path.read_text())['offset'])))
 except (OSError,ValueError,KeyError,TypeError):pass
 # Local files always win, including after a cached online hit.
 readable=re.sub(r'[/\\\x00-\x1f]','_',artist+' - '+title)[:180]
 for suffix in ('.lrc','.txt'):
  local=LOCAL/(key+suffix)
  if not local.is_file():local=LOCAL/(readable+suffix)
  if local.is_file():
   if local.stat().st_size>2*1024*1024:continue
   text=local.read_text(errors='replace');return dict(parse({'syncedLyrics':text if suffix=='.lrc' else '', 'plainLyrics':text},'Local'),offset=offset)
 saved={}
 try:saved=json.loads(path.read_text())
 except (OSError,ValueError):pass
 if not isinstance(saved,dict):saved={}
 positive=bool(saved.get('synced') or saved.get('plain') or saved.get('instrumental'))
 if saved and not refresh and time.time()-path.stat().st_mtime<(30*86400 if positive else 900):return dict(saved,offset=offset)
 duration=max(0,float(track.get('duration') or 0)/1000);data=None;unavailable=False
 for candidate in dict.fromkeys((title,clean_title(title))):
  params={'track_name':candidate,'artist_name':artist}
  if duration:params['duration']=round(duration)
  try:data=fetch('https://lrclib.net/api/get?'+urllib.parse.urlencode(params))
  except (OSError,ValueError,TimeoutError):unavailable=True;break
  if isinstance(data,dict) and (data.get('syncedLyrics') or data.get('plainLyrics') or data.get('instrumental')):break
  data=None
 if not data and not unavailable:
  try:data=choose(fetch('https://lrclib.net/api/search?'+urllib.parse.urlencode({'track_name':clean_title(title),'artist_name':artist})),title,artist,duration)
  except (OSError,ValueError,TimeoutError):unavailable=True
 if data:result=parse(data)
 else:
  # Independent plain-text fallback; never invent synchronized timestamps.
  try:
   other=fetch('https://api.lyrics.ovh/v1/'+urllib.parse.quote(artist,safe='')+'/'+urllib.parse.quote(clean_title(title),safe=''))
   result=parse({'plainLyrics':(other or {}).get('lyrics','')},'lyrics.ovh')
  except (OSError,ValueError,TimeoutError):result=dict(empty);unavailable=True
 if not (result['synced'] or result['plain'] or result.get('instrumental')):
  if positive:return dict(saved,offset=offset,notice='Saved lyrics · providers unavailable' if unavailable else 'Saved lyrics')
  result=dict(empty,notice='Lyrics providers are unavailable. Retry later or add a local lyric file.' if unavailable else 'No reliable lyrics matched this recording. Try Search or add a local lyric file.')
  # Temporary outages must not become a cached permanent miss.
  if unavailable:return dict(result,offset=offset)
 atomic(path,result);return dict(result,offset=offset)

def save_offset(track,value):
 offset=max(-60000,min(60000,int(value)));atomic(LOCAL/(identity(track)+'.offset.json'),{'offset':offset});return {'ok':True,'offset':offset}
def local_folder(track):
 LOCAL.mkdir(parents=True,exist_ok=True,mode=0o700)
 filename=re.sub(r'[/\\\x00-\x1f]','_',str(track.get('artist','')).split(',')[0].strip()+' - '+str(track.get('title','')).strip())[:180]+'.lrc'
 guide=LOCAL/'HOW-TO.txt'
 guide.write_text('Local lyrics override online results.\nSave UTF-8 .lrc (timed) or .txt (plain), using Artist - Title.\nFor the current song use: '+filename+'\nThen press Retry in the music widget.\nNo timestamps are invented for plain text.\n');guide.chmod(0o600)
 return {'folder':str(LOCAL),'filename':filename,'warning':'Local lyrics: save '+filename+' and press Retry.'}
