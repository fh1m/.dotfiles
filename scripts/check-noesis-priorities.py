#!/usr/bin/env python3
"""Actual native priority dialog writes a disposition, never an achievement."""
import json,subprocess,time
from noesis_native_fixture import Fixture
f=Fixture()
def open_priority():
 actions=f.state()['context_actions'];f.key('period','CTRL');f.key('Home')
 for _ in range(actions.index('priority')):f.key('Down')
 f.key('Return');f.wait(lambda state:state['priority_open'])
try:
 f.start();open_priority();f.key('Down');f.key('Return');f.key('Tab');f.key('Down');f.key('Return');f.key('Return','CTRL')
 f.wait(lambda state:state['pinned'] and state['manual_priority']=='high' and not state['priority_open'])
 result=subprocess.run([str(f.home/'.local/bin/noesis'),'timeline',f.record_id,'--vault',str(f.vault)],env=f.env,text=True,capture_output=True,check=True)
 events=json.loads(result.stdout)['activities'];assert len(events)==1 and events[0]['event']=='disposition' and events[0]['state']['pin'] is True
 assert all(event['event'] not in ('attempt','capability-decision') for event in events)
 open_priority();f.key('Tab');f.key('Down');f.key('Return');f.key('Return','CTRL');f.wait(lambda state:state['manual_priority']=='quiet' and not state['priority_open'])
 f.exit();f.start();f.wait(lambda state:state['manual_priority']=='quiet');assert f.state()['pinned']
 f.ipc('noesis-window','section','Today');f.wait(lambda state:state['today'].get('continue',{}).get('id')==f.record_id)
 assert all(row['id']!=f.record_id for row in f.state()['today'].get('records',[]))
 print('PASS: native pin/high/quiet dispositions persist after restart; Quiet preserves Continue and creates no assessment or competence event')
finally:f.stop()
