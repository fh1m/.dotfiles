"""Intentional-break game behavior, including independent reaction rounds."""
import shutil
import subprocess
from pathlib import Path

import pytest

from test_quickshell_ui_freshness import HAS_QS, put, run_native

ROOT = Path(__file__).resolve().parents[1]
DROPDOWNS = ROOT / 'home/.config/quickshell/sensei/modules/dropdowns'


def test_board_game_wins_blocks_and_terminal_positions():
    bun = shutil.which('bun')
    if not bun:
        pytest.skip('Bun is required to execute the actual game rules')
    script = r'''
const vm = require('node:vm');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const game = {};
vm.createContext(game);
vm.runInContext(fs.readFileSync(process.argv[1], 'utf8'), game);
for (const [player, other, expected] of [
  ['rock','rock','draw'], ['rock','paper','loss'], ['rock','scissors','win'],
  ['paper','rock','win'], ['paper','paper','draw'], ['paper','scissors','loss'],
  ['scissors','rock','loss'], ['scissors','paper','win'], ['scissors','scissors','draw']
]) assert.equal(game.rps(player, other), expected);
let board = ['O','O','','X','X','','','',''];
let answer = game.reply(board);
assert.equal(answer[2], 'O'); // Win rather than merely blocking the other row.
assert.equal(game.winner(answer), 'O');
assert.equal(board[2], ''); // Preserve the learner's previous board.
board = ['X','X','','','O','','','',''];
answer = game.reply(board);
assert.equal(answer[2], 'O'); // Block the immediate threat.
for (const terminal of [
  ['X','X','X','O','O','','','',''],
  ['X','O','X','X','O','O','O','X','X']
]) assert.equal(JSON.stringify(game.reply(terminal)), JSON.stringify(terminal));
'''
    result = subprocess.run([bun, '-e', script, str(DROPDOWNS / 'ZondoGames.js')],
                            text=True, capture_output=True, timeout=10)
    assert result.returncode == 0, result.stdout + result.stderr


@pytest.mark.skipif(not HAS_QS, reason='Explicit native Quickshell runtime required')
def test_reaction_rounds(tmp_path):
    for name in ('ZondoPlayground.qml', 'ControlTile.qml', 'ZondoGames.js'):
        put(tmp_path, name, (DROPDOWNS / name).read_text())
    put(tmp_path, 'components/NrLabel.qml',
        (ROOT / 'home/.config/quickshell/sensei/components/NrLabel.qml').read_text())
    put(tmp_path, 'config/Appearance.qml', '''pragma Singleton
import QtQuick
QtObject {
 property var font: ({ui:'Zed Mono',reading:'Iosevka',data:'Iosevka',icons:'monospace',weightSemi:600})
 property var textSize: ({control:14,section:18,body:14,caption:12})
 property var size: ({label:12})
 function tracking(size) { return 0 }
 function iconFor(label) { return '' }
}
''')
    colors = ['signalRed', 'paper', 'paperMuted', 'dim', 'alert', 'widgetAccent',
              'surfaceOne', 'surfaceTwo', 'ink', 'rule', 'widgetMuted', 'widgetText']
    put(tmp_path, 'config/Theme.qml', 'pragma Singleton\nimport QtQuick\nQtObject {\n' +
        '\n'.join(' property color ' + name + ': "#eeeeee"' for name in colors) +
        '\n property int radiusSmall:3\n property int motionAck:0\n}\n')
    # Unrelated guest/desktop services do not execute in an isolated game test.
    put(tmp_path, 'GuestLibrary.qml', 'import QtQuick\nItem {property bool showFeedback:false;property string feedback:""}\n')
    put(tmp_path, 'services/Den.qml', 'pragma Singleton\nimport QtQuick\nQtObject {function companion(action,arg) {}}\n')
    harness = '''import QtQuick
import Quickshell
ShellRoot {
 id: test
 property int phase:0
 property int ticks:0
 property var tap:null
 function button(item, label) {
  if (item.label===label) return item
  for (const child of item.children||[]) {
   const found=button(child,label); if(found)return found
  }
  return null
 }
 Item {width:800;height:1200;ZondoPlayground {id:playground}}
 Timer {interval:20;repeat:true;running:true;onTriggered:{
  test.ticks++
  if(test.ticks>100) {console.error('Reaction round did not finish');Qt.exit(2);return}
  if(test.phase===0) {
   test.tap=test.button(playground,'Start another 30-second round')
   const selector=test.button(playground,'Reaction · 30s')
   if(!test.tap||!selector)throw new Error('Reaction controls unavailable')
   selector.activated()
   playground.reactionReady=Date.now()-250
   test.tap.activated()
   if(playground.reactionTaps!==1||playground.reactionMs<250)
    throw new Error('First successful reaction was not measured')
   playground.reactionStart=Date.now()-31000
   test.phase=1
  } else if(playground.reactionStart===0) {
   if(playground.reactionTaps!==1)throw new Error('Round result disappeared before restart')
   test.tap.activated()
   if(playground.reactionTaps!==0||playground.reactionMs!==0)
    throw new Error('New reaction round retained the previous measurements')
   if(playground.reactionStart<=0||playground.reactionReady<=playground.reactionStart)
    throw new Error('New round has no future cue')
   console.log('PROOF_PASS independent reaction rounds');Qt.quit()
  }
 }}
}
'''
    assert 'PROOF_PASS independent reaction rounds' in run_native(tmp_path, harness)
