#!/usr/bin/env python3
"""Actual concurrent cold launcher tests in both placement modes; own fixture only."""
from concurrent.futures import ThreadPoolExecutor
import json,os,signal,subprocess,time,uuid
from noesis_native_fixture import Fixture
original=next(m for m in json.loads(subprocess.check_output(['hyprctl','monitors','-j'],text=True)) if m['focused'])
reports=[]
for placement in ('current','dedicated'):
 f=Fixture();pid=None
 try:
  state=f.home/'.local/state/sensei-learning';state.mkdir(parents=True,exist_ok=True)
  workspace='Noesis acceptance '+uuid.uuid4().hex[:6]
  draft_key=str(f.vault)+':'+f.record_id
  preserved_draft='Existing reasoning before cold launch\nবাংলা preserved context'
  (state/'window.json').write_text(json.dumps({'version':2,'placement':placement,'study_workspace':workspace,'drafts':{draft_key:preserved_draft},'interface_scale':1.25,'reading_scale':1.5,'layouts':{'practice':0.42}}))
  before=next(m for m in json.loads(subprocess.check_output(['hyprctl','monitors','-j'],text=True)) if m['focused'])['activeWorkspace']['name']
  started=time.monotonic()
  def launch(_):return subprocess.run([str(f.home/'.local/bin/noesis'),'window','--owner',str(f.vault),'--vault-id',f.vault_id,'--record-id',f.record_id],env=f.env,text=True,capture_output=True,timeout=20)
  with ThreadPoolExecutor(max_workers=4) as pool:results=list(pool.map(launch,range(4)))
  assert all(r.returncode==0 for r in results),[(r.stdout,r.stderr) for r in results]
  tokens={json.loads(r.stdout)['instance'] for r in results};assert len(tokens)==1
  pid=f.hello()['instance']['pid'];time.sleep(.5)
  clients=[c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==pid and c['title'].startswith('Noesis')];assert len(clients)==1
  expected=workspace if placement=='dedicated' else before
  assert clients[0]['workspace']['name']==expected,(clients[0]['workspace'],expected)
  reports.append({'placement':placement,'four_launches_seconds':round(time.monotonic()-started,3),'instance_count':1,'workspace':clients[0]['workspace']['name']})
  f.ipc('noesis','exit')
  deadline=time.monotonic()+8
  while time.monotonic()<deadline and os.path.exists(f'/proc/{pid}'):time.sleep(.1)
  assert not os.path.exists(f'/proc/{pid}')
  saved=json.loads((state/'window.json').read_text())
  assert saved['drafts'].get(draft_key)==preserved_draft,saved.get('drafts')
  assert saved['interface_scale']==1.25 and saved['reading_scale']==1.5,saved
  assert saved['layouts'].get('practice')==0.42,saved.get('layouts')
  print(placement,'PASS: four cold launches, one instance, correct workspace, saved drafts/scales/layout retained, graceful exit',flush=True)
 finally:
  if pid and os.path.exists(f'/proc/{pid}'):os.killpg(pid,signal.SIGTERM)
  subprocess.run(['hyprctl','dispatch','hl.dsp.focus({monitor='+json.dumps(original['name'])+'})'],capture_output=True)
  subprocess.run(['hyprctl','dispatch','hl.dsp.focus({workspace='+json.dumps('name:'+original['activeWorkspace']['name'])+'})'],capture_output=True)
from pathlib import Path
Path('/tmp/noesis-startup-evidence.json').write_text(json.dumps(reports,indent=2))
