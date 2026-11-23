#!/usr/bin/env python3
"""Generate a genuinely new original-unseen Q'B source, without MATLAB results."""

import hashlib
import json
import math
import random
import struct
from pathlib import Path


HERE = Path(__file__).resolve().parent
SEED = 202611246341
CLASSIFICATION = "V635_PROSPECTIVE_ORIGINAL_UNSEEN_PUBLIC_QTB_12TILE"


def hex64(value):
    assert math.isfinite(value)
    return struct.pack(">d", float(value)).hex()


def matrix(n, p):
    rng = random.Random(SEED + p * 23011 + n * 90311 + 4403)
    columns = [[0.0] * n for _ in range(p)]
    columns[0][0] = 4.5
    for row in range(p, n - 1):
        columns[0][row] = ((-1.0) ** row) * (0.9 + 0.4 * rng.random()) * (2.0 ** (row % 5 - 2))
    for k in range(1, p):
        columns[k][k] = 2.0 ** (-k)
    for row in range(p, n - 1):
        columns[1][row] = columns[0][row] * 0.00625 + ((-1.0) ** row) * 0.0078125
    assert all(col[-1] == 0.0 for col in columns)
    return [hex64(value) for col in columns for value in col]


def response(n, p, probe):
    rng = random.Random(SEED + 1_000_003 * n + 23_011 * p + probe * 911)
    values = [
        rng.uniform(-1, 1) * 2.0 ** ((row + probe) % 9 - 4)
        for row in range(n - 1)
    ]
    if probe % 3 == 0:
        values[1] = 2.0 ** 25
        values[2] = -(2.0 ** 25)
        values[3] = 2.0 ** -23 * (1 + (probe + 1) * 2.0 ** -52)
    elif probe % 3 == 1:
        values[15] = 1.0
        values[16] = -(1.0 + (probe + 1) * 2.0 ** -52)
        values[31] = 2.0 ** -14
    else:
        values[p] = 1.0
        values[p + 1] = -1.0
        values[n - 3] = 2.0 ** -25
    values.append(0.0)
    assert len(values) == n
    return [hex64(value) for value in values]


def main():
    output = HERE / "input.json"
    assert not output.exists(), "preserve frozen prospective source"
    matrices = []
    cases = []
    for p in (9, 10):
        n = 65
        identifier = f"v635_original_unseen_n{n}_p{p}"
        matrices.append({"id": identifier, "n": n, "p": p, "a_colmajor_hex": matrix(n, p)})
        for probe in range(6):
            cases.append({
                "id": f"{identifier}_probe_{probe:02d}",
                "matrix_id": identifier,
                "b_colmajor_hex": response(n, p, probe),
            })
    source = {
        "classification": CLASSIFICATION,
        "seed": SEED,
        "V12": "SEALED",
        "source_only": True,
        "original_MATLAB_numerical_outputs_read": False,
        "independent_Rust_outputs_read": False,
        "padding": [2, 7],
        "widths": [1, 2, 11, 12, 13, 16, 17, 20, 23, 24, 25, 28, 32],
        "matrices": matrices,
        "cases": cases,
    }
    raw = (json.dumps(source, separators=(",", ":"), sort_keys=True) + "\n").encode()
    output.write_bytes(raw)
    digest = hashlib.sha256(raw).hexdigest()
    (HERE / "input.sha256").write_text(f"{digest}  input.json\n")
    print("V635 ORIGINAL-UNSEEN input SHA", digest, "2 matrices, 12 probes")


if __name__ == "__main__":
    main()
