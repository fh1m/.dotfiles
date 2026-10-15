#!/usr/bin/env python3
"""Cursor locator/recovery independent of input sharing. No keystroke recording."""
import json,os,pathlib,selectors,signal,socket,subprocess,sys,time,tomllib,ctypes,concurrent.futures
sys.path.insert(0,str(pathlib.Path.home()/'.local/share/sensei'))
from den_layout import roles as display_roles
ROOT=pathlib.Path.home()/'.local/state/homie-control'
SOCK=ROOT/'cursor.sock'
QS=str(pathlib.Path.home()/'.local/opt/sensei-quickshell/bin/qs')
def hypr(*args):return subprocess.check_output(['hyprctl','-i','0',*args],timeout=3)
def remote(command):return subprocess.check_output(['ssh','-F',str(ROOT/'client.conf'),'homie',command],timeout=4)
def pulse(peer=False):
    if peer:
        remote('python3 /home/fh1m/.local/state/homie-control/den-cursor.py show-local');return
    monitors=json.loads(hypr('monitors','-j'));pos=json.loads(hypr('cursorpos','-j'))
    for m in monitors:
        w,h=m['width']/m['scale'],m['height']/m['scale']
        if m['x']<=pos['x']<m['x']+w and m['y']<=pos['y']<m['y']+h:
            subprocess.run([QS,'-p',str(ROOT/'cursor-ui'),'ipc','call','den-cursor','pulse',m['name'],str(pos['x']-m['x']),str(pos['y']-m['y'])],check=True,timeout=3);return

def recover(manual=True):
    if manual:(ROOT/'input/user-paused').write_text('1')
    # Stop the master capture completely before moving the cursor. Independent of a peer reply.
    subprocess.run(['systemctl','--user','stop','den-input'],check=True,timeout=5)
    (ROOT/'input/active').write_text('0')
    monitors=json.loads(hypr('monitors','-j'));m=display_roles(monitors).get('main',monitors[0]);x=round(m['x']+m['width']/m['scale']/2);y=round(m['y']+m['height']/m['scale']/2)
    hypr('dispatch','hl.dsp.focus({monitor='+json.dumps(m['name'])+'})')
    hypr('dispatch',f'hl.dsp.cursor.move({{x={x},y={y}}})')
    hypr('setcursor','Sensei-Signal','24')
    pulse()  # Recovery deliberately leaves sharing stopped; never recapture after escape.

def daemon():
    try:SOCK.unlink()
    except FileNotFoundError:pass
    server=socket.socket(socket.AF_UNIX,socket.SOCK_DGRAM);server.bind(str(SOCK));os.chmod(SOCK,0o600)
    binary=QS if pathlib.Path(QS).exists() else '/usr/bin/qs'
    gui=subprocess.Popen([binary,'-p',str(ROOT/'cursor-ui'),'--no-duplicate'])
    selector=selectors.DefaultSelector();selector.register(server,selectors.EVENT_READ,'request')
    gui_pidfd=os.pidfd_open(gui.pid);selector.register(gui_pidfd,selectors.EVENT_READ,'gui-exit')
    ipc=None
    pool=concurrent.futures.ThreadPoolExecutor(max_workers=2)
    master=bool(tomllib.loads((ROOT/'input/config.toml').read_text()).get('clients'))
    peer_owned=False
    previous_owner=None
    return_armed=False
    return_monitor=None
    libc=ctypes.CDLL(None)
    watch=libc.inotify_init1(os.O_NONBLOCK|os.O_CLOEXEC)
    libc.inotify_add_watch(watch,os.fsencode(ROOT/'input'),8)
    selector.register(watch,selectors.EVENT_READ,'state')
    def gui_focus(name):
        subprocess.run([binary,'-p',str(ROOT/'cursor-ui'),'ipc','call','den-cursor','focus',name],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=2)
    def remote_owner(owned):
        try:remote('python3 /home/fh1m/.local/state/homie-control/den-cursor.py '+('owner-on' if owned else 'owner-off'))
        except (OSError,subprocess.SubprocessError):pass
    def refresh_focus():
        nonlocal previous_owner, return_armed, return_monitor
        monitors=json.loads(hypr('monitors','-j'))
        if master:
            try:owned=(ROOT/'input/active').read_text().strip()=='1'
            except OSError:owned=False
            gui_focus('' if owned else next((m['name'] for m in monitors if m.get('focused')),''))
            if previous_owner!=owned:pool.submit(remote_owner,owned);previous_owner=owned
        else:
            gui_focus(next((m['name'] for m in monitors if m.get('focused')),'') if peer_owned else '')
            try:return_armed=(ROOT/'input/return-armed').read_text().strip()=='1'
            except OSError:return_armed=False
            return_monitor=display_roles(monitors).get('main')

    def install():
        if not tomllib.loads((ROOT/"input/config.toml").read_text()).get("clients"):return
        hypr('eval','dofile('+json.dumps(str(ROOT/'den-ctrl.lua'))+')')
    install()
    instance=json.loads(hypr('instances','-j'))[0]
    path=pathlib.Path(os.environ['XDG_RUNTIME_DIR'])/'hypr'/instance['instance']/'.socket2.sock'
    ipc=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM);ipc.connect(str(path));selector.register(ipc,selectors.EVENT_READ,'hypr');buffer=b''
    time.sleep(.2)
    refresh_focus()
    try:
        while True:
            if gui.poll() is not None:raise RuntimeError('Cursor UI stopped')
            # No polling while idle. During remote ownership, query cursor position
            # through a short local Unix IPC request: no per-frame subprocess/rendering.
            if return_armed and return_monitor:
                q=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM);q.settimeout(.2)
                try:
                    q.connect(str(path.with_name('.socket.sock')));q.sendall(b'j/cursorpos')
                    chunks=[]
                    while True:
                        chunk=q.recv(4096)
                        if not chunk:break
                        chunks.append(chunk)
                    pos=json.loads(b''.join(chunks));m=return_monitor
                    bottom=m['y']+m['height']/m['scale']-1
                    edge=1 if pos['y']>=bottom else (2 if pos['x']<=m['x'] else 0)
                    if edge:
                        return_armed=False
                        subprocess.run([str(ROOT/'bin/lan-mouse'),'cli','return-edge',str(edge)],timeout=1,check=True,stdout=subprocess.DEVNULL)
                except (OSError,ValueError,subprocess.SubprocessError):pass
                finally:q.close()
            for key,_ in selector.select(.04 if return_armed else None):
                if key.data=='gui-exit':raise RuntimeError('Cursor UI stopped')
                if key.data=='state':
                    os.read(watch,8192);refresh_focus();continue
                if key.data=='hypr':
                    data=ipc.recv(8192)
                    if not data:return
                    buffer+=data
                    while b'\n' in buffer:
                        line,buffer=buffer.split(b'\n',1)
                        if line.startswith(b'configreloaded'):install()
                        if line.startswith((b'focusedmon',b'monitoradded',b'monitorremoved')):refresh_focus()
                    continue
                action=server.recv(128).decode()
                try:
                    if action in ('owner-on','owner-off'):peer_owned=(action=='owner-on');refresh_focus()
                    elif action in ('recover','peer-lost'):recover(manual=action=='recover');refresh_focus()
                    elif action=='show-local':pulse()
                    elif action=='show':
                        try:peer=(ROOT/'input/active').read_text().strip()=='1'
                        except OSError:peer=False
                        if peer:pool.submit(pulse,True)
                        else:pulse()
                except (subprocess.SubprocessError,OSError,ValueError):
                    # Recovery remains local even if the PC is offline.
                    if action=='show':pulse()
    finally:
        gui.terminate();server.close();os.close(gui_pidfd);os.close(watch);pool.shutdown(wait=False,cancel_futures=True);SOCK.unlink(missing_ok=True)
        try:hypr('eval','if _G.den_ctrl_subscription then _G.den_ctrl_subscription:remove(); _G.den_ctrl_subscription=nil end')
        except (OSError,subprocess.SubprocessError):pass

if __name__=='__main__':
    def stop(signum,frame):raise SystemExit(0)
    signal.signal(signal.SIGTERM,stop)
    action=sys.argv[1]
    if action=='daemon':daemon()
    else:
        s=socket.socket(socket.AF_UNIX,socket.SOCK_DGRAM);s.sendto(action.encode(),str(SOCK))
