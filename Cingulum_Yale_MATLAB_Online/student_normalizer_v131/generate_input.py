"""Fresh Student-t arguments covering integer and half-integer beta normalizers."""
import hashlib
import json
import math
import random
import struct
from pathlib import Path
rng=random.Random(1318217)
rows=[]
for df in [*range(3,350),383,447,511,512,513,767,1023,1024]:
    for k,t in enumerate((rng.uniform(.5,4.), math.sqrt(df)*rng.uniform(1.1,1.8))):
        rows.append(dict(id=f"df{df}_{k}",df=df,t=struct.pack(">d",t).hex()))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
