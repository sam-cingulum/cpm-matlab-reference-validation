"""F survival arguments on both sides of the beta mean and at exact binary exponents."""
from pathlib import Path
import hashlib
import json
import random
import struct

rng=random.Random(106408)
rows=[]
for d in (3,5,8,11,17,24,37,56,73,94,121):
    for i,ratio in enumerate((.005,.02,.0625,.125,.25,.5,.75,1.,1.5,2.,5.,12.,40.,90.)):
        f=ratio*(d/2.)*rng.uniform(.92,1.08)
        rows.append(dict(id=f"df{d}_{i}",df=d,f=struct.pack(">d",f).hex()))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
