#!/usr/bin/env python3
"""Prospective new-X source-only two-reflector RHS microkernel holdout.

Neither the generator nor the original MATLAB runner reads original numerical
results or Rust forecasts. All raw binary64 matrix/RHS source words are frozen
before compiling the independent Rust forecast or running original MATLAB.
"""

import hashlib
import json
import math
from pathlib import Path
import random
import struct


HERE = Path(__file__).resolve().parent
SEED = 202611230523
N_VALUES = (48, 65)
P_VALUES = (9, 10, 11, 12)
PROBES = (
    "unit_r02", "unit_r15", "unit_r16", "unit_r23", "unit_r24",
    "unit_r31", "unit_r32", "unit_r33", "ulp_cancel_r16_r17",
    "ulp_cancel_r31_r32", "alternating_dyadic", "alternating_ulp",
)
CLASSIFICATION = "V523_NEW_X_SOURCE_UNSEEN_R2026B_QR_RHS_MICROKERNEL_INPUT"


def word(value):
    assert math.isfinite(value)
    return struct.pack(">d", float(value)).hex()


def rhs(n, name):
    values = [0.0] * n
    if name.startswith("unit_r"):
        values[int(name[6:]) - 1] = 1.0
    elif name.startswith("ulp_cancel_r"):
        left, right = name[len("ulp_cancel_r"):].split("_r")
        values[int(left) - 1] = 1.0
        values[int(right) - 1] = -(1.0 + 2.0 ** -52)
    elif name == "alternating_dyadic":
        for row in range(1, n - 1):
            values[row] = ((-1.0) ** row) * (2.0 ** ((row % 5) - 3))
    elif name == "alternating_ulp":
        for row in range(1, n - 1):
            values[row] = ((-1.0) ** row) * (
                (1.0 + 2.0 ** -52) if row % 3 == 0 else 1.0
            )
    else:
        raise ValueError(name)
    assert values[-1] == 0.0
    return values


def main():
    matrices = []
    cases = []
    for p in P_VALUES:
        for n in N_VALUES:
            seed = SEED + p * 23011 + n * 90311 + 417
            rng = random.Random(seed)
            columns = [[0.0] * n for _ in range(p)]
            columns[0][0] = 4.5
            for row in range(p, n - 1):
                columns[0][row] = ((-1.0) ** row) * (
                    0.9 + 0.4 * rng.random()
                ) * (2.0 ** ((row % 5) - 2))
            for k in range(1, p):
                columns[k][k] = 2.0 ** (-k)
            for row in range(p, n - 1):
                columns[1][row] = (
                    columns[0][row] * 0.00625
                    + ((-1.0) ** row) * 0.0078125
                )
            assert all(col[-1] == 0.0 for col in columns)
            matrix_id = f"v523_newx_n{n}_p{p}_seed{seed}"
            matrices.append({
                "id": matrix_id, "n": n, "p": p,
                "a_colmajor_hex": [word(v) for col in columns for v in col],
            })
            for name in PROBES:
                cases.append({
                    "id": f"{matrix_id}__{name}",
                    "matrix_id": matrix_id, "probe": name,
                    "b_colmajor_hex": [word(v) for v in rhs(n, name)],
                })
    assert len(matrices) == 8 and len(cases) == 96
    payload = {
        "classification": CLASSIFICATION,
        "V12": "SEALED",
        "source_only": True,
        "NOT_new_firstblind": True,
        "original_MATLAB_numerical_outputs_read": False,
        "source_original_only_reads_Rust_values": False,
        "independent_Rust_outputs_read": False,
        "seed": SEED,
        "matrix_count": len(matrices),
        "case_count": len(cases),
        "matrices": matrices,
        "cases": cases,
        "rhs_variants": ["unmodified", "interior_reverse", "alternating_sign"],
        "layouts": ["repeated", "signed_power2"],
        "widths": [1, 2, 11, 12, 13, 23, 24],
        "padding_n48": [0, 2, 3, 7],
        "padding_n65": [0, 1, 2, 7],
        "original_repetitions": 2,
    }
    raw = (json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n").encode()
    destination = HERE / "input.json"
    assert not destination.exists(), "source input already frozen"
    destination.write_bytes(raw)
    digest = hashlib.sha256(raw).hexdigest()
    (HERE / "input.sha256").write_text(f"{digest}  input.json\n")
    print(f"V523 new X/B source SHA {digest}, matrices {len(matrices)}, RHS cases {len(cases)}")


if __name__ == "__main__":
    main()
