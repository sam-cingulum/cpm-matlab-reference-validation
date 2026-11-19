"""Automatic-path and partition inputs independent of both PCA cohorts and earlier path tests."""
import hashlib
import json
import random
import struct
from pathlib import Path
rng=random.Random(1190775)
bits=lambda v:struct.pack(">d",v).hex()
cases=[]
for j,(n,m) in enumerate(((112,3),(117,7),(120,10),(123,11),(135,13),(146,16),(179,21),(220,25),(243,31),(254,42))):
    a=[rng.gauss(0,1) for _ in range(n)]
    cols=[[rng.gauss(.1*i,.45)+(-1)**i*(1.+i/120)*a[k] for k in range(n)] for i in range(m)]
    y=[rng.gauss(-.25,.5)+a[k]*1.5 for k in range(n)]
    cases.append(dict(id=f"dense_{j}_n{n}_m{m}",n=n,m=m,x=[bits(v) for c in cols for v in c],
                y=list(map(bits,y)),seed=rng.randrange(2**24),alpha=(.5,.375,.75,.625)[j%4]))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
