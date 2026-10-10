"""Machine-local host coordination; no learning mutations or tool relocation."""
import base64,json,os,subprocess,time,uuid
from pathlib import Path
from .persistence import lock

def process_start(pid):
    try:return Path(f'/proc/{int(pid)}/stat').read_text().rsplit(')',1)[1].split()[19]
    except (OSError,ValueError,IndexError):return None

def resolve_request(request):
    if not isinstance(request,dict) or request.get('version')!=1:raise ValueError('Unsupported host request version')
    uuid.UUID(request['request_id'])
    if request.get('action') not in ('open','resume','capture','start'):raise ValueError('Unsupported host action')
    result=dict(request)
    owner=request.get('owner')
    if not owner and request.get('action')=='capture':
        config=Path.home()/'.config/sensei-learning/config.json'
        value=json.loads(config.read_text()).get('active_vault') if config.exists() else None
        if not value:raise ValueError('Choose an owning learning vault before capture')
        from .scopes import identity
        owner={'vault_id':identity(Path(value)),'registered_location':value}
    if owner:
        from .collection import selected_roots
        from .scopes import identity,assert_unique
        if not isinstance(owner,dict):raise ValueError('Owner must include vault identity and registered location')
        root=Path(owner['registered_location']).expanduser().resolve()
        selected_roots([str(root)])
        expected=str(uuid.UUID(owner['vault_id']))
        if identity(root)!=expected:raise ValueError('Requested owner identity does not match its registered location')
        assert_unique(root)
        result['owner']={'vault_id':expected,'registered_location':str(root)}
        result['vault']=str(root)
        if request.get('record_id'):
            from .references import resolve
            result['record']=resolve({'vault_id':expected,'record_id':request['record_id']})
    elif request.get('record_id') or request.get('action')=='resume':
        raise ValueError('A record request requires its exact owner')
    return result

def executable(home):
    if os.environ.get('NOESIS_QS'):return os.environ['NOESIS_QS']
    preferred=Path(home)/'.local/opt/sensei-quickshell/bin/qs'
    return str(preferred) if preferred.exists() else 'qs'

def launch(home,*,embedded=False,owner=None,vault_id=None,record_id=None,capture=False,start=False):
    home=Path(home);qs=executable(home)
    config=(home/'.config/quickshell'/('wrayth' if embedded else 'noesis')).resolve()
    if not (config/'shell.qml').is_file():raise ValueError('Noesis host is not installed: '+str(config))
    state=home/'.local/state/sensei-learning';state.mkdir(parents=True,exist_ok=True);state.chmod(0o700)
    prefs=json.loads((state/'window.json').read_text()) if (state/'window.json').exists() else {}
    request={'version':1,'request_id':str(uuid.uuid4()),'action':'start' if start else 'capture' if capture else 'resume' if record_id else 'open'}
    if owner:
        from .scopes import identity
        request['owner']={'vault_id':vault_id or identity(Path(owner).expanduser().resolve()),'registered_location':str(Path(owner).expanduser().resolve())}
    if record_id:request['record_id']=record_id
    request=resolve_request(request)
    def ipc(target,method,*args):
        run=subprocess.run([qs,'-p',str(config),'ipc','call',target,method,*args],text=True,capture_output=True,timeout=5)
        if run.returncode:return None
        try:return json.loads(run.stdout)
        except ValueError:return None
    with lock(state/'host-launch'):
        hello=ipc('noesis','hello')
        if not embedded and not (hello and hello.get('host_ready',True)):
            primary=config;config=(home/'.config/quickshell/wrayth').resolve();rollback=ipc('noesis','hello')
            if rollback and rollback.get('version')==1 and rollback.get('host_ready') and rollback.get('host')=='embedded':hello=rollback;embedded=True
            else:config=primary
        if hello and hello.get('version')!=1:raise ValueError('Running Noesis host uses an incompatible protocol; close it after saving before upgrading')
        if hello and hello.get('exit_pending'):
            deadline=time.monotonic()+10
            while hello and hello.get('exit_pending') and time.monotonic()<deadline:
                time.sleep(.1);hello=ipc('noesis','hello')
            if hello and hello.get('exit_pending'):raise RuntimeError('Noesis is still finishing a save; inspect the existing window before reopening')
        if not hello:
            if embedded:raise ValueError('Embedded rollback host is not active; start Wrayth with NOESIS_HOST=embedded')
            child_environment=dict(os.environ)
            if os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'):
                monitors=json.loads(subprocess.check_output(['hyprctl','monitors','-j'],text=True))
                focused=next((m for m in monitors if m.get('focused')),monitors[0] if monitors else None)
                preferred=next((m for m in monitors if m['name']==prefs.get('monitor','eDP-1')),focused)
                selected=focused if prefs.get('placement')=='current' else preferred
                if selected:child_environment['NOESIS_MAIN_MONITOR']=selected['name']
            if prefs.get('placement','dedicated')=='dedicated' and os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'):
                if selected:subprocess.run(['hyprctl','dispatch','hl.dsp.focus({monitor='+json.dumps(selected['name'])+'})'],check=True,capture_output=True)
                workspace=prefs.get('study_workspace','Study')
                if not workspace or any(ord(c)<32 for c in workspace):raise ValueError('Invalid study workspace name')
                subprocess.run(['hyprctl','dispatch','hl.dsp.focus({workspace='+json.dumps('name:'+workspace)+'})'],check=True,capture_output=True)
            fd=os.open(state/'application.log',os.O_WRONLY|os.O_CREAT|os.O_APPEND,0o600)
            with os.fdopen(fd,'ab') as log:
                process=subprocess.Popen([qs,'-p',str(config),'--no-duplicate'],env=child_environment,stdout=log,stderr=log,start_new_session=True)
            deadline=time.monotonic()+10
            while time.monotonic()<deadline:
                hello=ipc('noesis','hello')
                if hello and hello.get('host_ready',True):break
                if process.poll() not in (None,0):raise RuntimeError('Noesis startup failed; inspect '+str(state/'application.log'))
                time.sleep(.1)
            if not hello:raise RuntimeError('Noesis startup did not become ready; inspect '+str(state/'application.log'))
        if not hello.get('host_ready',True):raise RuntimeError('Another Noesis host owns the session; close it before selecting this host')
        payload=base64.b64encode(json.dumps(request,separators=(',',':')).encode()).decode()
        ack=ipc('noesis','request',payload)
        if not ack:raise RuntimeError('Launch acknowledgement is uncertain; inspect request '+request['request_id']+' before repeating')
        if ack.get('status')=='rejected':raise ValueError(ack.get('error','Launch rejected'))
        deadline=time.monotonic()+10
        while ack.get('status')=='received' and time.monotonic()<deadline:
            time.sleep(.05);ack=ipc('noesis','requestStatus',request['request_id']) or {'status':'unknown'}
        if ack.get('status')!='ready':raise RuntimeError('Noesis request '+request['request_id']+' is '+ack.get('status','unknown')+': '+ack.get('error','inspect before repeating'))
        return ack
