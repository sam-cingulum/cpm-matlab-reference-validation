"""Independent synthetic training and held-out groups in MATLAB column-major order."""
import hashlib
import json
from pathlib import Path
import random
import struct

rng = random.Random(1100349)

def bits(x):
    return struct.pack(">d", x).hex()

def group(n, side, tasks, task, symmetric):
    outcomes = [rng.gauss(.3, 1.) for _ in range(n)]
    flat = []
    for t in range(tasks):
        for y in outcomes:
            slab = [0.] * (side * side)
            for c in range(side):
                for r in range(c + 1 if symmetric else 0, side):
                    signal = (-1)**(r+t) * (1.5*y if c < 2 else .2*y)
                    value = rng.gauss(.125*r, .75)+signal
                    slab[r+c*side] = value
                    if symmetric:
                        slab[c+r*side] = value
            flat.extend(slab)
    return dict(shape=[side,side,n,tasks],matrix=list(map(bits,flat)),outcomes=list(map(bits,outcomes)),task=task)

rows = []
for j, n in enumerate([37,45,53,62,77,89,111,124]):
    side = 3+j%3
    tasks = 1 if j%4 == 0 else 2
    task1,task2 = (1,2) if j%3==2 and tasks==2 else (0,0)
    sym = j not in (3,6)
    rows.append(dict(id=f"cross_{j}",train=group(n,side,tasks,task1,sym),
                     test=group(11+3*j,side,tasks,task2,sym),threshold=[.01,.05,.2][j%3],
                     alpha=[1e-6,.5,.9,.125][j%4],seed=rng.randrange(1000000),k=2+j%4))
p = Path(__file__).with_name("input.json")
p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
