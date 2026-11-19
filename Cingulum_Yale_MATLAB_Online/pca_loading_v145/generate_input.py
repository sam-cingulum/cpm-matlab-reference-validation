"""Multiple continuous behavior measures with unequal scales and coupled columns."""
import hashlib,json,random,struct
from pathlib import Path
rng=random.Random(1454517); rows=[]
for n in (11,14,17,19,20,21,23,35,57,73,97,126):
    for width in (3,4,5,6):
        for family in range(2):
            base=[rng.uniform(-2.,2.) for _ in range(n)]
            values=[(13.75*(j+1) if family else 0.) + (.4+.21*j)*rng.gauss(0.,1.) +
                    ((-1.)**j)*(.7 if family else .2)*v for j in range(width) for v in base]
            rows.append(dict(id=f"loading_{n}_{width}_{family}",n=n,width=width,x=[struct.pack(">d",v).hex() for v in values]))
p=Path(__file__).with_name("input.json");buf=(json.dumps(rows,separators=(",",":"))+"\n").encode();p.write_bytes(buf);p.with_suffix(".sha256").write_text(hashlib.sha256(buf).hexdigest()+"  input.json\n")
