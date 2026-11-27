"""Advisory working-space reserve; never prunes files or claims guaranteed capacity."""
import json
import math
import os
from pathlib import Path


def root_headroom(home=None, statvfs=os.statvfs):
    config = Path(home or Path.home()) / '.config/sensei-den/storage-budget.json'
    try:
        policy = json.loads(config.read_text()) if config.exists() else {}
        reserve = policy.get('reserveGiB', 80)
        critical = policy.get('criticalGiB', 20)
        if any(isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value)
               for value in (reserve, critical)) or not 0 < critical < reserve:
            raise ValueError('Invalid reserve ordering')
        disk = statvfs('/')
        available = disk.f_bavail * disk.f_frsize
        if available < 0:
            raise ValueError('Invalid available space')
        return {'known': True, 'availableBytes': available, 'reserveGiB': reserve,
                'criticalGiB': critical, 'state': 'critical' if available < critical * 2**30
                else 'reserve-deficit' if available < reserve * 2**30 else 'healthy'}
    except (OSError, ValueError, TypeError, AttributeError):
        return {'known': False, 'state': 'unknown', 'error': 'Storage budget unavailable or invalid'}
