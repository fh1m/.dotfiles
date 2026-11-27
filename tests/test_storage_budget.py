import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace

import pytest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('den_storage_budget', ROOT / 'home/.local/share/sensei/storage_budget.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


@pytest.mark.parametrize('gib,state', [(19, 'critical'), (20, 'reserve-deficit'), (79, 'reserve-deficit'), (80, 'healthy')])
def test_nonroot_available_space_and_exact_reserve_boundaries(tmp_path, gib, state):
    disk = SimpleNamespace(f_bavail=gib * 2**30, f_bfree=200 * 2**30, f_frsize=1)
    result = module.root_headroom(tmp_path, lambda _: disk)
    assert result['state'] == state
    assert result['availableBytes'] == gib * 2**30


@pytest.mark.parametrize('policy', [{'reserveGiB': 5, 'criticalGiB': 20}, {'reserveGiB': True}, {'criticalGiB': -1}, []])
def test_invalid_user_budget_never_reports_healthy(tmp_path, policy):
    config = tmp_path / '.config/sensei-den/storage-budget.json'
    config.parent.mkdir(parents=True)
    config.write_text(json.dumps(policy))
    result = module.root_headroom(tmp_path)
    assert result['known'] is False and result['state'] == 'unknown'


def test_missing_filesystem_measurement_is_unknown(tmp_path):
    def unavailable(_):
        raise OSError('synthetic unavailable mount')
    assert module.root_headroom(tmp_path, unavailable)['state'] == 'unknown'
