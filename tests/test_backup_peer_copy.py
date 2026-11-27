"""Real Restic repositories prove copy identity, freshness and retained evidence."""
import datetime
import importlib.machinery
import importlib.util
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from unittest.mock import patch

import pytest

ROOT = Path(__file__).resolve().parents[1]
RESTIC = shutil.which("restic")
pytestmark = pytest.mark.skipif(RESTIC is None, reason="Requires the real Restic executable")


def fixture_backup(tmp_path):
    sys.path.insert(0, str(ROOT / "home/.local/share/sensei"))
    loader = importlib.machinery.SourceFileLoader("peer_copy_fixture", str(ROOT / "home/.local/bin/sensei-den"))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    with patch.object(Path, "home", return_value=tmp_path):
        loader.exec_module(module)
    module.CONFIG.mkdir(parents=True)
    source = tmp_path / "source"
    source.write_text("independent reasoning remains intact")
    password = tmp_path / "password"
    password.write_text("disposable-fixture-only")
    password.chmod(0o600)
    repository = tmp_path / "repository"
    copied = tmp_path / "copied"
    cfg = {"repository": str(repository), "passwordFile": str(password), "paths": [str(source)],
           "minimumFreeGiB": 0, "peerCopy": {"repository": str(copied), "fromRepository": str(repository),
                                          "passwordFile": str(password), "minimumFreeGiB": 0}}
    (module.CONFIG / "backup.json").write_text(json.dumps(cfg))
    env = dict(os.environ, RESTIC_REPOSITORY=str(repository), RESTIC_PASSWORD_FILE=str(password))
    subprocess.run([RESTIC, "init"], env=env, capture_output=True, text=True, check=True, timeout=30)
    assert module.backup("run")["ok"]
    return module, cfg, source, env


def test_offline_copy_does_not_keep_a_stale_success(tmp_path):
    module, cfg, source, env = fixture_backup(tmp_path)
    first = module.backup("peer-copy")
    assert first["ok"] and first["sourceSnapshot"] == first["latestSourceSnapshot"]
    second = module.backup("peer-copy")
    assert second["copiedSnapshot"] == first["copiedSnapshot"]
    Path(cfg["repository"]).rename(tmp_path / "disconnected-repository")
    with pytest.raises(ValueError, match="Source snapshot inventory unavailable"):
        module.backup("peer-copy")
    status = module.backup("status")["peerCopy"]
    assert not status["ok"] and status["state"] == "blocked"
    assert status["copiedSnapshot"] == first["copiedSnapshot"]
    copied_env = dict(env, RESTIC_REPOSITORY=cfg["peerCopy"]["repository"])
    restored = subprocess.run([RESTIC, "dump", first["copiedSnapshot"], str(source)], env=copied_env,
                              capture_output=True, text=True, check=True, timeout=30)
    assert restored.stdout == "independent reasoning remains intact"


def test_source_checkpoint_advancing_during_copy_is_not_reported_current(tmp_path):
    module, cfg, source, env = fixture_backup(tmp_path)
    original = module.guarded_backup
    advanced = False

    def advance_source_after_real_copy(command, *args, **kwargs):
        nonlocal advanced
        result = original(command, *args, **kwargs)
        if "copy" in command and not advanced:
            advanced = True
            source.write_text("new experiment evidence")
            subprocess.run([RESTIC, "backup", "--tag", "digital-den", str(source)], env=env,
                           capture_output=True, text=True, check=True, timeout=30)
        return result

    with patch.object(module, "guarded_backup", side_effect=advance_source_after_real_copy):
        raced = module.backup("peer-copy")
    assert not raced["ok"] and raced["state"] == "awaiting-current-source"
    assert raced["sourceSnapshot"] != raced["latestSourceSnapshot"] and raced["copiedSnapshot"]
    current = module.backup("peer-copy")
    assert current["ok"] and current["sourceSnapshot"] == raced["latestSourceSnapshot"]
    receipt = module.STATE / "peer-copy-status.json"
    previous_day = datetime.datetime.now().astimezone() - datetime.timedelta(days=1)
    saved = json.loads(receipt.read_text())
    saved["sourceCreated"] = previous_day.isoformat()
    receipt.write_text(json.dumps(saved))
    aged = module.backup("status")["peerCopy"]
    assert not aged["ok"] and aged["state"] == "awaiting-current-source"
    assert aged["ageSeconds"] >= 23 * 3600
