"""Paired raw designs for eight IRLS weight functions, default and explicit tuning."""
import hashlib
import json
import random
import struct
from pathlib import Path

def bits(v):
    return struct.pack(">d", v).hex()

rng = random.Random(15855021)
rows = []
for j,n in enumerate((9, 16, 17, 18, 31, 33, 50, 52, 94, 153, 258, 513)):
    x = [rng.gauss(.3, 1.) for _ in range(n)]
    y = [.8 - .6 * v + rng.gauss(0., .4) for v in x]
    # Exercise trailing zero weights as well as rejected interior rows.
    for k in range(1, 2 + j % 3):
        y[-k] += 2.75 * (-1) ** k
    if j % 2:
        y[n // 2] -= 3.25
    for weight in ("andrews", "bisquare", "cauchy", "fair", "huber", "logistic", "talwar", "welsch"):
        for tune in (None, 2.5 + .25 * (j % 3)):
            rows.append(dict(id=f"weight_v158_{weight}_{n}_{'default' if tune is None else 'tuned'}",
                             n=n, x_hex=list(map(bits,x)), y_hex=list(map(bits,y)),
                             weight_function=weight, default_tune=tune is None, tune=tune))
p = Path(__file__).with_name("input.json")
p.write_text(json.dumps(dict(cases=rows),separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
