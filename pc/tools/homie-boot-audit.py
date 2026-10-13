#!/usr/bin/python3 -I
"""Private, read-only boot observations for a later Windows/Linux round trip."""
import datetime
import json
import os
from pathlib import Path
import subprocess


def observe(*command):
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=15)
        return dict(code=result.returncode, output=result.stdout.strip(), error=result.stderr.strip())
    except (OSError, subprocess.TimeoutExpired) as exc:
        return dict(code=-1, error=str(exc))


if __name__ == '__main__':
    if os.geteuid() != 0:
        raise SystemExit('Boot audit requires root to read firmware; it does not change it')
    output = Path('/var/lib/homie-boot-audit')
    # Keep the privileged collector's output in root-owned private storage.
    for parent in [output, *output.parents]:
        if parent.is_symlink():
            raise SystemExit('Audit output parent is symlinked; refused')
    output.mkdir(parents=True, exist_ok=True)
    output.chmod(0o700)
    boot_id = Path('/proc/sys/kernel/random/boot_id').read_text().strip()
    data = dict(timestamp=datetime.datetime.now(datetime.timezone.utc).isoformat(), boot_id=boot_id,
                kernel=os.uname().release,
                firmware=observe('/usr/bin/efibootmgr', '-v'),
                disks=observe('/usr/bin/lsblk', '-b', '-J', '-o', 'NAME,MODEL,SERIAL,SIZE,FSTYPE,UUID,PARTUUID,MOUNTPOINTS'),
                root=observe('/usr/bin/findmnt', '-no', 'SOURCE,UUID,OPTIONS', '/'),
                esp=observe('/usr/bin/findmnt', '-no', 'SOURCE,PARTUUID', '/boot'),
                nvidia=observe('/usr/bin/nvidia-smi', '--query-gpu=name,driver_version,pci.bus_id', '--format=csv,noheader'),
                failed_units=observe('/usr/bin/systemctl', '--failed', '--no-legend', '--no-pager'),
                theme={})
    import hashlib
    for path in ['/boot/limine.conf', '/boot/EFI/LIMINE/limine.conf', '/boot/EFI/BOOT/limine.conf']:
        file = Path(path)
        if file.is_file():
            content = file.read_bytes()
            data['theme'][path] = dict(sha256=hashlib.sha256(content).hexdigest(),
                                      roots=[line for line in content.decode().splitlines() if line.startswith('/') and not line.startswith('//')])
    # Exclusive creation prevents overwrite/symlink attacks in the user's directory.
    path = output / (boot_id + '-' + datetime.datetime.now(datetime.timezone.utc).strftime('%H%M%S%f') + '.json')
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'w') as stream:
        json.dump(data, stream, indent=2)
        stream.write('\n')
    print('Private boot observations saved:', path)
