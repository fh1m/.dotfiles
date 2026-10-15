#!/usr/bin/env python3
"""Event-driven, bounded text/PNG clipboard exchange over pinned SSH. No disk payloads."""
import base64, hashlib, json, os, pathlib, selectors, signal, subprocess, sys, threading
SELF = str(pathlib.Path(__file__).resolve())
LIMIT = 8 * 1024 * 1024

def event():
    if os.environ.get('CLIPBOARD_STATE') in ('nil', 'clear', 'sensitive'):
        return
    try:
        types = subprocess.check_output(['wl-paste', '--list-types'], timeout=2).decode().splitlines()
        mime = next((t for t in ('text/plain;charset=utf-8', 'text/plain', 'image/png') if t in types), None)
        if not mime:
            return
        data = sys.stdin.buffer.read(LIMIT + 1)
        if len(data) > LIMIT:
            return
        print(json.dumps({'mime': mime, 'data': base64.b64encode(data).decode()}), flush=True)
    except (subprocess.SubprocessError, UnicodeError):
        pass

def validate(line):
    if len(line) > LIMIT * 2:
        raise ValueError('oversized frame')
    obj = json.loads(line)
    if obj['mime'] not in ('text/plain;charset=utf-8', 'text/plain', 'image/png'):
        raise ValueError('unsupported MIME')
    data = base64.b64decode(obj['data'], validate=True)
    if len(data) > LIMIT:
        raise ValueError('oversized clipboard')
    digest = hashlib.sha256(obj['mime'].encode() + b'\0' + data).digest()
    return obj['mime'], data, digest

def worker(receive_initial=False):
    lock = threading.Lock()
    current = [None]
    if receive_initial:
        mime, data, digest = validate(sys.stdin.readline())
        current[0] = digest
        subprocess.run(['wl-copy', '--type', mime], input=data, check=True, timeout=3, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    watcher = subprocess.Popen(['wl-paste', '--watch', sys.executable, SELF, 'event'], stdout=subprocess.PIPE, text=True)
    def emit():
        for line in watcher.stdout:
            try:
                _, _, digest = validate(line)
                with lock:
                    if digest == current[0]:
                        continue
                    current[0] = digest
                    sys.stdout.write(line); sys.stdout.flush()
            except (ValueError, KeyError, TypeError):
                continue
    threading.Thread(target=emit, daemon=True).start()
    try:
        for line in sys.stdin:
            try:
                mime, data, digest = validate(line)
                with lock:
                    current[0] = digest
                    subprocess.run(['wl-copy', '--type', mime], input=data, check=True, timeout=3, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except (ValueError, KeyError, TypeError, subprocess.SubprocessError):
                continue
    finally:
        watcher.terminate(); watcher.wait(timeout=3)

def hub():
    state = pathlib.Path.home() / '.local/state/homie-control'
    # Remote worker uses the running compositor's actual Wayland socket, not an SSH shell's stale environment.
    remote = "python3 -c 'import json,os,subprocess; i=json.loads(subprocess.check_output([\"hyprctl\",\"-i\",\"0\",\"instances\",\"-j\"]))[0]; os.environ.update(WAYLAND_DISPLAY=i[\"wl_socket\"],XDG_RUNTIME_DIR=\"/run/user/1000\"); os.execv(\"/usr/bin/python3\",[\"python3\",os.path.expanduser(\"~/.local/state/homie-control/den-clipboard.py\"),\"receiver\"])'"
    processes = [subprocess.Popen([sys.executable, SELF, 'worker'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0),
                 subprocess.Popen(['ssh', '-F', str(state/'client.conf'), 'homie', remote], stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0)]
    # Laptop owns the initial clipboard. Initialize the receiver even if it is empty,
    # so its first later copy can flow back without waiting for a laptop copy.
    try:
        types = subprocess.check_output(['wl-paste', '--list-types'], stderr=subprocess.DEVNULL, timeout=2).decode().splitlines()
        mime = next((t for t in ('text/plain;charset=utf-8', 'text/plain', 'image/png') if t in types), None)
        data = subprocess.check_output(['wl-paste', '--no-newline', '--type', mime], timeout=2) if mime else b''
    except subprocess.SubprocessError:
        mime, data = None, b''
    if len(data) > LIMIT:
        mime, data = None, b''
    initial = (json.dumps({'mime': mime or 'text/plain;charset=utf-8', 'data': base64.b64encode(data).decode()}) + '\n').encode()
    _, _, initial_digest = validate(initial)
    processes[1].stdin.write(initial); processes[1].stdin.flush()
    selector = selectors.DefaultSelector()
    for n, process in enumerate(processes):
        selector.register(process.stdout, selectors.EVENT_READ, n)
    digest = initial_digest
    latest = initial
    try:
        while True:
            for key, _ in selector.select():
                n = key.data
                line = key.fileobj.readline(LIMIT * 2 + 1)
                if not line or not line.endswith(b'\n'):
                    raise RuntimeError('clipboard peer disconnected or invalid frame')
                try:
                    _, _, new_digest = validate(line)
                except (ValueError, KeyError, TypeError):
                    continue
                if new_digest != digest:
                    digest = new_digest; latest = line
                    processes[1-n].stdin.write(line); processes[1-n].stdin.flush()
    finally:
        for process in processes:
            process.stdin.close()
            process.terminate()
        for process in processes:
            process.wait(timeout=5)

if __name__ == '__main__':
    def stop(signum, frame):
        raise SystemExit(0)
    signal.signal(signal.SIGTERM, stop)
    {'event': event, 'worker': worker, 'receiver': lambda: worker(True), 'hub': hub}[sys.argv[1]]()
