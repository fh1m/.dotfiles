import importlib.machinery
import importlib.util
import os
from pathlib import Path
from unittest.mock import patch

import pytest

ROOT=Path(__file__).resolve().parents[1]


def test_android_tailnet_status_only_reports_candidates(tmp_path):
    pytest.importorskip('dbus')
    source=ROOT/'home/.local/bin/sensei-phone'
    loader=importlib.machinery.SourceFileLoader('phone_status_observational',str(source))
    spec=importlib.util.spec_from_loader(loader.name,loader);module=importlib.util.module_from_spec(spec)
    with patch.object(Path,'home',return_value=tmp_path):loader.exec_module(module)
    status={'Peer':{'device':{'HostName':'A52','OS':'android','Online':True,'TailscaleIPs':['100.64.0.7']},'other':{'HostName':'Laptop','OS':'linux','TailscaleIPs':['100.64.0.8']}}}
    candidates=module.android_peers(status)
    assert candidates==[{'name':'A52','os':'android','online':True,'ips':['100.64.0.7'],'relay':None,'address':None,'lastSeen':None},{'name':'Laptop','os':'linux','online':None,'ips':['100.64.0.8'],'relay':None,'address':None,'lastSeen':None}]
    full_source=source.read_text().split('def full():',1)[1].split('\ndef ',1)[0]
    assert 'customDevices' not in full_source
    assert 'forceOnNetworkChange' not in full_source
