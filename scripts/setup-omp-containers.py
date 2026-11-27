#!/usr/bin/env python3
"""Link the host OMP runtime/state into existing running Distrobox containers."""
import argparse
import json
import subprocess
import tempfile
from urllib.parse import urlparse
from pathlib import Path


def setup(home,apply=False,tools=False,ubuntu_mirror=None):
    if ubuntu_mirror:
        parsed=urlparse(ubuntu_mirror)
        if parsed.scheme!='https' or not parsed.netloc or any(c.isspace() for c in ubuntu_mirror):raise ValueError('Mirror must be one HTTPS URL')
    config=json.loads((home/'.local/share/omp-den/projects.json').read_text())
    results=[]
    if tools and apply:
        subprocess.run([str(home/'.bun/bin/bun'),'install','--frozen-lockfile','--ignore-scripts','--cwd',str(home/'.local/share/omp-den/tools')],check=True)
    for project,p in config['projects'].items():
        container=p['environment']
        if container=='host':continue
        r=subprocess.run(['docker','inspect','-f','{{.State.Running}}',container],text=True,capture_output=True)
        if r.returncode or r.stdout.strip()!='true':
            results.append({'project':project,'status':'stopped; explicit omp-work start required'});continue
        account=subprocess.check_output(['docker','exec',container,'getent','passwd','fh1m'],text=True).strip().split(':')
        container_home=account[5]
        links=[(str(home/'.bun/bin/bun'),'/usr/local/bin/bun'),
               (str(home/'.bun/bin/omp'),'/usr/local/bin/omp'),
               (str(home/'.local/bin/omp-work'),'/usr/local/bin/omp-work'),
               (str(home/'.local/bin/omp-unified'),'/usr/local/bin/omp-unified'),
               (str(home/'.omp/agent'),container_home+'/.omp/agent')]
        for source,target in links:
            # Distrobox also exposes the same inode under /run/host; compare identity.
            probe=subprocess.run(['docker','exec',container,'test','-e',target]).returncode==0
            if probe:
                same=subprocess.run(['docker','exec',container,'test',target,'-ef',source]).returncode==0
                if not same:raise RuntimeError('Existing different target; preserve and resolve manually: '+container+':'+target)
                continue
            if apply:
                subprocess.run(['docker','exec','-u','root',container,'mkdir','-p',str(Path(target).parent)],check=True)
                subprocess.run(['docker','exec','-u','root',container,'ln','-s',source,target],check=True)
        if apply:subprocess.run(['docker','exec','-u','root',container,'chown','fh1m:fh1m',container_home+'/.omp'],check=True)
        if tools:
            present=subprocess.run(['docker','exec',container,'bash','-c','command -v clangd'],stdout=subprocess.DEVNULL).returncode==0
            if not present and apply:
                with tempfile.TemporaryDirectory(prefix='omp-apt-') as tmp:
                    options=[]
                    if ubuntu_mirror:
                        code=subprocess.check_output(['docker','exec',container,'bash','-c','. /etc/os-release; printf %s \"$VERSION_CODENAME\"'],text=True)
                        if code not in ('jammy','noble'):raise ValueError('Unsupported Ubuntu release: '+code)
                        source=Path(tmp)/'ubuntu.list'
                        source.write_text(''.join('deb '+ubuntu_mirror.rstrip('/')+'/ '+suite+' main universe\n' for suite in [code,code+'-updates',code+'-security']))
                        options=['-o','Dir::Etc::sourcelist='+str(source),'-o','Dir::Etc::sourceparts=-']
                    subprocess.run(['docker','exec','-u','root',container,'apt-get',*options,'update'],check=True)
                    subprocess.run(['docker','exec','-u','root','-e','DEBIAN_FRONTEND=noninteractive',container,'apt-get',*options,'install','-y','--no-install-recommends','clangd'],check=True)
        results.append({'project':project,'status':'linked' if apply else 'preview','links':links})
    return {'apply':apply,'containers':results}

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--home',type=Path,default=Path.home());p.add_argument('--apply',action='store_true');p.add_argument('--tools',action='store_true');p.add_argument('--ubuntu-mirror');a=p.parse_args()
    print(json.dumps(setup(a.home,a.apply,a.tools,a.ubuntu_mirror),indent=2))
