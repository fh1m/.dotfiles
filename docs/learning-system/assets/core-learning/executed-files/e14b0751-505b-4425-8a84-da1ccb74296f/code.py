import os
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt
out=Path(os.environ["NOESIS_RUN_DIRECTORY"])
dt=0.02;time=np.arange(0,20,dt);rows=[]
for anti in [False,True]:
    x=0.;integral=0.;trace=[]
    for t in time:
        reference=3. if t<8 else 1.
        error=reference-x;raw=2*error+0.8*integral;u=np.clip(raw,-2,2)
        if not anti or raw==u or (raw>u and error<0) or (raw<u and error>0): integral+=error*dt
        x+=dt*(-x+u);trace.append(x)
    trace=np.array(trace)
    late=np.sqrt(np.mean((trace[time>=10]-1)**2))
    print("conditional integration",anti,"late RMSE",float(late),"normalized illustrative units")
    rows.append(trace);plt.plot(time,trace,label="conditional integration "+str(anti))
plt.axvline(8,color="gray",linestyle="--");plt.legend();plt.xlabel("simulated seconds");plt.ylabel("normalized illustrative state")
plt.savefig(out/"windup.png")
np.savetxt(out/"windup.csv",np.column_stack([time,*rows]),delimiter=",",header="time,plain_PI,conditional_PI")
assert all(np.isfinite(row).all() for row in rows)
print("hypothetical plant only: xdot=-x+u; actuator limit +/-2; no hardware inference")
