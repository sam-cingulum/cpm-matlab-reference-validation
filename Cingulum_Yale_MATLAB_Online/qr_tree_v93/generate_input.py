"""Independent triples and dense inputs for measuring the reductions of each QR entry."""
import hashlib
import json
import random
from pathlib import Path
rng = random.Random(930219)
cases = []
for n in (19, 20, 21, 22, 23, 24, 31, 32, 43, 44, 57, 64, 65, 79, 95, 111, 127, 128):
    for stage in (1, 2, 3):
        start = 2 if stage == 3 else 1
        cases.append(dict(id=f"n{n}_r{stage}",n=n,stage=stage,
                          x=[rng.gauss(0,1) for _ in range(2*n)],
                          triples=[rng.sample(range(start,n),3) for _ in range(24)]))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases,separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
