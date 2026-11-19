"""Every selected width from 13 to 64 on two independent dense response designs."""
from pathlib import Path
import hashlib
import json
import random
import struct

rng = random.Random(940188)
def bits(v):
    return struct.pack(">d", v).hex()
cases = []
for m in range(13,65):
    for design,(alpha,penalty) in enumerate(((1e-9,.15),(.625,.1875))):
        n = (69, 82, 93, 104, 115, 128, 139, 146)[(m+3*design)%8]
        columns = [[rng.gauss((j%4)*.2, .7+(j%9)*.2) for _ in range(n)] for j in range(m)]
        y = [rng.gauss(-.25,.2) + sum(col[i]*((-1)**j / (j+1)) for j,col in enumerate(columns)) for i in range(n)]
        cases.append(dict(id=f"m{m}_n{n}_design{design}",m=m,n=n,alpha=alpha,penalty=penalty,
                          x=[bits(v) for col in columns for v in col],y=list(map(bits,y))))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
