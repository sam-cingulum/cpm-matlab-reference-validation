"""Finite weighted and unweighted matrices for unchanged computeLambdaMax."""
import hashlib
import json
from pathlib import Path
import random
import struct

rng=random.Random(2026111960)
def bits(v):
    return struct.pack(">d",v).hex()
rows=[]
for n,m in ((9,3),(12,4),(14,15),(15,14),(23,5),(37,2),(43,6),(49,9),
            (50,4),(51,7),(52,4),(59,2),(65,5),(97,3),(129,4),(193,8),(257,4),(513,2)):
    for mode in ("unweighted","normalized","nonunit"):
        for standardize in (False,True):
            # Store column-major operands as binary64 hex to avoid decimal parser differences.
            y=[rng.uniform(-7,8)*2**(i%6-2) for i in range(n)]
            cols=[]
            for j in range(m):
                if j==1 and m>=3:
                    col=[2.5]*n
                elif j==2 and m>=4:
                    col=[1.0+rng.uniform(-3,3)*2**-33 for i in range(n)]
                else:
                    col=[rng.uniform(-2,3)*2**((i+j)%9-4)+.125*yi for i,yi in enumerate(y)]
                cols.append(col)
            w=[] if mode=="unweighted" else [rng.uniform(.125,3) for i in range(n)]
            if mode=="normalized":
                total=sum(w)
                w=[v/total for v in w]
            rows.append(dict(id=f"v60_n{n}_m{m}_{mode}_{int(standardize)}",n=n,m=m,standardize=standardize,
                alpha_hex=bits(rng.choice([.0625,.375,.625,1.])),x_hex=[bits(v) for col in cols for v in col],
                y_hex=list(map(bits,y)),weight_hex=list(map(bits,w)),weight_mode=mode))
p=Path(__file__).with_name('input.json')
p.write_text(json.dumps(rows,separators=(',',':'))+'\n')
p.with_name('input.sha256').write_text(hashlib.sha256(p.read_bytes()).hexdigest()+'  input.json\n')
