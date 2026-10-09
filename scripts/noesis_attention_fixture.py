"""Trusted, authored Eq. 1 acceptance; not a trained Transformer reproduction."""
import hashlib,json,subprocess,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei-learning'))
from noesis.models import create
from noesis.activities import record_activity
from noesis.index import Index

IMPLEMENTATION='''import json,math,platform,sys
from pathlib import Path
import numpy as np

def attention(q,k,v):
    if q.ndim!=2 or k.ndim!=2 or v.ndim!=2 or q.shape[1]!=k.shape[1] or k.shape[0]!=v.shape[0] or q.shape[1]==0:
        raise ValueError("Incompatible query, key or value dimensions")
    logits=q@k.T/math.sqrt(q.shape[1])
    weights=np.exp(logits-logits.max(axis=1,keepdims=True))
    weights/=weights.sum(axis=1,keepdims=True)
    return weights@v

def scalar_reference(q,k,v):
    rows=[]
    for query in q:
        logits=[sum(float(a)*float(b) for a,b in zip(query,key))/math.sqrt(len(query)) for key in k]
        weights=[math.exp(score-max(logits)) for score in logits]
        rows.append([sum(weight*float(value[column]) for weight,value in zip(weights,v))/sum(weights) for column in range(v.shape[1])])
    return np.asarray(rows)

q=np.eye(2);k=np.eye(2);v=np.array([[1.,10.],[3.,20.]])
p=math.exp(1/math.sqrt(2))/(math.exp(1/math.sqrt(2))+1)
expected=np.array([[p+3*(1-p),10*p+20*(1-p)],[(1-p)+3*p,10*(1-p)+20*p]])
actual=attention(q,k,v)
np.testing.assert_allclose(actual,expected,rtol=1e-12,atol=1e-12)
rng=np.random.default_rng(1706);errors=[]
for _ in range(100):
    q=rng.normal(size=(3,4));k=rng.normal(size=(5,4));v=rng.normal(size=(5,2))
    result=attention(q,k,v);reference=scalar_reference(q,k,v)
    np.testing.assert_allclose(result,reference,rtol=1e-12,atol=1e-12)
    errors.append(float(np.max(np.abs(result-reference))))
np.testing.assert_allclose(attention(np.zeros((1,2)),np.eye(2),np.array([[1.,10.],[3.,20.]])),[[2.,15.]])
try:attention(np.zeros((1,3)),np.zeros((2,4)),np.zeros((2,1)))
except ValueError:pass
else:raise AssertionError("Dimension mismatch accepted")
q=np.eye(2);k=np.eye(2);v=np.array([[1.,10.],[3.,20.]])
unscaled=np.exp(q@k.T);unscaled=unscaled/unscaled.sum(axis=1,keepdims=True)@v
bug_difference=float(np.max(np.abs(unscaled-actual)))
assert bug_difference>0.1
report={"scope":"Attention Is All You Need, Eq. 1; forward computation only", "source":"https://arxiv.org/html/1706.03762v7#S3.SS2.SSS1", "expected":expected.tolist(),"observed":actual.tolist(),"random_cases":100,"maximum_error":max(errors),"unscaled_counterexample_difference":bug_difference,"units":"dimensionless synthetic values","python":platform.python_version(),"numpy":np.__version__,"limitations":"No training, BLEU replication, gradient verification or learner competence claim"}
Path(sys.argv[1]).write_text(json.dumps(report,indent=2))
print(json.dumps(report))
'''


def run(vault,paper_id,annotation_ref,folder):
    folder=Path(folder);code=folder/'attention-implementation';code.mkdir()
    script=code/'verify_attention.py';script.write_text(IMPLEMENTATION)
    subprocess.run(['git','init','-q',str(code)],check=True)
    subprocess.run(['git','-C',str(code),'add','verify_attention.py'],check=True)
    subprocess.run(['git','-C',str(code),'-c','user.name=Noesis fixture','-c','user.email=fixture@example.invalid','commit','-qm','Authored attention equation verification'],check=True)
    question=create(vault,'question','Why scale the dot product?','Which assumptions make its variance grow with the key dimension?',parent_id=paper_id,fields={'provenance':'agent-authored disposable acceptance fixture','annotation_ref':annotation_ref})
    reconstruction=create(vault,'task','Reconstruct attention equation','## Problem statement\n\nDerive softmax(Q K^T / sqrt(d_k)) V and predict a two-key case.\n\n## Reconstruction\n\nFor independent, zero-mean, unit-variance components, the dot product variance is d_k. Scaling makes the variance one. These assumptions are not guaranteed for arbitrary learned keys.',parent_id=question['id'],relation='assigns',fields={'annotation_ref':annotation_ref,'provenance':'agent-authored; not independently performed by the learner'})
    record_activity(vault,reconstruction['path'],'attempt','Agent-authored reconstruction checked against the source and an analytic two-key example.',outcome='succeeded',assistance=['agent','reference'],assessment='fixture source/formula check',scope='Eq. 1 only')
    project=create(vault,'project','Attention forward verification',parent_id=paper_id,fields={'repository':str(code)})
    experiment=create(vault,'experiment','Scaled attention numerical check',parent_id=project['id'],fields={'hypothesis':'The scaled matrix implementation agrees with a scalar reference to 1e-12; omitting scaling changes the two-key output','configuration':{'random_seed':1706,'random_cases':100,'tolerance':1e-12,'units':'dimensionless synthetic values'},'source_scope':'Eq. 1 forward computation only','annotation_ref':annotation_ref})
    report_path=folder/'attention-results.json'
    executed=subprocess.run([sys.executable,str(script),str(report_path)],capture_output=True,text=True,check=True,timeout=30)
    report=json.loads(report_path.read_text())
    artifact=create(vault,'artifact','Executed attention verification report',parent_id=experiment['id'],fields={'location':str(report_path),'sha256':hashlib.sha256(report_path.read_bytes()).hexdigest(),'ownership':'authored disposable execution output'})
    record_activity(vault,experiment['path'],'comparison','Executed the authored implementation, analytic example, scalar reference, uniform-query and dimension checks.',predicted='Maximum absolute error <= 1e-12',observed=str(report['maximum_error']),units='dimensionless synthetic values',conclusion='Forward equation checks pass; unscaled implementation has a preserved counterexample',next_experiment='Check gradients before using this implementation for training',artifact_id=artifact['id'],code_snapshot=experiment['code_snapshot'],execution={'command':[sys.executable,str(script),str(report_path)],'returncode':executed.returncode,'report_sha256':hashlib.sha256(report_path.read_bytes()).hexdigest()},assistance=['agent','reference'],scope=report['scope'])
    index=Index(vault)
    try:
        index.reconcile()
        assert index.record(experiment['id'])['props']['code_snapshot']['commit']
        assert index.timeline(reconstruction['id'])[-1]['assistance']==['agent','reference']
        assert index.timeline(experiment['id'])[-1]['execution']['returncode']==0
    finally:index.close()
    return {'question':question,'reconstruction':reconstruction,'project':project,'experiment':experiment,'report':report}
