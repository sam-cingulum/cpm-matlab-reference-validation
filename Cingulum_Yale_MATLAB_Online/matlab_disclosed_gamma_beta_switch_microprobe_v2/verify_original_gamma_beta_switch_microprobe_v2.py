#!/usr/bin/env python3
"""Validate full original MathWorks SOURCE-DISCLOSED gamma/beta V2 output.

No native Rust forecast is used. Requires immutable prepublished public input
and two complete unchanged original-run repetitions. Not a V12 certificate.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
HEX = re.compile(r"[0-9a-f]{16}\Z")
SCHEMA = "CINGULUM_R2026B_GAMMA_BETA_BRANCH_MICROPROBE_V2_SOURCE_DISCLOSED"
CLASSIFICATION = "ORIGINAL_MATHWORKS_R2026B_GAMMA_BETA_SWITCH_MICROPROBE_V2_SOURCE_DISCLOSED"
REQUIRED_INPUT = {
    "gamma": {"id", "x_hex"},
    "beta": {"id", "a_hex", "b_hex", "x_hex"},
    "student": {"id", "nu_hex", "t_hex"},
}
REQUIRED_OUTPUT = {
    "gamma": {"id", "rep", "x_hex", "gammaln_hex",
              "gammaln_xplus1_hex", "gammaln_recurrence_hex",
              "gamma_hex", "log_gamma_hex"},
    "beta": {"id", "rep", "a_hex", "b_hex", "x_hex",
             "ga_hex", "gb_hex", "gsum_hex", "betaln_hex",
             "composed_betaln_hex", "lower_hex", "upper_hex",
             "log_x_hex", "log1p_negative_x_hex",
             "log_prefactor_hex", "log_prefactor_alt_hex"},
    "student": {"id", "rep", "nu_hex", "t_hex", "t_abs_hex", "t2_hex",
                "den_hex", "u_hex", "x_hex", "tcdf_negative_hex",
                "two_tcdf_hex", "betainc_lower_hex",
                "betainc_upper_hex", "piecewise_tail_hex"},
}
EXPECTED_ROOT = {"classification", "source_unseen_V12", "input_schema",
                 "original_unmodified", "release", "matlab_version",
                 "computer", "mkl_cbwr", "max_num_comp_threads",
                 "repetitions", "gamma_count", "beta_count",
                 "student_count", "gamma", "beta", "student"}


def digest(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()


def checked_input() -> dict:
    data = (HERE / "input.json").read_bytes()
    published = (HERE / "input.sha256").read_text().strip().split()
    assert len(published) == 2 and published[1] == "input.json"
    assert published[0] == digest(data), "published input SHA mismatch"
    src = json.loads(data)
    assert src["schema"] == SCHEMA
    assert src["classification"] == "SOURCE_DISCLOSED_NUMERICAL_BRANCH_MICROPROBE_NOT_SOURCE_UNSEEN"
    assert src["original_MATLAB_numeric_data_supplied"] is False
    assert src["source_unseen_V12"] == "NOT_GENERATED"
    for kind, fields in REQUIRED_INPUT.items():
        rows = src[kind]
        assert len(rows) == src[kind + "_count"]
        assert len(rows) == len({r["id"] for r in rows})
        for r in rows:
            assert set(r) == fields
            for key, value in r.items():
                if key.endswith("_hex"):
                    assert isinstance(value, str) and HEX.fullmatch(value)
    return src


def validate(result: dict, src: dict) -> None:
    assert set(result) == EXPECTED_ROOT, "wrong original source output fields"
    assert result["classification"] == CLASSIFICATION
    assert result["source_unseen_V12"] == "NOT_GENERATED"
    assert result["input_schema"] == src["schema"]
    assert result["release"] == "2026b"
    assert result["original_unmodified"] is True
    assert result["mkl_cbwr"] == "COMPATIBLE"
    assert result["max_num_comp_threads"] == 1
    assert result["repetitions"] == 2
    assert result["matlab_version"] and result["computer"]
    for kind, required in REQUIRED_OUTPUT.items():
        n = src[kind + "_count"]
        rows = result[kind]
        assert result[kind + "_count"] == n
        assert len(rows) == 2 * n, (kind, "incomplete original output")
        for i in range(n):
            original, duplicate = dict(rows[i]), dict(rows[n + i])
            assert set(original) == set(duplicate) == required
            assert original.pop("rep") == 1 and duplicate.pop("rep") == 2
            assert original == duplicate, (kind, i, "original source nonrepeatability")
            assert original["id"] == src[kind][i]["id"]
            for name in REQUIRED_INPUT[kind] - {"id"}:
                assert original[name] == src[kind][i][name], (kind, i, name, "input altered")
            for key, value in original.items():
                if key.endswith("_hex"):
                    assert isinstance(value, str) and HEX.fullmatch(value), (kind, i, key)


def main() -> None:
    assert len(sys.argv) == 2, "usage: verify_original_gamma_beta_switch_microprobe_v2.py original_source_output.json"
    src = checked_input()
    original_bytes = Path(sys.argv[1]).read_bytes()
    result = json.loads(original_bytes)
    validate(result, src)
    print("ORIGINAL source-disclosed gamma/beta switch V2: two genuine source repetitions VALID")
    for kind in ("gamma", "beta", "student"):
        print(kind, src[kind + "_count"])
    print("input SHA256", (HERE / "input.sha256").read_text().split()[0])
    print("original numeric output SHA256", digest(original_bytes))
    # Adversarial one-bit tampering must be detected by full repetition rules.
    changed = json.loads(original_bytes)
    original_bit = changed["gamma"][0]["gammaln_hex"]
    changed["gamma"][0]["gammaln_hex"] = f"{int(original_bit, 16) ^ 1:016x}"
    try:
        validate(changed, src)
    except AssertionError:
        print("one-bit source corruption control: PASS (rejected)")
    else:
        raise AssertionError("one-bit altered original falsely accepted")


if __name__ == "__main__":
    main()
