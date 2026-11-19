"""Rank-one and finite full-rank fits separating Student-t, leverage and offset effects."""
import hashlib,json,random,struct
from pathlib import Path
rng=random.Random(140318);rows=[];bits=lambda v:struct.pack(">d",v).hex()
def add(name,x,y):
    rows.append(dict(id=name,n=len(x),x_hex=list(map(bits,x)),y_hex=list(map(bits,y))))
for n in (3,4,5,6,7,8,9,12,19,37,78,128,129,255,257,513):
    for j,k in enumerate((0.,1.,-1.,.125,-2.5,1.375)):
        y=[rng.uniform(-1.75,2.5) for _ in range(n)]
        if j%2 and n>8:y[1]+=10.
        add(f"rankone_{n}_{j}",[k]*n,y)
for n in range(3,11):
    for j in range(12):
        x=[rng.uniform(-.75,.75)+(1.25 if j%2 else 0.) for _ in range(n)]
        if j%4==0:x[-1]+=120.
        y=[-.5+.25*v+rng.uniform(-.5,.5) for v in x]
        add(f"full_{n}_{j}",x,y)
p=Path(__file__).with_name("input.json");buf=(json.dumps(dict(cases=rows),separators=(",",":"))+"\n").encode();p.write_bytes(buf);p.with_suffix(".sha256").write_text(hashlib.sha256(buf).hexdigest()+"  input.json\n")
