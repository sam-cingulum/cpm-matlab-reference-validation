"""Generate independent, deterministic binary inputs before any MATLAB execution."""
import csv
import itertools
import random
import struct
import sys
from pathlib import Path

out = Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=True)
rows = (3, 4, 6, 11, 13, 19, 31, 48, 64, 66, 127, 255, 256, 513, 777, 1000)
ratios = tuple(2.0 ** k for k in (-30, -27, -24, -23, -22, -18, -8, 0))
boundary = (2.0 ** -23 * (1 - 2.0 ** -24), 2.0 ** -23 * (1 + 2.0 ** -23))
with (out / "cases.csv").open("w", newline="") as cf, (out / "inputs.bin").open("wb") as bf:
    writer = csv.writer(cf, lineterminator="\n")
    writer.writerow(("case", "n", "p", "family", "ratio", "scale", "seed"))
    case = 0
    for n, p, family in itertools.product(rows, (2, 3, 4), ("duplicate", "combination", "imbalanced", "axes")):
        if p > n:
            continue
        for ratio, scale in itertools.product(ratios + (boundary if family == "axes" else ()), (-8, 0, 8)):
            case += 1
            seed = 142700000 + case
            rng = random.Random(seed)
            def draw():
                return (rng.getrandbits(24) - 2**23) / 2**23
            x = [[draw() for _ in range(n)] for _ in range(p)]
            if family == "duplicate":
                sign = (-1) ** (case % 2)
                x[-1] = [sign * a + ratio * b for a, b in zip(x[0], x[-1])]
            elif family == "combination":
                x[-1] = [sum((-1)**j * x[j][i] for j in range(p-1)) + ratio * x[-1][i] for i in range(n)]
            elif family == "imbalanced":
                x[-1] = [ratio * a for a in x[-1]]
            else:
                positions = rng.sample(range(n), p)
                x = [[0.0] * n for _ in range(p)]
                for j, i in enumerate(positions):
                    x[j][i] = (-1)**j * (ratio if j == p-1 else 1.0)
            x = [[v * 2.0**scale for v in col] for col in x]
            y = [draw() for _ in range(n)]
            writer.writerow((case, n, p, family, ratio.hex(), scale, seed))
            for col in x:
                bf.write(struct.pack(f"<{n}d", *col))
            bf.write(struct.pack(f"<{n}f", *y))
print(f"{case} independent cases")
