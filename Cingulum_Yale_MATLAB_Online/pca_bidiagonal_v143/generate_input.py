"""Multiple continuous behavior measures with unequal scales and coupled columns."""
import hashlib,json,random,struct
from pathlib import Path
rng=random.Random(1439183); rows=[]
for n in (10,13,16,18,19,20,21,22,31,53,89,127):
    for width in (3,4,5,6):
        for family in range(2):
            base=[rng.uniform(-2.,2.) for _ in range(n)]
            values=[(13.75*(j+1) if family else 0.) + (.4+.21*j)*rng.gauss(0.,1.) +
                    ((-1.)**j)*(.7 if family else .2)*v for j in range(width) for v in base]
            rows.append(dict(id=f"bidiag_{n}_{width}_{family}",n=n,width=width,x=[struct.pack(">d",v).hex() for v in values]))
p=Path(__file__).with_name("input.json");buf=(json.dumps(rows,separators=(",",":"))+"\n").encode();p.write_bytes(buf);p.with_suffix(".sha256").write_text(hashlib.sha256(buf).hexdigest()+"  input.json\n")
