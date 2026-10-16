#!/usr/bin/env python3
"""Supervised Spotify widget acceptance; changes playback and the visible music page.

Requires an official desktop session with at least 200 liked songs and a nonempty
first playlist, matching the reference account. No library writes are performed.
"""
def main():
 import argparse
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--live',action='store_true',help='Allow music selection and UI actions')
 args=parser.parse_args()
 if not args.live:parser.error('Use --live only when playback may be changed')
 import json,subprocess,time,sys
 from pathlib import Path
 sys.path.insert(0,str(Path.home()/'.local/share/sensei'))
 from spotify_bridge import request
 from spotify_control import OfficialPlayer,canonical_uri
 
 def ipc(*args):return subprocess.check_output(['qs','ipc','--any-display','-c','sensei','call','spotify',*args],text=True).strip()
 def state():return json.loads(ipc('state'))
 def wait(test):
  for _ in range(60):
   s=state()
   if test(s):return s
   time.sleep(.15)
  raise RuntimeError('Widget acceptance timed out: '+json.dumps({k:s[k] for k in ['page','loading','error','rows','contextRows']}))
 checks={}
 ipc('page','2');s=wait(lambda s:s['playlists']>0 and not s['loading']);checks['playlists']=s['playlists']
 ipc('library','liked');s=wait(lambda s:s['page']==3 and s['library']>=100 and not s['loading']);checks['likedFirstPage']=s['library']
 ipc('more');s=wait(lambda s:s['library']>=200 and not s['loading']);checks['likedAfterLoadMore']=s['library']
 liked=request('library',['liked'])['rows'];target=liked[0]['uri'];ipc('playRow','0')
 for _ in range(40):
  s=OfficialPlayer().status()
  if s['track']['uri']==target and s['playing']:break
  time.sleep(.2)
 checks['likedRowPlaysSelectedSong']=s['track']['uri']==target and s['playing']
 playlist=request('library',['playlists'])['rows'][0];items=request('context',['playlist',playlist['id']])['rows'];ipc('browse','playlist',playlist['id']);s=wait(lambda s:s['contextRows']==len(items) and not s['loading']);checks['playlistContents']=s['contextRows']
 index=min(2,len(items)-1);target=items[index]['uri'];ipc('playRow',str(index))
 for _ in range(40):
  s=OfficialPlayer().status()
  if s['track']['uri']==target and s['playing']:break
  time.sleep(.2)
 checks['playlistRowPlaysSelectedSong']=s['track']['uri']==target and s['playing']
 ipc('search','Daft Punk');s=wait(lambda s:s['page']==4 and s['rows']>0 and not s['loading']);checks['searchTracks']=s['rows']
 ipc('page','1');s=wait(lambda s:s['queue']>0 and not s['loading']);checks['queue']=s['queue']
 ipc('page','0');print(json.dumps(checks));assert all(checks.values()),checks

if __name__=='__main__':main()
