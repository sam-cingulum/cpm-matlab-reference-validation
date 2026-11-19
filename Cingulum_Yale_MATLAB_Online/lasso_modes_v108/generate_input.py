"""Square and adjacent rectangular designs for the default solver dispatch and first sweep."""
import hashlib
import json
import random
import struct
from pathlib import Path
rng = random.Random(108197)
bits=lambda x:struct.pack(">d",x).hex()
cases=[]
for n,m in ((22,17),(22,22),(22,30),(35,33),(35,35),(35,42),(46,41),(46,46),(46,49),(55,55),(55,61),(63,60),(63,64)):
    for alpha in (1e-9,.371):
        z=[rng.gauss(0,1.) for _ in range(n)]
        cols=[[rng.gauss(.02*j,.8+j/10)+.85*z[i] for i in range(n)] for j in range(m)]
        y=[rng.gauss(-.3,.4)+sum(v[i]*(-1)**j/(1+j) for j,v in enumerate(cols)) for i in range(n)]
        cases.append(dict(id=f"n{n}_m{m}_a{alpha}",n=n,m=m,x=[bits(v) for col in cols for v in col],
                    y=list(map(bits,y)),alpha=alpha))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
