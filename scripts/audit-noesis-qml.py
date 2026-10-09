#!/usr/bin/env python3
"""Read-only inventory of the reviewed QML boundary; no live home reads."""
from pathlib import Path
import json,re,subprocess
repo=Path(__file__).resolve().parents[1]
paths=subprocess.check_output(['git','ls-tree','-r','--name-only','aca05d1'],cwd=repo,text=True).splitlines()
paths=[p for p in paths if p.endswith('.qml') and ('wrayth/modules/learning/' in p or p.endswith('/services/Oasis.qml') or p.endswith('/config/NoesisStyle.qml'))]
manifest={'baseline':'aca05d1','files':{}}
for path in paths:
 text=subprocess.check_output(['git','show','aca05d1:'+path],cwd=repo,text=True)
 manifest['files'][path]={'imports':re.findall(r'^import (.+)$',text,re.M),'singleton_symbols':sorted(set(re.findall(r'\b(Oasis\.[\w]+|ShellState\.[\w]+|Theme\.[\w]+|Appearance\.[\w.]+)',text))),'processes':re.findall(r'Process\s*\{\s*id:\s*(\w+)',text),'file_views':re.findall(r'FileView\s*\{\s*path:\s*([^;\n]+)',text),'ipc_targets':re.findall(r'IpcHandler\s*\{\s*target:\s*"([^"]+)"',text),'timers':len(re.findall(r'\bTimer\s*\{',text))}
print(json.dumps(manifest,indent=2))
