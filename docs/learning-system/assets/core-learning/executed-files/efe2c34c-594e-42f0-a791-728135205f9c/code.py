from collections import deque
from itertools import permutations
def topo(n,edges):
    incoming=[0]*n
    outgoing=[[] for _ in range(n)]
    for a,b in edges: incoming[b]+=1; outgoing[a].append(b)
    ready=deque(i for i in range(n) if incoming[i]==0); order=[]
    while ready:
        a=ready.popleft(); order.append(a)
        for b in outgoing[a]:
            incoming[b]-=1
            if incoming[b]==0: ready.append(b)
    return order if len(order)==n else None
cases=[(2,[(1,0)]),(3,[(0,1),(1,2)]),(3,[(0,1),(1,0)]),(4,[(0,2),(1,2),(2,3)]),(0,[])]
for n,edges in cases:
    valid=[p for p in permutations(range(n)) if all(p.index(a)<p.index(b) for a,b in edges)]
    actual=topo(n,edges)
    assert (actual is None)==(not valid)
    if actual is not None: assert tuple(actual) in valid
    print(n,edges,"=>",actual)
print("five cases agree with exhaustive small-graph oracle")
