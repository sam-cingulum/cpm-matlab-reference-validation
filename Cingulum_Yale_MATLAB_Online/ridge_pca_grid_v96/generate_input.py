"""Multivariate behaviors and shuffled supplied penalties for original PCA ridge."""
from pathlib import Path
import random
import json
import hashlib
import struct

rng = random.Random(961170)
def bits(v):
    return struct.pack(">d",v).hex()
rows = []
for n in (27,36,48,57,72,83,99,118,132):
    j=len(rows);side=3+j%3;tasks=1+j%2;k=3+j%2
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
    labels=[i%k+1 for i in range(n)] if j%2 else []
    rng.shuffle(labels)
    grid=[.015625,.0625,.125,.375,.75,1.25];rng.shuffle(grid)
    rows.append(dict(id=f"supplied_pca_{j}_n{n}",shape=[side,side,n,tasks],matrix=list(map(bits,matrices)),
        outcomes=list(map(bits,base)),second_outcome=list(map(bits,second)),threshold=.005,alpha=(1e-9,.625,1)[j%3],
        lambda_value=grid,k=k,seed=rng.randrange(1000000),fold_labels=labels))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
