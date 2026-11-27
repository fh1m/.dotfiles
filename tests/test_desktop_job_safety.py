"""Safety transitions use disposable jobs; never touch real Docker, input or backups."""
import importlib.machinery,importlib.util,json,os,subprocess,sys,time,types
from pathlib import Path
from unittest.mock import patch
import pytest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'home/.local/share/sensei'))
import job_runtime as jobs

def load(name,path,home):
 loader=importlib.machinery.SourceFileLoader(name,str(ROOT/path));spec=importlib.util.spec_from_loader(name,loader);m=importlib.util.module_from_spec(spec)
 with patch.object(Path,'home',return_value=home):loader.exec_module(m)
 return m

def test_large_job_output_is_bounded_and_result_survives(tmp_path):
 r=jobs.run_bounded([sys.executable,'-c','import sys;sys.stdout.write("x"*2000000);sys.exit(7)'],tmp_path/'log',max_bytes=4096,reserve_bytes=0)
 assert r['exitCode']==7 and r['logTruncated'] and r['discardedBytes']==2000000-4096
 assert (tmp_path/'log').stat().st_size==4096
 assert (tmp_path/'log').stat().st_mode&0o777==0o600

def test_hung_job_times_out(tmp_path):
 r=jobs.run_bounded([sys.executable,'-c','import time;time.sleep(60)'],tmp_path/'log',timeout=.15,reserve_bytes=0)
 assert r['exitCode']==124 and r['timedOut']

def test_dead_worker_reconciles_without_overwriting_completed_receipt():
 completed={'state':'finished','finished':123,'exitCode':0}
 assert jobs.reconcile(completed)==completed
 assert jobs.reconcile({'state':'running','worker':{'pid':99999999,'boot':'old','start':'1'}})['state']=='interrupted'
 assert jobs.reconcile({'state':'queued','created':time.time()-60})['state']=='interrupted'
 assert jobs.reconcile({'state':'running','worker':jobs.identity()})['state']=='running'

def test_docker_inspect_redacts_all_object_types(tmp_path):
 d=load('docker_safety','home/.local/bin/sensei-docker',tmp_path)
 fake={'Id':'123','Name':'demo','Config':{'Env':['TOKEN=secret-marker'],'Labels':{'secret':'secret-marker'},'Cmd':['secret-marker']},'Mounts':[{'Source':'secret-marker'}],'State':{'Running':True}}
 with patch.object(d,'run',return_value=json.dumps([fake])):
  for kind in ('container','image','network','volume'):
   result=d.inspect(kind,'demo');assert 'secret-marker' not in json.dumps(result)

def test_docker_copy_out_never_clobbers(tmp_path):
 d=load('docker_copy_safety','home/.local/bin/sensei-docker',tmp_path)
 existing=tmp_path/'existing';existing.write_text('keep')
 link=tmp_path/'link';link.symlink_to(existing)
 with patch.object(d,'job',return_value={'ok':True}) as job:
  for p in [existing,link,tmp_path/'..'/'escape']:
   with pytest.raises(ValueError):d.action('copy',['demo','/data',str(p),'out'])
  assert existing.read_text()=='keep' and not job.called
  target=tmp_path/'new';d.action('copy',['demo','/data',str(target),'out']);assert target.is_dir()

def test_completed_den_job_cannot_be_cancelled(tmp_path):
 d=load('den_cancel_safety','home/.local/bin/sensei-den',tmp_path)
 folder=d.STATE/'jobs';folder.mkdir(parents=True);p=folder/'example.json'
 record={'id':'example','state':'succeeded','finished':123,'exitCode':0,'unit':'den-job-example'};p.write_text(json.dumps(record));before=p.read_bytes()
 args=types.SimpleNamespace(host=None,action='cancel',id='example')
 with patch.object(d,'run') as run:
  result=d.job(args);assert result['state']=='succeeded' and not result['cancelled'] and not run.called
 assert p.read_bytes()==before

def test_mode_release_failure_does_not_commit(tmp_path):
 d=load('den_mode_safety','home/.local/bin/sensei-den',tmp_path);d.CONFIG.mkdir(parents=True)
 p=d.CONFIG/'continuity.json';p.write_text('{"mode":"auto"}');before=p.read_bytes()
 with patch.object(d,'host',return_value='arete'),patch.object(d,'service',return_value='active'),patch.object(d,'run',return_value=subprocess.CompletedProcess([],1,'','')):
  with pytest.raises(ValueError):d.mode('away')
 assert p.read_bytes()==before

def test_missing_required_backup_is_not_success(tmp_path):
 d=load('den_backup_safety','home/.local/bin/sensei-den',tmp_path);d.CONFIG.mkdir(parents=True);d.STATE.mkdir(parents=True)
 password=tmp_path/'password';password.write_text('fixture-only')
 present=tmp_path/'source';present.write_text('fixture')
 (d.CONFIG/'backup.json').write_text(json.dumps({'repository':str(tmp_path/'repo'),'passwordFile':str(password),'paths':[str(present),str(tmp_path/'missing')]}))
 with patch.object(d.shutil,'which',return_value='/usr/bin/restic'),patch.object(d,'guarded_backup') as run:
  with pytest.raises(ValueError):d.backup('run')
  assert not run.called
 state=json.loads((d.STATE/'backup-status.json').read_text());assert not state['ok'] and state['missingRequired']==1

def test_chatty_docker_worker_obeys_config_and_keeps_logs_private(tmp_path):
 d=load('docker_infinite_safety','home/.local/bin/sensei-docker',tmp_path)
 cfg=tmp_path/'.config/sensei/job-limits.json';cfg.parent.mkdir(parents=True);cfg.write_text(json.dumps({'docker':{'timeoutSeconds':1,'maxLogBytes':2048}}))
 pid_file=tmp_path/'child.pid';record=d.JOBS/'1234.json';log=record.with_suffix('.log')
 program='import os,pathlib;pathlib.Path('+repr(str(pid_file))+').write_text(str(os.getpid()))\nwhile True:os.write(1,b"fixture-private-secret"*4096)'
 record.write_text(json.dumps({'id':'1234','state':'queued','created':time.time(),'args':[sys.executable,'-c',program],'log':str(log),'label':'fixture'}))
 with patch.object(Path,'home',return_value=tmp_path):
  d.worker(record)
  outcome=json.loads(record.read_text())
  assert outcome['state']=='failed' and outcome['exitCode']==124 and outcome['timedOut']
  assert outcome['logBytes']==2048 and outcome['logTruncated'] and log.stat().st_size==2048
  assert jobs.identity(int(pid_file.read_text())) is None
  assert 'fixture-private-secret' not in json.dumps(d.tasks())
  original=log.read_bytes();d.action('task-export',['1234'])
 exported=list((tmp_path/'Documents/Digital Den/Logs').glob('*.log'))
 assert len(exported)==1 and exported[0].read_bytes()==original and log.read_bytes()==original
 assert exported[0].stat().st_mode&0o777==0o600

def test_log_export_never_overwrites_an_existing_file(tmp_path):
 source=tmp_path/'source';source.write_text('private fixture');destination=tmp_path/'existing';destination.write_text('keep')
 with pytest.raises(FileExistsError):jobs.export_log(source,destination)
 assert destination.read_text()=='keep' and source.read_text()=='private fixture'

def test_unknown_remote_job_host_cannot_fall_back_to_homie(tmp_path):
 d=load('den_wrong_host_safety','home/.local/bin/sensei-den',tmp_path)
 with patch.object(d,'remote') as remote:
  with pytest.raises(ValueError,match='Unsupported job host'):d.job(types.SimpleNamespace(host='unexpected-host'))
  remote.assert_not_called()

def test_backup_failure_exit_and_stderr_are_honest_at_cli_boundary(tmp_path):
 home=tmp_path/'home';config=home/'.config/sensei-den';config.mkdir(parents=True)
 modules=home/'.local/share';modules.mkdir(parents=True);(modules/'sensei').symlink_to(ROOT/'home/.local/share/sensei',target_is_directory=True)
 source=home/'source';source.write_text('keep');password=home/'password';password.write_text('fixture-only')
 (config/'backup.json').write_text(json.dumps({'repository':str(home/'repo'),'passwordFile':str(password),'paths':[str(source)],'minimumFreeGiB':0}))
 binary=tmp_path/'bin';binary.mkdir()
 (binary/'restic').write_text('#!/bin/sh\nprintf "%s\\n" PRIVATE_FIXTURE_DIAGNOSTIC >&2\nexit 3\n');(binary/'restic').chmod(0o755)
 (binary/'notify-send').write_text('#!/bin/sh\nexit 0\n');(binary/'notify-send').chmod(0o755)
 env=dict(os.environ,HOME=str(home),PATH=str(binary)+':'+os.environ['PATH'],DBUS_SESSION_BUS_ADDRESS='unix:path='+str(tmp_path/'no-bus'))
 command=[sys.executable,str(ROOT/'home/.local/bin/sensei-den'),'backup']
 check=subprocess.run(command+['check'],capture_output=True,text=True,env=env,timeout=5)
 assert check.returncode==1 and json.loads(check.stdout)['ok'] is False
 run=subprocess.run(command+['run'],capture_output=True,text=True,env=env,timeout=5)
 assert run.returncode==1 and 'PRIVATE_FIXTURE_DIAGNOSTIC' not in run.stdout
 assert 'PRIVATE_FIXTURE_DIAGNOSTIC' in (home/'.local/state/sensei-den/backup-diagnostics.log').read_text()
 assert source.read_text()=='keep'

def test_mode_remains_pending_until_peer_acknowledges_same_intent(tmp_path):
 d=load('den_mode_pending','home/.local/bin/sensei-den',tmp_path);d.CONFIG.mkdir(parents=True)
 path=d.CONFIG/'continuity.json';path.write_text('{"mode":"auto"}')
 with patch.object(d,'host',return_value='arete'),patch.object(d,'remote',side_effect=ValueError('fixture transport unavailable')):
  result=d.mode('together')
 assert result['peerPending']['mode']=='auto' and result['peerPending']['reason']
 generation=result['peerPending']['generation']
 for response in (json.dumps({'requested':'away'}),'null'):
  with patch.object(d,'remote',return_value=response):d.reconcile_mode()
  pending=json.loads(path.read_text())['peerPending']
  assert pending['generation']==generation and pending['reason']
 with patch.object(d,'remote',return_value=json.dumps({'requested':'auto'})):d.reconcile_mode()
 saved=json.loads(path.read_text())
 assert 'peerPending' not in saved and saved['peerAcknowledged']['generation']==generation

def test_late_mode_acknowledgement_cannot_erase_newer_intent(tmp_path):
 d=load('den_mode_generation','home/.local/bin/sensei-den',tmp_path);d.CONFIG.mkdir(parents=True)
 path=d.CONFIG/'continuity.json';path.write_text(json.dumps({'mode':'auto','generation':1,'peerPending':{'mode':'auto','generation':1}}))
 newer={'mode':'away','generation':2,'peerPending':{'mode':'homie','generation':2}}
 def acknowledge_old(*args):
  d.write(path,newer)
  return json.dumps({'requested':'auto'})
 with patch.object(d,'remote',side_effect=acknowledge_old):d.reconcile_mode()
 assert json.loads(path.read_text())==newer
