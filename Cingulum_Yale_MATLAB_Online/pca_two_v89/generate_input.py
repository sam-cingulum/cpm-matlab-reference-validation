"""Two-dimensional raw behavior covariates for measuring the first PCA loading."""
import hashlib
import json
from pathlib import Path
import random
import struct
rng = random.Random(891226)
cases = []
for n in (9, 15, 23, 31, 42, 43, 44, 45, 49, 50, 51, 57, 63, 64, 65, 79, 95, 111, 127, 128):
    for scale, coupling, shift in ((.375, .7, 0.), (2.75, -.9, 3.), (1., .05, 1024.)):
        x = [rng.gauss(shift, 1.) for _ in range(n)]
        y = [rng.gauss(-shift, scale) + coupling*(v-shift) for v in x]
        cases.append(dict(id=f"pca_{len(cases)}_n{n}", n=n, x=[struct.pack(">d", v).hex() for v in x+y]))
p = Path(__file__).with_name("input.json")
p.write_text(json.dumps(cases, separators=(",", ":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
