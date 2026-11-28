"""Deterministic novel positive finite binary64 gammaln arguments."""
import csv
import struct
import sys
from pathlib import Path

MASK = (1 << 64) - 1
state = 0x1428D417F0A11B17


def random_word():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)


def word(value):
    return struct.unpack("<Q", struct.pack("<d", value))[0]


def main(out):
    out.mkdir(parents=True, exist_ok=True)
    cases = []
    seen = set()

    def add(bits, family):
        if not 0 < bits < 0x7ff0000000000000 or bits in seen:
            return
        seen.add(bits)
        cases.append((len(cases) + 1, family, f"{bits:016x}"))

    # Sample both sides of candidate branches, integer transition, and large
    # finite overflow neighborhood. Avoid using the exact disclosed centers.
    for center in (2.0**-52, 0.5, 0.6796875, 1.0, 1.5, 2.0, 4.0, 12.0,
                   99.0, 100.0, 101.0, 102.0, 2.25e76, 2.55e305):
        for side in (-1, 1):
            for _ in range(32):
                add(word(center) + side * (17 + random_word() % 16384), "boundary")
    # Positive subnormal values across the full mantissa range.
    for _ in range(256):
        add(1 + random_word() % ((1 << 52) - 1), "subnormal")
    # Positive ordinary fractional values with broad exponent coverage.
    for _ in range(2048):
        exponent = 1 + random_word() % 2046
        add((exponent << 52) | (random_word() & ((1 << 52) - 1)), "wide")
    # Dense coverage of Cody/Stoltz branches, independent random mantissas.
    while len(cases) < 4096:
        exponent = 1019 + random_word() % 9
        add((exponent << 52) | (random_word() & ((1 << 52) - 1)), "dense")
    assert len(cases) == len(seen) == 4096
    with (out / "cases.csv").open("w", newline="") as file:
        writer = csv.writer(file, lineterminator="\n")
        writer.writerow(("case", "family", "x_hex"))
        writer.writerows(cases)
    (out / "inputs.bin").write_bytes(b"".join(struct.pack("<Q", int(row[2], 16)) for row in cases))


if __name__ == "__main__":
    main(Path(sys.argv[1]))
