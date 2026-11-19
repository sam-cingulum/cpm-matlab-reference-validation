"""Fixed full-rank pairs with missing observations plus separate exceptional controls."""
import hashlib
import json
from pathlib import Path
import random
import struct

rng = random.Random(1357203)
pack = lambda x: struct.pack(">d", x).hex()
cases = []
def append(name, group, x, y):
    cases.append(dict(id=name, group=group, n=len(x), x_hex=list(map(pack,x)), y_hex=list(map(pack,y))))

for n in (16,24,33,65,129,130,255,256,257,258,513,514):
    x0 = [rng.uniform(-2,4) for _ in range(n)]
    y0 = [0.25 - 0.625*x + rng.uniform(-0.375,0.375) for x in x0]
    for j in range(6):
        x,y=x0.copy(),y0.copy()
        if j in (1,4): x[0]=float("nan")
        if j in (2,4): y[-1]=float("nan")
        if j in (3,4): x[n//2]=y[n//2]=float("nan")
        if j==5:
            for k in range(1,n,5):
                (x if k%2 else y)[k]=float("nan")
        append(f"fit_{n}_{j}","missing",x,y)

for n in (0,1,2,3,5,8,9,17,32):
    x = [rng.uniform(-1,1) for _ in range(n)]
    y = [0.5+v+rng.uniform(-0.125,0.125) for v in x]
    append(f"short_{n}","control",x,y)
    if n>=3:
        for label,cx,cy in [
                ("zero_x",[0.]*n,y),("constant_x",[2.]*n,y),("constant_y",x,[1.]*n),
                ("exact_line",x,[0.5+v for v in x]),("all_nan",[float("nan")]*n,y),
                ("infinite_x",[float("inf"),*x[1:]],y),("infinite_y",x,[float("-inf"),*y[1:]])]:
            append(f"{label}_{n}","control",cx,cy)
p=Path(__file__).with_name("input.json"); raw=(json.dumps(dict(cases=cases),separators=(",",":"))+"\n").encode()
p.write_bytes(raw);p.with_suffix(".sha256").write_text(hashlib.sha256(raw).hexdigest()+"  input.json\n")
