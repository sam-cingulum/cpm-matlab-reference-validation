#!/usr/bin/env python3
"""Generate independent original-free V641 row-length/partial-tile parity inputs."""

import hashlib
import json
import math
import random
import struct
from pathlib import Path

HERE = Path(__file__).resolve().parent
SEED = 202611246411
CLASSIFICATION = "V641_PROSPECTIVE_ORIGINAL_UNSEEN_PUBLIC_QTB_ROW_LENGTH"
GEOMETRIES = [(48, 9, [2, 3]), (64, 10, [0, 1]), (65, 11, [1, 2]),
              (80, 9, [0, 3]), (96, 10, [0, 7])]
WIDTHS = [1, 2, 3, 5, 7, 9, 11, 12, 13, 14, 15, 16, 17, 19, 20, 21,
          23, 24, 25, 26, 27, 28, 29, 31, 32]


def word(value):
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
    return [word(value) for col in columns for value in col]


def response(n, p, probe):
    rng = random.Random(SEED + 1_000_003 * n + 23_011 * p + probe * 911)
    values = [rng.uniform(-1, 1) * 2.0 ** ((row + probe) % 9 - 4)
              for row in range(n - 1)]
    if probe % 5 == 0:
        values[1], values[2] = 2.0 ** 25, -(2.0 ** 25)
        values[3] = 2.0 ** -23 * (1 + 2.0 ** -52)
    elif probe % 5 == 1:
        values[15] = 1.0
        values[16] = -(1.0 + (probe + 1) * 2.0 ** -52)
        values[31] = 2.0 ** -14
    elif probe % 5 == 2:
        values[p], values[p + 1], values[n - 3] = 1.0, -1.0, 2.0 ** -25
    elif probe % 5 == 3:
        values[0] = -2.0 ** 30
        values[1] = 2.0 ** 30
        values[n - 2] = 2.0 ** -40
    else:
        for row in range(1, n - 1, 2):
            values[row] = -values[row - 1] * (1 + 2.0 ** -52)
    values.append(0.0)
    return [word(value) for value in values]


def main():
    output = HERE / "input.json"
    assert not output.exists(), "never replace frozen prospective source"
    matrices = []
    cases = []
    for n, p, pads in GEOMETRIES:
        identifier = f"v641_original_unseen_n{n}_p{p}"
        matrices.append({"id": identifier, "n": n, "p": p, "padding": pads,
                         "a_colmajor_hex": matrix(n, p)})
        for probe in range(5):
            cases.append({"id": f"{identifier}_probe_{probe:02d}",
                          "matrix_id": identifier,
                          "b_colmajor_hex": response(n, p, probe)})
    source = {"classification": CLASSIFICATION, "seed": SEED, "V12": "SEALED",
              "source_only": True, "original_MATLAB_numerical_outputs_read": False,
              "independent_Rust_outputs_read": False, "geometries": GEOMETRIES,
              "widths": WIDTHS, "matrices": matrices, "cases": cases}
    raw = (json.dumps(source, sort_keys=True, separators=(",", ":")) + "\n").encode()
    output.write_bytes(raw)
    digest = hashlib.sha256(raw).hexdigest()
    (HERE / "input.sha256").write_text(f"{digest}  input.json\n")
    print(f"V641 frozen original-free input SHA {digest}: {len(matrices)} matrices, {len(cases)} probes")


if __name__ == "__main__":
    main()
