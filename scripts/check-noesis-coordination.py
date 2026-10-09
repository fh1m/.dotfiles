#!/usr/bin/env python3
"""Native encoded requests, exact ownership, concurrency and stale bridge state."""
import base64,json,subprocess,time,uuid
from concurrent.futures import ThreadPoolExecutor
from noesis_native_fixture import Fixture,QS
f=Fixture()
try:
 f.start()
 def request(owner=None,record=None,action='resume',version=1,request_id=None):
  payload={'version':version,'request_id':request_id or str(uuid.uuid4()),'action':action}
  if owner:payload['owner']=owner
  if record:payload['record_id']=record
  return json.loads(f.ipc('noesis','request',base64.b64encode(json.dumps(payload).encode()).decode())),payload['request_id']
 owner={'vault_id':f.vault_id,'registered_location':str(f.vault)}
 ack,rid=request(owner,f.record_id);assert ack['status']=='received';f.wait(lambda s:json.loads(f.ipc('noesis','requestStatus',rid))['status']=='ready')
 again,_=request(owner,f.record_id,request_id=rid);assert again['status']=='ready'
 wrong=dict(owner,vault_id=str(uuid.uuid4()));ack,rid=request(wrong,f.record_id);f.wait(lambda s:json.loads(f.ipc('noesis','requestStatus',rid))['status']=='rejected');assert f.state()['vault']==str(f.vault)
 ack,rid=request(owner,f.record_id,version=999);assert ack['status']=='rejected'
 ack,rid=request(owner,action='capture');f.wait(lambda s:s['capture_open']);f.key('Escape')
 # Launchers address the same canonical config; none can start a second host.
 def launch(_):return subprocess.run([str(f.home/'.local/bin/noesis'),'window','--owner',str(f.vault),'--record-id',f.record_id],env=f.env,text=True,capture_output=True,timeout=15)
 with ThreadPoolExecutor(max_workers=4) as pool:results=list(pool.map(launch,range(4)))
 assert all(r.returncode==0 for r in results),[(r.stdout,r.stderr) for r in results]
 tokens={json.loads(r.stdout)['instance'] for r in results};assert tokens=={f.hello()['instance']['token']}
 projection=f.home/'.local/state/sensei-learning/companion.json'
 f.wait(lambda s:projection.exists() and json.loads(projection.read_text())['context'].get('vault_id')==f.vault_id)
 value=json.loads(projection.read_text());assert value['instance']['start_ticks'];assert 'drafts' not in value and 'body' not in value['context'];assert projection.stat().st_mode & 0o777==0o600
 print('PASS: encoded owner requests, deduplication, rejection, capture, four concurrent launches and private projection',flush=True)
finally:f.stop()
