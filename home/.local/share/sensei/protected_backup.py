"""Prepare one approved root-readable SDK archive for the ordinary user backup."""
import hashlib
import json
import os
from pathlib import Path
import selectors
import signal
import stat
import subprocess
import tempfile
import time
import shutil

import engineering as e

HELPER = '/usr/local/libexec/den-rootfs-export'
GIB = 1024 ** 3


def inspect_source():
    result = subprocess.run(['/usr/bin/sudo', '-n', HELPER, 'inspect'],
                            stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=120)
    if result.returncode:
        raise ValueError('Protected rootfs enrollment unavailable; no source exclusion is allowed')
    return json.loads(result.stdout)


def archive_identity(path):
    value = path.lstat()
    if not stat.S_ISREG(value.st_mode):
        raise ValueError('Protected archive is not a regular file')
    return [value.st_ino, value.st_size, value.st_mtime_ns, value.st_ctime_ns]


def prepare(spec, state):
    folder = Path(state) / 'backup-exports'
    folder.mkdir(parents=True, exist_ok=True, mode=0o700)
    with e.locked(folder / 'rootfs.lock'):
        return _prepare(spec, folder)


def _prepare(spec, folder):
    source = str(Path(spec['source']).resolve(strict=True))
    if any(character in source for character in '*?[]'):
        raise ValueError('Protected source cannot contain backup-pattern metacharacters')
    before = inspect_source()
    if before['source'] != source:
        raise ValueError('Requested source differs from root-owned enrollment')
    archive = folder / 'rootfs.tar.zst'
    receipt_path = folder / 'rootfs.json'
    previous = e.read(receipt_path, {})
    try:
        if (previous.get('source') == source and previous.get('fingerprint') == before['fingerprint']
                and previous.get('archiveIdentity') == archive_identity(archive)):
            return dict(previous, reused=True)
    except FileNotFoundError:
        pass
    reserve = int(spec.get('minimumFreeGiB', 20)) * GIB
    maximum = int(spec.get('maximumArchiveGiB', 8)) * GIB
    if reserve < 20 * GIB or maximum < GIB or maximum > 8 * GIB:
        raise ValueError('Invalid protected-archive storage budget')
    if shutil.disk_usage(folder).free < reserve + maximum:
        raise ValueError('Insufficient space for bounded protected export plus critical reserve')
    fd, temporary = tempfile.mkstemp(prefix='.rootfs-', suffix='.tmp', dir=folder)
    temporary = Path(temporary)
    producer = None
    diagnostic = bytearray()
    try:
        with os.fdopen(fd, 'wb') as output, selectors.DefaultSelector() as selector:
            producer = subprocess.Popen(['/usr/bin/sudo', '-n', HELPER, 'export'],
                                        stdin=subprocess.DEVNULL, stdout=output,
                                        stderr=subprocess.PIPE, start_new_session=True)
            os.set_blocking(producer.stderr.fileno(), False)
            selector.register(producer.stderr, selectors.EVENT_READ)
            deadline = time.monotonic() + 1800
            while True:
                for key, _ in selector.select(timeout=1):
                    chunk = os.read(key.fd, 65536)
                    if chunk:
                        diagnostic.extend(chunk)
                        del diagnostic[:-8192]
                    else:
                        selector.unregister(key.fileobj)
                if temporary.stat().st_size > maximum or shutil.disk_usage(folder).free < reserve:
                    raise ValueError('Protected export exceeded its storage budget')
                if time.monotonic() > deadline:
                    raise ValueError('Protected export exceeded its time budget')
                code = producer.poll()
                if code is not None:
                    if code:
                        raise ValueError('Protected export failed; original archive remains')
                    break
            output.flush()
            os.fsync(output.fileno())
        after = inspect_source()
        if before != after:
            raise ValueError('Protected source changed during export; original archive remains')
        digest = hashlib.sha256()
        with temporary.open('rb') as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                digest.update(chunk)
        temporary.replace(archive)
        receipt = dict(after, archive=str(archive), sha256=digest.hexdigest(),
                       archiveIdentity=archive_identity(archive), preparedAt=time.time())
        e.save(receipt_path, receipt)
        return dict(receipt, reused=False)
    finally:
        if producer is not None:
            if producer.poll() is None:
                # sudo forwards termination; closing stdout also breaks the tar pipeline.
                try:
                    os.killpg(producer.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    producer.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(producer.pid, signal.SIGKILL)
                    producer.wait(timeout=5)
            producer.stderr.close()
        temporary.unlink(missing_ok=True)
        if diagnostic:
            path = folder / 'rootfs-diagnostics.log'
            with path.open('wb') as stream:
                os.fchmod(stream.fileno(), 0o600)
                stream.write(diagnostic)
