"""V1374 Yale Hotelling firstblind input (T2Hot2ihe, YaleMRRC/CPM b903f83, unchanged).

V1372 (genuine R2026b, two 9V45 runs) showed MATLAB's cov(X) is (Xc'*Xc)/(n-1) with the syrk
Gram, which sums serially at exactly 8 or 9 rows and blocks differently above 256 rows; the
engine's Hotelling took that rule in 0b64f5d, retrospectively. No Hotelling firstblind before
this one had a group of 8 or 9 rows at two or more features, or a group above 256 rows at
width 2 to 6. V1374 aims fresh draws at both.

Group pairs: 8 and 9 rows against each other and against 7, 10, 12, 30; 257 to 262, 380 to 390
and 508 to 516 rows against small and large groups. Widths 1 to 6; four regimes (moderate
effect, heteroscedastic feature scales, large-offset cancellation, near null). Inputs are
deterministic Python PRNG draws (seed 1374261127) written as raw IEEE-754 words; no MATLAB
output was read to write them.
"""
import hashlib
import json
import math
import random
import struct
from pathlib import Path

rng = random.Random(1374261127)
bits = lambda x: struct.pack(">d", float(x)).hex()
PAIRS = [(8, 8), (8, 9), (9, 8), (9, 9), (8, 12), (9, 30), (7, 9), (10, 8),
         (257, 8), (9, 260), (262, 381), (384, 9), (509, 515), (8, 516), (386, 258), (260, 513)]
EXTRA = [(9, 9), (8, 9), (9, 8), (8, 8)]
cases = []


def draw(width, n1, n2, regime):
    shared = [[rng.gauss(0.0, 1.0) for _ in range(n)] for n in (n1, n2)]
    groups = []
    for group, n in enumerate((n1, n2)):
        cols = []
        for k in range(width):
            channel = []
            for i in range(n):
                e = rng.gauss(0.0, 1.0)
                c = shared[group][i]
                if regime == 0:
                    v = e + 0.3 * c + group * (0.5 + 0.1 * k)
                elif regime == 1:
                    scales = (4e-6, 3e3, 0.07, 9e5, 2e-3, 55.0)
                    v = scales[k] * ((1.0 + 0.6 * group) * e + 0.2 * c + group * 0.3)
                elif regime == 2:
                    offset = (-1 if k % 2 else 1) * (3e6 + k * 1e6)
                    v = offset + (0.01 + 0.002 * k) * (e + 0.25 * c + group * 0.4)
                else:
                    v = e + 0.4 * c + group * (0.002 + 0.001 * k)
                assert math.isfinite(v)
                channel.append(v)
            cols.append(channel)
        groups.append(cols)
    return [bits(v) for k in range(width) for group in groups for v in group[k]]


for width in range(1, 7):
    for j, (n1, n2) in enumerate(PAIRS):
        regime = (j + width) % 4
        cases.append({"id": f"hotelling_v1374_{len(cases)}", "width": width, "n1": n1, "n2": n2,
                      "x": draw(width, n1, n2, regime)})
    for j, (n1, n2) in enumerate(EXTRA):
        regime = (j + width + 2) % 4
        cases.append({"id": f"hotelling_v1374_{len(cases)}", "width": width, "n1": n1, "n2": n2,
                      "x": draw(width, n1, n2, regime)})

assert len(cases) == 120 and len({c["id"] for c in cases}) == 120
for c in cases:
    assert len(c["x"]) == c["width"] * (c["n1"] + c["n2"])
path = Path(__file__).with_name("input.json")
path.write_text(json.dumps(cases, separators=(",", ":")) + "\n")
path.with_suffix(".sha256").write_text(hashlib.sha256(path.read_bytes()).hexdigest() + "  input.json\n")
print("V1374 input SHA256:", hashlib.sha256(path.read_bytes()).hexdigest())
