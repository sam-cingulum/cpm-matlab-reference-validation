"""Two finite task measurements in each of two independent synthetic groups."""
import hashlib,json,random,struct
from pathlib import Path
rng=random.Random(1210844)
bits=lambda x:struct.pack(">d",x).hex()
cases=[]
for j in range(36):
    n1=(12,19,31,44,50,67,86,104,128)[j%9]
    n2=(15,22,39,47,53,71,94)[j%7]
    groups=[]
    for g,n in enumerate((n1,n2)):
        a=[rng.gauss((j%6)*.18*g,1.+.15*g) for _ in range(n)]
        b=[.78*v*(-1)**j+rng.gauss(-.18*g,1.2) for v in a]
        if j%3==1:a,b=b,[v*4 for v in a]
        groups.append([a,b])
    cases.append(dict(id=f"hotelling_{j}",n1=n1,n2=n2,x=[bits(v) for t in range(2) for group in groups for v in group[t]]))
p=Path(__file__).with_name("input.json");p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
