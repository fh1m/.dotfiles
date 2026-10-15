#!/usr/bin/env python3
"""Non-mutating drive/access check; intentionally does not inspect private filenames."""
import json, os, subprocess
from pathlib import Path
root=Path.home()/"Drives"
names=["Datasets","Storage","Windows-SATA","Windows-NVMe","Legacy-Linux","Home-Archive"]
checks=[]
for name in names:
    path=root/name
    target=path.resolve()
    result=subprocess.run(["findmnt","--json","--target",str(target),"--output","TARGET,FSTYPE,OPTIONS"],capture_output=True,text=True)
    mounted=json.loads(result.stdout).get("filesystems",[]) if result.returncode==0 else []
    exact=next((m for m in mounted if m["target"]==str(target)),None)
    readable=path.is_dir() and os.access(path,os.R_OK|os.X_OK)
    row={"volume":name,"mounted":bool(exact),"readable":readable,"mode":"ro" if exact and "ro" in exact["options"].split(",") else "rw"}
    checks.append(row)
print(json.dumps(checks,indent=2))
raise SystemExit(0 if all(c["mounted"] and c["readable"] for c in checks) else 1)
