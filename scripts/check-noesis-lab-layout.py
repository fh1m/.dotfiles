#!/usr/bin/env python3
"""Measured Lab fixture with authored, explicitly executed local code and PNG output."""
import json,subprocess,time,sys,os
from pathlib import Path
from unittest.mock import patch
from noesis_native_fixture import Fixture,REPO
sys.path.insert(0,str(REPO/'home/.local/share/sensei-learning'))
from noesis.models import create
from noesis.activities import record_activity
f=Fixture();evidence=Path('/tmp/noesis-lab-layout-evidence');evidence.mkdir(exist_ok=True)
repository=f.home/'fixture-code';repository.mkdir()
code=repository/'measure.py';code.write_text('import json,statistics\nvalues=[.11,.12,.13]\nprint(json.dumps({"mean":statistics.mean(values),"units":"rad/s","scope":"disposable UI fixture"}))\n')
for args in [['init','-q'],['add','measure.py'],['-c','user.name=Noesis Fixture','-c','user.email=fixture@example.invalid','-c','commit.gpgsign=false','commit','-qm','Disposable measurement fixture']]:subprocess.run(['git','-C',str(repository),*args],check=True,capture_output=True)
execution=subprocess.run([sys.executable,str(code)],check=True,capture_output=True,text=True,timeout=5);measurement=json.loads(execution.stdout)
os.environ['MPLCONFIGDIR']=str(f.home/'matplotlib-cache')
import matplotlib
matplotlib.use('Agg')
from matplotlib import pyplot as plt
figure,data=f.vault/'measurement.png',f.vault/'measurement.csv';data.write_text('sample,rate_rad_per_s\n1,0.11\n2,0.12\n3,0.13\n')
plot,axes=plt.subplots(figsize=(6,2.5));axes.plot([1,2,3],[.11,.12,.13],marker='o');axes.axhline(0,color='black',linestyle='--');axes.set(xlabel='Fixture sample',ylabel='Rate (rad/s)',title='Disposable measurement fixture');plot.tight_layout();plot.savefig(figure,dpi=100);plt.close(plot)
with patch('pathlib.Path.home',return_value=f.home):
 project=create(f.vault,'project','Bias measurement implementation',fields={'repository':str(repository)})
 run=create(f.vault,'experiment','Measured bias: original prediction, discrepancy and next calibration',parent_id=project['id'],fields={'hypothesis':'The fixture samples will have zero mean rate.','configuration':{'sample_count':3,'units':'rad/s','dataset':'measurement.csv'}})
 record_activity(f.vault,run['path'],'comparison','Explicitly executed disposable measurement fixture',predicted='0',observed=str(measurement['mean']),units=measurement['units'],uncertainty='Three synthetic samples; no physical instrument claim.',conclusion='The fixture mean differs from the zero prediction.',next_experiment='Test the fixture after subtracting the known offset.',execution={'command':[sys.executable,str(code)],'returncode':execution.returncode,'stdout':execution.stdout,'scope':'disposable UI fixture'})
 create(f.vault,'artifact','Measured rate figure',parent_id=run['id'],fields={'location':str(figure)})
 create(f.vault,'artifact','Original fixture data',parent_id=run['id'],fields={'location':str(data)})
 create(f.vault,'artifact','Unavailable calibration output',parent_id=run['id'],fields={'location':str(f.vault/'not-produced.csv')})
shell=f.config/'shell.qml';s=shell.read_text().replace('LearningUi.NoesisWindow {}','LearningUi.NoesisWindow {id:fixtureWindow}')
s=s.replace('ShellRoot {','ShellRoot {\n IpcHandler {target:"lab-fixture";function scale(value:real):void{fixtureWindow.openSettings();LearningUi.NoesisStyle.interfaceScale=value;LearningUi.NoesisStyle.readingScale=value;LearningUi.NoesisController.savePreferences();}}')
shell.write_text(s)
try:
 f.start();f.ipc('noesis-window','section','Lab');f.wait(lambda state:state['rows']>0);f.ipc('noesis-window','select',run['path']);f.wait(lambda state:state['loaded_figures']==1)
 context=f.state()['experiment'];assert context['hypothesis']==run['hypothesis'];assert context['latest_comparison']['observed']=='0.12';assert any(row['availability']=='artifact unavailable' for row in context['artifacts'])
 for width,height in [(1440,880),(1000,650),(500,650)]:
  for scale in [1,2]:
   f.ipc('lab-fixture','scale',str(scale));time.sleep(.2);f.key('Escape');subprocess.run(['hyprctl','dispatch','hl.dsp.window.resize({x='+str(width)+',y='+str(height)+',relative=false,window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True);time.sleep(1)
   state=f.state();assert state['read_viewport_height']>100,state
   client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid);x,y=client['at'];w,h=client['size'];name=f'lab-{width}-{scale}'
   subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(evidence/(name+'.png'))],check=True,timeout=10);(evidence/(name+'.json')).write_text(json.dumps(state,indent=2))
 warnings=[line for line in (f.home/'qml.log').read_text().splitlines() if ('WARN' in line or 'ERROR' in line) and 'Could not register app ID' not in line];assert not warnings,warnings
 print('PASS: executed fixture evidence, prediction, comparison, local figure and missing artifact retained across six native layouts. Inspect:',evidence)
finally:f.stop()
