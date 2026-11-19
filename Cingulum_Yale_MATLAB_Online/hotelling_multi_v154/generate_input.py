"""One through six finite task measurements in each of two independent synthetic groups."""
import hashlib,json,random,struct
from pathlib import Path
rng=random.Random(15422059)
bits=lambda x:struct.pack(">d",x).hex()
cases=[]
for j in range(72):
    n1=(13,18,32,43,51,69,84,106,126)[j%9]
    n2=(16,23,38,46,54,72,96)[j%7]
    width=1+(j//12)
    groups=[]
    for g,n in enumerate((n1,n2)):
        a=[rng.gauss((j%6)*.18*g,1.+.15*g) for _ in range(n)]
        b=[.78*v*(-1)**j+rng.gauss(-.18*g,1.2) for v in a]
        if j%3==1:a,b=b,[v*4 for v in a]
        cols=[a,b]
        for i in range(2,width):
            scale=(.25,1.,4.)[(j+i)%3]
            cols.append([scale*(rng.gauss(.125*i*g,1.)+.625*a[k]-.375*b[k]) for k in range(n)])
        groups.append(cols[:width])
    cases.append(dict(id=f"hotelling_v154_{j}",width=width,n1=n1,n2=n2,x=[bits(v) for t in range(width) for group in groups for v in group[t]]))
p=Path(__file__).with_name("input.json");p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
