"""Fresh default-bisquare robustfit data near vector length boundaries."""
import hashlib
import json
import math
import random
import struct
from pathlib import Path

rng = random.Random(12904897)
pack = lambda x: struct.pack(">d", x).hex()
cases = []
lengths = [127,128,129,130,143,159,191,223,255,256,257,319,383,511,512,513,767,1023,1024,1025]
for n in lengths:
    for rep in range(3):
        scale = (.25,1.,4.)[rep]
        x = [rng.gauss(.125 if rep==0 else -.25,scale) for i in range(n)]
        y = [.2 + v * (.4 if rep==1 else -.55) + rng.gauss(0.,.6) for v in x]
        if rep==2:
            for i in range(0,n,31):
                y[i] += 8*(-1)**i
        cases.append(dict(id=f"long_{n}_{rep}",n=n,x_hex=list(map(pack,x)),y_hex=list(map(pack,y))))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(dict(cases=cases),separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
