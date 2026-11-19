"""Exactly centered Walsh predictors isolate the old coordinate's contribution."""
from pathlib import Path
import hashlib
import json
import random
import struct

rng = random.Random(103095)
bits = lambda value: struct.pack(">d",value).hex()
rows = []
for n in (8,16,32,64):
    for m in (1,2):
        for shape in ("orthogonal","scaled","dense"):
            for replicate in range(3):
                cols = []
                for j in range(m):
                    col = []
                    for i in range(n//2):
                        sign = (-1.)**((i>>j)&1)
                        amplitude = 1. if shape=="orthogonal" else (2.**(i%4-1) if shape=="scaled" else rng.uniform(.3,2.))
                        col.extend([sign*amplitude,-sign*amplitude])
                    cols.append(col)
                y = []
                for i in range(0,n,2):
                    noise = rng.gauss(0.,1.) * (1. if replicate!=2 else 2.**(i%13-6))
                    value = 1.73*cols[0][i] + (0. if m==1 else .79*cols[1][i]) + noise
                    y.extend([value,-value])
                rows.append(dict(id=f"n{n}_m{m}_{shape}_{replicate}",n=n,m=m,x=[bits(v) for col in cols for v in col],
                                 y=list(map(bits,y)),alpha=(1.,.5,1.)[replicate],penalty=(0.,.125,.0625)[replicate]))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
