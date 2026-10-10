from duplicate import first_duplicate
import json
cases=[([],None),([0,0],0),([1,2,1,2],1),([1,2,3],None),([-1,2,-1],-1)]
results=[dict(values=v,expected=e,observed=first_duplicate(v)) for v,e in cases]
assert all(r["expected"]==r["observed"] for r in results)
open("observed.json","w").write(json.dumps(results))
