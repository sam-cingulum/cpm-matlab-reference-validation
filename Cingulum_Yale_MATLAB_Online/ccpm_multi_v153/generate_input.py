"""Three- through six-task symmetric matrices for all six outputs of the original Yale cCPM."""
from pathlib import Path
import random
import json
import hashlib
import struct

rng = random.Random(15309231)
def bits(v):
    return struct.pack(">d",v).hex()
rows = []
for n in (24,27,34,42,46,56,68,74,86,98,104,122):
    j=len(rows);side=4+j%3;tasks=3+j%4;k=3+j%2
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
    # Give the source rank test a zero task, an exactly proportional pair,
    # or two zero tasks on one edge while the other edges remain full rank.
    if j%4:
        for i in range(n):
            for pos in (1,side):
                first=i*side*side+pos;second=(i+n)*side*side+pos
                if j%4 in (1,3):
                    matrices[first]=0.
                if j%4==2:
                    matrices[second]=2.*matrices[first]
                elif j%4==3:
                    matrices[second]=0.
    rows.append(dict(id=f"ccpm_v153_{j}_n{n}",shape=[side,side,n,tasks],matrix=list(map(bits,matrices)),
                     outcomes=list(map(bits,base)),threshold=(.005,.05,.25)[j%3],k=k,seed=rng.randrange(1000000)))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
