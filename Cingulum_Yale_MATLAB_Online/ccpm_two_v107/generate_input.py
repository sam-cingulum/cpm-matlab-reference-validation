"""Two-task symmetric matrices for all six outputs of the original Yale cCPM."""
from pathlib import Path
import random
import json
import hashlib
import struct

rng = random.Random(1070394)
def bits(v):
    return struct.pack(">d",v).hex()
rows = []
for n in (25,33,46,56,71,85,99,117):
    j=len(rows);side=3+j%3;tasks=2;k=3+j%2
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
    rows.append(dict(id=f"ccpm_{j}_n{n}",shape=[side,side,n,tasks],matrix=list(map(bits,matrices)),
                     outcomes=list(map(bits,base)),threshold=(.005,.05,.25)[j%3],k=k,seed=rng.randrange(1000000)))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
