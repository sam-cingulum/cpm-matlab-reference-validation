"""Fresh finite operands for scalar inner products and moment measurements."""
import hashlib
import json
import math
import random
from pathlib import Path

rng = random.Random(2026111958)
rows=[]
for n in (33,39,40,41,42,43,44,45,46,47,48,49,50,51,52,55,56,57,63,64,65,72,80,96,127,128,129,191,192,193,255,256,257):
    def vector():
        return [math.ldexp(rng.randint(-65535,65535),rng.randrange(-32,9)) for _ in range(n)]
    dense=[dict(x=vector(),y=vector()) for _ in range(5)]
    triples=set()
    while len(triples)<64:triples.add(tuple(sorted(rng.sample(range(n),3))))
    rows.append(dict(n=n,dense=dense,triples=sorted(triples)))
p=Path(__file__).with_name("input.json")
p.write_text(json.dumps(rows,separators=(",",":"))+"\n")
p.with_name("input.sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
