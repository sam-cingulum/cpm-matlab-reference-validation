"""Generate byte-reproducible synthetic full-rank fits for all lengths 129..1025."""
from pathlib import Path
import hashlib
import json
import struct
import sys

MASK = (1 << 64) - 1


def draws(seed):
    """SplitMix64; convert the upper 52 bits to a centered binary fraction."""
    state = seed
    while True:
        state = (state + 0x9E3779B97F4A7C15) & MASK
        z = state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        yield ((z ^ (z >> 31)) >> 12) * 2.0**-51 - 1.0


def case(i, n):
    r = draws(1340339 + 30593*i)
    kind = i % 4
    center, spread = [(0., 0.625), (2.5, 0.125), (-0.5, 5.), (0.5, 1.25)][kind]
    xs, ys = [], []
    for j in range(n):
        x = center + spread * next(r)
        y = (0.375 - x*0.75) + 0.375*next(r)
        if kind == 2 and j % 37 == 0:
            y += 4. if next(r) > 0. else -6.
        if kind == 3 and j == n//2:
            x += 12.
        xs.append(struct.pack(">d", x).hex())
        ys.append(struct.pack(">d", y).hex())
    return dict(id=f"range_{i}_{n}", n=n, x_hex=xs, y_hex=ys)


def generate(folder):
    folder.mkdir(parents=True, exist_ok=True)
    lengths = list(range(129, 1026)) + [129 + (37*j) % 897 for j in range(63)]
    assert len(lengths) == 960
    manifest = []
    for start in range(0, len(lengths), 32):
        rows = [case(i, lengths[i]) for i in range(start, start+32)]
        path = folder/f"input_{start//32:02}.json"
        raw = (json.dumps(dict(cases=rows), separators=(",", ":"))+"\n").encode()
        path.write_bytes(raw)
        manifest.append(f"{hashlib.sha256(raw).hexdigest()}  {path.name}\n")
    return "".join(manifest)


if __name__ == "__main__":
    sys.stdout.write(generate(Path(sys.argv[1])))
