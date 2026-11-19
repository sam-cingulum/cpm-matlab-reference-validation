"""One-column no-intercept designs across eight weights and explicit tuning."""
import hashlib
import json
import random
import struct
from pathlib import Path

def bits(v):
    return struct.pack(">d", v).hex()

rng = random.Random(16044017)
rows = []
for j,n in enumerate((5, 10, 17, 32, 51, 94, 259, 513)):
    x = [rng.gauss(.3, 1.) for _ in range(n)]
    if j % 4 == 1:
        x = [2.5] * n
    y = [-.2 + .9 * v + rng.gauss(0., .4) for v in x]
    # Exercise trailing zero weights as well as rejected interior rows.
    for k in range(1, 2 + j % 3):
        y[-k] += 2.75 * (-1) ** k
    if j % 2:
        y[n // 2] -= 3.25
    for weight in ("andrews", "bisquare", "cauchy", "fair", "huber", "logistic", "talwar", "welsch"):
        for tune in (None, 2.5 + .25 * (j % 3)):
            rows.append(dict(id=f"no_intercept_v160_{weight}_{n}_{'default' if tune is None else 'tuned'}",
                             n=n, x_hex=list(map(bits,x)), y_hex=list(map(bits,y)),
                             weight_function=weight, default_tune=tune is None, tune=tune))
p = Path(__file__).with_name("input.json")
p.write_text(json.dumps(dict(cases=rows),separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
