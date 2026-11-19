"""A large square and two small squares distinguish Householder norm reductions."""
import hashlib
import json
import random
from pathlib import Path

rng = random.Random(910024)
rows = []
for n in (9, 15, 16, 17, 23, 31, 32, 33, 43, 44, 49, 63, 64, 65, 96, 127, 128):
    triples = {(1, 2, 3), (n-3, n-2, n-1), (1, n//2, n-1)}
    for stride in (2, 4, 8, 16, 32):
        for start in (1, 2, 3, 4, n-1-2*stride):
            if 0 < start < n-2*stride:
                triples.add((start, start+stride, start+2*stride))
    for _ in range(8):
        triples.add(tuple(sorted(rng.sample(range(1, n), 3))))
    for triple in sorted(triples):
        for j in range(3):
            rows.append(dict(id=f"n{n}_{'_'.join(map(str,triple))}_{j}", n=n, positions=triple, large=j))
path = Path(__file__).with_name("input.json")
path.write_text(json.dumps(rows,separators=(",",":"))+"\n")
path.with_suffix(".sha256").write_text(hashlib.sha256(path.read_bytes()).hexdigest()+"  input.json\n")
