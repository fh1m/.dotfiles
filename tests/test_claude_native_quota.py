"""Subscription measurements retain identity, age and failure provenance."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import sys
import time
from datetime import datetime,timezone
from unittest.mock import patch

import pytest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'home/.local/share/sensei'))
import claude_quota as quota

IDENTITY={'signedIn':True,'email':'learner@example.invalid','organizationId':'org-one'}


def trusted_probe_fixture(directory,probe,monkeypatch):
    monkeypatch.setattr(quota,'probe_directory',lambda:probe)
    probe.mkdir(mode=0o700)
    directory.mkdir()
    (directory/'.claude.json').write_text(json.dumps({'projects':{str(probe):{'hasTrustDialogAccepted':True}}}))


def payload(percent=42,stamp=None):
    return {'provider':'claude','usage':{'accountEmail':IDENTITY['email'],
        'updatedAt':stamp or datetime.now(timezone.utc).isoformat(),
        'primary':{'usedPercent':percent,'resetsAt':None}}}


@pytest.mark.parametrize('change',[
    lambda d:d['usage'].update(accountEmail='other@example.invalid'),
    lambda d:d['usage'].update(updatedAt='2026-01-01T12:00:00'),
    lambda d:d['usage']['primary'].update(usedPercent=float('nan')),
    lambda d:d['usage']['primary'].update(usedPercent=101),
    lambda d:d['usage']['primary'].update(usedPercent=True),
    lambda d:d['usage']['primary'].update(resetsAt='2026-01-01T12:00:00'),
    lambda d:d.update(usage=['not-an-observation']),
    lambda d:d['usage'].update(identity='not-an-identity'),
])
def test_unattributable_or_invalid_measurements_are_rejected(change):
    data=payload();change(data)
    with pytest.raises(ValueError):quota.normalize(data,IDENTITY)


def test_profile_and_organization_changes_cannot_reuse_another_cache(tmp_path,monkeypatch):
    monkeypatch.setenv('XDG_CACHE_HOME',str(tmp_path))
    a=quota.cache_path('/tmp/profile-a',IDENTITY)
    assert a!=quota.cache_path('/tmp/profile-b',IDENTITY)
    assert a!=quota.cache_path('/tmp/profile-a',dict(IDENTITY,organizationId='org-two'))
    assert a!=quota.cache_path('/tmp/profile-a',dict(IDENTITY,email='other@example.invalid'))


@pytest.mark.parametrize('failure',['provider','identity-change'])
def test_failed_refresh_preserves_original_measurement_and_does_not_publish_wrong_account(tmp_path,monkeypatch,failure):
    monkeypatch.setenv('XDG_CACHE_HOME',str(tmp_path))
    directory=tmp_path/'profile';now=time.time()
    trusted_probe_fixture(directory,tmp_path/'probe',monkeypatch)
    old=quota.normalize(payload(17,datetime.fromtimestamp(now-60,timezone.utc).isoformat()),IDENTITY)
    old['checkedAt']=now-60
    path=quota.cache_path(directory,IDENTITY);quota.write(path,old)
    def query(argv,output,**kwargs):
        output.write_text(json.dumps(payload(88)))
        return {'exitCode':1 if failure=='provider' else 0,'logTruncated':False}
    monkeypatch.setattr(quota.shutil,'which',lambda name:'/fixture/codexbar')
    monkeypatch.setattr(quota,'run_bounded',query)
    monkeypatch.setattr(quota,'native_identity',lambda directory:dict(IDENTITY,email='changed@example.invalid'))
    result=quota.collect(directory,IDENTITY,force=True)
    assert result['stale'] and result['error']
    assert result['fiveHour']['used_percentage']==17
    assert result['measurementAt']==old['measurementAt']
    assert quota.read(path)['updatedAt']==old['updatedAt']


def test_repeated_manual_refresh_is_bounded_without_changing_measurement_age(tmp_path,monkeypatch):
    monkeypatch.setenv('XDG_CACHE_HOME',str(tmp_path))
    directory=tmp_path/'profile';now=time.time()
    old=quota.normalize(payload(23,datetime.fromtimestamp(now-60,timezone.utc).isoformat()),IDENTITY)
    old['checkedAt']=now-5
    quota.write(quota.cache_path(directory,IDENTITY),old)
    def unexpected(*args,**kwargs):raise AssertionError('Duplicate provider request during cooldown')
    monkeypatch.setattr(quota,'run_bounded',unexpected)
    result=quota.collect(directory,IDENTITY,force=True)
    assert result['measurementAt']==old['measurementAt']
    assert result['checkedAt']==old['checkedAt']


def test_environment_uses_selected_native_profile_not_injected_api_credentials(tmp_path,monkeypatch):
    monkeypatch.setenv('ANTHROPIC_API_KEY','test-only-secret')
    monkeypatch.setenv('CLAUDE_CODE_OAUTH_TOKEN','test-only-token')
    monkeypatch.setenv('CLAUDE_CODE_USE_BEDROCK','1')
    monkeypatch.setenv('CUDA_HOME','/fixture/cuda')
    env=quota.environment(tmp_path)
    assert 'ANTHROPIC_API_KEY' not in env and 'CLAUDE_CODE_OAUTH_TOKEN' not in env
    assert 'CLAUDE_CODE_USE_BEDROCK' not in env
    assert env['CLAUDE_CONFIG_DIR']==str(tmp_path.resolve()) and env['CUDA_HOME']=='/fixture/cuda'


def test_unapproved_probe_never_starts_a_provider_process(tmp_path,monkeypatch):
    monkeypatch.setenv('XDG_CACHE_HOME',str(tmp_path/'cache'))
    monkeypatch.setenv('XDG_DATA_HOME',str(tmp_path/'data'))
    marker=tmp_path/'provider-started'
    binary=tmp_path/'codexbar'
    binary.write_text('#!/usr/bin/python3\nfrom pathlib import Path\n'
                      f'Path({str(marker)!r}).write_text("started")\nprint("{{}}")\n')
    binary.chmod(0o700)
    monkeypatch.setattr(quota.shutil,'which',lambda name:str(binary))
    result=quota.collect(tmp_path/'unapproved-profile',IDENTITY,force=True)
    assert not marker.exists()
    assert result['requiresApproval'] is True


def test_trust_from_another_profile_does_not_authorize_the_selected_profile(tmp_path,monkeypatch):
    monkeypatch.setenv('XDG_DATA_HOME',str(tmp_path/'data'))
    probe=quota.probe_directory()
    probe.mkdir(parents=True,mode=0o700)
    profile=tmp_path/'profile-one';profile.mkdir()
    (profile/'.claude.json').write_text(json.dumps({'projects':{str(probe):{'hasTrustDialogAccepted':True}}}))
    assert quota.native_probe_trusted(profile)
    assert not quota.native_probe_trusted(tmp_path/'profile-two')
