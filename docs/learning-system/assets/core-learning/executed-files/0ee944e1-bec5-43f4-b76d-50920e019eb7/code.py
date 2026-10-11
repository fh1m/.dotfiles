import os
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt
x=np.arange(8)
a=np.sin(2*np.pi*0.125*x)
b=np.sin(2*np.pi*1.125*x)
print("max sampled difference", float(np.max(np.abs(a-b))))
assert np.allclose(a,b)
plt.plot(x,a,"o-",label="sampled 0.125 cycles/sample")
plt.plot(x,b,"x",label="sampled 1.125 cycles/sample")
plt.legend()
plt.savefig(Path(os.environ["NOESIS_RUN_DIRECTORY"])/"aliasing.png")
