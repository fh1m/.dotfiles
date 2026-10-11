#!/usr/bin/env python3
"""Native empty-vault visual thinking and terminal execution acceptance.
No Noesis learning records are prepared through CLI or backend calls.
"""
import json, os, time, subprocess, signal, uuid, sys, shutil
from pathlib import Path
from noesis_native_fixture import Fixture, REPO
# Reuse established native mouse/key instrumentation, including popup capture.
prefix=(REPO/'scripts/check-noesis-self-service.py').read_text().split('clipboard=subprocess.run')[0]
exec(compile(prefix,'native-instrumentation','exec'))
f.env['PATH']=str(f.home/'.local/bin')+':'+f.env['PATH']
shell=f.config/'shell.qml';shell.write_text(shell.read_text().replace('function chooseDesk(index:int)', 'function captureDesk(path:string):void{window.studyDesk.applicationSurface.grabToImage(r=>r.saveToFile(path));}\n  function chooseDesk(index:int)'))
assets=REPO/'docs/learning-system/assets/core-learning';assets.mkdir(parents=True,exist_ok=True)
clipboard=subprocess.run(['wl-paste','--no-newline'],capture_output=True)
owned=[]
source_library=None
def click(label):
 result=f.ipc('journey-fixture','click',label);assert result=='clicked',(label,result)
def type(name,value):
 client=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)) if c['pid']==f.process.pid and c['title'].startswith('Noesis'))
 subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+json.dumps('address:'+client['address'])+'})'],check=True,capture_output=True);time.sleep(.15)
 assert f.ipc('journey-fixture','focusField',name)=='focused',name
 for attempt in range(4):
  subprocess.run(['wl-copy'],input=value,text=True,check=True);time.sleep(.25)
  assert subprocess.check_output(['wl-paste','--no-newline'],text=True)==value
  assert f.ipc('journey-fixture','focusField',name)=='focused',name
  f.ipc('journey-fixture','pasteField');time.sleep(.15)
  if f.ipc('journey-fixture','field',name)==value:break
  time.sleep(.2)
 else:raise AssertionError((name,f.ipc('journey-fixture','field',name),value))
def capture(name):
 f.ipc("noesis","open");time.sleep(.5)
 client=next(c for c in json.loads(subprocess.check_output(["hyprctl","clients","-j"],text=True)) if c["pid"]==f.process.pid and c["title"].startswith("Noesis"))
 subprocess.run(["hyprctl","dispatch","hl.dsp.focus({window="+json.dumps("address:"+client["address"])+"})"],check=True,capture_output=True);time.sleep(.3)
 p=assets/(name+'.png');p.unlink(missing_ok=True);f.ipc('journey-fixture','capture',str(p));deadline=time.monotonic()+5
 while not p.exists() and time.monotonic()<deadline:time.sleep(.1)
 assert p.exists(),name
def selected():return json.loads(f.ipc('journey-fixture','state'))['selected']
def settle():
 for _ in range(3):
  f.wait(lambda s:not s['working'],seconds=30);time.sleep(.4)
  if f.state()['working']:continue
  time.sleep(.2)
 state=json.loads(f.ipc('journey-fixture','state'));assert not state['error'],state
try:
 # Provision only disposable external-tool state, not learning records.
 registry=f.home/'.config/obsidian';registry.mkdir(parents=True,exist_ok=True)
 vault_token=uuid.uuid4().hex[:16]
 (registry/'obsidian.json').write_text(json.dumps({'cli':True,'vaults':{vault_token:{'path':str(f.vault),'open':True,'ts':int(time.time()*1000)}}}))
 (registry/'user-flags.conf').write_text('--user-data-dir='+str(registry)+'\n--disable-gpu\n--disable-dev-shm-usage\n')
 obs=f.vault/'.obsidian';obs.mkdir(exist_ok=True);(obs/'core-plugins.json').write_text('["canvas"]')
 source=Path.home()/'Study/Obsidian/Knowledge/.obsidian/plugins/obsidian-excalidraw-plugin'
 shutil.copytree(source,obs/'plugins/obsidian-excalidraw-plugin',ignore=shutil.ignore_patterns('data.json'));(obs/'community-plugins.json').write_text('["obsidian-excalidraw-plugin"]');(obs/'app.json').write_text('{"isSafeMode":false}')
 socket=f.home/'editor.sock';nvim=f.home/'.config/noesis-pilot';nvim.mkdir();(nvim/'init.lua').write_text('vim.fn.serverstart('+json.dumps(str(socket))+')\n');f.env['NVIM_APPNAME']='noesis-pilot'
 obslog=(f.home/'obsidian.log').open('w');op=subprocess.Popen(['obsidian','--disable-gpu','--in-process-gpu','obsidian://open?vault='+vault_token],env=f.env,stdout=obslog,stderr=obslog,start_new_session=True);owned.append(op);time.sleep(5)
 subprocess.run(['obsidian','vault='+f.vault.name,'plugins:restrict','off'],env=f.env,check=True,capture_output=True)
 enabled=subprocess.run(['obsidian','vault='+f.vault.name,'eval','code=(async()=>{await app.plugins.loadManifests();if(!app.plugins.plugins["obsidian-excalidraw-plugin"])await app.plugins.enablePluginAndSave("obsidian-excalidraw-plugin");return !!app.plugins.plugins["obsidian-excalidraw-plugin"]})()'],env=f.env,check=True,capture_output=True,text=True)
 deadline=time.monotonic()+15
 while time.monotonic()<deadline:
  active=subprocess.run(['obsidian','vault='+vault_token,'eval','code=!!app.plugins.plugins["obsidian-excalidraw-plugin"]'],env=f.env,capture_output=True,text=True)
  if 'true' in active.stdout:break
  time.sleep(.2)
 else:raise AssertionError(('Native Excalidraw activation failed',enabled,active))
 f.start(resume=True);f.ipc('journey-fixture','init');time.sleep(.5)
 click('Start learning');type('learning-origin','Agent validation question: why does a sampled sine wave alias?');type('learning-title','Agent validation · sampling uncertainty');click('Continue');capture('question-preserved');assert f.ipc('journey-fixture','field','record-purpose')=='Agent validation question: why does a sampled sine wave alias?';click('Save');settle();origin=selected();capture('question-actions')
 click('Draw / Diagram');assert f.ipc('journey-fixture','choose','drawing-mode','0').startswith('Canvas');type('exploration-title','Agent validation · sampling map');capture('create-map');click('Create linked drawing');settle();drawing=selected();assert drawing['artifact_kind']=='drawing';capture('linked-map')
 assert origin['path'] in json.loads((f.vault/drawing['local_file']).read_text())['nodes'][0]['text']
 # Native owned Obsidian open; CLI read-only verification of selected file.
 out=subprocess.check_output(['obsidian','vault='+str(f.vault.name),'file','info=path'],env=f.env,text=True).strip();assert drawing['local_file'] in out,out
 # Rename the existing owned drawing through the reachable native action.
 click('More');click('Rename / locate linked file');type('exploration-title','Agent validation · renamed sampling map');click('Save artifact link');settle();drawing=selected();assert drawing['id'] and drawing['local_file'].endswith('renamed sampling map.canvas');assert (f.vault/drawing['local_file']).is_file();capture('renamed-map')
 # A moved file stays missing until the learner explicitly reconnects its identity.
 moved=(f.vault/drawing['local_file']).with_name('relocated.canvas');(f.vault/drawing['local_file']).rename(moved)
 click('Open linked file');f.wait(lambda state:not state['working'],seconds=30);assert 'missing' in f.state()['error'].lower();capture('missing-drawing')
 click('More');click('Rename / locate linked file');type('artifact-location',str(moved.relative_to(f.vault)));click('Save artifact link');settle();assert selected()['id']==drawing['id'];drawing=selected();assert drawing['local_file']==str(moved.relative_to(f.vault));capture('reconnected-map')
 # Follow the existing navigation return, then create freehand from same origin.
 f.ipc('journey-fixture','back');time.sleep(.6);assert selected()['id']==origin['id']
 click('Draw / Diagram')
 # Set selector through its native popup, named in production for accessibility.
 assert f.ipc('journey-fixture','choose','drawing-mode','1').startswith('Freehand')
 type('exploration-title','Agent validation · freehand mechanism');click('Create linked drawing');settle();freehand=selected();assert (f.vault/freehand['local_file']).is_file();capture('linked-freehand')
 f.ipc('journey-fixture','back');time.sleep(.6);assert selected()['id']==origin['id']
 click('Try in code');type('exploration-title','Agent validation · sampled signal check');type('exploration-prediction','Agent validation prediction: integer samples cannot distinguish these two frequencies.');click('Create scratch experiment');settle();scratch=selected();assert scratch['scratch_directory'];capture('scratch-workbench')
 deadline=time.monotonic()+10
 while not socket.exists() and time.monotonic()<deadline:time.sleep(.1)
 assert socket.exists(),'Native editor socket missing'
 code='import os\nfrom pathlib import Path\nimport numpy as np\nimport matplotlib.pyplot as plt\nx=np.arange(8)\na=np.sin(2*np.pi*0.125*x)\nb=np.sin(2*np.pi*1.125*x)\nprint("max sampled difference", float(np.max(np.abs(a-b))))\nassert np.allclose(a,b)\nplt.plot(x,a,"o-",label="sampled 0.125 cycles/sample")\nplt.plot(x,b,"x",label="sampled 1.125 cycles/sample")\nplt.legend()\nplt.savefig(Path(os.environ["NOESIS_RUN_DIRECTORY"])/"aliasing.png")\n'
 # Edit in the actual Neovim process; not an agent-created Noesis record.
 subprocess.run(['nvim','--server',str(socket),'--remote-expr','execute("%delete _")'],env=f.env,check=True,capture_output=True)
 subprocess.run(['nvim','--server',str(socket),'--remote-expr','setline(1, '+json.dumps(code.splitlines())+')'],env=f.env,check=True,capture_output=True)
 subprocess.run(['nvim','--server',str(socket),'--remote-expr','execute("write")'],env=f.env,check=True,capture_output=True)
 click('Open terminal to run');settle();time.sleep(2)
 clients=json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True));terminal=next(c for c in clients if str(c.get('title','')).startswith('Noesis · quick experiment'))
 subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+json.dumps('address:'+terminal['address'])+'})'],check=True,capture_output=True);subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods="",key="Return",window='+json.dumps('address:'+terminal['address'])+'})'],check=True,capture_output=True)
 deadline=time.monotonic()+20
 while not list((f.vault/scratch['scratch_directory']).glob('runs/*/execution.json')) and time.monotonic()<deadline:time.sleep(.2)
 manifests=list((f.vault/scratch['scratch_directory']).glob('runs/*/execution.json'));assert manifests,'Execution did not finish'
 execution=json.loads(manifests[0].read_text());assert execution['exit_code']==0,execution
 stdout=manifests[0].with_name('stdout.txt').read_text();assert 'max sampled difference' in stdout,stdout
 f.ipc('journey-fixture','open',json.dumps(scratch));time.sleep(1);capture('executed-check')
 f.exit();f.start(resume=True);f.ipc('journey-fixture','init');time.sleep(.8);assert selected()['id']==scratch['id'];capture('resumed-experiment')
 # Previously unprepared subjects use the same controls, not lesson builders.
 domains={}
 def edit_run_current(code,label):
  current=selected();capture(label+'-before-code')
  file=Path(current['local_file']);file=file if file.is_absolute() else f.vault/file
  subprocess.run(['nvim','--server',str(socket),'--remote-expr','execute("edit " . fnameescape('+json.dumps(str(file))+'))'],env=f.env,check=True,capture_output=True)
  actual=subprocess.check_output(['nvim','--server',str(socket),'--remote-expr','expand("%:p")'],env=f.env,text=True).strip();assert Path(actual)==file
  for expression in ['execute("%delete _")','setline(1, '+json.dumps(code.splitlines())+')','execute("write")']:
   subprocess.run(['nvim','--server',str(socket),'--remote-expr',expression],env=f.env,check=True,capture_output=True)
  before=set((f.vault/current['scratch_directory']).glob('runs/*/execution.json'))
  click('Open terminal to run');settle();time.sleep(.7)
  clients=json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True));client=min((c for c in clients if c.get('title')=='Noesis · quick experiment'),key=lambda c:c.get('focusHistoryID',0))
  subprocess.run(['hyprctl','dispatch','hl.dsp.send_shortcut({mods="",key="Return",window='+json.dumps('address:'+client['address'])+'})'],check=True,capture_output=True)
  deadline=time.monotonic()+20;new=set()
  while time.monotonic()<deadline:
   new=set((f.vault/current['scratch_directory']).glob('runs/*/execution.json'))-before
   if new:break
   time.sleep(.2)
  assert new,'Explicit terminal run did not finish'
  manifest=next(iter(new));result=json.loads(manifest.read_text());result['stdout']=manifest.with_name('stdout.txt').read_text();result['stderr']=manifest.with_name('stderr.txt').read_text()
  capture(label+'-result');return result
 click('Start learning');time.sleep(.4);type('learning-origin','https://docs.scipy.org/doc/scipy/tutorial/signal.html');type('learning-title','Agent validation · unfamiliar signal documentation');click('Continue');click('Save');settle();article=selected();capture('article-start')
 click('Learning options');click('Ask a question');type('record-title','Agent validation · article mechanism question');type('record-purpose','Why can different frequencies agree at integer samples? The source title is manually supplied; connect the executed check without duplicating it.');click('Save');settle();article_question=selected();capture('article-question')
 click('Learning options');click('Connect existing knowledge');type('prerequisite-search','sampled signal check');time.sleep(.7);click('Agent validation · sampled signal check');type('prerequisite-reason','Actual executed aliasing check relevant to this source question');click('Connect existing record');settle();domains['mathematics']={'source':article['id'],'question':article_question['id'],'experiment':scratch['id']}
 click('Start learning');time.sleep(.4);type('learning-origin','Agent validation problem: return a topological order of a directed graph, or identify a cycle. Include edges pointing against vertex-number order.');type('learning-title','Agent validation · dependency ordering');assert f.ipc('journey-fixture','choose','learning-format','9')=='Practice problem';click('Continue');assert 'topological' in f.ipc('journey-fixture','field','record-purpose');click('Save');settle();problem=selected()
 click('Start independent attempt');settle();assert f.state()['reference_hidden'];type('practice-reasoning','Agent validation first approach: return vertex-number order. I have not yet accounted for reversed edges or cycles.');click('Draw / Diagram');assert f.ipc('journey-fixture','choose','drawing-mode','0').startswith('Canvas');type('exploration-title','Agent validation · dependency invariant map');click('Create linked drawing');settle();capture('protected-problem-map');f.ipc('journey-fixture','back');time.sleep(.7);assert selected()['id']==problem['id'] and f.state()['reference_hidden']
 click('Outcome & assistance');assert f.ipc('journey-fixture','choose','attempt-outcome','2')=='failed';assert f.ipc('journey-fixture','choose','attempt-assistance','5')=='agent';click('Done');click('Record attempt outcome');settle();capture('failed-algorithm-attempt')
 click('Investigate the missing mechanism');type('record-title','Agent validation · zero indegree invariant');type('record-purpose','Why is a zero-indegree vertex safe to remove? How does an unprocessed remainder expose a cycle? Preserve the failed approach.');click('Save');settle();invariant=selected()
 click('Try in code');type('exploration-title','Agent validation · topological ordering check');type('exploration-prediction','Reversed edges invalidate vertex-number order; a cycle has no valid ordering.');click('Create scratch experiment');settle();algorithm=selected()
 failed=edit_run_current('edges=[(1,0)]\norder=[0,1]\nprint("naive order",order)\nassert all(order.index(a)<order.index(b) for a,b in edges), "vertex-number order violates dependency"\n','algorithm-failure');assert failed['exit_code']==1
 corrected=edit_run_current('from collections import deque\nfrom itertools import permutations\ndef topo(n,edges):\n    incoming=[0]*n\n    outgoing=[[] for _ in range(n)]\n    for a,b in edges: incoming[b]+=1; outgoing[a].append(b)\n    ready=deque(i for i in range(n) if incoming[i]==0); order=[]\n    while ready:\n        a=ready.popleft(); order.append(a)\n        for b in outgoing[a]:\n            incoming[b]-=1\n            if incoming[b]==0: ready.append(b)\n    return order if len(order)==n else None\ncases=[(2,[(1,0)]),(3,[(0,1),(1,2)]),(3,[(0,1),(1,0)]),(4,[(0,2),(1,2),(2,3)]),(0,[])]\nfor n,edges in cases:\n    valid=[p for p in permutations(range(n)) if all(p.index(a)<p.index(b) for a,b in edges)]\n    actual=topo(n,edges)\n    assert (actual is None)==(not valid)\n    if actual is not None: assert tuple(actual) in valid\n    print(n,edges,"=>",actual)\nprint("five cases agree with exhaustive small-graph oracle")\n','algorithm-corrected');assert corrected['exit_code']==0
 domains['computer_science']={'problem':problem['id'],'invariant_question':invariant['id'],'experiment':algorithm['id'],'failed_execution':failed,'corrected_execution':corrected,'assistance':'agent; no learner achievement'}
 click('Start learning');time.sleep(.4);type('learning-origin','Agent validation engineering question: does integral windup delay recovery after saturation in a hypothetical first-order plant? This is not Mongla plant data.');type('learning-title','Agent validation · saturation and recovery');assert f.ipc('journey-fixture','choose','learning-format','7')=='Question';click('Continue');click('Save');settle();engineering=selected()
 click('Draw / Diagram');assert f.ipc('journey-fixture','choose','drawing-mode','0').startswith('Canvas');type('exploration-title','Agent validation · feedback block diagram');click('Create linked drawing');settle();block=selected();capture('engineering-block-map');f.ipc('journey-fixture','back');time.sleep(.7)
 click('Try in code');type('exploration-title','Agent validation · bounded windup simulation');type('exploration-prediction','Conditional integration may reduce recovery delay in this illustrative model; it does not establish vehicle performance.');click('Create scratch experiment');settle();simulation=selected()
 simulated=edit_run_current('import os\nfrom pathlib import Path\nimport numpy as np\nimport matplotlib.pyplot as plt\nout=Path(os.environ["NOESIS_RUN_DIRECTORY"])\ndt=0.02;time=np.arange(0,20,dt);rows=[]\nfor anti in [False,True]:\n    x=0.;integral=0.;trace=[]\n    for t in time:\n        reference=3. if t<8 else 1.\n        error=reference-x;raw=2*error+0.8*integral;u=np.clip(raw,-2,2)\n        if not anti or raw==u or (raw>u and error<0) or (raw<u and error>0): integral+=error*dt\n        x+=dt*(-x+u);trace.append(x)\n    trace=np.array(trace)\n    late=np.sqrt(np.mean((trace[time>=10]-1)**2))\n    print("conditional integration",anti,"late RMSE",float(late),"normalized illustrative units")\n    rows.append(trace);plt.plot(time,trace,label="conditional integration "+str(anti))\nplt.axvline(8,color="gray",linestyle="--");plt.legend();plt.xlabel("simulated seconds");plt.ylabel("normalized illustrative state")\nplt.savefig(out/"windup.png")\nnp.savetxt(out/"windup.csv",np.column_stack([time,*rows]),delimiter=",",header="time,plain_PI,conditional_PI")\nassert all(np.isfinite(row).all() for row in rows)\nprint("hypothetical plant only: xdot=-x+u; actuator limit +/-2; no hardware inference")\n','engineering-simulation');assert simulated['exit_code']==0
 f.ipc('journey-fixture','mode','fullscreen');f.ipc('noesis-study-desk','showView','figures');time.sleep(1);desk=json.loads(f.ipc('noesis-study-desk','state'));assert desk['visible'] and desk['record']==simulation['id'];capture('fullscreen-experiment')
 desk_image=assets/'screenpad-figures.png';desk_image.unlink(missing_ok=True);f.ipc('journey-fixture','captureDesk',str(desk_image));time.sleep(1);assert desk_image.exists()
 click('Edit scratch code');settle();desk=json.loads(f.ipc('noesis-study-desk','state'));assert desk['visible'] and not f.state()['visible'];assert f.ipc('journey-fixture','deskClick','Resume Noesis')=='clicked';time.sleep(.6);assert selected()['id']==simulation['id'];f.ipc('journey-fixture','mode','normal')
 domains['engineering']={'question':engineering['id'],'drawing':block['id'],'experiment':simulation['id'],'execution':simulated,'limitation':'illustrative first-order software model; no physical performance claim'}
 # Genuine PDF and annotation provisioned only in an isolated external Zotero profile.
 from noesis_self_service_zotero import SourceLibrary
 source_library=SourceLibrary(f.home,port=23129,native_probe=True)
 annotation=source_library.add_annotated_pdf()
 adapter=f.home/'.local/share/sensei-learning/noesis/zotero.py';adapter.write_text(adapter.read_text().replace('127.0.0.1:23119','127.0.0.1:23129'))
 # Test-only URI transport selects the isolated native reader instead of the owner's reader.
 # The staged app invokes its unchanged installed ZoteroProtocolHandler and captures actual reader state.
 shim=f.home/'.local/bin/xdg-open'
 shim.write_text('#!/usr/bin/env python3\nimport sys,json,urllib.request,urllib.parse\nuri=sys.argv[1]\nassert uri.startswith("zotero://open-pdf/library/items/")\nurl='+repr(source_library.base+'noesis-native?token='+source_library.probe_token)+'+"&"+urllib.parse.urlencode({"uri":uri})\nwith urllib.request.urlopen(url,timeout=30) as r: state=json.loads(r.read())\nstate["requested_uri"]=uri\nopen('+repr(str(f.home/'native-reader.json'))+',"w").write(json.dumps(state))\n')
 shim.chmod(0o755)
 capture('return-before-research');click('Start learning');time.sleep(.4);click('Choose from Zotero');time.sleep(1);click('Attention Is All You Need - agent source fixture');settle();paper=selected();capture('annotated-paper')
 click('Open this annotation');settle()
 deadline=time.monotonic()+20
 while not (f.home/'native-reader.json').exists() and time.monotonic()<deadline:time.sleep(.2)
 assert (f.home/'native-reader.json').exists(),'Native annotation transport did not finish; inspect isolated reader log'
 reader=json.loads((f.home/'native-reader.json').read_text());assert reader['readers'],reader
 reader_state=reader['readers'][0]['state'];assert reader_state['selectedAnnotationIDs']==[annotation['annotation']],reader_state
 assert reader_state['primaryViewStats']['pageIndex']==2,reader_state
 assert annotation['annotation'] in reader['requested_uri'] and 'page=3' in reader['requested_uri'],reader
 capture('annotation-return')
 click('Ask about this annotation');type('record-title','Agent validation · attention scaling question');type('record-purpose','Why divide the dot product by the square root of dimension? This is independent interpretation linked to the exact imported source, not a copied annotation.');click('Save');settle();research_question=selected();assert research_question['annotation_ref']['annotation_key']==annotation['annotation']
 click('Open derivation in Obsidian ↗');settle();capture('research-derivation-return')
 out=subprocess.check_output(['obsidian','vault='+str(f.vault.name),'file','info=path'],env=f.env,text=True).strip();assert research_question['path'] in out,out
 click('Try in code');type('exploration-title','Agent validation · attention equation check');type('exploration-prediction','Matched stable softmax and explicit row computation should agree; this is an equation check, not paper reproduction.');click('Create scratch experiment');settle();research_experiment=selected()
 equation=edit_run_current('import numpy as np\nfrom scipy.special import softmax\nq=np.array([[1.,2.],[0.,1.]])\nk=np.array([[1.,0.],[0.,1.],[1.,1.]])\nv=np.array([[2.,0.],[0.,3.],[1.,1.]])\nscores=q@k.T/np.sqrt(q.shape[1])\nactual=softmax(scores,axis=1)@v\nexpected=[]\nfor row in scores:\n    weights=np.exp(row-row.max());weights/=weights.sum();expected.append(sum(w*value for w,value in zip(weights,v)))\nnp.testing.assert_allclose(actual,expected)\nprint("attention equation output",actual.tolist())\nprint("explicit row calculation agrees; no trained-model or learner-understanding claim")\n','research-equation');assert equation['exit_code']==0
 domains['research']={'paper':paper['id'],'annotation_question':research_question['id'],'experiment':research_experiment['id'],'execution':equation}
 f.ipc('journey-fixture','back');time.sleep(.6);assert selected()['id']==research_question['id'];f.ipc('journey-fixture','back');time.sleep(.6);assert selected()['id']==paper['id'];capture('research-source-return')
 f.ipc('journey-fixture','open',json.dumps(origin));time.sleep(.7);f.ipc('journey-fixture','scale','2');time.sleep(.5);click('Draw / Diagram');capture('drawing-dialog-200');click('Cancel');f.ipc('journey-fixture','scale','1');time.sleep(.4)
 f.ipc('journey-fixture','framesStart');time.sleep(5);frames=json.loads(f.ipc('journey-fixture','framesStop'));frames.sort();frame_p95=frames[min(len(frames)-1,int(len(frames)*.95))] if frames else None
 result={'frame_sample_count':len(frames),'frame_p95_ms':frame_p95,'fixture':str(f.home),'record_creation':'native controls only','question_title_preserved':True,'canvas_created_opened':True,'freehand_created_opened':True,'native_editor':True,'terminal_execution':execution,'stdout':stdout,'exact_restart':True,'domains':domains,'annotation':annotation,'native_reader':reader,'learner_achievement':False}
 (assets/'acceptance.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
finally:
 f.stop()
 if source_library:source_library.stop()
 for p in owned:
  if p.poll() is None:os.killpg(p.pid,signal.SIGTERM)
 for client in json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True)):
  try:args=Path('/proc/'+str(client['pid'])+'/environ').read_bytes()
  except OSError:continue
  if ('HOME='+str(f.home)).encode()+b'\0' in args and client.get('class') in ('kitty','com.mitchellh.ghostty','Alacritty'):os.kill(client['pid'],signal.SIGTERM)
 if clipboard.returncode==0:subprocess.run(['wl-copy'],input=clipboard.stdout,check=True)
 else:subprocess.run(['wl-copy','--clear'],check=True)
