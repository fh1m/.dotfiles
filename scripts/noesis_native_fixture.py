"""Reusable disposable native fixture; never restarts Wrayth or opens personal data."""
from pathlib import Path
import importlib.util,json,os,signal,subprocess,tempfile,time,uuid,base64
REPO=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('installer',REPO/'scripts/install.py');installer=importlib.util.module_from_spec(spec);spec.loader.exec_module(installer)
QS=str(Path.home()/'.local/opt/sensei-quickshell/bin/qs')
class Fixture:
 def __init__(self,delay=None,fail_preferences=False,fail_receipt=False):
  self.home=Path(tempfile.mkdtemp(prefix='noesis-lifecycle-'));installer.install(self.home,True)
  self.env=dict(os.environ,HOME=str(self.home),XDG_CONFIG_HOME=str(self.home/'.config'),XDG_CACHE_HOME=str(self.home/'.cache'),XDG_STATE_HOME=str(self.home/'.local/state'),NOESIS_WINDOW_MODE='normal',QS_DISABLE_CRASH_HANDLER='1',NOESIS_QS=QS)
  self.vault=self.home/'vault';(self.vault/'System').mkdir(parents=True)
  self.vault_id=str(uuid.uuid4());self.record_id=str(uuid.uuid4())
  (self.vault/'System/System.json').write_text(json.dumps({'directories':['Notes'],'noesis_schema':2,'vault_id':self.vault_id}))
  (self.vault/'problem.md').write_text('---\nid: '+self.record_id+'\nnoesis_schema: 2\ntype: task\ntitle: Disposable shutdown prediction\n---\n## Problem statement\n\nExplain the changed case before consulting a reference.\n')
  config=self.home/'.config/sensei-learning';config.mkdir(exist_ok=True);(config/'config.json').write_text(json.dumps({'active_vault':str(self.vault)}))
  self.config=self.home/'.config/quickshell/noesis'
  shell=self.config/'shell.qml';s=shell.read_text().replace('org.fh1m.Noesis','org.fh1m.Noesis.Fixture'+uuid.uuid4().hex)
  s=s.replace('import Quickshell','import Quickshell\nimport Quickshell.Io',1).replace(' LearningUi.NoesisWindow {}',' LearningUi.NoesisWindow {}\n IpcHandler {target:"fixture";function executeFixture(args:string):string{LearningUi.NoesisController.run(JSON.parse(Qt.atob(args)));return JSON.stringify({working:LearningUi.NoesisController.working,error:LearningUi.NoesisController.error,kind:LearningUi.NoesisController.operationKind});}}')
  shell.write_text(s)
  s=s.replace('target:"fixture";','target:"fixture";function acknowledgeUncertainExit():void{LearningUi.NoesisController.requestExit(true);}')
  shell.write_text(s)
  if delay or fail_preferences or fail_receipt:
   cli=self.home/'.local/bin/sensei-learn';cli.rename(cli.with_name('sensei-learn-real'))
   cli.write_text('#!/usr/bin/env python3\nimport os,sys,time,json\n'+("if sys.argv[1]=='window-state':sys.exit(1)\n" if fail_preferences else '')+("if sys.argv[1]=='operation-status':sys.stderr.write('Fixture receipt storage unavailable');sys.exit(1)\n" if fail_receipt else '')+('if sys.argv[1] in '+repr(delay or [])+':time.sleep(2)\n')+("if sys.argv[1] in ['read-resource','open-project']:print(json.dumps({'message':'Fixture handoff complete'}));sys.exit(0)\n" if delay and 'read-resource' in delay else '')+'os.execv('+repr(str(cli.with_name('sensei-learn-real')))+',[sys.argv[0],*sys.argv[1:]])\n');cli.chmod(0o755)
  self.process=None
 def start(self):
  self.log=(self.home/'qml.log').open('a');self.process=subprocess.Popen([QS,'-p',str(self.config),'--no-color'],env=self.env,stdout=self.log,stderr=self.log,start_new_session=True)
  self.wait(lambda s:s['visible'] and s['worker'])
  self.ipc('noesis-window','section','Practice');self.wait(lambda s:s['rows']==1)
  self.ipc('noesis-window','select','problem.md');self.wait(lambda s:s['selected']=='problem.md' and s['preview_length']>0)
  self.client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==self.process.pid and c['title'].startswith('Noesis'))
  subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+json.dumps('address:'+self.client['address'])+'})'],check=True,capture_output=True)
 def ipc(self,target,method,*args):
  r=subprocess.run([QS,'-p',str(self.config),'ipc','call',target,method,*args],env=self.env,text=True,capture_output=True,timeout=5)
  if r.returncode:raise RuntimeError(r.stderr or r.stdout)
  return r.stdout.strip()
 def state(self):return json.loads(self.ipc('noesis-window','state'))
 def hello(self):return json.loads(self.ipc('noesis','hello'))
 def wait(self,predicate,seconds=8):
  deadline=time.monotonic()+seconds
  while time.monotonic()<deadline:
   try:
    s=self.state()
    if predicate(s):return s
   except (RuntimeError,ValueError,OSError,KeyError):pass
   time.sleep(.05)
  raise AssertionError('Fixture wait timed out '+(self.home/'qml.log').read_text()[-4000:])
 def key(self,key,mods=''):
  subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods='+json.dumps(mods)+',key='+json.dumps(key)+',window='+json.dumps('address:'+self.client['address'])+'})'],check=True,capture_output=True)
 def run(self,*args):
  result=json.loads(self.ipc('fixture','executeFixture',base64.b64encode(json.dumps(args).encode()).decode()))
  if result['error']:raise AssertionError(result)
  return result
 def exit(self):self.ipc('noesis','exit');self.process.wait(timeout=8)
 def stop(self,forced=False):
  if self.process and self.process.poll() is None:
   os.killpg(self.process.pid,signal.SIGKILL if forced else signal.SIGTERM);self.process.wait(timeout=5)
  if hasattr(self,'log'):self.log.close()
 def preferences(self):return json.loads((self.home/'.local/state/sensei-learning/window.json').read_text())
