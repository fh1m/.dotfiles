"""Shared desktop capabilities. No drive identities or private state in Git."""
import json
import os
import subprocess
from pathlib import Path

def config():
    try:
        return json.loads((Path.home()/'.config/sensei/machine.json').read_text())
    except (OSError, ValueError):
        return {'profile': 'pc', 'primaryOutput': ''}

def gpu_pci():
    for device in sorted(Path('/sys/bus/pci/devices').glob('*')):
        try:
            if (device/'vendor').read_text().strip() == '0x10de' and (device/'class').read_text().strip().startswith('0x03'):
                return device.name
        except OSError:
            pass
    return ''

def command(args, default=''):
    try:
        return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL, timeout=3).strip()
    except (OSError, subprocess.SubprocessError):
        return default

def facts():
    settings = config()
    try:
        monitors = json.loads(command(['hyprctl', 'monitors', '-j'], '[]'))
    except ValueError:
        monitors = []
    gpu_name = command(['nvidia-smi', '--query-gpu=name', '--format=csv,noheader'], 'NVIDIA GPU').splitlines()[0]
    cpu = next((line.split(':', 1)[1].strip() for line in Path('/proc/cpuinfo').read_text().splitlines() if line.startswith('model name')), 'CPU')
    output = settings.get('primaryOutput', '')
    if not any(m['name'] == output for m in monitors):
        output = next((m['name'] for m in monitors if m.get('focused')), monitors[0]['name'] if monitors else '')
    return {**settings, 'primaryOutput': output, 'gpuPCI': gpu_pci(), 'gpuName': gpu_name,
            'cpuName': cpu, 'hasBattery': bool(list(Path('/sys/class/power_supply').glob('BAT*'))),
            'hasWireless': bool(list(Path('/sys/class/net').glob('*/wireless'))), 'hasScreenPad': False, 'hasIntelGPU': False}

def desktop_state():
    path = Path.home()/'.config/sensei/desktop-state.json'
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {'training': False}

def save_state(value):
    path = Path.home()/'.config/sensei/desktop-state.json'
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix('.tmp')
    temp.write_text(json.dumps(value))
    temp.chmod(0o600)
    temp.replace(path)

def clean_graphics_env():
    env = dict(os.environ)
    for key in ['DRI_PRIME', '__NV_PRIME_RENDER_OFFLOAD', '__GLX_VENDOR_LIBRARY_NAME',
                '__EGL_VENDOR_LIBRARY_FILENAMES', '__VK_LAYER_NV_optimus',
                'VK_ICD_FILENAMES', 'VK_DRIVER_FILES', 'LIBVA_DRIVER_NAME', 'NVD_BACKEND']:
        env.pop(key, None)
    return env
