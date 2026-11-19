"""Fresh raw designs for comparing full lasso paths to independent single-penalty fits."""
from pathlib import Path
import hashlib
import json
import random
import struct
rng = random.Random(950208)
def bits(x):
    return struct.pack(">d",x).hex()
cases=[]
for n in (41,69,92,127):
    for m in (1,3,7,12,15,24,39):
        for alpha in (1e-9,.5,1.):
            common=[rng.gauss(0,1) for _ in range(n)]
            cols=[[rng.gauss(.2*j,.75+j/11) + ((-1)**j)*.65*common[i] for i in range(n)] for j in range(m)]
            y=[rng.gauss(.4,.3) + sum(c[i]*(-1)**j/(j+1) for j,c in enumerate(cols)) for i in range(n)]
            penalties=[.03125,.125,.375,.75,1.5,3.]
            rng.shuffle(penalties)
            cases.append(dict(id=f"n{n}_m{m}_a{alpha}",n=n,m=m,x=[bits(v) for col in cols for v in col],
                              y=list(map(bits,y)),alpha=alpha,penalties=penalties))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
