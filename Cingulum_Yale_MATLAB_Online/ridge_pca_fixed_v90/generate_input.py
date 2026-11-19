"""Fresh matrix cohorts with two raw behavior measures and one known fit penalty."""
from pathlib import Path
import hashlib
import json
import random
import struct
rng = random.Random(901019)
def bits(x):
    return struct.pack(">d", x).hex()
cases = []
for case,n in enumerate((22,25,28,31,43,57,69,79,92,107,129,145)):
    k = 3 + case%2
    nr = (3,4,5)[case%3]
    nt = 1+case%2
    sym = case%3!=2
    y = [rng.gauss(.5,1.) for _ in range(n)]
    v = [rng.gauss(1.5,.5+(case%3)/3) + [1.65,-.9,.7][case%3]*w for w in y]
    A = []
    for t in range(nt):
        for j in range(n):
            slab=[0.]*(nr*nr)
            for col in range(nr):
                for row in range(col+1 if sym else 0,nr):
                    s = (2.2*y[j] + (-.7 if case%3==1 else .7)*v[j]) * (-1)**(row+t) if col==0 else 0.
                    slab[row+col*nr]=rng.gauss(.1*row,.8)+s
                    if sym:
                        slab[col+row*nr]=slab[row+col*nr]
            A.extend(slab)
    labels = [i%k+1 for i in range(n)] if case%4 in (1,2) else []
    rng.shuffle(labels)
    cases.append(dict(id=f"pca_{case}_n{n}",shape=[nr,nr,n,nt],matrix=list(map(bits,A)),outcomes=list(map(bits,y)),
        second_outcome=list(map(bits,v)),threshold=.01,alpha=(1e-9,.375,1.)[case%3],lambda_value=(.125,.25,.0625)[case%3],
        k=k,seed=rng.randrange(1000000),fold_labels=labels))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
