"""Explicit playback backend. Never retry or transfer ownership on failure."""
import json
import os
from pathlib import Path
import subprocess
import time

PLAYER = 'org.mpris.MediaPlayer2.Player'
BUS = 'org.mpris.MediaPlayer2.spotify'
PATH = '/org/mpris/MediaPlayer2'

class OfficialPlayer:
    def __init__(self):
        from gi.repository import Gio, GLib
        self.GLib = GLib
        self.bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    def call(self, interface, method, signature=None, args=()):
        value = self.GLib.Variant(signature, args) if signature else None
        return self.bus.call_sync(BUS, PATH, interface, method, value, None, 0, 2500, None).unpack()
    def properties(self):
        return self.call('org.freedesktop.DBus.Properties', 'GetAll', '(s)', (PLAYER,))[0]
    def set(self, name, signature, value):
        return self.call('org.freedesktop.DBus.Properties', 'Set', '(ssv)',
                         (PLAYER, name, self.GLib.Variant(signature, value)))
    def status(self):
        p = self.properties(); m = p.get('Metadata', {})
        return {'ready':True, 'backend':'official', 'owner':'official-client', 'localReleased':False,
                'playing':p.get('PlaybackStatus') == 'Playing', 'loading':False,
                'volume':round(p.get('Volume',0)*100), 'progress':p.get('Position',0)//1000,
                'shuffle':p.get('Shuffle',False), 'repeat':{'None':'off','Track':'track','Playlist':'context'}.get(p.get('LoopStatus'),'off'),
                'eventTime':time.time()*1000, 'eventUri':m.get('xesam:url',''),
                'track':{'title':m.get('xesam:title','Spotify'), 'artist':', '.join(m.get('xesam:artist',[])),
                         'album':m.get('xesam:album',''), 'art':m.get('mpris:artUrl',''),
                         'uri':m.get('xesam:url',''), 'duration':m.get('mpris:length',0)//1000},
                'capabilities':{k:p.get(k,False) for k in ('CanControl','CanPlay','CanPause','CanGoNext','CanGoPrevious','CanSeek')}}
    def action(self, name, args):
        p=self.properties()
        if not p.get('CanControl',False):raise ValueError('Spotify is not accepting controls. Open the official client.')
        methods={'play':('Play','CanPlay'),'pause':('Pause','CanPause'),'toggle':('PlayPause','CanPause'),
                 'next':('Next','CanGoNext'),'previous':('Previous','CanGoPrevious')}
        if name in methods:
            if name=='toggle':name='pause' if p.get('PlaybackStatus')=='Playing' else 'play'
            method,cap=methods[name]
            if not p.get(cap,False):raise ValueError('This playback device does not support '+name)
            self.call(PLAYER,method)
        elif name=='volume':self.set('Volume','d',max(0,min(100,float(args[0])))/100)
        elif name=='shuffle':self.set('Shuffle','b',not p.get('Shuffle',False))
        elif name=='repeat':
            values=['None','Playlist','Track'];self.set('LoopStatus','s',values[(values.index(p.get('LoopStatus','None'))+1)%3])
        elif name in ('seek','seek-to'):
            if not p.get('CanSeek'):raise ValueError('This device cannot seek')
            if name=='seek':self.call(PLAYER,'Seek','(x)',(int(float(args[0])*1000),))
            else:
                track=p.get('Metadata',{}).get('mpris:trackid')
                if not track:raise ValueError('The current track identity is unavailable')
                self.call(PLAYER,'SetPosition','(ox)',(track,int(float(args[0])*1000)))
        elif name in ('play-track','play-context'):
            uri=('spotify:track:'+args[0]) if name=='play-track' else 'spotify:'+args[0]+':'+args[1]
            self.call(PLAYER,'OpenUri','(s)',(uri,))
        else:raise ValueError('Open this selection in Spotify; the official backend does not expose this queue operation.')
        return {'ok':True,'backend':'official'}

def settings_path():return Path.home()/'.config/sensei-den/music.json'
def selection():
    try:
        value=json.loads(settings_path().read_text()).get('backend','native')
        if value not in ('native','official'):raise ValueError('Invalid music backend; configuration preserved')
        return value
    except FileNotFoundError:return 'native'
def select(value):
    if value not in ('native','official'):raise ValueError('Choose native or official')
    p=settings_path();p.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    temp=p.with_name(p.name+'.'+str(os.getpid())+'.tmp')
    with temp.open('w') as f:
        os.chmod(temp,0o600);json.dump({'backend':value},f)
    temp.replace(p)
    return {'ok':True,'backend':value}
def main(args):
    args=args or ['status']
    name=args[0]
    if name=='backend':return select(args[1]) if len(args)>1 else {'backend':selection()}
    if name=='autostart' and selection()!='official':return {'ok':True,'skipped':True}
    if name in ('launch','autostart'):
        installed=Path(os.environ.get('XDG_DATA_HOME',str(Path.home()/'.local/share')))/'spotify-launcher/install/usr/bin/spotify'
        subprocess.Popen(['spotify-launcher']+(['--skip-update'] if name=='autostart' and installed.exists() else []),stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
        return {'ok':True}
    backend=selection()
    if backend=='official':return OfficialPlayer().status() if name=='status' else OfficialPlayer().action(name,args[1:])
    # Exactly one native invocation, including uncertain command failures.
    result=subprocess.run([str(Path.home()/'.local/bin/sensei-spotify-transport'),*args],capture_output=True,text=True,timeout=15)
    value=json.loads(result.stdout)
    if name=='status':value.update(backend='native',owner='external' if value.get('localReleased') else 'native-client')
    return value
