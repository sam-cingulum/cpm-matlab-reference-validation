"""Correlated synthetic designs for complete automatic ten-fold regularization paths."""
import hashlib
import json
import random
import struct
from pathlib import Path


def design(i):
    rng = random.Random(12661000 + i)
    n = (113, 137, 179, 203, 229, 247)[i % 6]
    m = (21, 25, 31, 34, 37, 42)[i % 6]
    a = [rng.gauss(0., 1.) for _ in range(n)]
    b = [rng.gauss(0., 1.) for _ in range(n)]
    cols = [[(-1)**j * (1. + j/120) * a[k] + (j % 3 - 1) * b[k]/5 +
             rng.gauss(j/10, .25 + .1 * (i % 3)) for k in range(n)] for j in range(m)]
    y = [1.5 * a[k] + .125 * b[k] + rng.gauss(-.25, .5) for k in range(n)]
    bits = lambda x: struct.pack(">d", x).hex()
    return dict(id=f"cv_support_{i}", n=n, m=m, alpha=(.375, .5, .625, .75)[i % 4],
                seed=rng.randrange(2**24), x=[bits(v) for col in cols for v in col], y=list(map(bits,y)))


if __name__ == "__main__":
    # Fixed identifiers selected with independent native model comparisons.
    indices = [0, 1, 2, 3, 4, 5, 6, 8, 9, 10]
    path = Path(__file__).with_name("input.json")
    path.write_text(json.dumps([design(i) for i in indices], separators=(",", ":")) + "\n")
    path.with_suffix(".sha256").write_text(hashlib.sha256(path.read_bytes()).hexdigest()+"  input.json\n")
