"""Select a live desktop by identity, never by an unstable instance index."""
import json
import os
from pathlib import Path
import socket
import subprocess
import time


def live_socket(path, timeout):
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
            connection.settimeout(timeout)
            connection.connect(str(path))
        return True
    except OSError:
        return False


def wait_for_session(timeout=45, environ=None):
    environment = os.environ if environ is None else environ
    deadline = time.monotonic() + timeout
    runtime = Path(environment.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}'))
    while time.monotonic() < deadline:
        try:
            remaining = deadline - time.monotonic()
            instances = json.loads(subprocess.check_output(
                ['hyprctl', 'instances', '-j'], env=environment,
                stderr=subprocess.DEVNULL, timeout=min(3, remaining)))
            valid = []
            for instance in instances:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    break
                if (live_socket(runtime / 'hypr' / instance['instance'] / '.socket.sock', min(.2, remaining))
                        and live_socket(runtime / instance['wl_socket'], min(.2, remaining))):
                    valid.append(instance)
            inherited = environment.get('HYPRLAND_INSTANCE_SIGNATURE')
            selected = next((item for item in valid if item['instance'] == inherited), None)
            if selected is not None:
                return selected, runtime
            if len(valid) == 1:
                return valid[0], runtime
            if len(valid) > 1:
                raise RuntimeError('Den waiting: multiple graphical sessions; select an explicit session')
        except (OSError, ValueError, KeyError, subprocess.SubprocessError):
            pass
        time.sleep(max(0, min(1, deadline - time.monotonic())))
    raise TimeoutError(f'Den unavailable: no live graphical socket within {timeout:g} seconds')
