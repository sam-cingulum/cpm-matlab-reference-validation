"""Trace the diagonal corner left by full Gram tiles on dense, finite designs."""
from pathlib import Path
import hashlib
import json
import random

rng = random.Random(920413)
cases = []
for n in (19, 32, 65, 67, 76, 99, 139):
    for m in (13, 14, 15, 16, 23, 25):
        columns = [rng.gauss(.1*(j//n),1.) for j in range(n*m)]
        last = m//4*4
        edges = [(i,j) for i in range(last,m) for j in range(i,m)]
        if m == 16:
            edges = [(0,12),(12,12)]
        for i,j in edges:
            cases.append(dict(n=n,m=m,i=i+1,j=j+1,x=columns,triples=[rng.sample(range(n),3) for _ in range(24)]))
path = Path(__file__).with_name("input.json")
path.write_text(json.dumps(cases,separators=(",",":"))+"\n")
path.with_suffix(".sha256").write_text(hashlib.sha256(path.read_bytes()).hexdigest()+"  input.json\n")
