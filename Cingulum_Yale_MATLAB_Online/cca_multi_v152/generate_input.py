"""Three- through six-task full-rank edge designs for the canonical-correlation stage of Yale cCPM."""
import hashlib
import json
import random
import struct
from pathlib import Path
rng=random.Random(15220381)
bits=lambda v:struct.pack(">d",v).hex()
cases=[]
for j,n in enumerate([13,16,22,27,34,41,49,62,77,90,105,127]*4):
    m=3 + j//12
    a=[rng.gauss(0,1) for _ in range(n)]
    cols=[[rng.gauss(.1*i,1.+(.5 if i==j%m else 0.))+.5*a[k] for k in range(n)] for i in range(m)]
    y=[rng.gauss(-.25,(.25,1.,5.)[j%3])+sum(v[k]*(-1)**i/(i+1) for i,v in enumerate(cols)) for k in range(n)]
    cases.append(dict(id=f"cca_v152_{j}_n{n}",n=n,m=m,x=[bits(v) for c in cols for v in c],
                y=list(map(bits,y))))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
