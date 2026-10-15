#!/usr/bin/env python3
"""Execute a trusted synthetic gyroscope calibration and verify recoverable evidence.

This is a software experiment with generated measurements, not a hardware result.
No private vault, reader profile or third-party research code is used.
"""
import csv,hashlib,json,math,shutil,subprocess,sys,tempfile
from pathlib import Path
from statistics import mean,stdev
repo=Path(__file__).resolve().parents[1];sys.path.insert(0,str(repo/'home/.local/share/sensei-learning'))
from noesis.persistence import migration,parse
from noesis.models import create
from noesis.activities import record_activity
from noesis.index import Index
from noesis.recovery import backup,restore
from noesis.identity_recovery import replace_location
from noesis.scopes import register
from noesis.artifacts import inspect
from unittest.mock import patch
with tempfile.TemporaryDirectory(prefix='noesis-experiment-') as temporary:
 home=Path(temporary)
 with patch('pathlib.Path.home',return_value=home):
  vault=home/'vault';(vault/'System').mkdir(parents=True);(vault/'System/System.json').write_text(json.dumps({'directories':[],'types':{}}));migration(vault,True);register(vault)
  code=home/'implementation';code.mkdir();subprocess.run(['git','init','-q',str(code)],check=True)
  script=code/'calibrate.py';script.write_text('from statistics import mean\ndef estimate(samples):\n    return mean(samples)\n')
  subprocess.run(['git','-C',str(code),'add','calibrate.py'],check=True)
  subprocess.run(['git','-C',str(code),'-c','user.name=Noesis fixture','-c','user.email=fixture@example.invalid','commit','-qm','Trusted calibration implementation'],check=True)
  project=create(vault,'project','Stationary gyroscope calibration',fields={'repository':str(code)})
  experiment=create(vault,'experiment','Test zero-bias assumption',parent_id=project['id'],fields={'hypothesis':'Stationary angular velocity has mean zero within 0.005 rad/s','configuration':{'samples':1000,'rate_hz':100,'units':'rad/s'}})
  samples=[0.12+0.004*math.sin(n*0.1) for n in range(1000)]
  spec=__import__('importlib.util',fromlist=['spec_from_file_location']);module_spec=spec.spec_from_file_location('trusted_calibration',script);implementation=spec.module_from_spec(module_spec);module_spec.loader.exec_module(implementation)
  measured=mean(samples);bias=implementation.estimate(samples[:500]);residual=[v-bias for v in samples[500:]]
  assert abs(measured)>0.005;assert abs(mean(residual))<0.005
  data=home/'measurements.csv'
  with data.open('w',newline='') as stream:
   writer=csv.writer(stream);writer.writerow(['time_s','angular_velocity_rad_s']);writer.writerows((n/100,v) for n,v in enumerate(samples))
  import matplotlib;matplotlib.use('Agg')
  import matplotlib.pyplot as plt
  figure,axis=plt.subplots(figsize=(7,3));axis.plot([n/100 for n in range(1000)],samples,label='Generated stationary measurements');axis.axhline(0,color='black',linestyle='--',label='Original prediction');axis.axhline(bias,color='tab:orange',label='Estimated bias');axis.set(xlabel='Time (s)',ylabel='Angular velocity (rad/s)');axis.legend();figure.tight_layout();plot=home/'calibration.png';figure.savefig(plot,dpi=120);plt.close(figure)
  artifact=create(vault,'artifact','Gyroscope measurements',parent_id=experiment['id'],fields={'location':str(data),'sha256':hashlib.sha256(data.read_bytes()).hexdigest(),'units':'rad/s','ownership':'synthetic generated measurements'})
  create(vault,'artifact','Prediction and measurement figure',parent_id=experiment['id'],fields={'location':str(plot)})
  comparison=record_activity(vault,experiment['path'],'comparison','The zero-bias model contradicts generated measurements. Check bias calibration next.',predicted='0 ± 0.005 rad/s',observed=f'{measured:.6f} rad/s',units='rad/s',uncertainty=f'sample standard deviation {stdev(samples):.6f} rad/s',conclusion='Original zero-bias hypothesis rejected in this generated software fixture',code_snapshot=experiment['code_snapshot'],artifact_id=artifact['id'],next_experiment='Validate the estimated bias on held-out samples')
  record_activity(vault,experiment['path'],'comparison','Held-out numerical check',predicted='Residual mean within ±0.005 rad/s',observed=f'{mean(residual):.6f} rad/s',units='rad/s',code_snapshot=experiment['code_snapshot'])
  index=Index(vault);index.reconcile();assert len(index.timeline(experiment['id']))==2;assert index.record(experiment['id'])['props']['hypothesis']==experiment['hypothesis'];index.close()
  # Missing storage reports unavailable, while the history remains present.
  data.rename(home/'temporarily-disconnected.csv');assert inspect(vault,artifact['id'])['availability']=='artifact unavailable';(home/'temporarily-disconnected.csv').rename(data)
  report=backup(vault,home/'restic');restored=home/'restored';restore(report['snapshot_id'],restored,home/'restic');replace_location(restored,vault)
  index=Index(restored);index.reconcile();assert len(index.timeline(experiment['id']))==2;assert index.record(experiment['id'])['props']['code_snapshot']['commit']==experiment['code_snapshot']['commit'];index.close()
  print(json.dumps({'fixture':'executed software calibration; generated measurements, no hardware claim','mean_rad_s':measured,'bias_rad_s':bias,'held_out_residual_rad_s':mean(residual),'original_hypothesis':'contradicted','comparison_id':comparison['id'],'restored':True,'artifacts':'external references restored; original artifact storage required'},indent=2))
