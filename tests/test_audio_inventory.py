"""An unavailable audio server is not a successful empty device inventory."""
import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

from test_quickshell_ui_freshness import HAS_QS, helper, run_native, setup_services

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.parametrize('mode', ['list-failed', 'info-failed', 'list-invalid', 'info-invalid', 'empty'])
def test_inventory_distinguishes_empty_from_unavailable(tmp_path, mode):
    pactl = tmp_path / 'pactl'
    pactl.write_text('#!' + sys.executable + '''
import json,os,sys
operation=sys.argv[-1]
mode=os.environ['AUDIO_FIXTURE_MODE']
if mode==operation+'-failed':
 print('private transport diagnostic',file=sys.stderr);raise SystemExit(7)
if mode==operation+'-invalid':print('not json');raise SystemExit
print(json.dumps({} if operation=='info' else {'sinks':[],'sources':[],'sink_inputs':[],'source_outputs':[],'cards':[]}))
''')
    pactl.chmod(0o700)
    env = dict(os.environ, PATH=str(tmp_path) + os.pathsep + os.environ['PATH'], AUDIO_FIXTURE_MODE=mode)
    result = subprocess.run([sys.executable, str(ROOT / 'home/.local/bin/sensei-audio'), 'list'],
                            env=env, text=True, capture_output=True, timeout=8)
    response = json.loads(result.stdout)
    if mode == 'empty':
        assert result.returncode == 0 and not response.get('error')
        assert response['sinks'] == [] and response['sources'] == []
    else:
        assert result.returncode != 0, response
        assert response.get('error'), response
        assert 'sinks' not in response  # Unknown, not a fabricated zero-device result.
        assert 'private transport diagnostic' not in result.stdout


AUDIO_BACKEND = r'''import json,sys
from pathlib import Path
home=Path.home()
if sys.argv[1:]!=['list']:
 with (home/'audio-controls.jsonl').open('a') as out:out.write(json.dumps(sys.argv[1:])+'\n')
 print('Volume change failed',file=sys.stderr);raise SystemExit(9)
count=home/'audio-query-count'
n=int(count.read_text())+1 if count.exists() else 1
count.write_text(str(n))
if n==2:print(json.dumps({'error':'Audio server unavailable'}));raise SystemExit(1)
index=1 if n==1 else 2
print(json.dumps({'sinks':[{'index':index,'name':'sink-'+str(index),'description':'Test output','ports':{}}],
 'sources':[],'sink-inputs':[],'source-outputs':[],'cards':[],
 'defaultSink':'sink-'+str(index),'defaultSource':'after-action-refresh' if n>=4 else ''}))
'''


@pytest.mark.skipif(not HAS_QS, reason='Explicit native Quickshell runtime required')
def test_mixer_recovery(tmp_path):
    setup_services(tmp_path, 'SoundDesk.qml')
    helper(tmp_path, 'sensei-audio', AUDIO_BACKEND)
    harness = '''import QtQuick
import Quickshell
import qs.services
ShellRoot {
 id: test
 property int phase:0
 property int ticks:0
 Timer {interval:20;repeat:true;running:true;onTriggered:{
  test.ticks++
  if(test.ticks>150){console.error('Audio recovery timed out: '+test.phase);Qt.exit(2);return}
  if(test.phase===0){SoundDesk.refresh();test.phase=1;return}
  if(test.phase===1&&SoundDesk.data.sinks?.[0]?.name==='sink-1'){
   SoundDesk.refresh();test.phase=2;return
  }
  if(test.phase===2&&(SoundDesk.error||SoundDesk.data.error)){
   if(SoundDesk.data.sinks?.[0]?.name!=='sink-1')throw new Error('Failed query erased the last known devices')
   if(!SoundDesk.error)throw new Error('Failed query has no actionable error')
   SoundDesk.action('mute',1,'1') // Must not control a stale server node.
   SoundDesk.refresh();test.phase=3;return
  }
  if(test.phase===3&&SoundDesk.data.sinks?.[0]?.name==='sink-2'){
   if(SoundDesk.error)throw new Error('Successful inventory did not recover')
   SoundDesk.action('mute',2,'1');test.phase=4;return
  }
  if(test.phase===4&&SoundDesk.data.defaultSource==='after-action-refresh'){
   if(!SoundDesk.error.includes('Volume change failed'))throw new Error('Inventory refresh hid a failed control')
   console.log('PROOF_PASS audio failure/recovery ownership');Qt.quit()
  }
 }}
}
'''
    report = run_native(tmp_path, harness, timeout=8)
    assert 'PROOF_PASS audio failure/recovery ownership' in report
    actions = [json.loads(row) for row in (tmp_path / 'audio-controls.jsonl').read_text().splitlines()]
    assert actions == [['mute', '2', '1']]  # No command reached the stale sink after failure.
