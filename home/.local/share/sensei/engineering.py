"""Local engineering contracts. No daemon, arbitrary UI commands or privileged actions."""
import contextlib
import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import time
import uuid

VERSION = 1
ID = re.compile(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,79}$')


def home():
    return Path(os.environ.get('SENSEI_ENGINEERING_HOME', Path.home()))


def state():
    return home()/'.local/state/sensei-engineering'


def config():
    return home()/'.config/sensei-engineering'


def read(path, default=None):
    try:
        return json.loads(Path(path).read_text())
    except FileNotFoundError:
        return {} if default is None else default


def save(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    temporary = path.with_name(path.name+'.'+uuid.uuid4().hex+'.tmp')
    try:
        with temporary.open('x') as stream:
            temporary.chmod(0o600)
            json.dump(value, stream, ensure_ascii=False, allow_nan=False)
            stream.write('\n');stream.flush();os.fsync(stream.fileno())
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


@contextlib.contextmanager
def locked(path):
    path = Path(path);path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    with path.open('a') as stream:
        path.chmod(0o600);fcntl.flock(stream, fcntl.LOCK_EX)
        yield


def identifier(value):
    if not isinstance(value, str) or not ID.fullmatch(value):
        raise ValueError('Invalid stable identifier')
    return value


def machine():
    return socket.gethostname().split('.')[0].casefold()


def fingerprint(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, allow_nan=False).encode()).hexdigest()


def receipt(kind, payload, *, project=None, event_id=None):
    """Bounded transition journal plus atomic small UI projection, not a telemetry bus."""
    identifier(kind)
    if project is not None:identifier(project)
    if not isinstance(payload, dict) or len(json.dumps(payload)) > 16384:
        raise ValueError('Receipt payload is not a bounded object')
    row = dict(version=VERSION, id=str(uuid.UUID(event_id)) if event_id else str(uuid.uuid4()),
               kind=kind, host=machine(), project=project, at=time.time(), data=payload)
    with locked(state()/'receipts.lock'):
        head = read(state()/'receipts.json', {'version':1, 'sequence':0, 'events':[]})
        if any(x['id']==row['id'] for x in head['events']):return row
        journal = state()/'receipts.jsonl'
        if journal.exists() and journal.stat().st_size > 1024*1024:
            (state()/'receipts.4.jsonl').unlink(missing_ok=True)
            for index in range(3,0,-1):
                source=state()/f'receipts.{index}.jsonl'
                if source.exists():source.replace(state()/f'receipts.{index+1}.jsonl')
            journal.replace(state()/'receipts.1.jsonl')
        with journal.open('a') as stream:
            journal.chmod(0o600);stream.write(json.dumps(row,allow_nan=False)+'\n');stream.flush();os.fsync(stream.fileno())
        save(state()/'receipts.json', dict(version=1, sequence=head['sequence']+1, events=(head['events']+[row])[-128:]))
    return row


def projects():
    catalog=read(config()/'projects.json', {'version':1,'projects':[]})
    if catalog.get('version')!=1 or not isinstance(catalog.get('projects'),list):
        raise ValueError('Unsupported project catalog')
    ids=[identifier(p['id']) for p in catalog['projects']]
    if len(ids)!=len(set(ids)):raise ValueError('Duplicate project identity')
    return catalog['projects']


def project(identity):
    identifier(identity)
    value=next((p for p in projects() if p['id']==identity),None)
    if not value:raise ValueError('Unknown registered project')
    return value


def checkout(p):
    path=Path(p.get('locations',{}).get(machine(),'')).expanduser()
    if not str(p.get('locations',{}).get(machine(),'')) or not path.is_dir():
        raise ValueError('Project has no existing checkout on this host')
    return path.resolve()


def task(p, name):
    identifier(name)
    value=p.get('tasks',{}).get(name)
    if not isinstance(value,dict):raise ValueError('Unknown reviewed project task')
    argv=value.get('argv')
    if not isinstance(argv,list) or not 1<=len(argv)<=100 or any(not isinstance(a,str) or '\0' in a or len(a)>4096 for a in argv):
        raise ValueError('Task must contain a bounded argument array')
    if p.get('trusted_tasks',{}).get(name)!=fingerprint(value):
        raise ValueError('Task is new or changed; review and trust its exact definition first')
    resources=value.get('resources',{})
    if not isinstance(resources,dict) or set(resources)-{'memoryMiB','cpuPercent'}:raise ValueError('Unsupported resource requirements')
    for key,bounds in [('memoryMiB',(32,1048576)),('cpuPercent',(1,10000))]:
        if key in resources and (type(resources[key]) is not int or not bounds[0]<=resources[key]<=bounds[1]):raise ValueError('Invalid resource limit')
    for key in ('inputs','artifacts'):
        if not isinstance(value.get(key,[]),list):raise ValueError('Task paths must be lists')
        for name in value.get(key,[]):safe_relative(name)
    return value


ACTIONS={
 'project.open':dict(title='Open project tmux',effect='session',required=['project']),
 'project.preflight':dict(title='Check project environment',effect='read',required=['project']),
 'jobs.list':dict(title='Inspect local jobs',effect='read',required=[]),
 'job.logs':dict(title='Read owned job log',effect='read',required=['id']),
 'job.artifacts':dict(title='Read owned job artifacts',effect='read',required=['id']),
 'job.cancel':dict(title='Cancel owned job',effect='execution',required=['id']),
 'job.launch':dict(title='Run reviewed project task',effect='execution',required=['project','task']),
 'hardware.register':dict(title='Register a hardware passport',effect='write',required=['id','node','label']),
 'hardware.list':dict(title='Inspect registered hardware',effect='read',required=[]),
}


def validate(action, params):
    if action not in ACTIONS:raise ValueError('Unknown action')
    if not isinstance(params,dict):raise ValueError('Parameters must be an object')
    spec=ACTIONS[action]
    if set(params)!=set(spec['required']):raise ValueError('Missing or unexpected action parameters')
    for key in spec['required']:
        if key in ('node','label'):
            if not isinstance(params[key],str) or not params[key].strip() or len(params[key])>200:raise ValueError('Invalid hardware field')
        else:identifier(params[key])
    p=project(params['project']) if 'project' in params else None
    root=checkout(p) if p else None
    t=task(p,params['task']) if 'task' in params else None
    return dict(action=action,params=params,host=machine(),effect=spec['effect'],
                checkout=str(root) if root else None,task=t)


def prepare(action, params):
    plan=validate(action,params)
    if plan['effect']=='read':return dict(plan=plan,confirmation=None)
    token=uuid.uuid4().hex
    save(state()/'confirmations'/f'{token}.json',dict(plan=plan,expires=time.time()+120))
    return dict(plan=plan,confirmation=token,expires_in_seconds=120)


def invoke(action, params, confirmation=None):
    plan=validate(action,params)
    if plan['effect']!='read':
        if not isinstance(confirmation,str) or not re.fullmatch(r'[a-f0-9]{32}',confirmation):
            raise ValueError('Prepare and explicitly confirm this operation first')
        path=state()/'confirmations'/f'{confirmation}.json'
        with locked(state()/'confirmations.lock'):
            approved=read(path)
            if approved.get('expires',0)<time.time() or approved.get('plan')!=plan:
                raise ValueError('Confirmation expired or operation changed')
            path.unlink()
    binary=home()/'.local/bin'
    if action in ('job.logs','job.artifacts','job.cancel'):
        return command([str(binary/'sensei-den'),'job',action.split('.')[1],'--id',params['id']])
    if action=='environment.preflight':return environment_preflight(project(params['project']),params['environment'])
    if action=='ros.health':return ros_health(project(params['project']),params['environment'])
    if action=='project.preflight':return preflight(project(params['project']))
    if action=='hardware.list':return hardware_inventory()
    if action=='hardware.register':return command([str(binary/'sensei-hardware'),'register',params['id'],'--node',params['node'],'--label',params['label']])
    if action=='jobs.list':
        return command([str(binary/'sensei-den'),'job','list'])
    if action=='project.open':
        subprocess.Popen([str(binary/'sensei-terminal'),'--working-directory',plan['checkout'],'-e',str(binary/'sensei-lab'),'open','--project',plan['checkout'],'--name',params['project']],
                         stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
        return receipt('project.launch',{'action':action},project=params['project'])
    t=plan['task'];argv=[str(binary/'sensei-den'),'job','run','--project',plan['checkout']]
    if t.get('resources',{}).get('memoryMiB'):argv+=['--memory-mib',str(t['resources']['memoryMiB'])]
    if t.get('resources',{}).get('cpuPercent'):argv+=['--cpu-percent',str(t['resources']['cpuPercent'])]
    for name in t.get('inputs',[]):argv+=['--input',safe_relative(name)]
    for name in t.get('artifacts',[]):argv+=['--artifact',safe_relative(name)]
    result=command(argv+['--',*t['argv']])
    receipt('job.submitted',{'job':result.get('id'),'task':params['task']},project=params['project'])
    return result


def safe_relative(name):
    if not isinstance(name,str) or not name or Path(name).is_absolute() or '..' in Path(name).parts:
        raise ValueError('Project-relative path required')
    return name


def command(argv, timeout=20):
    result=subprocess.run(argv,capture_output=True,text=True,timeout=timeout)
    if result.returncode:raise ValueError(result.stderr.strip()[-500:] or 'Action failed')
    return json.loads(result.stdout)


def preflight(p):
    root=checkout(p);checks=[dict(name='Checkout',ok=True,detail=str(root))]
    for name in p.get('required_files',[]):
        relative=safe_relative(name);path=(root/relative).resolve()
        checks.append(dict(name=relative,ok=path.is_relative_to(root) and path.exists()))
    for envname in p.get('required_environment',[]):
        if not isinstance(envname,str) or not re.fullmatch('[A-Z][A-Z0-9_]*',envname):raise ValueError('Invalid environment key')
        checks.append(dict(name=envname,ok=bool(os.environ.get(envname))))
    # Never return environment values or run a repository-supplied preflight script.
    return dict(project=p['id'],host=machine(),checks=checks,ok=all(x['ok'] for x in checks))


def hardware_inventory():
    helper=home()/'.local/bin/sensei-hardware'
    if helper.is_file():return command([str(helper),'list'])
    return dict(version=1,devices=[])


def environment(p, name):
    identifier(name)
    spec=p.get('environments',{}).get(name)
    if not isinstance(spec,dict) or p.get('trusted_environments',{}).get(name)!=fingerprint(spec):
        raise ValueError('Review and trust this environment definition first')
    if spec.get('kind') not in ('native','compose','distrobox'):raise ValueError('Unsupported environment kind')
    return spec


def environment_preflight(p,name):
    spec=environment(p,name);root=checkout(p);checks=[]
    if spec['kind']=='compose':
        relative=safe_relative(spec.get('file','compose.yaml'));path=(root/relative).resolve()
        if not path.is_relative_to(root):raise ValueError('Compose file must stay inside the checkout')
        if not path.is_file():return dict(ok=False,checks=[dict(name='Compose file',ok=False)])
        result=subprocess.run(['docker','compose','-f',str(path),'config','--quiet'],cwd=root,capture_output=True,text=True,timeout=8)
        checks.append(dict(name='Compose configuration',ok=result.returncode==0,detail='Valid' if result.returncode==0 else 'Configuration rejected; inspect with DockerLab'))
    if spec['kind']=='distrobox':
        container=identifier(spec.get('container',''))
        result=subprocess.run(['docker','inspect','--format','{{.State.Running}}',container],capture_output=True,text=True,timeout=4)
        checks.append(dict(name='Container running',ok=result.returncode==0 and result.stdout.strip()=='true'))
    for relative in spec.get('required_files',[]):
        path=(root/safe_relative(relative)).resolve();checks.append(dict(name=relative,ok=path.is_relative_to(root) and path.exists()))
    if spec.get('ros_domain_id') is not None:
        value=spec['ros_domain_id']
        if type(value) is not int or not 0<=value<=232:raise ValueError('Invalid ROS domain ID')
        checks.append(dict(name='Explicit ROS domain',ok=True,detail=str(value)))
    return dict(project=p['id'],environment=name,checks=checks,ok=all(c['ok'] for c in checks))


def ros_health(p,name):
    spec=environment(p,name);prefix=[]
    if spec['kind']=='distrobox':prefix=['distrobox-enter','--name',identifier(spec.get('container','')),'--']
    elif spec['kind']!='native':raise ValueError('Choose a native or Distrobox ROS environment, not a whole Compose stack')
    env=os.environ.copy()
    if spec.get('ros_domain_id') is not None:
        value=spec['ros_domain_id']
        if type(value) is not int or not 0<=value<=232:raise ValueError('Invalid ROS domain ID')
        env['ROS_DOMAIN_ID']=str(value)
    setup=spec.get('ros_setup')
    if setup:
        if not isinstance(setup,str) or not re.fullmatch(r'/opt/ros/[a-zA-Z0-9_-]+/setup\.bash',setup):raise ValueError('Use the installed ROS distribution setup script')
        prefix+=['env','ROS_DOMAIN_ID='+env.get('ROS_DOMAIN_ID','0'),'bash','--noprofile','--norc','-c','source "$1"; shift; exec "$@"','sensei-ros',setup]
    result={}
    for kind in ('node','topic'):
        argv=prefix+['ros2',kind,'list','--no-daemon','--spin-time','1']
        if kind=='topic':argv+=['-t']
        r=subprocess.run(argv,cwd=checkout(p),env=env,capture_output=True,text=True,timeout=8)
        result[kind+'s']=r.stdout.splitlines()[:200] if r.returncode==0 else []
        if r.returncode:result.setdefault('errors',[]).append(kind+' query unavailable in this environment')
    result.update(observed_at=time.time(),domain=env.get('ROS_DOMAIN_ID','0'),note='Bounded discovery snapshot, not proof of topic throughput, freshness or robot safety.')
    return result

ACTIONS.update({
 'environment.preflight':dict(title='Simulation environment preflight',effect='read',required=['project','environment']),
 'ros.health':dict(title='Explicit bounded ROS graph snapshot',effect='read',required=['project','environment']),
})
