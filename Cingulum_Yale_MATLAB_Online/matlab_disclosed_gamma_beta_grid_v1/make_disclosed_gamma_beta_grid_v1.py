#!/usr/bin/env python3
"""Public, deliberately DISCLOSED independent gamma/beta input grid.

No historical robustfit data, original MATLAB numerical intermediates, or
V12 source-unseen inputs are included. The grid is predetermined and hashed.
"""
from __future__ import annotations

import hashlib
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCHEMA = "CINGULUM_R2026B_GAMMA_BETA_SOURCE_DISCLOSED_GRID_V1"


def hexd(x: float) -> str:
    return struct.pack(">d", float(x)).hex()


def build() -> dict:
    # Across half-integer, integer, noninteger, recurrence and ULP boundaries.
    bases = [0.5 * n for n in range(1, 122)]
    bases.extend([0.125, 0.375, 0.625, 0.875, 1.125, 1.375, 1.875,
                  2.125, 2.375, 3.125, 4.25, 5.75, 6.125, 7.25,
                  9.625, 11.125, 14.625, 21.125, 32.375, 40.625])
    values = sorted(set(
        y for x in bases for y in
        (math.nextafter(x, 0.0), x, math.nextafter(x, math.inf))
        if math.isfinite(y) and y > 0.0
    ))
    gamma = [{"id": f"gamma_g{i:04d}", "x_hex": hexd(x)}
             for i, x in enumerate(values)]
    a_values = [0.5, 1.0, 1.5, 2.0, 3.5, 4.0, 5.5, 7.5,
                9.0, 11.5, 17.5, 23.5, 36.5, 52.5]
    b_values = [0.5, 1.0, 2.5, 7.5]
    x_values = [2.0 ** -50, 2.0 ** -30, 2.0 ** -16, 2.0 ** -8,
                0.01, 0.1, 0.25, 1 / 3, 0.5, 2 / 3, 0.75, 0.9,
                0.99, 1.0 - 2.0 ** -16, 1.0 - 2.0 ** -30]
    betas = []
    for a in a_values:
        for b in b_values:
            for x in x_values:
                betas.append({
                    "id": f"beta_b{len(betas):05d}",
                    "a_hex": hexd(a),
                    "b_hex": hexd(b),
                    "x_hex": hexd(x),
                })
    return {
        "schema": SCHEMA,
        "classification": "SOURCE_DISCLOSED_NUMERICAL_KERNEL_PROBE_NOT_SOURCE_UNSEEN",
        "gamma_count": len(gamma),
        "beta_count": len(betas),
        "gamma": gamma,
        "beta": betas,
    }


def main():
    payload = (json.dumps(build(), indent=2, sort_keys=True) + "\n").encode()
    target = ROOT / "input.json"
    if target.exists():
        assert target.read_bytes() == payload, "disclosed input was changed"
    else:
        target.write_bytes(payload)
    (ROOT / "input.sha256").write_text(hashlib.sha256(payload).hexdigest() + "  input.json\n")
    print("DISCLOSED V1, SHA256", hashlib.sha256(payload).hexdigest(),
          "gamma", len(build()["gamma"]), "beta", len(build()["beta"]))


if __name__ == "__main__":
    main()
