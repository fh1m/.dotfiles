"""Bounded convolution lesson. Explicit local build/check, existing records and receipts."""
import hashlib
import json
import math
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path
from .activities import record_activity, unfinished_attempts
from .index import Index
from .models import create
from .persistence import contained, lock, publish, checksum
from .development import snapshot


def configuration(value):
    if not isinstance(value, dict) or set(value) != {'signal', 'kernel', 'boundary', 'stride', 'convention'}:
        raise ValueError('Specify signal, odd kernel, boundary, stride and convention')
    for key, lower, upper in [('signal', 3, 8), ('kernel', 1, 5)]:
        values = value[key]
        if (not isinstance(values, list) or not lower <= len(values) <= upper
                or any(type(n) not in (int, float) or not math.isfinite(n) or abs(n) > 100 for n in values)):
            raise ValueError('Use 3–8 finite signal samples and 1, 3 or 5 kernel weights, each within ±100')
    if len(value['kernel']) % 2 != 1 or value['boundary'] not in ('zero', 'edge') or value['convention'] not in ('convolution', 'correlation') or type(value['stride']) is not int or value['stride'] not in (1, 2, 3):
        raise ValueError('Choose an odd kernel, zero/repeated edge boundary, convention and stride 1–3')
    return value


def calculate(value):
    c = configuration(value)
    x, k = c['signal'], c['kernel']
    weights = list(reversed(k)) if c['convention'] == 'convolution' else k
    radius = len(k) // 2
    steps = []
    for center in range(0, len(x), c['stride']):
        terms = []
        for j, weight in enumerate(weights):
            i = center + j - radius
            sample = x[i] if 0 <= i < len(x) else 0 if c['boundary'] == 'zero' else x[max(0, min(len(x)-1, i))]
            terms.append(dict(index=i, sample=sample, weight=weight, product=sample*weight, outside=not 0 <= i < len(x)))
        steps.append(dict(center=center, terms=terms, output=sum(t['product'] for t in terms)))
    return dict(configuration=c, outputs=[s['output'] for s in steps], steps=steps,
                alignment='Centered odd kernel; output centers 0, stride, … < signal length. Explicit radius padding, then valid, then subsample.')


def target(root, identity, kinds):
    from .scopes import assert_unique
    assert_unique(root)
    index = Index(root)
    try:
        health = index.reconcile()
        if health['errors']:raise ValueError('Resolve index errors before running this lesson')
        result = index.record(identity)
        if result['props'].get('type') not in kinds:raise ValueError('Open the owning concept or its convolution experiment')
        if unfinished_attempts(index.timeline(identity)):
            raise ValueError('Save the protected attempt before revealing computed material')
        return result
    finally:index.close()


def observe(root, identity, value, prediction, operation_id):
    c = configuration(value)
    if not isinstance(prediction, str) or not 1 <= len(prediction.strip()) <= 4000:raise ValueError('Write a prediction before revealing the output')
    record = target(root, identity, ('concept',))
    result = calculate(c)
    return record_activity(root, record['path'], 'comparison',
        'Prediction preserved before revealing the native computed output. No understanding claim.\n\n'+prediction,
        operation_id=operation_id, expected_id=identity, demo='convolution-1d',
        prediction=prediction, observed=result, evidence_kind='software-run', engine='Noesis bounded scalar calculation',
        learner_achievement=False)


TEMPLATE = '''"""Starter supplied by Noesis. Reconstruct/replace it; its authorship is not yours.
Centered odd kernel; same-length centers, explicit padding and optional subsampling.
"""
def convolve(signal, kernel, boundary="zero", stride=1, convention="convolution"):
    weights = kernel[::-1] if convention == "convolution" else kernel
    radius = len(kernel) // 2
    output = []
    for center in range(0, len(signal), stride):
        total = 0
        for j, weight in enumerate(weights):
            i = center + j - radius
            sample = signal[i] if 0 <= i < len(signal) else (
                0 if boundary == "zero" else signal[max(0, min(len(signal)-1, i))])
            total += sample * weight
        output.append(total)
    return output
'''

# This runner owns the oracle. The editable implementation cannot submit a self-reported verdict.
RUNNER = '''import importlib.util, json, sys
import numpy as np
c = json.loads(sys.argv[2])
spec = importlib.util.spec_from_file_location("learner_convolution", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
actual = m.convolve(c["signal"], c["kernel"], c["boundary"], c["stride"], c["convention"])
x = np.asarray(c["signal"], dtype=float)
k = np.asarray(c["kernel"], dtype=float)
r = len(k)//2
padded = np.pad(x, (r, r), mode="constant" if c["boundary"]=="zero" else "edge")
function = np.convolve if c["convention"]=="convolution" else np.correlate
oracle = function(padded, k, mode="valid")[::c["stride"]]
actual = np.asarray(actual, dtype=float)
if actual.shape != oracle.shape or not np.isfinite(actual).all():
    raise ValueError("Implementation returned the wrong shape or nonfinite values")
print(json.dumps(dict(actual=actual.tolist(), oracle=oracle.tolist(), agrees=bool(np.allclose(actual, oracle, rtol=1e-10, atol=1e-10)), numpy_version=np.__version__, python_version=sys.version.split()[0])))
'''


def prepare(root, identity, value, prediction, operation_id):
    c = configuration(value)
    if not prediction.strip() or len(prediction)>4000:raise ValueError('Preserve the build prediction first')
    uuid.UUID(operation_id)
    from .activities import operation_status
    status=operation_status(root,operation_id)
    if status['status']=='committed':
        old=status['records'][0] if status['records'] else {}
        if old.get('type')!='experiment' or old.get('parent_ref',{}).get('record_id')!=identity or old.get('configuration')!=c or old.get('hypothesis')!=prediction:
            raise ValueError('Build operation already belongs to a different request')
        return old
    target(root, identity, ('concept',))
    directory = contained(root, 'Implementations/Convolution/'+operation_id)
    with lock(root):
        if not directory.exists():
            directory.mkdir(parents=True)
            publish(directory/'convolution.py', TEMPLATE)
            publish(directory/'.gitignore', 'observations/\n__pycache__/\n')
            publish(directory/'README.md', '# Convolution reconstruction\n\nStarter authored by Noesis; execution is not understanding.\n\nEdit convolution.py, commit your revision, then use Run local comparison in Noesis.\nOracle: explicit radius padding → NumPy valid convolution/correlation → stride subsampling.\n')
            subprocess.run(['git','init','-q',str(directory)],check=True)
            subprocess.run(['git','-C',str(directory),'add','.'],check=True)
            subprocess.run(['git','-C',str(directory),'-c','user.name=Noesis starter','-c','user.email=starter@invalid.example','commit','-qm','Noesis supplied convolution starter'],check=True)
    return create(root, 'experiment', 'Convolution · reconstruct and compare',
        '## Original prediction\n'+prediction+'\n\n## Reconstruction\nOpen the implementation, replace the supplied starter, and commit your changes. Then run a matched comparison.\n',
        fields={'demo':'convolution-1d','repository':str(directory),'code_snapshot':snapshot(directory),
                'configuration':c,'hypothesis':prediction,'code_entrypoint':'convolution.py','starter_authorship':'Noesis supplied; not learner-authored'},
        parent_id=identity, relation='references', operation_id=operation_id)


def check(root, identity, value, prediction, operation_id):
    c = configuration(value)
    if not prediction.strip() or len(prediction)>4000:raise ValueError('Predict this code comparison first')
    uuid.UUID(operation_id)
    from .activities import operation_status
    if operation_status(root,operation_id)['status']=='committed':raise ValueError('This execution request already committed. Inspect its evidence rather than replaying it')
    record = target(root, identity, ('experiment',))
    props = record['props']
    if props.get('demo') != 'convolution-1d':raise ValueError('Choose the explicitly created convolution experiment')
    parent=props.get('parent_ref',{})
    if parent.get('record_id'):target(root,parent['record_id'],('concept',))
    directory = Path(props['repository']).resolve()
    if not directory.is_relative_to(root.resolve()/'Implementations/Convolution'):raise ValueError('Implementation moved outside its explicit pilot folder; reconnect it rather than silently executing another repository')
    script = directory/'convolution.py'
    if not script.is_file() or script.is_symlink() or script.stat().st_size>64000:raise ValueError('Choose a local convolution.py below 64 KiB')
    state = snapshot(directory)
    digest = hashlib.sha256(script.read_bytes()).hexdigest()
    reservation = contained(root, '.Noesis/Executions/'+operation_id+'.json')
    # Reserve before execution. A killed process cannot silently run the same request again.
    with lock(root):
        if reservation.exists():raise ValueError('This execution was already started. Inspect its receipt/output; do not replay it')
        publish(reservation,json.dumps({'status':'started','record_id':identity,'configuration':c,'prediction':prediction,'code_sha256':digest,'code_snapshot':state}))
    try:
        with tempfile.TemporaryFile() as stdout, tempfile.TemporaryFile() as stderr:
            executed = subprocess.run([sys.executable,'-I','-c',RUNNER,str(script),json.dumps(c)],stdout=stdout,stderr=stderr,timeout=15,cwd=directory)
            stdout.seek(0);output_text=stdout.read(16001).decode('utf-8',errors='replace')
            stderr.seek(0);error_text=stderr.read(2000).decode('utf-8',errors='replace')
        if executed.returncode or len(output_text)>16000:
            witness=json.loads(reservation.read_text());witness.update(status='failed',diagnostic=error_text);publish(reservation,json.dumps(witness),checksum(reservation.read_text()))
            raise ValueError('Implementation failed: '+(error_text or 'invalid or excessive output'))
        result = json.loads(output_text)
        result.update(configuration=c, prediction=prediction, code_snapshot=state, code_sha256=digest,
                      execution='explicit local Python invocation', learner_achievement=False,
                      starter_authorship=props['starter_authorship'], tolerance={'rtol':1e-10,'atol':1e-10})
        if hashlib.sha256(script.read_bytes()).hexdigest()!=digest or snapshot(directory)['commit']!=state['commit']:
            raise ValueError('Implementation changed during execution; output cannot be attributed to this revision')
        output = directory/'observations'/ (operation_id+'.json')
        publish(output,json.dumps(result,indent=2)+'\n')
        # A small native-viewable figure from actual outputs; never fabricated measurements.
        try:
            import matplotlib
            matplotlib.use('Agg')
            from matplotlib import pyplot as plt
            figure=output.with_suffix('.png')
            fig,axes=plt.subplots(2,1,figsize=(8,4.2),layout='constrained')
            axes[0].stem(range(len(c['signal'])),c['signal']);axes[0].set_title('Example signal · not sensor measurements');axes[0].set_ylabel('Sample')
            centers=list(range(0,len(c['signal']),c['stride']))
            axes[1].plot(centers,result['actual'],'o-',label='Executed implementation')
            axes[1].plot(centers,result['oracle'],'x--',label='Matched NumPy oracle');axes[1].legend();axes[1].set_xlabel('Output center');axes[1].set_ylabel('Output')
            fig.savefig(figure,dpi=130);plt.close(fig)
            create(root,'artifact','Convolution · executed comparison figure '+operation_id[:8],
                'Figure generated from explicitly executed example outputs, not measured sensor data or learner achievement.',
                fields={'location':str(figure),'sha256':hashlib.sha256(figure.read_bytes()).hexdigest(),'revision':state['commit'],'evidence_kind':'software-run'},
                parent_id=identity,relation='references',operation_id=str(uuid.uuid5(uuid.UUID(operation_id),'figure-artifact')))
        except ImportError:pass  # Output evidence remains usable without an optional plotting package.
        artifact = create(root,'artifact','Convolution · executed output '+operation_id[:8],
            'Actual explicitly executed comparison, not a learner understanding award.',
            fields={'location':str(output),'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'revision':state['commit'],'evidence_kind':'software-run'},
            parent_id=identity,relation='references',operation_id=str(uuid.uuid5(uuid.UUID(operation_id),'output-artifact')))
        return record_activity(root,record['path'],'comparison','Executed local convolution.py against an explicitly matched NumPy oracle.\n\n'+prediction,
            operation_id=operation_id,expected_id=identity,demo='convolution-1d',prediction=prediction,
            observed=result,artifact_id=artifact['id'],execution={'engine':'Python + NumPy','code_sha256':digest,'commit':state['commit'],'dirty':state['dirty']},evidence_kind='software-run',learner_achievement=False)
    except (subprocess.TimeoutExpired,json.JSONDecodeError,KeyError,TypeError) as error:
        raise ValueError('Comparison did not complete: '+str(error)+'. Inspect this execution before starting a new one') from error
