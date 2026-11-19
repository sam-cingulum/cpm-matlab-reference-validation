"""Raw real designs to isolate the exact first coordinate sweep and its standardization."""
import hashlib,json,random,struct
from pathlib import Path
rng=random.Random(773091)
bits=lambda v:struct.pack(">d",v).hex()
cases=[]
for n in (13,18,36,44,49,52,73,103):
    for m in (1,2,3,4,5,12):
        for alpha,lam in ((1e-9,.125),(.375,.0625),(1.,.30)):
            x=[[rng.gauss(.4*j,1.+j/4) for j in range(m)] for _ in range(n)]
            y=[.375+sum(v*((-1)**j)/(j+1) for j,v in enumerate(row))+rng.gauss(0,.23) for row in x]
            cases.append(dict(id=f"n{n}_m{m}_a{alpha}",n=n,m=m,alpha=alpha,penalty=lam,
                              x=[bits(row[j]) for j in range(m) for row in x],y=list(map(bits,y))))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
