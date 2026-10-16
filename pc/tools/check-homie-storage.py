#!/usr/bin/env python3
"""Read-only automount/access check; no private filenames are printed or retained."""
import json
import os
from pathlib import Path
import subprocess

PROTECTED={'Windows-SATA','Windows-NVMe','Legacy-Linux','Home-Archive'}
VOLUMES=['Datasets','Storage',*sorted(PROTECTED)]

def inspect(path, protected=False):
    path=Path(path);target=path.resolve();accessible=False
    try:
        # stat() of an autofs root does not prove that the underlying disk works.
        # Enter the directory before sampling findmnt; discard names immediately.
        with os.scandir(target) as entries:next(entries,None)
        accessible=os.access(target,os.R_OK|os.X_OK)
    except OSError:pass
    result=subprocess.run(['findmnt','--json','--target',str(target),'--output','TARGET,FSTYPE,OPTIONS'],capture_output=True,text=True)
    mounted=json.loads(result.stdout).get('filesystems',[]) if result.returncode==0 else []
    exact=next((m for m in reversed(mounted) if m['target']==str(target) and m['fstype']!='autofs'),None)
    mode='ro' if exact and 'ro' in exact['options'].split(',') else 'rw' if exact else 'unavailable'
    return {'volume':path.name,'mounted':bool(exact),'readable':accessible and bool(exact),
            'mode':mode,'protectionOkay':not protected or mode=='ro'}

def main():
    checks=[inspect(Path.home()/'Drives'/name,name in PROTECTED) for name in VOLUMES]
    print(json.dumps(checks,indent=2))
    return 0 if all(c['mounted'] and c['readable'] and c['protectionOkay'] for c in checks) else 1

if __name__=='__main__':raise SystemExit(main())
