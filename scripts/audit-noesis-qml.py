#!/usr/bin/env python3
"""Read-only current Noesis QML boundary inventory, or an explicit Git revision."""
from pathlib import Path
import argparse,json,re,subprocess
repo=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--ref',help='Optional available Git revision; default audits current source');args=p.parse_args()
if args.ref:
 result=subprocess.run(['git','ls-tree','-r','--name-only',args.ref],cwd=repo,text=True,capture_output=True)
 if result.returncode:p.error('Revision unavailable in this checkout; omit --ref to audit current source')
 paths=result.stdout.splitlines()
else:paths=[str(p.relative_to(repo)) for p in (repo/'home').rglob('*.qml')]
def selected(path):
 return path.endswith('.qml') and ('sensei-learning/ui/' in path or '/quickshell/noesis/' in path or 'sensei/modules/learning/' in path or path.endswith('/services/Oasis.qml') or path.endswith('/config/NoesisStyle.qml'))
manifest={'baseline':args.ref or 'working-tree','files':{}}
for path in sorted(filter(selected,paths)):
 text=subprocess.check_output(['git','show',args.ref+':'+path],cwd=repo,text=True) if args.ref else (repo/path).read_text()
 manifest['files'][path]={'imports':re.findall(r'^import (.+)$',text,re.M),'singleton_symbols':sorted(set(re.findall(r'\b((?:NoesisController|Oasis|ShellState|Theme|Appearance)\.[\w.]+)',text))),'processes':re.findall(r'Process\s*\{\s*id:\s*(\w+)',text),'file_views':re.findall(r'FileView\s*\{\s*path:\s*([^;\n]+)',text),'ipc_targets':re.findall(r'IpcHandler\s*\{\s*target:\s*"([^"]+)"',text),'timers':len(re.findall(r'\bTimer\s*\{',text))}
print(json.dumps(manifest,indent=2))
