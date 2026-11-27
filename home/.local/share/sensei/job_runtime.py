"""Bounded private logs and PID-generation checks for owned desktop jobs."""
import os,signal,subprocess,time
from pathlib import Path

def policy(kind,record=None):
    """User-owned budgets; old evidence is never automatically pruned."""
    import json
    try:settings=json.loads((Path.home()/'.config/sensei/job-limits.json').read_text()).get(kind,{})
    except FileNotFoundError:settings={}
    defaults={'phone':(3600,4*1024*1024),'docker':(86400,8*1024*1024),'engineering':(86400,8*1024*1024)}
    seconds,size=defaults[kind];record=record or {}
    values={'timeout':record.get('timeout',settings.get('timeoutSeconds',seconds)),
            'max_bytes':record.get('logBudget',settings.get('maxLogBytes',size)),
            'reserve_bytes':settings.get('minimumFreeBytes',128*1024*1024)}
    for key,low,high in [('timeout',1,7*86400),('max_bytes',1024,256*1024*1024),('reserve_bytes',1024*1024,16*1024**3)]:
        if type(values[key]) is not int or not low<=values[key]<=high:raise ValueError('Invalid '+kind+' job budget: '+key)
    return values

def export_log(log,destination):
    import shutil
    log=Path(log);destination=Path(destination)
    destination.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    fd=os.open(destination,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
    try:
        with os.fdopen(fd,'wb') as target,log.open('rb') as source:shutil.copyfileobj(source,target)
    except BaseException:
        destination.unlink(missing_ok=True);raise
    return str(destination)

def identity(pid=None):
    pid=os.getpid() if pid is None else int(pid)
    try:
        raw=Path(f'/proc/{pid}/stat').read_text();fields=raw.rsplit(') ',1)[1].split()
        if fields[0]=='Z':return None
        return {'pid':pid,'start':fields[19],'boot':Path('/proc/sys/kernel/random/boot_id').read_text().strip()}
    except (OSError,ValueError,IndexError):return None

def alive(record):
    expected=record.get('worker')
    return isinstance(expected,dict) and identity(expected.get('pid',0))==expected

def reconcile(record):
    if record.get('state') in ('queued','starting','running'):
        # Allow launcher-to-worker handover, but never leave yesterday's queue live.
        if record.get('worker'):
            missing=not alive(record)
        else:missing=time.time()-record.get('created',0)>30
        if missing:
            return dict(record,state='interrupted',finished=time.time(),error='Worker ended before recording a result')
    return record

def run_bounded(command,log,*,cwd=None,timeout=86400,max_bytes=8*1024*1024,reserve_bytes=128*1024*1024,env=None,preflight=None):
    import selectors,shutil
    log=Path(log);log.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    limit=max(1024,int(max_bytes));written=0;discarded=0;timed_out=False;low_space=False
    p=None;previous=None
    def interrupted(*_):raise SystemExit(143)
    try:
        previous=signal.signal(signal.SIGTERM,interrupted)
        with log.open('wb') as output:
            os.chmod(log,0o600)
            p=subprocess.Popen(command,cwd=cwd,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,start_new_session=True)
            selector=selectors.DefaultSelector();selector.register(p.stdout,selectors.EVENT_READ)
            deadline=time.monotonic()+timeout;last_space=0;last_preflight=0
            try:
                while selector.get_map():
                    if preflight is not None and time.monotonic()-last_preflight>=5:
                        preflight();last_preflight=time.monotonic()
                    if time.monotonic()>=deadline:
                        timed_out=True;break
                    for key,_ in selector.select(timeout=min(1,max(0,deadline-time.monotonic()))):
                        data=os.read(key.fd,65536)
                        if not data:selector.unregister(key.fileobj);continue
                        if time.monotonic()-last_space>=5:
                            low_space=shutil.disk_usage(log.parent).free<reserve_bytes;last_space=time.monotonic()
                        keep=data[:max(0,limit-written)] if not low_space else b''
                        if keep:output.write(keep);output.flush();written+=len(keep)
                        discarded+=len(data)-len(keep)
                if not timed_out:p.wait(timeout=max(.1,deadline-time.monotonic()))
            except subprocess.TimeoutExpired:timed_out=True
            finally:selector.close()
    finally:
        if p is not None:
            if p.poll() is None:
                os.killpg(p.pid,signal.SIGTERM)
                try:p.wait(timeout=3)
                except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
            p.stdout.close()
        if previous is not None:signal.signal(signal.SIGTERM,previous)
    return {'exitCode':124 if timed_out else p.returncode,'logBytes':written,'logBudgetBytes':limit,'timeoutSeconds':timeout,'retention':'preserve-until-explicit-removal','discardedBytes':discarded,'logTruncated':discarded>0,'timedOut':timed_out,'lowSpace':low_space}
