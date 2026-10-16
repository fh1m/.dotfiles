"""Desktop-owned catalogue, independent of the developer Web API quota."""
import hashlib,json,os,re,time
from pathlib import Path
from spotify_bridge import request
STORE=Path.home()/'.cache/sensei-spotify/desktop'
READS={'home','library','context','more','search','queue','devices'}
WRITES={'queue-add','like','unlike','playlist-add','playlist-create','enqueue','connect','liked-play'}

def dispatch(args):
    name=args[0];op=name;values=args[1:];extra={}
    if name=='account':
        from spotify_control import OfficialPlayer
        try:ready=OfficialPlayer().status()['ready']
        except Exception:ready=False
        try:bridge=request('probe')
        except Exception:bridge={'error':'Desktop bridge unavailable'}
        return {'backend':'official','service':'connected' if bridge.get('connected') else bridge.get('error','disconnected'),'cachedLogin':ready,'version':bridge.get('version',''),'deviceName':'Spotify desktop','catalogue':'desktop session'}
    if name=='home':op='library';values=['recent']
    if name=='library':values=values[:1]
    if name=='context':values=values[:2]
    if name=='more':
        match=re.fullmatch(r'desktop:(liked|albums|artists):(\d+)',values[0])
        context=re.fullmatch(r'desktop:context:(playlist|album|artist):([A-Za-z0-9]{1,64}):(\d+)',values[0])
        if match:op='library';values=[match[1],int(match[2])]
        elif context:op='context';values=[context[1],context[2],int(context[3])]
        else:raise ValueError('Invalid desktop pagination token; refresh the current view')
        extra={'target':args[3] if len(args)>3 else 'library','contextId':args[4] if len(args)>4 else ''}
    if name not in READS:
        result=request(op,values)
        if not result.get('error'):
            for path in STORE.glob('*.json'):
                try:
                    record=json.loads(path.read_text());record['at']=0
                    temporary=path.with_name(path.name+'.'+str(os.getpid())+'.tmp')
                    with temporary.open('w') as file:os.chmod(temporary,0o600);json.dump(record,file)
                    temporary.replace(path)
                except (OSError,ValueError):pass
        return result
    key=hashlib.sha256(json.dumps([op,values],sort_keys=True).encode()).hexdigest();path=STORE/(key+'.json')
    cached=None
    try:cached=json.loads(path.read_text())
    except (FileNotFoundError,ValueError):pass
    ttl=2 if name in ('queue','devices') else 300
    force=args[-1:] == ['refresh']
    if cached and not force and time.time()-cached.get('at',0)<ttl:return {**cached['data'],**extra}
    try:
        result=request(op,values)
        if 'error' in result:raise ValueError(result['error'])
    except Exception as error:
        message=str(error) if isinstance(error,ValueError) else 'Spotify desktop is unavailable. Open Spotify and reconnect the local bridge.'
        if cached:return {**cached['data'],**extra,'warning':message+' Showing saved desktop data.','stale':True}
        return {'error':message}
    STORE.mkdir(parents=True,exist_ok=True,mode=0o700)
    temporary=path.with_name(path.name+'.'+str(os.getpid())+'.tmp')
    with temporary.open('w') as file:
        os.chmod(temporary,0o600);json.dump({'at':time.time(),'data':result},file)
    temporary.replace(path)
    return {**result,**extra}
