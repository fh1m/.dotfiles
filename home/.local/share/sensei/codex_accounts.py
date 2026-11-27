"""Persistent, identity-bound Codex account monitoring state (no auth material)."""
from __future__ import annotations
import hashlib, json, os, tempfile, time
from pathlib import Path


def stable_id(source: str, identity: str) -> str:
    return hashlib.sha256((source + "\0" + identity).encode()).hexdigest()[:24]


def empty_state():
    return {"schema": 1, "monitored": {}, "cache": {}}


def read_state(path):
    try:
        value = json.loads(Path(path).read_text())
        if value.get("schema") != 1 or not isinstance(value.get("monitored"), dict) or not isinstance(value.get("cache"), dict):
            raise ValueError("invalid account state")
        return value
    except FileNotFoundError:
        return empty_state()


def write_state(path, state):
    path = Path(path); path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(dir=path.parent, prefix=".codex-accounts-")
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w") as stream:
            json.dump(state, stream, separators=(",", ":")); stream.flush(); os.fsync(stream.fileno())
        os.replace(temp, path); os.chmod(path, 0o600)
    finally:
        try: os.unlink(temp)
        except FileNotFoundError: pass


def monitor(state, account):
    state["monitored"][account["id"]] = {"source": account["source"], "identity": account["identity"], "name": account["name"]}


def unmonitor(state, account_id):
    state["monitored"].pop(account_id, None)
    state["cache"].pop(account_id, None)


def save_measurement(state, account_id, source, identity, measurement, now=None):
    if not isinstance(measurement, dict) or not isinstance(measurement.get("rateLimits"), (dict, list)):
        raise ValueError("malformed quota response")
    if not isinstance(measurement.get("fetchedAt"), (int, float)) or isinstance(measurement["fetchedAt"], bool):
        raise ValueError("missing native measurement timestamp")
    if measurement["fetchedAt"] > (time.time() if now is None else now) + 30:
        raise ValueError("future measurement timestamp")
    state["cache"][account_id] = {"source": source, "identity": identity, "measurement": measurement}


def cached(state, account_id, source, identity, now=None):
    entry = state["cache"].get(account_id)
    if not entry or entry.get("source") != source or entry.get("identity") != identity:
        return None
    measurement = entry.get("measurement")
    if not isinstance(measurement, dict): return None
    out = dict(measurement)
    age = (time.time() if now is None else now) - out["fetchedAt"]
    expired = False
    for key in ("primary", "secondary"):
        window = out.get("rateLimits", {}).get(key) if isinstance(out.get("rateLimits"), dict) else None
        reset = window.get("resetsAt") if isinstance(window, dict) else None
        if isinstance(reset, (int, float)) and reset <= (time.time() if now is None else now): expired = True
    out["stale"] = age > 300 or expired
    if expired: out["state"] = "expired"
    elif age > 300: out["state"] = "stale"
    return out


def failed_result(state, account_id, source, identity, error, now=None):
    result = cached(state, account_id, source, identity, now)
    if result is None: return {"state": "unknown", "error": str(error), "stale": True}
    result["error"] = str(error); result["stale"] = True
    if result.get("state") not in ("expired", "stale"): result["state"] = "stale"
    return result
