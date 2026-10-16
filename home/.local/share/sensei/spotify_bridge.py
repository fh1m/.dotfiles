"""Private loopback relay to a narrow Spicetify extension; no Spotify tokens."""
import hmac,json,queue,secrets,threading,time
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
from pathlib import Path
from urllib.request import Request,HTTPRedirectHandler,build_opener
CONFIG=Path.home()/'.config/sensei-den/spotify-bridge.json'
ALLOWED={'probe','library','context','search','queue','devices','play-list','play-context-track','queue-add','like','unlike','playlist-add','playlist-create','enqueue','connect','liked-play'}

class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self,*args,**kwargs):return None

def config():return json.loads(CONFIG.read_text())
def request(operation,args=()):
    if operation not in ALLOWED:raise ValueError('Unsupported desktop operation')
    cfg=config();data=json.dumps({'operation':operation,'args':list(args)}).encode()
    req=Request('http://127.0.0.1:'+str(cfg['port'])+'/request',data=data,headers={'Authorization':'Bearer '+cfg['secret'],'Content-Type':'application/json'})
    with build_opener(NoRedirect).open(req,timeout=25) as r:return json.load(r)

def create_server(cfg):
    cfg=dict(cfg);commands=queue.Queue(maxsize=8);pending={};lock=threading.Lock();poll_lock=threading.Lock();last_seen=[0]
    class Handler(BaseHTTPRequestHandler):
        def log_message(self,*a):pass
        def respond(self,code,value):
            data=json.dumps(value).encode();self.send_response(code)
            self.send_header('Content-Type','application/json');self.send_header('Cache-Control','no-store')
            origin=self.headers.get('Origin','')
            if origin in ('https://xpui.app.spotify.com','https://xpui.app.spotify.com:443'):self.send_header('Access-Control-Allow-Origin',origin)
            self.send_header('Access-Control-Allow-Headers','Authorization,Content-Type');self.send_header('Access-Control-Allow-Methods','POST,OPTIONS')
            self.send_header('Content-Length',str(len(data)));self.end_headers()
            try:self.wfile.write(data)
            except (BrokenPipeError,ConnectionResetError):pass
        def do_OPTIONS(self):self.respond(200,{})
        def do_POST(self):
            if self.headers.get('Host')!='127.0.0.1:'+str(cfg['port']):return self.respond(403,{'error':'Invalid host'})
            if not hmac.compare_digest(self.headers.get('Authorization',''),'Bearer '+cfg['secret']):return self.respond(403,{'error':'Unauthorized'})
            try:
                size=int(self.headers.get('Content-Length','0'))
                if not 0<=size<=8*1024*1024:return self.respond(413,{'error':'Response too large'})
                body=json.loads(self.rfile.read(size) or b'{}')
                if not isinstance(body,dict):return self.respond(400,{'error':'Expected a JSON object'})
                if self.path=='/poll':
                    if not poll_lock.acquire(blocking=False):return self.respond(409,{'error':'Desktop already connected'})
                    try:
                        last_seen[0]=time.monotonic()
                        try:command=commands.get(timeout=18)
                        except queue.Empty:command={}
                        with lock:valid=command and command.get('id') in pending
                        if command and (not valid or time.monotonic()-command.pop('_created',0)>20):command={}
                        return self.respond(200,command)
                    finally:poll_lock.release()
                if self.path=='/result':
                    with lock:entry=pending.get(body.get('id'))
                    if entry:
                        try:entry.put_nowait(body.get('result',{'error':'Empty desktop response'}))
                        except queue.Full:pass
                    return self.respond(200,{'ok':True})
                if self.path=='/request':
                    op=body.get('operation')
                    if op not in ALLOWED:return self.respond(400,{'error':'Unsupported operation'})
                    if time.monotonic()-last_seen[0]>25:return self.respond(200,{'error':'Spotify desktop bridge is disconnected. Open Spotify or repair the bridge from Account.'})
                    ident=secrets.token_hex(12);reply=queue.Queue(maxsize=1)
                    with lock:pending[ident]=reply
                    try:
                        commands.put_nowait({'id':ident,'operation':op,'args':body.get('args',[]),'_created':time.monotonic()})
                        try:result=reply.get(timeout=22)
                        except queue.Empty:result={'error':'Desktop request timed out; it was not retried.'}
                        return self.respond(200,result)
                    except queue.Full:return self.respond(200,{'error':'Desktop bridge busy; try again.'})
                    finally:
                        with lock:pending.pop(ident,None)
                return self.respond(404,{'error':'Unknown route'})
            except (ValueError,TypeError):return self.respond(400,{'error':'Invalid bridge request'})
    server=ThreadingHTTPServer(('127.0.0.1',cfg['port']),Handler);server.daemon_threads=True;cfg['port']=server.server_port
    return server

def serve():create_server(config()).serve_forever()

if __name__=='__main__':serve()
