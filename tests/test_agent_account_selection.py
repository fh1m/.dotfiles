import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SERVICE = ROOT / 'home/.config/quickshell/sensei/services/CodeDesk.qml'

# Deliberately out-of-order, cancellable external requests. No real accounts,
# credentials, transcripts, provider traffic or model sessions are involved.
BACKEND = r'''#!/usr/bin/env python3
import argparse
import json
import os
import signal
import time
from pathlib import Path

signal.signal(signal.SIGTERM, signal.SIG_IGN)
p = argparse.ArgumentParser()
p.add_argument('action')
p.add_argument('--account', default='')
p.add_argument('--days', type=int, default=30)
p.add_argument('--refresh', action='store_true')
a = p.parse_args()
scenario = os.environ['ACCOUNT_SCENARIO']
if a.action == 'claude-accounts':
    counter = Path.home() / 'discovery-count'
    count = int(counter.read_text()) + 1 if counter.exists() else 1
    counter.write_text(str(count))
    time.sleep(0.03)
    names = ['default'] if scenario == 'removed' and count > 1 else ['second', 'default']
    print(json.dumps({'accounts': [{'id': name, 'name': name, 'identity': {'signedIn': True}} for name in names]}), flush=True)
elif a.action == 'claude':
    account = a.account or 'default'
    time.sleep(0.35 if account == 'default' and a.days == 30 else 0.03)
    shown = 'default' if scenario == 'mismatch' else account
    print(json.dumps({'account': shown, 'days': a.days, 'totals': {'responses': 3}}), flush=True)
else:
    print('{}', flush=True)
'''

HARNESS = r'''import QtQuick
import Quickshell
import qs.services
ShellRoot {
    id: root
    property string scenario: Quickshell.env("ACCOUNT_SCENARIO")
    property int ticks: 0
    property int phase: 0
    property int changedAt: 0
    function check(condition, message) {
        if (!condition) { console.error("PROOF_FAIL", message); Qt.exit(2); return false; }
        return true;
    }
    function done() { console.log("PROOF_PASS", scenario); Qt.quit(); }
    Timer { interval: 5; running: true; onTriggered: {
        if (root.scenario !== "initial" && root.scenario !== "mismatch" && root.scenario !== "removed")
            CodeDesk.claudeAccount = "default";
        CodeDesk.tab = 1;
        CodeDesk.provider = 2;
        ShellState.dropdown = "code";
    }}
    Timer { interval: 20; repeat: true; running: true; onTriggered: {
        root.ticks++;
        if (root.ticks > 250) { console.error("PROOF_FAIL", "account workflow timed out", root.scenario); Qt.exit(3); return; }
        const shown = CodeDesk.claudeUsage;
        if (root.scenario === "initial" && shown.account) {
            if (root.check(CodeDesk.claudeAccount === "second" && shown.account === "second", "discovery displayed another account")) root.done();
            return;
        }
        if (root.scenario === "mismatch" && (shown.account || shown.error)) {
            if (root.check(CodeDesk.claudeAccount === "second" && !shown.account && !!shown.error, "mismatched provider response was displayed")) root.done();
            return;
        }
        if (root.phase === 0) {
            if (root.scenario === "removed") {
                if (shown.account !== "second") return;
                CodeDesk.refreshClaude(false);
            } else {
                if (!(CodeDesk.claudeAccounts.accounts || []).length || shown.account || shown.error) return;
                if (root.scenario === "switch") CodeDesk.selectClaudeAccount("second");
                else if (root.scenario === "days") CodeDesk.setClaudeDays(7);
                else if (root.scenario === "close") ShellState.dropdown = "";
                else if (root.scenario === "provider") CodeDesk.provider = 0;
            }
            root.changedAt = root.ticks;
            root.phase = 1;
            return;
        }
        if (root.ticks - root.changedAt < 35) return;
        if (root.scenario === "switch") {
            if (root.check(CodeDesk.claudeAccount === "second" && shown.account === "second", "old account reply replaced the selected account")) root.done();
        } else if (root.scenario === "days") {
            if (root.check(shown.account === "default" && shown.days === 7, "old date-range reply replaced the current range")) root.done();
        } else if (root.scenario === "removed") {
            if (root.check(CodeDesk.claudeAccount === "default" && shown.account === "default", "removed account remained selected or displayed")) root.done();
        } else if (root.scenario === "provider") {
            if (root.check(CodeDesk.provider === 0 && !shown.account, "hidden provider received a late account reply")) root.done();
        } else if (root.scenario === "close") {
            if (root.phase === 1) {
                if (!root.check(!shown.account, "closed widget received a late account reply")) return;
                ShellState.dropdown = "code";
                root.phase = 2;
                root.changedAt = root.ticks;
            } else if (root.check(shown.account === "default", "reopened widget did not resume its selected account")) root.done();
        }
    }}
}
'''


@pytest.mark.skipif(not os.environ.get('SENSEI_QS_BINARY'), reason='Requires an explicitly selected native Quickshell runtime')
@pytest.mark.parametrize('scenario', ['initial', 'switch', 'days', 'removed', 'close', 'provider', 'mismatch'])
def test_claude_selection_owns_displayed_usage(tmp_path, scenario):
    services = tmp_path / 'services'
    services.mkdir()
    shutil.copy2(SERVICE, services / 'CodeDesk.qml')
    (services / 'ShellState.qml').write_text('''pragma Singleton
import QtQuick
QtObject {
    property string dropdown: ""
    function publishAnchor() {}
    function toggleDropdown(name) { dropdown = dropdown === name ? "" : name; }
}
''')
    binary = tmp_path / '.local/bin/sensei-code'
    binary.parent.mkdir(parents=True)
    binary.write_text(BACKEND)
    binary.chmod(0o700)
    (tmp_path / 'shell.qml').write_text(HARNESS)
    with tempfile.TemporaryDirectory(prefix='den-account-runtime-') as runtime:
        env = dict(os.environ, HOME=str(tmp_path), ACCOUNT_SCENARIO=scenario,
                   XDG_RUNTIME_DIR=runtime, XDG_CONFIG_HOME=str(tmp_path / 'config'),
                   XDG_STATE_HOME=str(tmp_path / 'state'), XDG_CACHE_HOME=str(tmp_path / 'cache'),
                   DBUS_SESSION_BUS_ADDRESS='unix:path=' + runtime + '/no-bus',
                   QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
                   LC_ALL='C.UTF-8', QS_NO_RELOAD_POPUP='1')
        result = subprocess.run([os.environ['SENSEI_QS_BINARY'], '-p', str(tmp_path / 'shell.qml')],
                                env=env, capture_output=True, text=True, timeout=15)
    report = result.stdout + result.stderr
    assert result.returncode == 0, report
    assert 'PROOF_PASS ' + scenario in report, report
