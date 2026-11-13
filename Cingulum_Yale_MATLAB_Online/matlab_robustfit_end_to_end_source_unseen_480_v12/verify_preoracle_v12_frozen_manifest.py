#!/usr/bin/env python3
"""Fail closed before any new original MATLAB V12 source input exposure.

This script is PREAUTHORED only. No V12 lock, input, or native forecast exists.
It rejects absent, altered, disclosed, unsafely ordered or incomplete inputs.
"""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LENGTHS = (9, 11, 15, 17, 23, 25)
HEXD = re.compile(r"[0-9a-fA-F]{16}\Z")
HEX_SHA = re.compile(r"[0-9a-f]{64}\Z")


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def validate_lock(raw, lock, bytes_of_input, script_bytes):
    assert isinstance(lock, dict)
    assert set(("schema", "freeze_state", "raw_input_sha256", "native_frozen_sha256",
                "private_frozen_preoracle_commit", "rust_input_raw_xy_only",
                "forecast_complete_struct_has_17_stats_fields",
                "original_runner_sha256")).issubset(lock), "missing immutable preoracle fields"
    assert lock["schema"] == "CINGULUM_R2026B_V12_PREORACLE_LOCK_SHA256_V1"
    assert lock["freeze_state"] == "FROZEN_PUBLISHED_BEFORE_MATLAB_ORIGINAL"
    assert lock["rust_input_raw_xy_only"] is True
    assert lock["forecast_complete_struct_has_17_stats_fields"] is True
    assert lock["raw_input_sha256"] == digest(bytes_of_input)
    assert lock["original_runner_sha256"] == digest(script_bytes)
    assert all(HEX_SHA.fullmatch(lock[k]) for k in
               ("raw_input_sha256", "native_frozen_sha256", "original_runner_sha256"))
    assert re.fullmatch(r"[0-9a-f]{40}", lock["private_frozen_preoracle_commit"])
    assert raw["schema"] == "CINGULUM_MATHWORKS_R2026B_RAW_XY_FULL_ROBUSTFIT_480_V12_SOURCE_UNSEEN"
    assert len(raw["cases"]) == 480
    assert sorted(set(v["n"] for v in raw["cases"])) == list(LENGTHS)
    assert all(sum(v["n"] == n for v in raw["cases"]) == 80 for n in LENGTHS)
    ids = set()
    for row in raw["cases"]:
        assert isinstance(row["id"], str) and row["id"] not in ids
        ids.add(row["id"])
        n = row["n"]
        assert n in LENGTHS
        assert len(row["x_hex"]) == len(row["y_hex"]) == n
        assert all(isinstance(v, str) and HEXD.fullmatch(v) for v in
                   row["x_hex"] + row["y_hex"])
    assert lock["native_frozen_sha256"] != lock["raw_input_sha256"]


def main():
    input_file = ROOT / "input.json"
    freeze = ROOT / "PREORACLE_V12_LOCK.json"
    assert input_file.is_file() and freeze.is_file(), "V12 must remain disabled until frozen inputs and independent forecasts are actually published"
    input_bytes = input_file.read_bytes()
    raw = json.loads(input_bytes)
    lock = json.loads(freeze.read_bytes())
    validate_lock(raw, lock, input_bytes, (ROOT / "run_original_full_robustfit_v12.m").read_bytes())
    print("V12 preoracle lock SHA/shape verified; true push chronology must also be independently audited")


if __name__ == "__main__":
    main()
