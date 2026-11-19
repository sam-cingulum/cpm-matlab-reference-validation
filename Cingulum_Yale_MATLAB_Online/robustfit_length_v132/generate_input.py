"""Independent larger bisquare fits with outliers, strongly offset and continuous predictors."""
import hashlib
import json
import math
import random
import struct
from pathlib import Path

rng=random.Random(1324435)
pack=lambda v:struct.pack(">d",v).hex()
cases=[]
lengths=[128,129,157,199,201,209,220,221,222,223,224,225,239,251,255,256,257,
         258,259,281,303,335,339,341,342,343,344,369,401,479,510,511,512,513,
         515,637,767,769,1009,1025]
for n in lengths:
    for j in range(3):
        x=[rng.gauss((1.75,.03,-.3)[j],(.07,.75,3.5)[j]) for _ in range(n)]
        y=[-.38+(.27,-.84,.33)[j]*v+rng.gauss(0.,.4) for v in x]
        if j==2:
            for k in range(1,n,23):y[k]+=rng.choice([-7.,9.])
        cases.append(dict(id=f"extended_{n}_{j}",n=n,x_hex=list(map(pack,x)),y_hex=list(map(pack,y))))
p=Path(__file__).with_name("input.json");p.write_text(json.dumps(dict(cases=cases),separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
