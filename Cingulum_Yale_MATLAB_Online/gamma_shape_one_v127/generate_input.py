"""Fresh binary64 gamma arguments spanning subnormal through saturated probabilities."""
import hashlib
import json
import math
import random
import struct
from pathlib import Path

rng = random.Random(1270925)
xs = {0., *[math.ldexp(1., e) for e in (-1074, -1050, -1022, -1000, -200, -80)]}
for e in range(-64, 11):
    x = 2.**e
    xs.update((math.nextafter(x, 0.), x, math.nextafter(x, math.inf)))
for _ in range(180):
    xs.update((rng.uniform(.001, 1.), rng.uniform(1., 40.), 2.**rng.uniform(-48., -4.)))
p = Path(__file__).with_name("input.json")
p.write_text(json.dumps([struct.pack(">d", x).hex() for x in sorted(xs)], separators=(",", ":")) + "\n")
p.with_suffix(".sha256").write_text(hashlib.sha256(p.read_bytes()).hexdigest()+"  input.json\n")
