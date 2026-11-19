"""Independent one-predictor full-rank designs at every short fit length."""
import hashlib,json,random,struct
from pathlib import Path
rng=random.Random(1381222);bits=lambda v:struct.pack(">d",v).hex()
rows=[]
for n in range(3,11):
    for j in range(12):
        x=[(2.5 if j%2 else 0.)+rng.uniform(-1,1)*(1+j%3) for _ in range(n)]
        y=[.5-.25*v+rng.uniform(-.65,.65) for v in x]
        rows.append(dict(id=f"short_{n}_{j}",n=n,x_hex=list(map(bits,x)),y_hex=list(map(bits,y))))
p=Path(__file__).with_name("input.json");buf=(json.dumps(dict(cases=rows),separators=(",",":"))+"\n").encode();p.write_bytes(buf);p.with_suffix(".sha256").write_text(hashlib.sha256(buf).hexdigest()+"  input.json\n")
