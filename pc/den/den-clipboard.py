#!/usr/bin/env python3
"""Event-driven, bounded text/PNG clipboard exchange over pinned SSH. No disk payloads."""
import base64, hashlib, json, os, pathlib, selectors, signal, subprocess, sys
SELF = str(pathlib.Path(__file__).resolve())
LIMIT = 8 * 1024 * 1024
import time
PASSWORD_HINT='x-kde-passwordManagerHint'

def event():
    if os.environ.get('CLIPBOARD_STATE') in ('nil', 'clear', 'sensitive'):
        return
    try:
        types = subprocess.check_output(['wl-paste', '--list-types'], timeout=2).decode().splitlines()
        if PASSWORD_HINT in types or 'application/x-keepassxc-secret' in types:
            return
        mime = next((t for t in ('text/plain;charset=utf-8', 'text/plain', 'image/png') if t in types), None)
        if not mime:
            return
        data = sys.stdin.buffer.read(LIMIT + 1)
        if len(data) > LIMIT:
            return
        print(json.dumps({'mime': mime, 'data': base64.b64encode(data).decode()}), flush=True)
    except (OSError,subprocess.SubprocessError,UnicodeError):
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
    current = None
    if receive_initial:
        mime, data, current = validate(sys.stdin.readline())
        subprocess.run(['wl-copy', '--type', mime], input=data, check=True, timeout=3, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    watcher = subprocess.Popen(['wl-paste', '--watch', sys.executable, SELF, 'event'], stdout=subprocess.PIPE, text=True)
    selector = selectors.DefaultSelector()
    selector.register(sys.stdin, selectors.EVENT_READ, 'peer')
    selector.register(watcher.stdout, selectors.EVENT_READ, 'local')
    buffers = {'peer':b'', 'local':b''}
    try:
        while True:
            for key, _ in selector.select():
                chunk = os.read(key.fd,65536)
                if not chunk:
                    if key.data == 'local':raise RuntimeError('clipboard offer watcher stopped')
                    return
                buffers[key.data] += chunk
                while b'\n' in buffers[key.data]:
                    line, buffers[key.data] = buffers[key.data].split(b'\n',1)
                    try:
                        mime, data, digest = validate(line)
                        if key.data == 'local':
                            if digest == current:continue
                            current = digest
                            sys.stdout.buffer.write(line+b'\n');sys.stdout.buffer.flush()
                        else:
                            subprocess.run(['wl-copy', '--type', mime], input=data, check=True, timeout=3, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                            current = digest
                    except (ValueError, KeyError, TypeError, subprocess.SubprocessError):
                        continue
                if len(buffers[key.data])>LIMIT*2:raise RuntimeError('oversized clipboard frame')
    finally:
        selector.close()
        if watcher.poll() is None:watcher.terminate()
        try:watcher.wait(timeout=3)
        except subprocess.TimeoutExpired:watcher.kill();watcher.wait()
        watcher.stdout.close()

def hub():
    state = pathlib.Path.home() / '.local/state/homie-control'
    # Remote worker uses the running compositor's actual Wayland socket, not an SSH shell's stale environment.
    remote = "python3 -c 'import json,os,subprocess; i=json.loads(subprocess.check_output([\"hyprctl\",\"-i\",\"0\",\"instances\",\"-j\"]))[0]; os.environ.update(WAYLAND_DISPLAY=i[\"wl_socket\"],XDG_RUNTIME_DIR=\"/run/user/1000\"); os.execv(\"/usr/bin/python3\",[\"python3\",os.path.expanduser(\"~/.local/state/homie-control/den-clipboard.py\"),\"receiver\"])'"
    processes = [subprocess.Popen([sys.executable, SELF, 'worker'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0),
                 subprocess.Popen(['ssh', '-F', str(state/'client.conf'), 'homie', remote], stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0)]
    selector = selectors.DefaultSelector()
    for n, process in enumerate(processes):
        selector.register(process.stdout, selectors.EVENT_READ, n)
    # Reconnect never snapshots the current clipboard: wl-paste --watch supplies
    # sensitivity metadata for actual offers. An unset source must not clear a peer.
    digest = None
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
            try:process.stdin.close()
            except (OSError,BrokenPipeError):pass
            if process.poll() is None:process.terminate()
        for process in processes:
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:process.kill();process.wait()
        selector.close()

def reconnect():
    delay=2
    while True:
        started=time.monotonic()
        try:hub()
        except (OSError,ValueError,subprocess.SubprocessError,RuntimeError):
            print('Clipboard peer unavailable; waiting to reconnect',file=sys.stderr,flush=True)
        if time.monotonic()-started>120:delay=2
        time.sleep(delay)
        delay=min(60,delay*2)

if __name__ == '__main__':
    def stop(signum, frame):
        raise SystemExit(0)
    signal.signal(signal.SIGTERM, stop)
    {'event':event,'worker':worker,'receiver':worker,'hub':reconnect}[sys.argv[1]]()
