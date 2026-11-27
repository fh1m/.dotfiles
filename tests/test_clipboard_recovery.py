"""Exercise real worker framing/EOF against an isolated clipboard transport."""
import base64
import json
import os
import subprocess
import sys
import time
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKER = ROOT / "pc/den/den-clipboard.py"


def wait_for(predicate, timeout=4):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.01)
    raise AssertionError("Clipboard worker did not reach the expected state")

def png_fixture():
    def chunk(kind, payload):
        return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(b"\x00\xff\x1b\x84")) + chunk(b"IEND", b""))


def test_batched_and_fragmented_offers_are_applied_then_eof_reaps_watcher(tmp_path):
    ready = tmp_path / "watcher-pid"
    receipts = tmp_path / "copies.jsonl"
    paste = tmp_path / "wl-paste"
    paste.write_text("#!" + sys.executable + "\nimport os,pathlib,signal\n"
                     "pathlib.Path(os.environ['TEST_WATCHER_PID']).write_text(str(os.getpid()))\n"
                     "signal.pause()\n")
    copy = tmp_path / "wl-copy"
    copy.write_text("#!" + sys.executable + "\nimport base64,json,os,sys\n"
                    "data=sys.stdin.buffer.read()\n"
                    "with open(os.environ['TEST_COPY_RECEIPTS'],'a') as f:\n"
                    " f.write(json.dumps({'mime':sys.argv[-1],'data':base64.b64encode(data).decode()})+'\\n')\n")
    paste.chmod(0o755)
    copy.chmod(0o755)
    env = dict(os.environ, PATH=str(tmp_path) + os.pathsep + os.environ["PATH"],
               TEST_WATCHER_PID=str(ready), TEST_COPY_RECEIPTS=str(receipts))
    process = subprocess.Popen([sys.executable, str(WORKER), "worker"], env=env,
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    frames = [{"mime": "text/plain", "data": base64.b64encode(b"den framing first").decode()},
              {"mime": "image/png", "data": base64.b64encode(png_fixture()).decode()},
              {"mime": "text/plain", "data": base64.b64encode(b"fragment completed").decode()}]

    def applied():
        return [json.loads(line) for line in receipts.read_text().splitlines()] if receipts.exists() else []

    try:
        wait_for(ready.exists)
        # A TextIO.readline()+select loop strands the second already-buffered
        # frame. Both complete offers must progress without another peer write.
        process.stdin.write(b"".join(json.dumps(row).encode() + b"\n" for row in frames[:2]))
        process.stdin.flush()
        wait_for(lambda: len(applied()) == 2)
        assert applied() == frames[:2]
        fragment = json.dumps(frames[2]).encode() + b"\n"
        process.stdin.write(fragment[:11])
        process.stdin.flush()
        process.stdin.write(fragment[11:])
        process.stdin.flush()
        wait_for(lambda: len(applied()) == 3)
        assert applied() == frames
        process.stdin.close()
        process.wait(timeout=4)
        assert process.returncode == 0, process.stderr.read().decode()
        watcher_pid = int(ready.read_text())
        assert not Path("/proc", str(watcher_pid)).exists()
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=4)
        for stream in (process.stdin, process.stdout, process.stderr):
            if stream and not stream.closed:
                stream.close()
