"""Native Claude account observations. Cache timestamps are never provider measurements."""
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import time
from datetime import datetime

from job_runtime import run_bounded

SOURCE='native-claude-cli'
CACHE_SECONDS=300
MIN_REFRESH_SECONDS=30


def environment(directory):
    env={key:value for key,value in os.environ.items()
         if not key.startswith('ANTHROPIC_') and key not in {
             'CLAUDE_CODE_OAUTH_TOKEN','CLAUDE_CODE_OAUTH_TOKEN_FILE_DESCRIPTOR',
             'CLAUDE_CODE_USE_BEDROCK','CLAUDE_CODE_USE_VERTEX','CLAUDE_CODE_USE_FOUNDRY'}}
    selected=Path(directory).expanduser().resolve()
    # Native Claude keeps the default global config in ~/.claude.json; setting
    # CLAUDE_CONFIG_DIR even to ~/.claude changes that config-file lookup.
    if selected==(Path.home()/'.claude').resolve():
        env.pop('CLAUDE_CONFIG_DIR',None)
    else:env['CLAUDE_CONFIG_DIR']=str(selected)
    return env


def probe_directory():
    # Pinned CodexBar 0.85.0 uses Foundation's Linux application-support path.
    return Path(os.environ.get('XDG_DATA_HOME',Path.home()/'.local/share'))/'CodexBar/ClaudeProbe'


def native_probe_trusted(directory):
    """Read native consent; never accept a provider safety prompt on the user's behalf."""
    probe=probe_directory()
    if probe.is_symlink() or not probe.is_dir():return False
    selected=Path(directory).expanduser().resolve()
    config=Path.home()/'.claude.json' if selected==(Path.home()/'.claude').resolve() else selected/'.claude.json'
    projects=read(config).get('projects',{})
    if not isinstance(projects,dict):return False
    project=projects.get(str(probe.resolve()),{})
    return isinstance(project,dict) and project.get('hasTrustDialogAccepted') is True


def native_identity(directory):
    executable=shutil.which('claude')
    if not executable:return {'signedIn':False,'state':'not-installed'}
    try:
        result=subprocess.run([executable,'auth','status'],env=environment(directory),
                              capture_output=True,text=True,timeout=8)
        data=json.loads(result.stdout)
        if not isinstance(data,dict) or result.returncode or data.get('loggedIn') is not True:
            return {'signedIn':False,'state':'needs-sign-in'}
        return {'signedIn':True,'email':data.get('email'),'organization':data.get('orgName'),
                'organizationId':data.get('orgId'),'plan':data.get('subscriptionType') or data.get('planTier'),'state':'connected'}
    except (OSError,ValueError,subprocess.SubprocessError):
        return {'signedIn':None,'state':'authentication-unavailable'}


def cache_path(directory,identity):
    root=Path(os.environ.get('XDG_CACHE_HOME',Path.home()/'.cache'))/'sensei-code/native-claude'
    key=json.dumps([str(Path(directory).expanduser().resolve()),identity.get('email'),identity.get('organizationId')],separators=(',',':'))
    return root/(hashlib.sha256(key.encode()).hexdigest()+'.json')


def read(path):
    try:
        value=json.loads(path.read_text())
        return value if isinstance(value,dict) else {}
    except (OSError,ValueError):return {}


def write(path,data):
    path.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
    path.parent.chmod(0o700)
    temporary=path.with_name(path.name+'.'+str(os.getpid())+'.tmp')
    with temporary.open('x') as stream:
        os.fchmod(stream.fileno(),0o600)
        json.dump(data,stream)
    temporary.replace(path)


def timestamp(value):
    if not isinstance(value,str):raise ValueError('Missing timestamp')
    parsed=datetime.fromisoformat(value.replace('Z','+00:00'))
    if parsed.tzinfo is None:raise ValueError('Timestamp has no timezone')
    return parsed.timestamp()


def normalize(payload,identity):
    if not isinstance(payload,dict) or payload.get('provider')!='claude' or payload.get('error'):
        raise ValueError('Native quota query did not return a Claude measurement')
    usage=payload.get('usage')
    if not isinstance(usage,dict):raise ValueError('Missing native usage')
    account=usage.get('identity') or {}
    if not isinstance(account,dict):raise ValueError('Invalid native identity')
    observed_email=usage.get('accountEmail') or account.get('accountEmail')
    if not identity.get('email') or not isinstance(observed_email,str) or observed_email.casefold()!=identity['email'].casefold():
        raise ValueError('Native quota identity does not match the selected account')
    stamp=usage.get('updatedAt')
    measured=timestamp(stamp)
    if not math.isfinite(measured) or measured>time.time()+60:
        raise ValueError('Native quota response has no valid measurement time')
    def window(value):
        if value is None:return None
        if not isinstance(value,dict):raise ValueError('Invalid quota window')
        percent=value.get('usedPercent')
        if type(percent) not in (int,float) or not math.isfinite(percent) or not 0<=percent<=100:
            raise ValueError('Native quota response has an invalid percentage')
        reset=value.get('resetsAt')
        if reset is not None:
            timestamp(reset)
        return {'used_percentage':percent,'resets_at':reset,'resetDescription':value.get('resetDescription')}
    limits={'updatedAt':stamp,'fiveHour':window(usage.get('primary')),
            'sevenDay':window(usage.get('secondary')),'modelWindow':window(usage.get('tertiary')),
            'source':SOURCE,'measurementAt':measured}
    if not any(limits[name] is not None for name in ('fiveHour','sevenDay','modelWindow')):
        raise ValueError('Native quota response has no reported window')
    return limits


def collect(directory,identity,force=False):
    path=cache_path(directory,identity)
    previous=read(path)
    now=time.time()
    if previous.get('source')!=SOURCE:previous={}
    if (type(previous.get('measurementAt',0)) not in (int,float)
        or type(previous.get('checkedAt',0)) not in (int,float)
        or not math.isfinite(previous.get('measurementAt',0))
        or not math.isfinite(previous.get('checkedAt',0))):
        previous={}
    age=now-previous.get('measurementAt',0)
    attempted=now-previous.get('checkedAt',0)
    if previous and ((not force and not previous.get('error') and age<CACHE_SECONDS) or attempted<MIN_REFRESH_SECONDS):
        return dict(previous,stale=bool(previous.get('error')) or age>=CACHE_SECONDS)
    if identity.get('signedIn') is not True:
        return {'source':SOURCE,'error':'Sign in to this native Claude profile to read subscription limits','stale':True}
    executable=shutil.which('codexbar')
    if not executable:
        return dict(previous,source=SOURCE,error='Install the pinned CodexBar CLI with setup-agent-usage.py',stale=True)
    if not native_probe_trusted(directory):
        return dict(previous,source=SOURCE,stale=True,requiresApproval=True,
                    probeDirectory=str(probe_directory()),
                    error='Open native Claude interactively in '+str(probe_directory())+' using this profile, approve its folder prompt, then refresh. No model prompt is needed.')
    path.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
    import fcntl
    with path.with_suffix('.lock').open('a') as lock:
        try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:
            return dict(previous,source=SOURCE,pending=True,stale=age>=CACHE_SECONDS)
        try:
            env=environment(directory)
            env['CODEXBAR_CONFIG']=str(path.parent/'cli-settings.json')
            result=run_bounded([executable,'usage','--provider','claude','--source','cli',
                                '--format','json','--no-credits','--no-color'],
                               path.with_suffix('.request.json'),timeout=70,max_bytes=131072,env=env)
            if result['exitCode'] or result['logTruncated']:
                raise ValueError('Native quota query failed')
            payload=json.loads(path.with_suffix('.request.json').read_text())
            if isinstance(payload,list):
                if len(payload)!=1:raise ValueError('Ambiguous native quota response')
                payload=payload[0]
            limits=normalize(payload,identity)
            current_identity=native_identity(directory)
            if any(current_identity.get(key)!=identity.get(key) for key in ('email','organizationId')) or current_identity.get('signedIn') is not True:
                raise ValueError('Authentication changed during the quota request')
            limits.update(checkedAt=now,stale=time.time()-limits['measurementAt']>=CACHE_SECONDS)
        except (OSError,ValueError,TypeError,subprocess.SubprocessError):
            limits=dict(previous,source=SOURCE,checkedAt=now,stale=True,
                        error='Native Claude quota could not be refreshed; retained values keep their original measurement time')
        write(path,limits)
        return limits


def cached_limits(directory,identity):
    value=read(cache_path(directory,identity))
    if value.get('source')!=SOURCE or type(value.get('measurementAt')) not in (int,float) or not math.isfinite(value['measurementAt']):return None
    return dict(value,stale=bool(value.get('error')) or time.time()-value.get('measurementAt',0)>=CACHE_SECONDS)
