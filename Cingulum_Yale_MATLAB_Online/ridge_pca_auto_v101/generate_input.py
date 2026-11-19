"""Fresh two-measure cohorts for the original omitted-penalty PCA ridge branch."""
from pathlib import Path
import random
import json
import hashlib
import struct

rng = random.Random(1010670)
def bits(v):
    return struct.pack(">d",v).hex()
rows = []
for n in (38,44,52,63,71,86,94,107):
    j=len(rows);side=3+j%3;tasks=1+j%2;k=10
    base=[rng.gauss(.3,1.) for _ in range(n)]
    second=[rng.gauss(-.2,.8)+(1. if j%2 else -1.5)*v for v in base]
    matrices=[]
    for t in range(tasks):
        for y,v in zip(base,second):
            slab=[0.] * (side*side)
            for c in range(side):
                for r in range(c+1,side):
                    signal = (y*2. + v*(.8 if j%2 else -.8))*(-1)**(t+r) if c<2 else 0.
                    slab[r+c*side]=slab[c+r*side]=rng.gauss(.02*r,1.)+signal
            matrices.extend(slab)
    rows.append(dict(id=f"auto_pca_{j}_n{n}",shape=[side,side,n,tasks],matrix=list(map(bits,matrices)),
        outcomes=list(map(bits,base)),second_outcome=list(map(bits,second)),threshold=.005,alpha=(1e-9,.625,1)[j%3],
        k=k,seed=665,fold_labels=[]))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
