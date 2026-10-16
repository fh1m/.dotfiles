"""Owned job execution and recoverable, versioned provenance receipts."""
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import time

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
def execute(path):
    p=Path(path);data=json.loads(p.read_text());data.update(schema=1,started=time.time(),state='running',environment={'python':sys.version.split()[0],'platform':platform.platform()});save(p,data)
    try:
        result=subprocess.run(data['command'],cwd=data['project']);code=result.returncode
        data.update(state='succeeded' if code==0 else 'failed',exitCode=code)
    except Exception as error:data.update(state='failed',exitCode=127,error=str(error)[:300])
    data['finished']=time.time();data['artifacts']=[]
    for name in data.get('expectedArtifacts',[]):
        try:data['artifacts'].append(artifact(data['project'],name))
        except (ValueError,OSError) as error:data.setdefault('artifactErrors',[]).append({'path':name,'error':str(error)})
    save(p,data);return data['exitCode']
if __name__=='__main__':sys.exit(execute(sys.argv[1]))
