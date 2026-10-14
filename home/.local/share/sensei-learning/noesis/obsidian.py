"""Native lifecycle probes without relying on a particular Electron installation."""
import os
from pathlib import Path


def app_running(proc=Path('/proc')):
    for entry in proc.iterdir():
        if not entry.name.isdecimal():continue
        try:
            if entry.stat().st_uid!=os.getuid():continue
            args=(entry/'cmdline').read_bytes().decode(errors='replace').split('\0')
        except (OSError,ProcessLookupError):continue
        if any(Path(arg).name.lower() in ('obsidian','obsidian.appimage') for arg in args[:2] if arg):return True
        if any(Path(arg).name=='app.asar' and Path(arg).parent.name.lower()=='obsidian' for arg in args if arg and not arg.startswith('obsidian://')):return True
    return False
