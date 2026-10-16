#!/usr/bin/env python3
"""Deterministic synthetic stationary-IMU calibration; no hardware claims."""
import csv
import json
import math
from pathlib import Path
import statistics

out=Path('results');out.mkdir(exist_ok=True)
truth=.035
samples=[truth+.006*math.sin(i*.37)+.002*math.cos(i*.71) for i in range(1000)]
bias=statistics.mean(samples);residual=[x-bias for x in samples]
with (out/'imu.csv').open('w',newline='') as f:
 w=csv.writer(f);w.writerow(['time_s','gyro_rad_s','corrected_rad_s'])
 w.writerows((i*.01,x,residual[i]) for i,x in enumerate(samples))
report={'source':'synthetic deterministic stationary fixture','units':'rad/s','samples':len(samples),
        'true_bias':truth,'estimated_bias':bias,'bias_error':abs(bias-truth),
        'rms_before':math.sqrt(statistics.mean(x*x for x in samples)),
        'rms_after':math.sqrt(statistics.mean(x*x for x in residual)),
        'passed':abs(bias-truth)<.0001}
(out/'metrics.json').write_text(json.dumps(report,indent=2))
points=' '.join(f'{40+i*.7:.1f},{150-x*1800:.1f}' for i,x in enumerate(samples))
corrected=' '.join(f'{40+i*.7:.1f},{150-x*1800:.1f}' for i,x in enumerate(residual))
(out/'calibration.svg').write_text(f'''<svg xmlns="http://www.w3.org/2000/svg" width="800" height="240" viewBox="0 0 800 240"><rect width="800" height="240" fill="#100c10"/><text x="35" y="30" fill="#ebe4de" font-family="monospace" font-size="15">SYNTHETIC IMU // stationary bias calibration</text><path d="M40 150H750" stroke="#4a4147"/><polyline points="{points}" fill="none" stroke="#ee287a"/><polyline points="{corrected}" fill="none" stroke="#b5c6be"/><text x="35" y="215" fill="#c3b8be" font-family="monospace">pink: raw rad/s · pale: bias corrected · dt 0.01 s</text></svg>''')
print(json.dumps(report));raise SystemExit(0 if report['passed'] else 1)
