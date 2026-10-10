#!/usr/bin/env python3
"""Native investigation slice: disposable records, real Qt input, retained window renders."""
import base64
import hashlib
import json
import subprocess
import sys
import time
from pathlib import Path
from unittest.mock import patch
from noesis_native_fixture import Fixture, REPO, installer

sys.path.insert(0, str(REPO / 'home/.local/share/sensei-learning'))
from noesis.models import create
from noesis.activities import record_activity

fixture = Fixture(expected_practice_rows=2)
baseline = '--before' in sys.argv
evidence = REPO / 'docs/learning-system/assets/frontier'
evidence.mkdir(parents=True, exist_ok=True)
fontconfig = fixture.home / 'fonts.conf'
fontconfig.write_text('<fontconfig><include ignore_missing="yes">/etc/fonts/fonts.conf</include><dir>' + str(Path.home() / '.local/share/fonts') + '</dir></fontconfig>')
fixture.env['FONTCONFIG_FILE'] = str(fontconfig)
with patch('pathlib.Path.home', return_value=fixture.home):
    concept = create(fixture.vault, 'concept', 'Convolution · understand the mechanism',
        '## What problem does this solve?\nCombine **local measurements** with a shared kernel to describe *filtering*.\n\n'
        '## Reconstruct a minimal case\nLet x = [1, 2, 3], k = [1, 0, −1]. Predict the zero-padded discrete convolution before computing it.\n\n'
        '## Assumptions to inspect\nConvolution and cross-correlation use different kernel conventions. State which one you implement. Border conditions change edge results.\n\n'
        '## What remains unknown?\nHow do padding and stride affect the boundary? Which properties survive subsampling?\n\n'
        'বাংলা: ফলাফল দেখার আগে আপনার পূর্বানুমান লিখুন।')
    reading = create(fixture.vault, 'resource', 'Kernel boundary conditions · reading desk',
        '## What changes at an edge?\n**Keep the kernel convention fixed.** Compare the same signal under different boundary assumptions.\n\n'
        '## Before computing\n- [ ] Predict the edge value\n  - [ ] State the boundary condition\n- [ ] Compare a changed case\n\n'
        '## Conditions to compare\n| Condition | Meaning |\n| --- | --- |\n| Zero padding | Samples outside the signal are zero |\n| Repeated boundary | Extend the nearest edge sample |\n\n'
        '## Minimal implementation\n```python\nedge = signal[0] if boundary == "repeat" else 0\n```\n\n'
        '## Complete derivation\n$$\ny_n = \\sum_i x_i k_{n-i}\n$$\n\n'
        '> A matching output is evidence about this case, not universal understanding.',
        fields={'source_kind':'note'})
    question = create(fixture.vault, 'question', 'Why does the convolution boundary change?',
        '## Motivating question\nCan the same kernel produce different edge values when padding changes?\n\n'
        '## Prediction\nKeep the kernel convention fixed. Compare zero padding with repeated boundary samples.\n\n'
        '## Changed case\nTry an asymmetric kernel and explain any disagreement with a trusted implementation.',
        parent_id=concept['id'], relation='investigates', fields={'investigation': {'depth': 'deep'}})
    capability = create(fixture.vault, 'capability', 'Explain a discrete convolution',
        'A scoped ability, not a claim of detector mastery.', parent_id=concept['id'], relation='pursues',
        fields={'criteria': ['Explain kernel reversal and zero-padding boundaries']})
    paper = create(fixture.vault, 'resource', 'YOLO · from useful detection to missing mechanisms',
        '## Reading objective\nUnderstand the original 2015 detector separately from the version used in code.\n\n'
        '## Missing mechanism\nReconstruct convolution before interpreting learned features.',
        fields={'source_kind': 'paper', 'source': 'https://arxiv.org/abs/1506.02640'})
    implementation = fixture.vault / 'convolution-validation'
    implementation.mkdir()
    (implementation / 'kernel.py').write_text("""# Agent-authored disposable verification, not learner achievement.
import json
import numpy as np

def convolve(signal, kernel):
    return [sum(signal[i] * kernel[n-i] for i in range(len(signal)) if 0 <= n-i < len(kernel))
            for n in range(len(signal)+len(kernel)-1)]

signal = [1, 2, 3]
cases = []
for kernel in ([1, 0, -1], [2, 1, 0]):
    actual = convolve(signal, kernel)
    oracle = np.convolve(signal, kernel, mode='full').tolist()
    assert actual == oracle
    cases.append(dict(kernel=kernel, observed=actual, oracle=oracle, agrees=True))
print(json.dumps(dict(author='agent-authored validation', learner_achievement=False,
                     convention='discrete convolution', signal=signal, cases=cases,
                     numpy_version=np.__version__)))
""")
    (implementation / '.gitignore').write_text('observed.json\n')
    subprocess.run(['git', 'init', '-q', str(implementation)], check=True)
    subprocess.run(['git', '-C', str(implementation), 'add', 'kernel.py', '.gitignore'], check=True)
    subprocess.run(['git', '-C', str(implementation), '-c', 'user.name=Noesis disposable validation',
                    '-c', 'user.email=validation@invalid.example', 'commit', '-qm', 'Authored minimal convolution validation'], check=True)
    output = subprocess.check_output([sys.executable, str(implementation / 'kernel.py')], text=True)
    (implementation / 'observed.json').write_text(output)
    project = create(fixture.vault, 'project', 'Minimal convolution · agent-authored validation',
        'Inspectable implementation and actual oracle comparison. This is validation evidence, not learner achievement.',
        parent_id=concept['id'], fields={'repository': str(implementation)})
    import hashlib
    artifact = create(fixture.vault, 'artifact', 'Executed convolution comparison · two kernel cases',
        'Both cases were executed against NumPy. No detector accuracy or learner understanding is inferred.',
        parent_id=concept['id'], relation='references',
        fields={'location': str(implementation / 'observed.json'), 'sha256': hashlib.sha256(output.encode()).hexdigest(),
                'revision': project['code_snapshot']['commit'], 'evidence_kind': 'software-run'})
    from noesis.models import relationship
    relationship(fixture.vault, paper['id'], concept['id'], 'references', reason='Investigate the mechanism used by convolutional detectors; versions remain separate.')
    from datetime import datetime, timezone, timedelta
    with patch('noesis.activities.datetime') as synthetic_clock:
        synthetic_clock.now.return_value=datetime.now(timezone.utc)-timedelta(days=8)
        start = record_activity(fixture.vault, question['path'], 'attempt-start', 'Synthetic UI fixture prediction; not owner achievement.', assistance=['none'])
        assessment = record_activity(fixture.vault, question['path'], 'attempt', 'Synthetic UI fixture outcome; not owner achievement.',
                                     attempt_id=start['id'], outcome='succeeded', assistance=['none'], scope='Three-element signal, zero padding')
        record_activity(fixture.vault, capability['path'], 'capability-decision', 'Synthetic UI fixture judgment; not owner achievement.',
            actor='learner', criterion=capability['criteria'][0], dimension='explain', decision='accept',
            evidence_id=assessment['id'], scope='Three-element signal, zero padding', evidence_kind='explanation', confidence='low', independent=False)
    delayed = record_activity(fixture.vault, question['path'], 'review', 'Synthetic elapsed-time fixture assessment; not owner retention.', outcome='succeeded', assistance=['unknown'], scope='Three-element signal, zero padding')
    graph_problem=create(fixture.vault,'task','Shortest paths · predict before settling a vertex',
        '## Problem statement\nA directed graph has nonnegative weighted edges. Find the shortest distance from the start to each vertex.\n\n'
        '### Changed case\nA vertex can be discovered with one distance and reached later by a cheaper route. Explain when a distance can become permanent.\n\n'
        '### Constraints\nDisconnected vertices are allowed. State what would fail if negative edges were admitted.',fields={'source_kind':'problem-statement'})
    graph_start=record_activity(fixture.vault,graph_problem['path'],'attempt-start','Synthetic validation first approach; not owner reasoning.',assistance=['none'])
    graph_failed=record_activity(fixture.vault,graph_problem['path'],'attempt','Synthetic failure: confused discovery with finalization.',attempt_id=graph_start['id'],outcome='failed',assistance=['editorial'],scope='Nonnegative shortest paths')
    # Public Mongla source inspected at a fixed commit, never executed here.
    mongla_revision='8083365f88bb629080b987e97124cd070dd95bcd'
    mongla_url='https://github.com/fh1m/mongla_ws/blob/'+mongla_revision+'/'
    mongla=create(fixture.vault,'project','Mongla · PID and control boundaries',
        '## Engineering question\nWhich feedback loop owns depth and heading, and what can its current evidence establish?\n\n'
        '## Boundaries to inspect\nThe host command code, board firmware and offline control bench are distinct. A bench result is not an in-water result.\n\n'
        '## Continuation\nInspect yaw approach behavior and the sign convention before comparing control changes. No controller was run in this Noesis fixture.',
        fields={'source':'https://github.com/fh1m/mongla_ws','source_revision':mongla_revision})
    pid_question=create(fixture.vault,'question','Why does Mongla taper its yaw command near the target?',
        '## Current inquiry\nCompare a hard command floor with a tapered approach. Predict whether dead zone, inertia and sampling can produce a limit cycle.\n\n'
        '## Source boundary\nInspect motion_yaw.py at the pinned source revision. Separate this host-side path from the Hengla board-control bench.\n\n'
        '## Still unknown\nWhich effects have been measured on this hull, which are model assumptions, and which need a water test?',
        parent_id=mongla['id'],relation='investigates')
    sampling=create(fixture.vault,'concept','Sampling, error and PID state',
        '## Mechanism to reconstruct\nExplain how sample interval changes accumulated error and the derivative estimate. State the units.\n\n'
        '## Smallest changed case\nChange the interval while holding the continuous-time gains fixed. Predict what happens if the implementation treats gains per sample instead.',
        parent_id=pid_question['id'],relation='contains')
    relationship(fixture.vault,pid_question['id'],sampling['id'],'prerequisite',role='deep-descent',reason='Explain the sampled control mechanism without blocking source inspection.',context=pid_question['id'])
    yaw_source=create(fixture.vault,'resource','Mongla yaw implementation · inspected source',
        '## Inspect this implementation\nTrace the approach-band floor, integral limits, derivative convention and stale-feedback behavior.\n\n'
        '## Evidence boundary\nReading source does not establish tuning quality or underwater performance.',
        parent_id=pid_question['id'],relation='references',fields={'source_kind':'docs','source':mongla_url+'src/mongla_control/mongla_control/motion_yaw.py','source_revision':mongla_revision})
    # Same record UUID in another authorized disposable owner must remain distinct.
    import uuid
    from noesis.persistence import render
    from noesis.scopes import register
    other_vault = fixture.home / 'other-vault'
    (other_vault / 'System').mkdir(parents=True)
    other_owner = str(uuid.uuid4())
    (other_vault / 'System/System.json').write_text(json.dumps({'directories': ['Notes'], 'noesis_schema': 2, 'vault_id': other_owner}))
    (other_vault / 'same-id.md').write_text(render({'id': concept['id'], 'type': 'concept', 'title': 'Another owner, same identity', 'noesis_schema': 2}, 'Different ownership; never merge this reasoning.'))
    register(fixture.vault)
    register(other_vault)

if baseline:
    prefix = 'home/.local/share/sensei-learning/ui/'
    names = subprocess.check_output(['git', 'ls-tree', '--name-only', '433d2d1:' + prefix.rstrip('/')], cwd=REPO, text=True).splitlines()
    for name in names:
        data = subprocess.check_output(['git', 'show', '433d2d1:' + prefix + name], cwd=REPO)
        (fixture.home / '.local/share/sensei-learning/ui' / name).write_bytes(installer.render(data, fixture.home, 'zenbook'))

window_file = fixture.home / '.local/share/sensei-learning/ui/NoesisWindow.qml'
window_text = window_file.read_text().replace(' readonly property var applicationSurface:applicationContent', ' readonly property var applicationSurface:applicationContent\n readonly property var reviewSurface:reviewCapture')
window_text = window_text.replace(' ColumnLayout {id:applicationContent;', ' Item {id:reviewCapture;anchors.fill:parent\n ColumnLayout {id:applicationContent;').replace(' IpcHandler {target:"noesis-window"', ' }\n IpcHandler {target:"noesis-window"')
window_file.write_text(window_text)
workspace_file = fixture.home / '.local/share/sensei-learning/ui/NoesisWorkspace.qml'
workspace_file.write_text(workspace_file.read_text().replace(' id:root', ' id:root\n readonly property var reviewOverlay:Overlay.overlay', 1))
shell = fixture.config / 'shell.qml'
text = shell.read_text().replace('import QtQuick', 'import QtQuick\nimport QtTest', 1)
text = text.replace('LearningUi.NoesisWindow {}', 'LearningUi.NoesisWindow {id:window}')
text = text.replace('ShellRoot {', '''ShellRoot {
 property var frameSamples:[]
 property bool measuring:false
 FrameAnimation {running:measuring;onTriggered:if(frameTime>0)frameSamples.push(frameTime*1000)}
 TestCase {id:input;parent:window.contentItem;visible:false;name:"FrontierInput";when:false}
 function find(item,predicate){if(predicate(item))return item;for(let child of item.children||[]){let found=find(child,predicate);if(found)return found;}return null;}
 function scrollTo(item){let parent=item.parent;while(parent){if(typeof parent.contentY==="number"&&typeof parent.contentHeight==="number"){for(let n=0;n<40;n++){let point=item.mapToItem(parent,0,0);if(point.y>=0&&point.y+item.height<=parent.height)return true;input.mouseWheel(parent,Math.max(1,parent.width/2),Math.max(1,parent.height/2),0,point.y<0?240:-240);input.wait(30);}return false;}parent=parent.parent;}return true;}
 IpcHandler {target:"frontier-fixture";
  function framesStart():void{frameSamples=[];measuring=true;}
  function framesStop():string{measuring=false;return JSON.stringify(frameSamples);}
  function init():void{let workspace=find(window.contentItem,item=>typeof item.openWork==="function");workspace.reviewOverlay.parent=window.reviewSurface;}
  function open(payload:string):void{let row=JSON.parse(Qt.atob(payload));window.applicationSurface.children[0];let workspace=find(window.contentItem,item=>typeof item.openWork==="function");workspace.openWork(row);}
  function capture(path:string):void{window.reviewSurface.grabToImage(result=>result.saveToFile(path));}
  function click(label:string):string{let item=find(window.contentItem,item=>item.visible&&item.enabled&&(item.text===label||item.title===label)&&typeof item.clicked==="function");if(!item)return "missing:"+label;if(!scrollTo(item))return "unreachable:"+label;input.wait(250);if(!input.waitForPolish(item.parent,1500))return "layout pending:"+label;if(item.title===label){input.mouseClick(item,item.width/2,item.height/2);return "clicked";}let activated=false;let mark=()=>{activated=true;};item.clicked.connect(mark);input.mouseClick(item,item.width/2,item.height/2);input.wait(50);item.clicked.disconnect(mark);return activated?"clicked":"not activated:"+label;}
  function choose(name:string,index:int):string{let item=find(window.contentItem,item=>item.objectName===name);if(!item)return "missing";item.forceActiveFocus();input.keyClick(Qt.Key_Home);for(let n=0;n<index;n++)input.keyClick(Qt.Key_Down);input.wait(80);return item.currentText;}
  function debug():string{let result=[];function scan(item){if(item.objectName)result.push({name:item.objectName,visible:item.visible,width:item.width,height:item.height});for(let child of item.children||[])scan(child);}scan(window.contentItem);return JSON.stringify(result);}
  function clickName(name:string):string{let item=find(window.contentItem,item=>item.objectName===name);if(!item)return "missing";input.mouseClick(item,item.width/2,item.height/2);return "clicked";}
  function typeField(name:string,value:string):string{let item=find(window.contentItem,item=>item.objectName===name);if(!item)return "missing";item.forceActiveFocus();input.keyClick(Qt.Key_A,Qt.ControlModifier);for(let character of value){if(character===" ")input.keyClick(Qt.Key_Space);else input.keyClick(Qt.Key_A+character.toUpperCase().charCodeAt(0)-65);}return item.text;}
  function typeNotes():string{let item=find(window.contentItem,item=>item.objectName==="investigation-reasoning");if(!item)return "missing";input.mouseClick(item,30,30);input.keyClick(Qt.Key_P);input.keyClick(Qt.Key_A);input.keyClick(Qt.Key_D);return item.text;}
  function mode(value:string):void{LearningUi.NoesisController.presentationMode=value;window.applyPresentation();}
  function scale(value:real):void{LearningUi.NoesisStyle.interfaceScale=value;LearningUi.NoesisStyle.readingScale=value;}
  function state():string{let workspace=find(window.contentItem,item=>typeof item.openWork==="function");return JSON.stringify({investigation:workspace.investigationWorking||false,frontier:workspace.frontier||{},history:workspace.history.map(row=>row.event),modalOpen:workspace.modalOpen,reading:workspace.readingWorking||false,locator:workspace.selectedState.locator||null,navigation:workspace.navigation.length,index:workspace.navigationIndex});}
  function collection():void{let workspace=find(window.contentItem,item=>typeof item.openWork==="function");workspace.returnCollection();}
  function back():void{let workspace=find(window.contentItem,item=>typeof item.openWork==="function");workspace.back();}
  function readingState():string{let result={tables:0,rawFormatting:0,tableContent:false};function scan(item){if(item.visible&&item.value?.kind==="table")result.tables++;if(item.visible&&item.readOnly&&typeof item.getText==="function"){let text=item.getText(0,item.length);if(text.indexOf("Samples outside the signal are zero")>=0)result.tableContent=true;if(text.indexOf("**Keep the kernel")>=0||text.indexOf("| Condition |")>=0||text.indexOf("\\sum_i")>=0)result.rawFormatting++;}for(let child of item.children||[])scan(child);}scan(window.contentItem);return JSON.stringify(result);}
 }
''')
shell.write_text(text)
reports = []
performance = {}


def open_record(record):
    fixture.ipc("noesis-window", "section", "Learn")
    row = dict(record, vault=str(fixture.vault), vault_id=fixture.vault_id)
    fixture.ipc('frontier-fixture', 'open', base64.b64encode(json.dumps(row).encode()).decode())
    fixture.wait(lambda state: state['selected'] == record['path'] and state['preview_length'] > 0)
    time.sleep(.3)


def capture(name):
    target = evidence / (name + '.png')
    target.unlink(missing_ok=True)
    fixture.ipc('frontier-fixture', 'capture', str(target))
    deadline = time.monotonic() + 5
    while not target.exists() and time.monotonic() < deadline:
        time.sleep(.05)
    assert target.exists(), target
    reports.append({'image': target.name, 'state': fixture.state()})


try:
    fixture.start()
    fixture.ipc('frontier-fixture', 'init')
    open_record(concept)
    capture('concept-before' if baseline else 'concept-after')
    fixture.ipc('frontier-fixture', 'mode', 'fullscreen')
    fixture.wait(lambda state: state['presentation'] == 'fullscreen' and state['width'] == 1920 and not state['mode_pending'])
    capture('concept-fullscreen-before' if baseline else 'concept-fullscreen-after')
    if baseline:
        open_record(reading)
        capture('formatted-reading-before')
    if not baseline:
        state = json.loads(fixture.ipc('frontier-fixture', 'state'))
        assert state['investigation'] and len(state['frontier']['items']) >= 4, state
        open_record(reading)
        rendered=json.loads(fixture.ipc('frontier-fixture','readingState'))
        assert rendered['tables']>=1 and rendered['tableContent'] and rendered['rawFormatting']==0, rendered
        capture('formatted-reading')
        assert fixture.ipc('frontier-fixture','typeField','reading-reasoning','my edge prediction needs checking') == 'my edge prediction needs checking'
        capture('reading-with-notes')
        assert fixture.ipc('frontier-fixture','click','Set a reading place') == 'clicked'
        assert fixture.ipc('frontier-fixture','choose','reading-place-kind','2') == 'Section'
        assert fixture.ipc('frontier-fixture','typeField','reading-place','boundary') == 'boundary'
        assert fixture.ipc('frontier-fixture','click','Save reading place') == 'clicked'
        fixture.wait(lambda state: not state['working'] and json.loads(fixture.ipc('frontier-fixture','state'))['locator'] == {'kind':'section','value':'boundary'})
        assert fixture.ipc('frontier-fixture','click','Ask a source-linked question') == 'clicked'
        assert fixture.ipc('frontier-fixture','typeField','record-title','boundary assumption') == 'boundary assumption'
        assert fixture.ipc('frontier-fixture','typeField','record-purpose','does repeated padding change prediction') == 'does repeated padding change prediction'
        assert fixture.ipc('frontier-fixture','click','Save') == 'clicked'
        fixture.wait(lambda state: 'boundary assumption' in state['selected'] and not state['working'] and not json.loads(fixture.ipc('frontier-fixture','state'))['modalOpen'] and json.loads(fixture.ipc('frontier-fixture','state'))['frontier'].get('parent_ref',{}).get('record_id')==reading['id'])
        assert fixture.ipc('frontier-fixture','click','← Return to Kernel boundary conditions · reading desk') == 'clicked'
        try:
            fixture.wait(lambda state: state['selected']==reading['path'] and json.loads(fixture.ipc('frontier-fixture','state'))['locator'] == {'kind':'section','value':'boundary'})
        except AssertionError:
            print('Source return diagnostics:', fixture.state()['selected'], fixture.ipc('frontier-fixture','state'), flush=True)
            raise
        open_record(concept)
        assert fixture.ipc('frontier-fixture', 'typeNotes').lower().startswith('pad')
        assert fixture.ipc('frontier-fixture', 'click', 'Try explaining without notes') == 'clicked'
        fixture.wait(lambda state: bool(state['attempt']) and state['reference_hidden'])
        capture('reconstruction-protected')
        fixture.ipc('noesis','hide')
        fixture.wait(lambda state: not state['visible'] and not state['worker'] and not state['watch'])
        fixture.ipc('noesis','open')
        fixture.wait(lambda state: state['visible'] and state['worker'] and state['selected']==concept['path'] and bool(state['attempt']))
        open_record(question)
        capture('question-after')
        fixture.exit()
        fixture.start()
        fixture.ipc('frontier-fixture', 'init')
        # Fixture.start selects its seed problem; the saved navigation stack must still exist.
        state = json.loads(fixture.ipc('frontier-fixture', 'state'))
        assert state['navigation'] >= 3, state
        fixture.ipc('frontier-fixture', 'back')
        fixture.wait(lambda state: state['selected'] == question['path'])
        fixture.ipc('frontier-fixture', 'back')
        fixture.wait(lambda state: state['selected'] == concept['path'] and bool(state['attempt']))
        assert fixture.state()['draft_length'] > 0
        fixture.ipc('frontier-fixture', 'scale', '2')
        time.sleep(.4)
        capture('concept-200-question')
        assert fixture.ipc('frontier-fixture', 'click', 'Show reasoning') == 'clicked'
        capture('concept-200-reasoning')
        fixture.ipc('frontier-fixture', 'scale', '1')
        time.sleep(.3)
        assert fixture.ipc('frontier-fixture', 'click', 'Record how the attempt went') == 'clicked'
        time.sleep(.25)
        result=fixture.ipc('frontier-fixture', 'choose', 'attempt-outcome', '3');assert result == 'partial', result
        assert fixture.ipc('frontier-fixture', 'choose', 'attempt-assistance', '1') == 'none'
        assert fixture.ipc('frontier-fixture', 'click', 'Save reconstruction result') == 'clicked'
        fixture.wait(lambda state: not state['attempt'] and not state['working'] and 'attempt' in json.loads(fixture.ipc('frontier-fixture','state'))['history'])
        assert fixture.ipc('frontier-fixture','click','Investigate what blocked this attempt') == 'clicked'
        assert fixture.ipc('frontier-fixture','typeField','record-title','What makes the changed boundary fail?')
        assert fixture.ipc('frontier-fixture','typeField','record-purpose','Preserve the missing mechanism without declaring success')
        capture('failure-to-question')
        assert fixture.ipc('frontier-fixture','click','Save') == 'clicked'
        fixture.wait(lambda state: 'what makes the changed boundary fail?' in state['selected'].lower() and not state['working'])
        from noesis.index import Index
        index=Index(fixture.vault)
        try:
            index.reconcile()
            created=index.record(index.db.execute('SELECT id FROM records WHERE path=?',(fixture.state()['selected'],)).fetchone()[0])['props']
            assert created['parent_ref']['record_id']==concept['id'] and created['evidence_refs'][0]['vault_id']==fixture.vault_id
            basis=index.record(created['evidence_refs'][0]['record_id'])['props']
            assert basis['outcome']=='partial' and basis['target']['record_id']==concept['id']
        finally:index.close()
        assert fixture.ipc('frontier-fixture','click','← Return to Convolution · understand the mechanism') == 'clicked'
        fixture.wait(lambda state: state['selected']==concept['path'] and 'attempt' in json.loads(fixture.ipc('frontier-fixture','state'))['history'])
        time.sleep(.3)
        result=fixture.ipc('frontier-fixture', 'click', 'Assess what this attempt demonstrates');assert result=='clicked',result
        time.sleep(.5)
        capture('claim-picker')
        result=fixture.ipc('frontier-fixture', 'clickName', 'claim-capability-row');assert result == 'clicked', (result, fixture.state(), fixture.ipc('frontier-fixture','debug'))
        time.sleep(.3)
        assert fixture.ipc('frontier-fixture', 'typeField', 'claim-scope', 'minimal boundary case') == 'minimal boundary case'
        assert fixture.ipc('frontier-fixture', 'typeField', 'claim-reason', 'partial reconstruction remains uncertain') == 'partial reconstruction remains uncertain'
        assert fixture.ipc('frontier-fixture', 'choose', 'claim-decision', '1') == 'Does not establish it'
        capture('understanding-claim-dialog')
        assert fixture.ipc('frontier-fixture', 'click', 'Save decision') == 'clicked'
        fixture.wait(lambda state: not state['working'] and not state['error'])
        time.sleep(.3)
        open_record(capability)
        capture('capability-claim-after')
        fixture.ipc('frontier-fixture', 'framesStart')
        time.sleep(3)
        frames=json.loads(fixture.ipc('frontier-fixture','framesStop'))
        assert len(frames)>30
        performance.update({'instrumented_frame_samples':len(frames),'frame_p95_ms':round(sorted(frames)[int(len(frames)*.95)],3)})
        fixture.ipc('frontier-fixture','collection')
        assert fixture.ipc('frontier-fixture','click','Concepts') == 'clicked'
        time.sleep(.3)
        assert fixture.ipc('frontier-fixture','click','Start a concept') == 'clicked'
        assert fixture.ipc('frontier-fixture','typeField','record-title','filter mechanism') == 'filter mechanism'
        assert fixture.ipc('frontier-fixture','typeField','record-purpose','explain local mixing') == 'explain local mixing'
        assert fixture.ipc('frontier-fixture','click','Save') == 'clicked'
        fixture.wait(lambda state: 'filter mechanism' in state['selected'] and not state['working'])
        capture('new-investigation')
        open_record(graph_problem)
        capture('dsa-failed-attempt')
        assert fixture.ipc('frontier-fixture','click','Investigate the missing mechanism') == 'clicked'
        assert fixture.ipc('frontier-fixture','typeField','record-title','When can a shortest distance become permanent?')
        assert fixture.ipc('frontier-fixture','typeField','record-purpose','Explain the invariant before attempting a changed graph')
        assert fixture.ipc('frontier-fixture','click','Save') == 'clicked'
        fixture.wait(lambda state: 'when can a shortest distance become permanent?' in state['selected'].lower() and not state['working'])
        index=Index(fixture.vault)
        try:
            index.reconcile()
            inquiry=index.record(index.db.execute('SELECT id FROM records WHERE path=?',(fixture.state()['selected'],)).fetchone()[0])['props']
            assert inquiry['parent_ref']['record_id']==graph_problem['id'] and inquiry['evidence_refs'][0]['record_id']==graph_failed['id']
            assert index.record(graph_failed['id'])['props']['assistance']==['editorial']
        finally:index.close()
        capture('dsa-missing-invariant')
        fixture.ipc('frontier-fixture','mode','fullscreen')
        fixture.wait(lambda state: state['presentation']=='fullscreen' and not state['mode_pending'])
        open_record(pid_question)
        capture('mongla-pid-inquiry')
        result=fixture.ipc('frontier-fixture','click','Sampling, error and PID state');assert result=='clicked',result
        fixture.wait(lambda state: state['selected']==sampling['path'])
        capture('mongla-pid-descent')
        assert fixture.ipc('frontier-fixture','click','← Return to Why does Mongla taper its yaw command near the target?') == 'clicked'
        fixture.wait(lambda state: state['selected']==pid_question['path'])
        assert fixture.ipc('frontier-fixture','click','Mongla yaw implementation · inspected source') == 'clicked'
        fixture.wait(lambda state: state['selected']==yaw_source['path'])
        fixture.ipc('frontier-fixture','back')
        fixture.wait(lambda state: state['selected']==pid_question['path'])
        capture('mongla-pid-return')
        fixture.exit()
        fixture.start()
        fixture.ipc('frontier-fixture','init')
        fixture.ipc('frontier-fixture','back')
        fixture.wait(lambda state: state['selected']==pid_question['path'])
        open_record(question)
        assert fixture.ipc('frontier-fixture','click','Assess what this attempt demonstrates') == 'clicked'
        time.sleep(.4)
        assert fixture.ipc('frontier-fixture','clickName','claim-capability-row') == 'clicked'
        time.sleep(.3)
        assert fixture.ipc('frontier-fixture','choose','claim-dimension','7') == 'Demonstrate retention after a delay'
        assert fixture.ipc('frontier-fixture','choose','retention-basis','1').startswith('Can explain')
        assert fixture.ipc('frontier-fixture','typeField','retention-days','3650') == '3650'
        assert fixture.ipc('frontier-fixture','typeField','claim-reason','Synthetic later assessment; not owner retention')
        assert fixture.ipc('frontier-fixture','click','Save decision') != 'clicked', 'Future interval must not certify retention'
        capture('retention-not-yet')
        assert fixture.ipc('frontier-fixture','typeField','retention-days','7') == '7'
        time.sleep(.3)
        capture('retention-assessment')
        assert fixture.ipc('frontier-fixture','click','Save decision') == 'clicked'
        fixture.wait(lambda state: not state['working'] and not state['error'])
        from noesis.index import Index
        from noesis.frontier import claims
        index=Index(fixture.vault)
        try:
            index.reconcile()
            retained=next(row for row in claims(index,capability['id']) if row['dimension']=='retained')
            assert retained['interval_days']==7 and retained['decision']=='accept' and not retained['independent']
        finally:index.close()
        open_record(concept)
        owned_row = dict(id=concept['id'], path='same-id.md', title='Another owner, same identity', type='concept', vault=str(other_vault), vault_id=other_owner)
        fixture.ipc('frontier-fixture', 'open', base64.b64encode(json.dumps(owned_row).encode()).decode())
        fixture.wait(lambda state: state['vault'] == str(other_vault) and state['selected'] == 'same-id.md' and state['preview_length'] > 0)
        assert fixture.state()['draft_length'] == 0
        assert fixture.ipc('frontier-fixture', 'typeNotes').lower() == 'pad'
        fixture.ipc('frontier-fixture', 'back')
        fixture.wait(lambda state: state['vault'] == str(fixture.vault) and state['selected'] == concept['path'])
        assert fixture.state()['draft_length'] == 0, 'Foreign draft leaked into the original owner'
    (evidence / ('before.json' if baseline else 'after.json')).write_text(json.dumps({
        'fixture_only': True, 'baseline': '433d2d1', 'captures': reports, 'performance':performance,
        'capture_method':'Native Qt Quick viewport with an equivalent Item wrapper retaining the native popup overlay; no compositing or private desktop capture',
        'source_hashes':{str(path.relative_to(REPO)):hashlib.sha256(path.read_bytes()).hexdigest() for path in (REPO/'home/.local/share/sensei-learning/ui').glob('*.qml')} if not baseline else {},
        'assertions': ['working page', 'native typing', 'protected reconstruction', 'durable navigation and draft', '200% reflow', 'native result and explicit claim', 'executed agent-authored convolution oracle comparison', 'failed DSA attempt to owned question with editorial preserved', 'Mongla optional mechanism descent and exact source return', 'retention interval rejects future evidence and records explicit assessment'] if not baseline else []}, indent=2))
    print('PASS: native investigation evidence retained at', evidence)
finally:
    fixture.stop()
