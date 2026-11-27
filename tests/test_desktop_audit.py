"""Desktop lifecycle, status truthfulness and concurrent sampler contracts."""
import concurrent.futures
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
def load(name,path):
    loader=importlib.machinery.SourceFileLoader(name,str(ROOT/path))
    spec=importlib.util.spec_from_loader(name,loader);module=importlib.util.module_from_spec(spec);loader.exec_module(module);return module

status=load('audit_status','home/.local/bin/sensei-status')
def result(code=0,text=''):
    return subprocess.CompletedProcess([],code,text,'')

def test_failed_user_units_are_not_healthy():
    with patch.object(status,'run',side_effect=[result(),result(text='broken.service loaded failed failed\n')]):
        assert status.failed()=={'system':0,'user':1,'total':1}
    with patch.object(status,'run',side_effect=[None,result()]):assert status.failed()['total'] is None

def test_updates_distinguish_offline_zero_and_invalid():
    for response,expected in [(result(2),{'known':True,'count':0}),(result(1),{'known':False,'error':'check-failed'}),(result(text='broken'),{'known':False,'error':'invalid-response'}),(result(text='foo 1 -> 2\n'),{'known':True,'count':1})]:
        with patch.object(status,'run',return_value=response):assert status.updates()==expected

def test_route_is_not_an_internet_or_icmp_verdict():
    with patch.object(status,'run',side_effect=[result(text='[]'),result(text='[{"dst":"default","dev":"wlan0","gateway":"fe80::1"}]'),result(1)]):
        d=status.route();assert d['defaultRoutePresent'] and d['internet']=='unverified' and d['gatewayPingMs'] is None

def test_firewall_manager_does_not_award_protection():
    for response in [result(text='active\n'),result(3,'inactive\n'),None]:
        with patch.object(status,'run',return_value=response):assert status.firewall()['policy']=='unknown'

def test_sampler_concurrent_writes_and_no_argv_disclosure(tmp_path):
    env=dict(os.environ,XDG_RUNTIME_DIR=str(tmp_path),SENSEI_MONITOR_DETAIL='1')
    def sample(_):
        r=subprocess.run([sys.executable,str(ROOT/'home/.local/bin/system-monitor-data')],env=env,capture_output=True,text=True,timeout=20,check=True)
        d=json.loads(r.stdout)
        assert all(x['command']==x['name'] for x in d['processes'])
        return d
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:rows=list(pool.map(sample,range(8)))
    assert all(0<=r['cpu']<=100 for r in rows)
    assert json.loads((tmp_path/'fh1m-monitor.json').read_text())['time']>0
    assert not list(tmp_path.glob('*.tmp'))

def test_stream_config_and_shutdown(tmp_path):
    env=dict(os.environ,XDG_RUNTIME_DIR=str(tmp_path),SENSEI_MONITOR_PRIVATE='1')
    p=subprocess.Popen([sys.executable,str(ROOT/'home/.local/bin/system-monitor-data'),'--stream'],env=env,stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True)
    try:
        first=json.loads(p.stdout.readline());assert first['ips']==[] and first['extra']=={}
        p.stdin.write('{"detail":true,"private":true}\n');p.stdin.flush()
        second=json.loads(p.stdout.readline())
        assert second['private'] is True
        assert second['processes']==[] and second['ips']==[] and second['mounts']==[]
        p.stdin.write('{"detail":true,"private":false}\n');p.stdin.flush()
        third=json.loads(p.stdout.readline());assert third['private'] is False
        p.stdin.close();assert p.wait(timeout=5)==0
    finally:
        if p.poll() is None:p.kill();p.wait()

def test_owned_watcher_dies_when_parent_crashes(tmp_path):
    pidfile=tmp_path/'child.pid'
    parent_code='''import subprocess,sys,time
p=subprocess.Popen([sys.executable,'-c',sys.argv[1]])
open(sys.argv[2],'w').write(str(p.pid))
time.sleep(30)
'''
    child_code=f"import sys,time;sys.path.insert(0,{str(ROOT/'home/.local/share/sensei')!r});from child_lifetime import bind_parent;bind_parent();print('ready',flush=True);time.sleep(30)"
    p=subprocess.Popen([sys.executable,'-c',parent_code,child_code,str(pidfile)],stdout=subprocess.PIPE,text=True)
    child=None
    try:
        assert p.stdout.readline().strip()=='ready';child=int(pidfile.read_text());p.kill();p.wait()
        deadline=time.monotonic()+4
        while time.monotonic()<deadline:
            stat=Path(f'/proc/{child}/stat')
            if not stat.exists() or stat.read_text().split(') ')[1].startswith('Z'):break
            time.sleep(.05)
        else:raise AssertionError('Owned watcher survived parent SIGKILL')
    finally:
        if p.poll() is None:p.kill();p.wait()
        if child:
            try:os.kill(child,signal.SIGTERM)
            except ProcessLookupError:pass


def kde_peers(*identities):
    return result(text=json.dumps({'type':'as','data':[list(identities)]}))


def kde_properties(paired=True, reachable=True):
    return result(text=json.dumps({'type':'a{sv}','data':[{
        'isPaired':{'type':'b','data':paired},'isReachable':{'type':'b','data':reachable},
        'type':{'type':'s','data':'phone'},'name':{'type':'s','data':'PRIVATE_PHONE_NAME'},
        'verificationKey':{'type':'s','data':'PRIVATE_PAIRING_KEY'},
        'reachableAddresses':{'type':'as','data':['PRIVATE_ADDRESS']},
    }]}))


def test_discovery_separates_usable_pairing_from_resolver_noise_and_redacts_identity():
    warning=result(text=json.dumps({'MESSAGE':'PRIVATE_PEER_ID could not resolve'})+'\n')
    with patch.object(status.subprocess,'run',side_effect=[kde_peers('PRIVATE_PEER_ID'),kde_properties(),warning]):
        value=status.discovery()
    assert value['known'] and value['paired']==value['reachablePaired']==1
    assert value['state']=='discovery_warnings' and value['resolverTimeouts1h']==1
    assert 'PRIVATE_' not in json.dumps(value)


def test_discovery_unreachable_pair_is_not_deleted_or_reported_as_unpaired():
    with patch.object(status.subprocess,'run',side_effect=[kde_peers('peer'),kde_properties(reachable=False),result()]):
        value=status.discovery()
    assert value['state']=='waiting_for_peer' and value['paired']==1 and value['reachablePaired']==0
    assert 'asleep or offline' in value['guidance']


def test_discovery_incomplete_device_or_journal_cannot_be_healthy():
    with patch.object(status.subprocess,'run',side_effect=[kde_peers('peer'),result(1),result()]):
        value=status.discovery()
    assert not value['known'] and value['paired'] is None and value['state']=='unavailable'
    denied=subprocess.CompletedProcess([],1,'','journal access denied')
    with patch.object(status.subprocess,'run',side_effect=[kde_peers('peer'),kde_properties(),denied]):
        value=status.discovery()
    assert value['state']=='discovery_unverified' and value['resolverTimeouts1h'] is None


def test_discovery_advertised_unpaired_device_is_not_a_working_link():
    with patch.object(status.subprocess,'run',side_effect=[kde_peers('peer'),kde_properties(paired=False),result()]):
        value=status.discovery()
    assert value['state']=='no_paired_devices' and value['paired']==value['reachablePaired']==0
