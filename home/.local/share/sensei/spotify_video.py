"""Explicit music-video discovery and compact silent previews; never takes music ownership."""
import hashlib,json,os,re,shutil,subprocess,time,urllib.parse
from pathlib import Path
CACHE=Path.home()/'.cache/sensei-spotify/videos'
def query(track):
 return (' '.join(str(track.get(k,'')).strip() for k in ('artist','title'))+' official music video').strip()[:450]
def candidates(track,refresh=False):
 q=query(track);key=hashlib.sha256(q.encode()).hexdigest();path=CACHE/(key+'.json')
 old={}
 try:old=json.loads(path.read_text())
 except (OSError,ValueError):pass
 if old and not refresh and time.time()-path.stat().st_mtime<86400:return old
 if not shutil.which('yt-dlp'):return {'rows':[],'warning':'Install yt-dlp, or use Open YouTube search.','query':q}
 try:
  from youtube_music import run
  d=run(['--flat-playlist','--dump-single-json','--playlist-end','5','ytsearch5:'+q]);rows=[]
  for item in d.get('entries',[])[:5]:
   vid=item.get('id','')
   if not re.fullmatch(r'[A-Za-z0-9_-]{11}',vid):continue
   rows.append({'id':vid,'title':item.get('title','Video'),'channel':item.get('channel') or item.get('uploader') or '', 'duration':item.get('duration') or 0,'url':'https://www.youtube.com/watch?v='+vid})
  result={'rows':rows,'query':q,'warning':'Search candidates · confirm the artist and recording before opening.' if rows else 'No candidates found. Open YouTube search to look manually.'}
  if rows:
   CACHE.mkdir(parents=True,exist_ok=True,mode=0o700);temp=path.with_name(path.name+'.'+str(os.getpid())+'.tmp')
   with temp.open('w') as f:os.chmod(temp,0o600);json.dump(result,f)
   temp.replace(path)
  return result
 except (OSError,ValueError,subprocess.TimeoutExpired):
  return dict(old,warning='Video search is unavailable; showing saved candidates.') if old else {'rows':[],'query':q,'warning':'Video search is unavailable. Open YouTube search instead; music keeps playing.'}
def resolve(vid):
 if not re.fullmatch(r'[A-Za-z0-9_-]{11}',vid):raise ValueError('Invalid video identity')
 try:
  from youtube_music import run
  resolved=run(['--no-playlist','--dump-single-json','--skip-download','-f','best[ext=mp4][vcodec^=avc1][height<=720]/bestvideo[ext=mp4][vcodec^=avc1][height<=720]','https://www.youtube.com/watch?v='+vid])
  stream=resolved.get('url','')
  host=urllib.parse.urlsplit(stream).hostname or ''
  if not stream.startswith('https://') or not (host.endswith('.googlevideo.com') or host in ('youtube.com','www.youtube.com')):raise ValueError('Video unavailable')
 except (OSError,ValueError,subprocess.TimeoutExpired):return {'ok':False,'warning':'Video streaming is unavailable. Use YouTube search; Spotify keeps playing.'}
 return {'ok':True,'stream':stream}

def launch(vid):
 result=resolve(vid)
 if not result.get('ok'):return result
 if not shutil.which('mpv'):raise ValueError('Install mpv to preview videos.')
 stream=result['stream']
 directory=Path.home()/'.local/state/sensei-spotify';directory.mkdir(parents=True,exist_ok=True,mode=0o700)
 with (directory/'video-preview.log').open('w') as log:
  os.chmod(log.name,0o600)
  subprocess.Popen(['mpv','--no-audio','--force-window=immediate','--autofit=800x450','--title=Den · Music video preview','--wayland-app-id=sensei-music-video','--ytdl-format=best[ext=mp4][vcodec^=avc1][height<=720]/bestvideo[ext=mp4][vcodec^=avc1][height<=720]',stream],stdout=log,stderr=log,start_new_session=True)
 return {'ok':True,'warning':'Silent video preview opened · Spotify keeps the soundtrack. Video timing may differ.'}
def browser(track):
 subprocess.Popen(['xdg-open','https://www.youtube.com/results?'+urllib.parse.urlencode({'search_query':query(track)})],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
 return {'ok':True}
