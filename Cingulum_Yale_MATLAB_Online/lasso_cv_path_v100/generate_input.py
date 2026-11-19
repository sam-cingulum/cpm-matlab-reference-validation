"""Automatic-path and partition inputs independent of both PCA cohorts and earlier path tests."""
import hashlib
import json
import random
import struct
from pathlib import Path
rng=random.Random(1000357)
bits=lambda v:struct.pack(">d",v).hex()
cases=[]
for j,(n,m) in enumerate(((32,1),(39,2),(43,4),(54,6),(61,9),(74,11),(87,15),(97,19),(106,24),(119,32))):
    a=[rng.gauss(0,1) for _ in range(n)]
    cols=[[rng.gauss(.1*i,1.)+.5*a[k] for k in range(n)] for i in range(m)]
    y=[rng.gauss(-.25,.4)+sum(v[k]*(-1)**i/(i+1) for i,v in enumerate(cols)) for k in range(n)]
    cases.append(dict(id=f"auto_{j}_n{n}_m{m}",n=n,m=m,x=[bits(v) for c in cols for v in c],
                y=list(map(bits,y)),seed=rng.randrange(2**24),alpha=(1e-6,.375,1.,.625)[j%4]))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
