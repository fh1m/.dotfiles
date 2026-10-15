#!/usr/bin/env python3
"""Native lifecycle fault injection. Simulated tool handoff is labelled explicitly."""
import json,time,uuid,subprocess
from noesis_native_fixture import Fixture
reports=[]
def check(name,action,**options):
 f=Fixture(**options)
 try:
  f.start();action(f);reports.append({'case':name,'result':'passed','fixture':str(f.home)});print(name,'PASS',flush=True)
 finally:f.stop()
def debounce(f):
 f.key('a');f.exit();assert f.preferences()['drafts'][str(f.vault)+':'+f.record_id]=='a'
def mutation(f):
 f.run('event','problem.md','attempt-start','--target-id',f.record_id,'--data',json.dumps({'mode':'derive','scope':'fixture'}))
 f.wait(lambda s:s['working']);f.ipc('noesis','exit');time.sleep(.4);assert f.process.poll() is None
 f.process.wait(timeout=8);assert not f.preferences()['pending_operation'];assert list((f.vault/'Activity').rglob('*.md'))
def importing(f):
 source=f.home/'outline.json';source.write_text(json.dumps({'version':1,'title':'Fixture course','entries':[{'key':'one','kind':'unit','title':'First lesson','fields':{'unit_kind':'lecture'}}]}))
 f.run('course-import',str(source),'--apply','--operation-id',str(uuid.uuid4()))
 f.wait(lambda s:s['working']);f.ipc('noesis','exit');time.sleep(.4);assert f.process.poll() is None
 f.process.wait(timeout=8);assert not f.preferences()['pending_operation'];assert len(list((f.vault/'Records/resource').glob('*.md')))==1
def handoff(f):
 f.key('a');f.run('read-resource','problem.md','--target-id',f.record_id);f.wait(lambda s:s['working']);f.exit()
 assert f.preferences()['drafts'][str(f.vault)+':'+f.record_id]=='a'
def failed_save(f):
 f.key('a');f.ipc('noesis','exit');f.wait(lambda s:'could not be saved' in s['error']);assert f.process.poll() is None and not f.hello()['exit_pending']
def forced(f):
 f.key('a');f.wait(lambda s:s['draft_length']==1);time.sleep(.6)
 f.run('event','problem.md','attempt-start','--target-id',f.record_id,'--data',json.dumps({'mode':'derive','scope':'fixture'}));f.wait(lambda s:s['working']);time.sleep(.2)
 assert f.preferences()['pending_operation']['id'];f.stop(forced=True);f.start();f.wait(lambda s:not s['working']);assert f.state()['draft_length']==1 and not f.hello()['uncertain'];f.wait(lambda s:not f.preferences()['pending_operation'])
def wm_close(f):
 f.key('a');subprocess.run(['hyprctl','dispatch','hl.dsp.window.close({window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True)
 f.process.wait(timeout=8);assert f.preferences()['drafts'][str(f.vault)+':'+f.record_id]=='a'
def wm_failed(f):
 f.key('a');subprocess.run(['hyprctl','dispatch','hl.dsp.window.close({window='+json.dumps('address:'+f.client['address'])+'})'],check=True,capture_output=True)
 f.wait(lambda s:s['visible'] and 'could not be saved' in s['error']);assert f.process.poll() is None and f.state()['draft_length']==1
def uncertainty(f):
 f.run('event','problem.md','attempt-start','--target-id',f.record_id,'--data',json.dumps({'mode':'derive','scope':'fixture'}));f.wait(lambda s:s['working']);time.sleep(.2)
 pending=f.preferences()['pending_operation'];f.stop(forced=True);f.start();f.wait(lambda s:f.hello()['uncertain'])
 f.ipc('noesis','exit');f.wait(lambda s:not f.hello()['exit_pending']);assert f.process.poll() is None
 f.ipc('fixture','acknowledgeUncertainExit');f.process.wait(timeout=8);assert f.preferences()['pending_operation']['id']==pending['id']
 f.start();f.wait(lambda s:f.hello()['uncertain']);assert f.preferences()['pending_operation']['id']==pending['id']
def interrupted_import(f):
 source=f.home/'bibliography.json';source.write_text(json.dumps([{'id':'fixture','title':'Disposable interrupted import'}]))
 f.run('import-csl',str(source));f.wait(lambda s:s['working']);time.sleep(.2)
 pending=f.preferences()['pending_operation'];assert pending['receipt_supported'] is False
 f.stop(forced=True);f.start();f.wait(lambda s:f.hello()['uncertain']);assert 'no backend receipt' in f.state()['error']
 f.ipc('noesis','exit');f.wait(lambda s:not f.hello()['exit_pending']);assert f.process.poll() is None
 f.ipc('fixture','acknowledgeUncertainExit');f.process.wait(timeout=8);assert f.preferences()['pending_operation']['id']==pending['id']
check('Window-manager Close flushes draft debounce',wm_close)
check('Window-manager failed save reopens with input',wm_failed,fail_preferences=True)
check('Close during draft debounce',debounce)
check('Close during mutation waits for completion',mutation,delay=['event'])
check('Close during pending import',importing,delay=['course-import'])
check('Close during simulated specialist handoff',handoff,delay=['read-resource'])
check('Failed save retains application and input',failed_save,fail_preferences=True)
check('Forced termination recovers durable draft and inspects receipt',forced,delay=['event'])
check('Unavailable receipt blocks ordinary exit and survives acknowledged exit/restart',uncertainty,delay=['event'],fail_receipt=True)
check('Interrupted import without receipt preserves scope and requires inspection',interrupted_import,delay=['import-csl'])
from pathlib import Path
Path('/tmp/noesis-shutdown-evidence.json').write_text(json.dumps(reports,indent=2))
