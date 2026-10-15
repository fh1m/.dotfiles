import numpy as np
from scipy.special import softmax
q=np.array([[1.,2.],[0.,1.]])
k=np.array([[1.,0.],[0.,1.],[1.,1.]])
v=np.array([[2.,0.],[0.,3.],[1.,1.]])
scores=q@k.T/np.sqrt(q.shape[1])
actual=softmax(scores,axis=1)@v
expected=[]
for row in scores:
    weights=np.exp(row-row.max());weights/=weights.sum();expected.append(sum(w*value for w,value in zip(weights,v)))
np.testing.assert_allclose(actual,expected)
print("attention equation output",actual.tolist())
print("explicit row calculation agrees; no trained-model or learner-understanding claim")
