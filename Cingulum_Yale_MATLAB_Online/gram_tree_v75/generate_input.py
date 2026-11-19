"""Positive-only Gram probes for square diagonal and off-diagonal accumulation trees."""
from pathlib import Path
import hashlib,itertools,json,random
rng=random.Random(751435)
cases=[]
for n in (12,17,31,43,50,51,65,97):
    for m in (2,5,12):
        positions=list(dict.fromkeys([(0,0),(0,1),(1,1),(0,m-1),(m//2,m-1),(m-1,m-1)]))
        x=[rng.gauss(0,1) for _ in range(n*m)]
        for i,j in positions:
            cases.append(dict(n=n,m=m,i=i+1,j=j+1,x=x,triples=[rng.sample(range(n),3) for _ in range(24)]))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
