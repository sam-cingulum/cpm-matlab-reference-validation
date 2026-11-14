#!/usr/bin/env python3
"""Deterministic PUBLIC/DISCLOSED gamma-beta boundary microprobe inputs.

No MATLAB outputs, no regression inputs, no random user/clinical data.
Run and commit input.json + input.sha256 BEFORE genuine original execution.
"""
from __future__ import annotations

import hashlib
import json
import math
import struct
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCHEMA = "CINGULUM_R2026B_GAMMA_BETA_BRANCH_MICROPROBE_V2_SOURCE_DISCLOSED"
CLASS = "SOURCE_DISCLOSED_NUMERICAL_BRANCH_MICROPROBE_NOT_SOURCE_UNSEEN"


def hx(f: float) -> str:
    assert math.isfinite(f)
    return struct.pack(">d", f).hex()


def adjacent(v: float, side: int) -> float:
    return math.nextafter(v, math.inf if side > 0 else -math.inf)


def neighbors(v: float) -> list[float]:
    return [adjacent(v, -1), v, adjacent(v, 1)]


def main() -> None:
    gvalues = set()
    anchors = [.25, .5, .75, 1., 1.5, 2., 2.5, 3.5, 4.5,
               6.5, 7.5, 8., 10.5, 11.5, 15.5, 16.,
               19.5, 20., 30.5, 31.5, 32., 40.5, 50.5, 60.5]
    fractions = [0.1, .2, 1./3., 2./3., .875, 1.125, 1.375,
                 2.25, 2.75, 5.25, 5.75, 8.25, 12.25, 18.25,
                 24.25, 32.25, 48.25, 60.25]
    for v in anchors + fractions:
        gvalues.update(x for x in neighbors(v) if 0. < x <= 61.)
    gamma = [
        {"id": f"switch_gamma_{i:04d}", "x_hex": hx(v)}
        for i, v in enumerate(sorted(gvalues))
    ]

    betavalues: set[tuple[float, float, float]] = set()
    for a in [.5, 1.5, 3.5, 7.5, 10.5, 15.5, 20.5]:
        for b in [.5, 1., 1.5, 2., 3.5, 7.5]:
            switch = (a + 1.) / (a + b + 2.)
            mass = a / (a + b)
            xs = neighbors(switch) + neighbors(mass) + [
                2.**-40, 2.**-20, .01, .25, .5, .75,
                1. - 2.**-20, 1. - 2.**-40]
            for x in xs:
                if 0. < x < 1.:
                    betavalues.add((a, b, x))
    beta = [
        {"id": f"switch_beta_{i:04d}", "a_hex": hx(a), "b_hex": hx(b),
         "x_hex": hx(x)}
        for i, (a, b, x) in enumerate(sorted(betavalues))
    ]

    studentvalues: set[tuple[float, float]] = set()
    for nu in [7., 9., 13., 15., 21., 23., 27., 31., 35., 39.]:
        th = math.sqrt(nu)
        ts = [0., 2.**-40, .125, .5, 1., 2., th,
              adjacent(th, -1), adjacent(th, 1),
              -adjacent(th, -1), -th, -adjacent(th, 1),
              2.*th, 4.*th, 20., 1e3, 1e6]
        for t in ts:
            studentvalues.add((nu, t))
    student = [
        {"id": f"switch_student_{i:04d}", "nu_hex": hx(nu), "t_hex": hx(t)}
        for i, (nu, t) in enumerate(sorted(studentvalues))
    ]
    manifest = {
        "schema": SCHEMA,
        "classification": CLASS,
        "input_classification": "PUBLIC_SOURCE_DISCLOSED_NOT_NEW_SOURCE_UNSEEN",
        "original_MATLAB_numeric_data_supplied": False,
        "source_unseen_V12": "NOT_GENERATED",
        "gamma_count": len(gamma), "beta_count": len(beta),
        "student_count": len(student),
        "gamma": gamma, "beta": beta, "student": student
    }
    encoded = (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode()
    (HERE / "input.json").write_bytes(encoded)
    digest = hashlib.sha256(encoded).hexdigest()
    (HERE / "input.sha256").write_text(f"{digest}  input.json\n")
    assert len(gamma) >= 100 and len(beta) >= 400 and len(student) >= 160
    print(f"DISCLOSED boundary grid: gamma={len(gamma)}, beta={len(beta)}, "
          f"student={len(student)}; input_sha256={digest}")


if __name__ == "__main__":
    main()
