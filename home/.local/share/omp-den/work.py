#!/usr/bin/env python3
"""One OMP entrypoint; explicit project runtimes, private history and handoffs."""
import datetime
import json
from pathlib import Path
import sqlite3
import subprocess
import sys

BASE = Path(__file__).resolve().parent


def load_config(path=BASE/'projects.json'):
    data = json.loads(Path(path).read_text().replace('@HOME@', str(Path.home())))
    if data.get('version') != 1:
        raise ValueError('Unsupported project registry version')
    return data


def project(config, name):
    name = config.get('aliases', {}).get(name, name)
    if name not in config['projects']:
        raise ValueError('Unknown project: '+name)
    return name, config['projects'][name]


def in_project(cwd, root):
    return Path(cwd).resolve().is_relative_to(Path(root).resolve())


def execution(p, argv, interactive=False):
    if p['environment'] == 'host':
        return argv
    ros = p.get('ros')
    script = ('source /opt/ros/'+ros+'/setup.bash || exit; ' if ros else '')+'exec "$@"'
    return ['docker', 'exec', *(['-it'] if interactive else ['-i']), '-u', 'fh1m', '-w', p['cwd'],
            p['environment'], 'bash', '-c', script, 'omp-work', *argv]


def run(argv, **kw):
    return subprocess.run(argv, text=True, **kw)


def ready(p):
    if not Path(p['cwd']).is_dir():
        raise ValueError('Workspace missing: '+p['cwd'])
    if p['environment'] != 'host':
        r = run(['docker', 'inspect', '-f', '{{.State.Running}}', p['environment']], capture_output=True)
        if r.returncode or r.stdout.strip() != 'true':
            raise ValueError(p['environment']+' is not running. Run: omp-work start '+p['environment'])


def text(content):
    if isinstance(content, str): return content
    if isinstance(content, list): return '\n'.join(x.get('text', '') for x in content if isinstance(x, dict) and x.get('type') == 'text')
    return ''


def records(path):
    with Path(path).open(errors='replace') as source:
        for line in source:
            try: yield json.loads(line)
            except (ValueError, TypeError): continue


def header(rows):
    result = {}
    slot = {}
    for row in rows:
        if row.get('type') == 'title': slot = row
        if row.get('type') == 'session':
            result = dict(row)
            if slot.get('title'): result['title'] = slot['title']
            break
    return result


def handoff(path):
    result = {'session':str(path), 'verified_current':False, 'last_request':'', 'last_reply':'', 'last_task_event':None}
    tasks = {}
    # Historical events are evidence of prior intent, never new instructions.
    for row in records(path):
        if row.get('type') != 'message': continue
        msg = row.get('message', {})
        if msg.get('role') == 'user' and text(msg.get('content')):
            result['last_request'] = text(msg['content'])[-6000:]
        if msg.get('role') == 'assistant':
            if text(msg.get('content')): result['last_reply'] = text(msg['content'])[-6000:]
            for block in msg.get('content', []) if isinstance(msg.get('content'), list) else []:
                if block.get('type') == 'toolCall' and block.get('name') in ('todo', 'functions.todo', 'update_plan', 'functions.update_plan'):
                    event=block.get('arguments', {})
                    if isinstance(event,str):
                        try:event=json.loads(event)
                        except ValueError:continue
                    if not isinstance(event,dict):continue
                    result['last_task_event'] = event
                    if isinstance(event.get('plan'),list):
                        tasks={p['step']:p.get('status','pending') for p in event['plan'] if isinstance(p,dict) and p.get('step')}
                    elif event.get('op')=='init':
                        items=event.get('items') or [item for phase in event.get('list') or [] for item in phase.get('items',[])]
                        tasks={item:'pending' for item in items}
                    elif event.get('op')=='append':
                        tasks.update({item:'pending' for item in event.get('items') or []})
                    elif event.get('task'):
                        status={'done':'completed','start':'in_progress','block':'blocked','unblock':'pending'}.get(event.get('op'))
                        if status:tasks[event['task']]=status
                        elif event.get('op') in ('rm','drop'):tasks.pop(event['task'],None)
    result['historical_tasks']=[{'task':task,'status':status} for task,status in tasks.items()]
    return result


def title_candidate(original, prompts):
    if original and original.strip(): return ' '.join(original.split())[:120]
    for prompt in prompts:
        prompt = ' '.join(prompt.split())
        if not prompt or prompt.startswith(('<', '# AGENTS.md', 'You are ')): continue
        if prompt.lower().strip(' .!') in ('continue', 'ok', 'okay', 'yes', 'go', 'do it', 'resume'): continue
        # A faithful excerpt is preferable to invented AI history.
        if len(prompt) > 12: return prompt[:117]+'…' if len(prompt) > 120 else prompt
    return None


def original_titles(home):
    result = {}
    roots = [home/'.codex', *(home/'Envs/dockers').glob('*/.codex')]
    for root in roots:
        databases = sorted(root.glob('state_*.sqlite'), key=lambda p:int(p.stem.split('_')[-1]), reverse=True)
        if databases:
            try:
                with sqlite3.connect(databases[0].as_uri()+'?mode=ro', uri=True) as db:
                    for id_, title in db.execute('SELECT id,title FROM threads WHERE title IS NOT NULL'):
                        if title: result[id_] = title
            except sqlite3.Error as error: print('Title metadata unavailable:', databases[0], str(error), file=sys.stderr)
        index = root/'session_index.jsonl'
        if index.exists():
            for row in records(index):
                if row.get('id') and row.get('thread_name'): result.setdefault(row['id'], row['thread_name'])
    return result


def inventory(home):
    registry = home/'.local/share/omp-unified/imports.json'
    return json.loads(registry.read_text()) if registry.exists() else {}


def reconcile(home, apply=False):
    titles = original_titles(home)
    candidates = []
    missing = []
    for key, value in inventory(home).items():
        p = Path(value['native'])
        if not p.exists(): missing.append(key); continue
        h = header(records(p))
        if h.get('title'): continue
        source_id = key.split('/',1)[1].split('~')[0].split('@')[0]
        prompts = []
        for row in records(p):
            if row.get('type') == 'message' and row.get('message',{}).get('role') == 'user':
                prompts.append(text(row['message'].get('content')))
                if len(prompts) >= 30: break
        title = title_candidate(titles.get(source_id), prompts)
        basis='source metadata' if source_id in titles else 'literal user request excerpt'
        if not title:
            title=key.split('/')[0]+' archive · '+source_id[:13]
            basis='source identity; no substantive request available'
        candidates.append({'path':str(p), 'title':title, 'source':key,'title_basis':basis})
    report = {'apply':apply, 'missing_native':missing, 'candidates':candidates}
    if apply and candidates:
        private = home/'.local/state/omp-den'/datetime.datetime.now().strftime('titles-%Y%m%d-%H%M%S-%f')
        private.mkdir(parents=True, mode=0o700)
        manifest = private/'titles.json'; manifest.write_text(json.dumps(candidates)); manifest.chmod(0o600)
        subprocess.run([str(home/'.bun/bin/bun'), str(BASE/'titles.ts'), str(manifest)], check=True)
        report['receipt'] = str(private/'results.json')
    return report


def sessions(home, config, name=None):
    selected = project(config,name)[1] if name else None
    root = home/'.omp/agent/sessions'
    result = []
    for p in root.glob('*/*.jsonl'):
        try:
            h = header(records(p)); cwd = h.get('cwd','')
            if selected and not in_project(cwd, selected['cwd']): continue
            result.append({'id':h.get('id'), 'title':h.get('title') or '(untitled)', 'cwd':cwd,
                           'path':str(p), 'modified':p.stat().st_mtime})
        except (OSError, ValueError): continue
    return sorted(result,key=lambda x:x['modified'],reverse=True)


def doctor(config):
    checks = []
    for name,p in config['projects'].items():
        r = {'project':name,'environment':p['environment'],'cwd':p['cwd']}
        try:
            ready(p)
            probe = 'command -v omp && command -v git && command -v python3 && test -r "$HOME/.omp/agent/config.yml" && omp --version'
            if p.get('ros'): probe += ' && printf "ROS_DISTRO=%s\\n" "$ROS_DISTRO" && command -v colcon'
            checked = run(execution(p,['bash','-c',probe]),cwd=p['cwd'],capture_output=True,timeout=25)
            r.update(ok=checked.returncode==0, output=checked.stdout.strip(), error=checked.stderr.strip())
        except (ValueError, subprocess.TimeoutExpired) as e: r.update(ok=False,error=str(e))
        checks.append(r)
    return {'projects':checks,'docker_access':run(['docker','info','--format','{{.ServerVersion}}'],capture_output=True).returncode==0}


def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    config = load_config(); home=Path(config['host_home'])
    command = args.pop(0) if args else 'help'
    if command in ('help','--help','-h'):
        print('''omp-work — unified engineering loop
  omp-work projects                 Show projects and exact runtime ownership
  omp-work PROJECT [OMP flags]      Open OMP inside the owning environment
  omp-work run PROJECT -- CMD ...   Run an argv command in that environment
  omp-work start PROJECT           Explicitly start its existing container
  omp-work doctor                  Probe OMP, ROS and Docker without model calls
  omp-work sessions [PROJECT]      List native histories across projects
  omp-work resume PROJECT [ID]     Resume a native session in its proper runtime
  omp-work handoff PROJECT         Read the latest historical request/task/reply
  omp-work titles [--apply]        Recover missing titles, preserving originals
  omp-work history [QUERY]         Search legacy discovery (omp-unified list)
  omp-work backup                  Consistent private archive of OMP state
No original conversation is deleted. A historical task is not proof it remains open.''')
        return 0
    if command == 'projects': print(json.dumps(config['projects'],indent=2)); return 0
    if command == 'doctor':
        result=doctor(config); print(json.dumps(result,indent=2));return int(any(not p['ok'] for p in result['projects']))
    if command == 'titles':
        result=reconcile(home,'--apply' in args)
        print(json.dumps({**result,'candidates':len(result['candidates'])},indent=2));return 0
    if command == 'history': return run([str(home/'.local/bin/omp-unified'),'list',*args]).returncode
    if command == 'backup': return run([sys.executable,str(BASE/'backup.py')]).returncode
    if command in ('sessions','resume','handoff'):
        name = args.pop(0) if args else None
        if command != 'sessions' and not name: raise ValueError('Specify a project')
        found = sessions(home,config,name)
        if command == 'sessions':
            for x in found: print(x['id'], x['title'], '\n ',x['cwd'])
            return 0
        if args:
            found=[x for x in found if x['id'].startswith(args[0])]
            if len(found)!=1: raise ValueError('Session ID must match exactly one session within this project')
        if not found: raise ValueError('No session in this project')
        if command == 'handoff': print(json.dumps(handoff(found[0]['path']),indent=2));return 0
        _,p=project(config,name);ready(p)
        return run(execution(p,['omp','--resume',found[0]['path'],'--cwd',p['cwd']],interactive=True),cwd=p['cwd']).returncode
    if command == 'start':
        if not args: raise ValueError('Specify a project or registered container')
        name = args[0]
        matches=[p for p in config['projects'].values() if p['environment']==name]
        p=matches[0] if matches else project(config,name)[1]
        if p['environment']=='host': return 0
        return run(['docker','start',p['environment']]).returncode
    if command == 'run':
        if not args: raise ValueError('Specify project and command')
        _,p=project(config,args.pop(0))
        if args and args[0]=='--':args.pop(0)
        if not args:raise ValueError('No command supplied')
        ready(p);print('ENV='+p['environment']+' CWD='+p['cwd'],flush=True)
        return run(execution(p,args),cwd=p['cwd']).returncode
    _,p=project(config,command);ready(p)
    return run(execution(p,['omp','--cwd',p['cwd'],*args],interactive=sys.stdin.isatty()),cwd=p['cwd']).returncode

if __name__ == '__main__':
    try: sys.exit(main())
    except (ValueError,OSError,subprocess.SubprocessError) as error:
        print('omp-work:',error,file=sys.stderr);sys.exit(2)
