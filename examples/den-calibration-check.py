#!/usr/bin/env python3
"""Run Mongla's actual held-out fit on a deterministic synthetic signal.

No ROS, hardware or network required. This is a portability/sanity check,
not a physical calibration result. The reviewed upstream file is hash-pinned.
"""
import argparse
import ast
import hashlib
import json
import socket
from collections.abc import Callable
from pathlib import Path
from typing import cast

import numpy as np

PIN = '2830bfaf0b8c0922ca4eafe74377645481631bf2abf489b335cf2c288599796f'


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source', type=Path, required=True)
    p.add_argument('--expected-sha', default=PIN)
    args = p.parse_args()
    data = args.source.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    if digest != args.expected_sha:
        p.error('Source hash differs from the reviewed revision; inspect before running.')
    # Extract the reviewed numerical function without importing ROS subscribers.
    tree = ast.parse(data)
    function = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == 'kfold_slope')
    namespace: dict[str, object] = {'np': np}
    exec(compile(ast.Module(body=[function], type_ignores=[]), str(args.source), 'exec'), namespace)  # noqa: S102 — hash-verified function above
    rng = np.random.default_rng(42)
    x = rng.normal(size=4096)
    y = .8*x + rng.normal(scale=.02, size=x.shape)
    fit_function = cast(Callable[[np.ndarray, np.ndarray], dict[str, float]], namespace['kfold_slope'])
    fit = fit_function(x, y)
    checks = {
        'known_gain': abs(fit['slope'] - .8) < .002,
        'held_out_noise': .015 < fit['holdout_rms_px'] < .025,
        'beats_null_model': fit['holdout_rms_px'] < fit['null_rms_px']/10,
        'finite': all(np.isfinite(v) for v in fit.values()),
    }
    print(json.dumps({'host': socket.gethostname(), 'signal': 'synthetic, dimensionless',
                      'source_sha256': digest, 'numpy': np.__version__,
                      'checks': checks, 'fit': fit}, indent=2))
    if not all(checks.values()):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
