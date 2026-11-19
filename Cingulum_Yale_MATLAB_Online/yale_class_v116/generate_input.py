"""Finite single-group Yale class inputs with independent nuisance and phenotype signals."""
import hashlib
import json
from pathlib import Path
import random
import struct

rng=random.Random(1160501)
bits=lambda v:struct.pack(">d",v).hex()
rows=[]
for j,n in enumerate((41,50,59,68,80,95,109,127)):
    side=3+j%3;tasks=1+j%3
    controls=[[rng.gauss(.1*t,1.) for i in range(n)] for t in range(2)]
    y=[rng.gauss(.2,.85)+.35*v for v in controls[0]]
    if j%3!=0:
        y=[round(v*4.)/4. for v in y]
    matrix=[]
    sym=j not in (3,6)
    for t in range(tasks):
        for i in range(n):
            slab=[0.]*(side*side)
            for c in range(side):
                for r in range(c+1 if sym else 0,side):
                    signal=(-1)**(t+r)*(1.6*y[i] if c<2 else .03*y[i])
                    v=rng.gauss(.1*r,1.)+signal+(1.+.25*c)*controls[(r+t)%2][i]
                    slab[r+c*side]=v
                    if sym:slab[c+r*side]=v
            matrix.extend(slab)
    rows.append(dict(id=f"class_fresh_{j}",group=dict(shape=[side,side,n,tasks],matrix=list(map(bits,matrix)),outcomes=list(map(bits,y))),
                     controls=[bits(x) for v in controls for x in v],cpm_controls=j%3,rcpm_controls=1+j%2,
                     k=3+j%3,seed=rng.randrange(1000000),threshold=[.01,.05,.2][j%3],alpha=[.35,1e-6,.85][j%3]))
p=Path(__file__).with_name("input.json");p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
