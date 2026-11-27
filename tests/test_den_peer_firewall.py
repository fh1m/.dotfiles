import importlib.util,json,pwd,socket,subprocess
from pathlib import Path
import pytest
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('peer_rules',ROOT/'scripts/reconcile-den-peer.py');peer=importlib.util.module_from_spec(spec);spec.loader.exec_module(peer)

def fixture(tmp_path):
 cfg={'network':'192.0.2.0/24','user':pwd.getpwuid(__import__('os').getuid()).pw_name,'hostname':'homie.local','expectedHost':'homie','identityFile':'fixture-key','knownHostsFile':'fixture-pins','hostKeyAlias':'homie-den'}
 path=tmp_path/'peers.nft';path.write_text('add element inet sensei_fw den_peers4 { 192.0.2.4 }\n')
 resolver=lambda *args:[(socket.AF_INET,socket.SOCK_STREAM,6,'',('192.0.2.18',22))]
 return cfg,path,resolver

def test_dhcp_change_preserves_scope_and_updates_persistent_peer(tmp_path):
 cfg,path,resolver=fixture(tmp_path);kernel={'192.0.2.4'}
 def run(command):
  if command[:3]==['nft','-j','list']:return subprocess.CompletedProcess(command,0,json.dumps({'nftables':[{'set':{'elem':list(kernel)}}]}),'')
  if command[0]=='runuser':return subprocess.CompletedProcess(command,0,'homie\n','')
  transaction=Path(command[-1]).read_text()
  assert transaction=='flush set inet sensei_fw den_peers4\nadd element inet sensei_fw den_peers4 { 192.0.2.18 }\n'
  if '-c' not in command:kernel.clear();kernel.add('192.0.2.18')
  return subprocess.CompletedProcess(command,0,'','')
 result=peer.reconcile(cfg,runner=run,resolver=resolver,apply=True,peers=path)
 assert result['state']=='updated' and kernel=={'192.0.2.18'}
 assert path.read_text()=='add element inet sensei_fw den_peers4 { 192.0.2.18 }\n'

@pytest.mark.parametrize('code,hostname',[(255,''),(0,'unpaired-host')])
def test_unverified_peer_cannot_change_firewall(tmp_path,code,hostname):
 cfg,path,resolver=fixture(tmp_path);original=path.read_bytes()
 def run(command):
  if command[:3]==['nft','-j','list']:return subprocess.CompletedProcess(command,0,'{"nftables":[{"set":{"elem":["192.0.2.4"]}}]}','')
  if command[0]=='runuser':return subprocess.CompletedProcess(command,code,hostname,'')
  raise AssertionError('Unverified discovery attempted firewall mutation')
 with pytest.raises(peer.PeerUnavailable):peer.reconcile(cfg,runner=run,resolver=resolver,apply=True,peers=path)
 assert path.read_bytes()==original

def test_failed_kernel_update_restores_persistent_pairing(tmp_path):
 cfg,path,resolver=fixture(tmp_path);original=path.read_bytes()
 def run(command):
  if command[:3]==['nft','-j','list']:return subprocess.CompletedProcess(command,0,'{"nftables":[{"set":{"elem":["192.0.2.4"]}}]}','')
  if command[0]=='runuser':return subprocess.CompletedProcess(command,0,'homie','')
  return subprocess.CompletedProcess(command,0 if '-c' in command else 1,'','')
 with pytest.raises(ValueError,match='persistent policy restored'):peer.reconcile(cfg,runner=run,resolver=resolver,apply=True,peers=path)
 assert path.read_bytes()==original
