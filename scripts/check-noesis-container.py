#!/usr/bin/env python3
"""Verify host-owned capture through an explicitly selected running Distrobox."""
import argparse,json,os,subprocess,tempfile,uuid
from pathlib import Path

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--container',required=True)
args=parser.parse_args()
repo=Path(__file__).resolve().parents[1]
listing=subprocess.check_output(['distrobox','list','--no-color'],text=True)
rows=[line.split('|') for line in listing.splitlines()[1:]]
if not any(len(row)>2 and row[1].strip()==args.container and row[2].strip().startswith('Up ') for row in rows):
    raise SystemExit('Choose an already-running container; this test will not start or configure one.')
with tempfile.TemporaryDirectory(prefix='noesis-host-bridge-',dir=Path.home()/'.cache') as directory:
    home=Path(directory);root=home/'vault';(root/'System').mkdir(parents=True)
    vault_id=str(uuid.uuid4());target_id=str(uuid.uuid4())
    (root/'System/System.json').write_text(json.dumps({'noesis_schema':2,'layout':'network','vault_id':vault_id,'directories':[],'types':{}}))
    (root/'target.md').write_text('---\nnoesis_schema: 2\nid: '+target_id+'\ntype: task\ntitle: Bridge target\n---\nOriginal learner reasoning.\n')
    original=(root/'target.md').read_bytes()
    executable=str(repo/'home/.local/bin/sensei-learn')
    environment=['HOME='+str(home),'XDG_CACHE_HOME='+str(home/'.cache'),'XDG_CONFIG_HOME='+str(home/'.config'),'XDG_STATE_HOME='+str(home/'.local/state')]
    operation_id=str(uuid.uuid4())
    probe=subprocess.run(['distrobox','enter','--name',args.container,'--','host-spawn','--version'],text=True,capture_output=True)
    if probe.returncode or tuple(int(n) for n in probe.stdout.strip().lstrip('v').split('.'))<(1,6,0):raise SystemExit('A supported host-spawn must already be installed; no automatic installation is performed.')
    command=['distrobox','enter','--name',args.container,'--','sh','-c','cd / && exec distrobox-host-exec "$@"','noesis-bridge','env',*environment,executable,'capture','--vault',str(root),'--context-id',target_id,'--operation-id',operation_id,'Host bridge observation']
    first=subprocess.check_output(command,text=True).strip();second=subprocess.check_output(command,text=True).strip()
    assert first==second,(first,second)
    host_env=dict(os.environ,HOME=str(home),XDG_CACHE_HOME=str(home/'.cache'),XDG_CONFIG_HOME=str(home/'.config'),XDG_STATE_HOME=str(home/'.local/state'))
    page=json.loads(subprocess.check_output([executable,'query','--vault',str(root),'Host bridge observation'],env=host_env,text=True))
    assert len(page['records'])==1 and str(root/page['records'][0]['path'])==first
    assert (root/'target.md').read_bytes()==original
    import sys
    sys.path.insert(0,str(repo/'home/.local/share/sensei-learning'))
    from noesis.persistence import parse
    props,_=parse(Path(first).read_text())
    assert props['parent_ref']['vault_id']==vault_id and props['parent_ref']['record_id']==target_id
    print('PASS: running Distrobox → host bridge → scoped capture; retry keeps one identity, original reasoning unchanged; no guest package installation or configuration.')

    code=home/'model.py';code.write_text('prediction = 0\n')
    probe=home/'neovim-bridge.lua'
    plugin=home/'sensei-learning.lua'
    (home/'.local/bin').mkdir(parents=True)
    (home/'.local/bin/noesis').symlink_to(Path.home()/'.local/bin/noesis')
    (home/'.config/sensei-learning').mkdir(parents=True)
    (home/'.config/sensei-learning/config.json').write_text(json.dumps({'active_vault':str(root)}))
    plugin.write_text((repo/'home/.config/nvim/after/plugin/sensei-learning.lua').read_text().replace('@HOME@',str(home)))
    lua='vim.env.NOESIS_VAULT='+json.dumps(str(root))+';vim.env.NOESIS_RECORD_ID='+json.dumps(target_id)+'\n'
    lua+='dofile('+json.dumps(str(plugin))+')\nvim.cmd.edit('+json.dumps(str(code))+')\n'
    lua+='vim.ui.input=function(_,callback)callback("Neovim bridge observation")end\n'
    lua+='local mapping=vim.fn.maparg("<leader>oc","n",false,true);assert(mapping.callback);mapping.callback()\n'
    lua+='local ok=vim.wait(10000,function()return #vim.fn.glob('+json.dumps(str(root/'Inbox/*.md'))+',false,true)>=2 end,50);assert(ok,"Neovim bridge capture timed out")\n'
    lua+='vim.env.NOESIS_VAULT="";vim.ui.input=function(_,callback)callback("Fallback bridge observation")end;mapping.callback()\n'
    lua+='assert(vim.wait(10000,function()return #vim.fn.glob('+json.dumps(str(root/'Inbox/*.md'))+',false,true)>=3 end,50),"Host configuration fallback timed out");vim.cmd.qa()\n'
    probe.write_text(lua)
    subprocess.run(['distrobox','enter','--name',args.container,'--','nvim','--headless','-u','NONE','-l',str(probe)],check=True,timeout=20)
    page=json.loads(subprocess.check_output([executable,'query','--vault',str(root),'Neovim bridge observation'],env=host_env,text=True))
    assert len(page['records'])==1
    props,body=parse((root/page['records'][0]['path']).read_text())
    assert props['parent_ref']['vault_id']==vault_id and props['parent_ref']['record_id']==target_id
    assert str(code) in body and 'not in Git' in body,body
    fallback=json.loads(subprocess.check_output([executable,'query','--vault',str(root),'Fallback bridge observation'],env=host_env,text=True))
    assert len(fallback['records'])==1
    assert (root/'target.md').read_bytes()==original
    print('PASS: actual guest Neovim mapping runs host Noesis with owner-scoped code provenance; headless integration, not human interaction evidence.')
