"""Paired raw designs for eight IRLS weight functions, default and explicit tuning."""
import hashlib
import json
import random
import struct
from pathlib import Path

def bits(v):
    return struct.pack(">d", v).hex()

rng = random.Random(15542071)
rows = []
for j,n in enumerate((17, 32, 51, 93, 152, 259)):
    x = [rng.gauss(.3, 1.) for _ in range(n)]
    y = [.8 - .6 * v + rng.gauss(0., .4) for v in x]
    y[-1] += 2.5
    for weight in ("andrews", "bisquare", "cauchy", "fair", "huber", "logistic", "talwar", "welsch"):
        for tune in (None, 2.5 + .25 * (j % 3)):
            rows.append(dict(id=f"{weight}_{n}_{'default' if tune is None else 'tuned'}",
                             n=n, x_hex=list(map(bits,x)), y_hex=list(map(bits,y)),
                             weight_function=weight, default_tune=tune is None, tune=tune))
p = Path(__file__).with_name("input.json")
p.write_text(json.dumps(dict(cases=rows),separators=(",",":"))+"\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
