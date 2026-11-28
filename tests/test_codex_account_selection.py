"""Consumer-visible account isolation and non-disruptive refresh in native QML."""
import pytest

from test_quickshell_ui_freshness import HAS_QS, helper, run_native, setup_services

BACKEND = r'''import json, signal, sys, time
from pathlib import Path
signal.signal(signal.SIGTERM, signal.SIG_IGN)
a = sys.argv[1:]
action = a[0]
account = a[a.index('--account')+1] if '--account' in a else ''
state = Path.home() / 'monitoring.json'
monitored = json.loads(state.read_text()) if state.exists() else ['a', 'b']
if action == 'list':
    time.sleep(.02)
    print(json.dumps({'accounts': [{'id': key, 'source':'profile', 'name': name,
          'identity': key, 'monitored':key in monitored} for key, name in [('a','Alpha'),('b','Beta')]]}), flush=True)
elif action == 'usage':
    time.sleep(.35 if account == 'a' else .03)
    print(json.dumps({'accountId':account, 'measurementAt':100,
          'rateLimits':{'primary':{'usedPercent':90 if account == 'a' else 20}}}), flush=True)
elif action in ('add','remove'):
    monitored = list(set(monitored + [account])) if action == 'add' else [key for key in monitored if key != account]
    state.write_text(json.dumps(monitored))
    print(json.dumps({'ok':True,'accountId':account}), flush=True)
'''

HARNESS = '''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    id: root
    property string scenario: Quickshell.env("ACCOUNT_SCENARIO")
    property int phase: 0
    property int ticks: 0
    property int changedAt: 0
    function check(condition, message) {
        if (!condition) {console.error("PROOF_FAIL", message);Qt.exit(2);return false;}
        return true;
    }
    Timer {interval:5;running:true;onTriggered:CodexAccounts.active=true}
    Timer {interval:20;repeat:true;running:true;onTriggered:{
        root.ticks++;
        if (root.ticks > 250) {console.error("PROOF_FAIL", "account workflow timeout");Qt.exit(3);return;}
        const shown=CodexAccounts.usage;
        if (root.scenario==="all") {
            if (CodexAccounts.busy||!shown.accountId) return;
            const first=CodexAccounts.accounts.find(account=>account.id==="a").snapshot;
            const second=CodexAccounts.accounts.find(account=>account.id==="b").snapshot;
            if (!root.check(first?.rateLimits?.primary?.usedPercent===90&&second?.rateLimits?.primary?.usedPercent===20,
                            "refresh left another monitored account without a current measurement")) return;
            console.log("PROOF_PASS",root.scenario);Qt.quit();return;
        }
        if (root.phase===0) {
            if (root.scenario==="refresh") {
                if (shown.accountId!=="a"||CodexAccounts.busy) return;
                CodexAccounts.refresh(false);
                if (!root.check(CodexAccounts.usage.accountId==="a"&&CodexAccounts.busy,"refresh blanked the visible measurement")) return;
            } else {
                if (CodexAccounts.selected!=="a"||!CodexAccounts.busy||shown.accountId) return;
                if (root.scenario==="switch") CodexAccounts.selectAccount("b");
                else if (root.scenario==="remove") CodexAccounts.monitor("a",false);
                else CodexAccounts.active=false;
            }
            root.phase=1;root.changedAt=root.ticks;return;
        }
        if (root.ticks-root.changedAt<40) return;
        if (root.scenario==="close"&&root.phase===1) {
            if (!root.check(!shown.accountId&&!CodexAccounts.busy,"closed widget accepted a late measurement")) return;
            CodexAccounts.active=true;root.phase=2;root.changedAt=root.ticks;return;
        }
        const expected=root.scenario==="refresh"||root.scenario==="close"?"a":"b";
        if (!root.check(CodexAccounts.selected===expected&&shown.accountId===expected&&!CodexAccounts.busy,"late response replaced the current account")) return;
        if (!root.check(shown.rateLimits.primary.usedPercent===(expected==="a"?90:20),"limits belong to another account")) return;
        if (root.scenario==="remove"&&!root.check(!CodexAccounts.accounts.find(account=>account.id==="a").monitored,"removed account became monitored again")) return;
        console.log("PROOF_PASS",root.scenario);Qt.quit();
    }}
}
'''


@pytest.mark.skipif(not HAS_QS, reason='Requires an explicitly selected native Quickshell runtime')
@pytest.mark.parametrize('scenario', ['switch', 'refresh', 'remove', 'close', 'all'])
def test_account_workflow_owns_its_measurements(tmp_path, scenario):
    setup_services(tmp_path, 'CodexAccounts.qml')
    helper(tmp_path, 'sensei-codex-accounts', BACKEND)
    report = run_native(tmp_path, HARNESS, {'ACCOUNT_SCENARIO': scenario})
    assert 'PROOF_PASS ' + scenario in report, report
