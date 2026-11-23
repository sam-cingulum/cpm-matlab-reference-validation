#!/usr/bin/env python3
"""V589 genuinely new X/B input, frozen ahead of original MATLAB output.

Generates two-reflector matrix geometry with a new independent PRNG seed.
No MATLAB numerical original, frozen Rust forecast, or score is read.
"""
import hashlib
import json
import math
import random
import struct
from pathlib import Path

HERE = Path(__file__).resolve().parent
SEED = 202611240589
CLASS = "V589_PROSPECTIVE_R2026B_ORIGINAL_ONLY_NEW_X_B"
PROBE_COUNT = 12


def hx(value):
    assert math.isfinite(value)
    return struct.pack(">d", float(value)).hex()


def matrix(n, p):
    rng = random.Random(SEED + p * 23011 + n * 90311 + 4403)
    x = [[0.0] * n for _ in range(p)]
    x[0][0] = 4.5
    for row in range(p, n - 1):
        x[0][row] = ((-1.0) ** row) * (0.9 + 0.4 * rng.random()) * (2.0 ** (row % 5 - 2))
    for k in range(1, p):
        x[k][k] = 2.0 ** (-k)
    for row in range(p, n - 1):
        x[1][row] = x[0][row] * 0.00625 + ((-1.0) ** row) * 0.0078125
    assert all(col[-1] == 0 for col in x)
    return [hx(value) for col in x for value in col]


def rhs(n, p, probe):
    rng = random.Random(SEED + 1_000_003 * n + 23_011 * p + probe * 911)
    vector = [
        rng.uniform(-1, 1) * (2.0 ** ((row + probe) % 9 - 4))
        for row in range(n - 1)
    ]
    if probe % 3 == 0:
        vector[1] = (2.0 ** 25)
        vector[2] = -(2.0 ** 25)
        vector[3] = (2.0 ** -23) * (1 + (probe + 1) * 2.0 ** -52)
    elif probe % 3 == 1:
        vector[15] = 1.0
        vector[16] = -(1.0 + (probe + 1) * 2.0 ** -52)
        vector[31] = 2.0 ** -14
    else:
        vector[p] = 1.0
        vector[p + 1] = -1.0
        vector[n - 3] = 2.0 ** -25
    vector.append(0.0)
    assert len(vector) == n and vector[-1] == 0.0
    return [hx(value) for value in vector]


def main():
    target = HERE / "input.json"
    assert not target.exists(), "never overwrite a frozen original-firstblind input"
    matrices = []
    cases = []
    for p in (9, 10, 11, 12):
        for n in (48, 65):
            matrix_id = f"v589_new_two_reflector_n{n}_p{p}"
            matrices.append({
                "id": matrix_id, "n": n, "p": p,
                "a_colmajor_hex": matrix(n, p),
            })
            for probe in range(PROBE_COUNT):
                cases.append({
                    "id": f"{matrix_id}_new_probe_{probe:02d}",
                    "matrix_id": matrix_id,
                    "probe": f"new_independent_{probe:02d}",
                    "layout": "repeated",
                    "b_colmajor_hex": rhs(n, p, probe),
                })
    assert len(matrices) == 8 and len(cases) == 96
    doc = {
        "classification": CLASS, "seed": SEED,
        "V12": "SEALED", "source_only": True,
        "NOT_new_original_firstblind": False,
        "new_source_firstblind_candidate": True,
        "original_MATLAB_numerical_outputs_read": False,
        "independent_Rust_outputs_read": False,
        "case_count": len(cases), "matrix_count": len(matrices),
        "padding_n48": [0, 2, 3, 7], "padding_n65": [0, 1, 2, 7],
        "widths": [1, 2, 11, 12, 13, 16, 17, 20, 23, 24, 25, 28, 32],
        "matrices": matrices, "cases": cases,
    }
    raw = (json.dumps(doc, sort_keys=True, separators=(",", ":")) + "\n").encode()
    target.write_bytes(raw)
    digest = hashlib.sha256(raw).hexdigest()
    (HERE / "input.sha256").write_text(digest + "  input.json\n")
    print("V589 original-free input SHA", digest, "matrices", len(matrices),
          "new X/B probes", len(cases))


if __name__ == "__main__":
    main()
