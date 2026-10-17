"""Owned job execution and recoverable, versioned provenance receipts."""
import fcntl
import contextlib
import resource
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import time

@contextlib.contextmanager
def submission(directory, limit=16):
    """Bound queued worker count under a host-local admission lock."""
    directory=Path(directory)
    with (directory/'.submission.lock').open('a') as stream:
        os.chmod(stream.name,0o600);fcntl.flock(stream,fcntl.LOCK_EX)
        pending=0
        for path in directory.glob('*.json'):
            try:
                if json.loads(path.read_text()).get('state') in ('queued','running'):pending+=1
            except (OSError,ValueError,TypeError):continue
        if pending>=limit:raise ValueError('Host queue is full (16 pending/running jobs); inspect or cancel owned jobs first')
        yield

def digest(path):
    h=hashlib.sha256()
    with Path(path).open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):h.update(chunk)
    return h.hexdigest()
def save(path,data):
    path=Path(path);temp=path.with_name(path.name+'.'+str(os.getpid())+'.tmp')
    with temp.open('w') as f:
        os.chmod(temp,0o600);json.dump(data,f,indent=2);f.flush();os.fsync(f.fileno())
    temp.replace(path)
def artifact(project,name):
    base=Path(project).resolve();p=(base/name).resolve()
    if not p.is_relative_to(base) or not p.is_file():raise ValueError('Artifact must be an existing file inside the project')
    return {'path':str(p.relative_to(base)),'bytes':p.stat().st_size,'sha256':digest(p)}
def _execute(path):
    p=Path(path);data=json.loads(p.read_text());data.update(schema=1,started=time.time(),state='running',environment={'python':sys.version.split()[0],'platform':platform.platform()});save(p,data)
    try:
        for item in data.get('inputs',[]):
            source=Path(item['path'])
            if not source.is_file() or digest(source)!=item['sha256']:
                raise ValueError('Queued input changed; submit a new job after review')
        usage_before=resource.getrusage(resource.RUSAGE_CHILDREN)
        result=subprocess.run(data['command'],cwd=data['project'],env={**os.environ,'SENSEI_PARENT_JOB':data.get('id','')});code=result.returncode
        usage=resource.getrusage(resource.RUSAGE_CHILDREN)
        data['resources']={'userSeconds':usage.ru_utime-usage_before.ru_utime,'systemSeconds':usage.ru_stime-usage_before.ru_stime,'peakRssKiB':usage.ru_maxrss}
        data.update(state='succeeded' if code==0 else 'failed',exitCode=code)
    except Exception as error:data.update(state='failed',exitCode=127,error=str(error)[:300])
    data['finished']=time.time();data['artifacts']=[]
    if data['exitCode']!=0:
        data['failureKey']=hashlib.sha256(json.dumps([data['project'],data['command']],sort_keys=True).encode()).hexdigest()
        log=p.with_suffix('.log')
        if log.is_file():
            with log.open('rb') as stream:
                stream.seek(0,2);stream.seek(max(0,stream.tell()-24000));lines=stream.read().decode(errors='replace').splitlines()
            data['firstFailure']=next((line[:300] for line in lines if any(word in line.casefold() for word in ('error','exception','failed'))),'Exit code '+str(data['exitCode']))
    for name in data.get('expectedArtifacts',[]):
        try:data['artifacts'].append(artifact(data['project'],name))
        except (ValueError,OSError) as error:data.setdefault('artifactErrors',[]).append({'path':name,'error':str(error)})
    save(p,data)
    if data.get('id'):
        try:
            from engineering import receipt,read,state
            recent=read(state()/'receipts.json',{'events':[]}).get('events',[])
            repeated=1+sum(1 for event in recent if data.get('failureKey') and event.get('kind')=='job.completed' and event.get('data',{}).get('failureKey')==data['failureKey'] and time.time()-event.get('at',0)<900)
            receipt('job.completed',{'job':data['id'],'outcome':data['state'],'exitCode':data['exitCode'],'elapsedSeconds':round(data['finished']-data['started'],3),'failureKey':data.get('failureKey'),'repeatFailures':repeated if data.get('failureKey') else 0})
        except (OSError,ValueError):pass  # Never change a scientific result because desktop projection failed.
    return data['exitCode']

def execute(path):
    # Per-host serial queue. Waiting workers sleep in flock, without polling.
    lock=Path(path).parent/'.execution.lock'
    with lock.open('a') as stream:
        os.chmod(lock,0o600);fcntl.flock(stream,fcntl.LOCK_EX)
        return _execute(path)
if __name__=='__main__':sys.exit(execute(sys.argv[1]))
