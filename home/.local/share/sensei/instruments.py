"""Small, on-demand ScreenPad projections. Existing tools remain authoritative."""
import json,subprocess
from pathlib import Path
import engineering as e

def output(argv,cwd=None):
 try:
  r=subprocess.run(argv,cwd=cwd,capture_output=True,text=True,timeout=3)
  return r.stdout.strip()[:4000] if r.returncode==0 else ''
 except (OSError,subprocess.SubprocessError):return ''

def snapshot(mode,project=None):
 if mode not in ('normal','coding','simulation','hardware'):raise ValueError('Unknown instrument')
 p=e.project(project) if project else None
 root=e.checkout(p) if p else None
 cards=[]
 def card(title,value,detail='',action=''):cards.append(dict(title=title,value=str(value),detail=detail,action=action))
 receipts=e.read(e.state()/'receipts.json',{'events':[]}).get('events',[])
 latest=next((r for r in reversed(receipts) if r.get('kind')=='job.completed' and (not project or r.get('project')==project)),None)
 if mode=='coding':
  sessions=output(['tmux','list-sessions','-F','#{session_name}']).splitlines()
  card('SESSIONS',len(sessions),' · '.join(sessions[:3]),'terminal')
  branch=output(['git','branch','--show-current'],root) if root else ''
  changes=output(['git','status','--porcelain'],root).splitlines() if root else []
  card('GIT',branch or 'Choose a project',str(len(changes))+' changed paths' if root else 'Registered projects only','project')
  card('LAST RUN',latest.get('data',{}).get('outcome','No receipt') if latest else 'No recorded run',latest.get('data',{}).get('job','') if latest else 'No success inferred','engineering')
  trees=output(['git','worktree','list','--porcelain'],root) if root else ''
  card('WORKTREES',sum(l.startswith('worktree ') for l in trees.splitlines()) if root else '—',p.get('title',project) if p else 'Choose a project','project')
 elif mode=='hardware':
  inventory=e.hardware_inventory();devices=inventory['devices']
  card('KNOWN DEVICES',len(devices),'Hardware passports','hardware')
  for d in devices[:3]:card(d.get('label',d.get('id','DEVICE')),d.get('status',d.get('state','Inspect')),d.get('node',''),'hardware')
  while len(cards)<4:card('PASSPORT','No device selected','Register identity before choosing a port','hardware')
 elif mode=='simulation':
  environments=list(p.get('environments',{})) if p else []
  card('ENVIRONMENT',environments[0] if environments else 'Choose a project','Readiness is checked explicitly','engineering')
  card('PREFLIGHT','Not run in this view','Use the reviewed project preflight','preflight')
  card('ROS GRAPH','Inspect on demand','No persistent graph discovery','engineering')
  card('LAST RUN',latest.get('data',{}).get('outcome','No receipt') if latest else 'No recorded run',latest.get('data',{}).get('job','') if latest else 'Run provenance is preserved','engineering')
 else:
  presence=e.read(e.home()/'.local/state/sensei-den/presence.json',{})
  card('DEN',presence.get('mode',{}).get('effective','Unknown'),'Explicit input controls in System → Den','den')
  card('CURRENT PROJECT',p.get('title',project) if p else 'Choose a project','Keep one useful context nearby','project')
  card('AGENDA','Tasks & reviews','Open the source-owned calendar','calendar')
  card('CAPTURE','Keep an observation','Screenshot, revision and run evidence','capture')
 return {'version':1,'mode':mode,'host':e.machine(),'project':project,'projects':[{'id':p['id'],'title':p.get('title',p['id'])} for p in e.projects()],'cards':cards,'note':'On-demand state; missing evidence is not success.'}
