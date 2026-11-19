"""Fresh matrix cohorts with three to six coupled behavior measures and fixed or grid penalties."""
from pathlib import Path
import hashlib
import json
import random
import struct
rng = random.Random(1461019)
def bits(x):
    return struct.pack(">d", x).hex()
cases = []
for case,n in enumerate((19,23,29,33,39,47,55,61,73,85,107,125)):
    k = 3 + case%2
    nr = (3,4,5)[case%3]
    nt = 1+case%2
    sym = case%3!=2
    y = [rng.gauss(.5,1.) for _ in range(n)]
    v = [rng.gauss(1.5,.5+(case%3)/3) + [1.65,-.9,.7][case%3]*w for w in y]
    width=3+case%4
    extra=[rng.gauss(.3*j,.5)+(.35+.125*j)*y[i]+(-1)**j*.25*v[i]
           for j in range(width-2) for i in range(n)]
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
    cases.append(dict(id=f"multi_pca_{case}_n{n}",shape=[nr,nr,n,nt],matrix=list(map(bits,A)),outcomes=list(map(bits,y)),
        additional=list(map(bits,v+extra)),width=width,threshold=.01,alpha=(1e-9,.375,1.)[case%3],lambda_value=[.125] if case%2==0 else [.5,.015625,.25,.0625],
        k=k,seed=rng.randrange(1000000),fold_labels=labels))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
