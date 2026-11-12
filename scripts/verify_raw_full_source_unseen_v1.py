#!/usr/bin/env python3
"""Fail-closed external exact-hex verifier for the 48-case source-unseen R2026b gate.

Stage A cannot access original robustfit outputs. Stage B cannot run before
clone predictions and their SHA256 have been committed to public Git.
All 12 fields compare IEEE-754 binary64 hexadecimal representations, not
decimal approximations. Separate actual Rust native parity is NOT claimed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "Cingulum_Yale_MATLAB_Online"
DIR = BASE / "robustfit_raw_full_source_unseen_v1"
EXPERIMENT = "cpm-r2026b-independently-implemented-raw-bisquare-original-source-unseen-v1"
FAMILIES = ("baseline", "outliers", "rescaled", "high_leverage",
            "near_flat", "negative_slope", "positive_offset", "heteroskedastic")
NS = (29, 35, 43, 44, 57, 71)
GATES = ("intercept", "slope", "R", "h", "w", "mad_s", "robust_s",
         "ols_s", "s", "t", "p", "callbacks")
CODE = (
    BASE / "cpm_independent_bisquare_fit_raw_v2.m",
    BASE / "run_raw_full_source_unseen_clone_only_v1.m",
    BASE / "run_raw_full_source_unseen_original_only_v1.m",
    ROOT / "scripts/verify_raw_full_source_unseen_v1.py",
    ROOT / ".github/workflows/matlab-raw-full-source-unseen-stage-a.yml",
    ROOT / ".github/workflows/matlab-raw-full-source-unseen-stage-b.yml",
)
HEX = re.compile(r"^[0-9a-fA-F]{16}$")


def require(x: object, message: str) -> None:
    if not x:
        raise AssertionError(message)


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def read(p: Path) -> dict:
    return json.loads(p.read_text())


def write(p: Path, obj: dict) -> None:
    require(not p.exists(), "IMMUTABLE_OVERWRITE_DENIED: " + str(p))
    p.write_text(json.dumps(obj, indent=2, sort_keys=True, allow_nan=False) + "\n")


def code_hashes() -> dict[str, str]:
    return {str(p.relative_to(ROOT)): sha(p) for p in CODE}


def initial() -> tuple[dict, dict]:
    m, d = read(DIR / "manifest.json"), read(DIR / "input.json")
    require(m["experiment_id"] == d["experiment_id"] == EXPERIMENT, "experiment_id")
    require(m["original_source_not_run_at_freeze"] and
            m["input_frozen_before_independent_clone_or_original_source"], "unseen contract")
    require(m["expected_all_binary64_exact"] and
            m["separate_independent_prediction_freeze_before_source"], "binary64 contract")
    require(m["expected_case_count"] == 48 and m["expected_exact_gates"] == list(GATES), "gates")
    require(sha(DIR / "input.json") == m["input_sha256"], "INPUT_SHA256_MISMATCH")
    require(len(d["cases"]) == 48, "48 cases required")
    require(len({c["id"] for c in d["cases"]}) == 48, "duplicate identifiers")
    for i, c in enumerate(d["cases"]):
        family, n = FAMILIES[i // 6], NS[i % 6]
        require(c["family"] == family and c["n"] == n, "case order changed")
        require(len(c["x"]) == len(c["y"]) == n, "case lengths changed")
    return m, d


def hex_list(v: object, n: int, desc: str) -> list[str]:
    if isinstance(v, str):  # MATLAB encodes a one-element cell as string on some releases.
        v = [v]
    require(isinstance(v, list) and len(v) == n, desc + ": wrong hex element count")
    require(all(isinstance(h, str) and HEX.fullmatch(h) for h in v),
            desc + ": invalid IEEE-754 bit string")
    return [h.lower() for h in v]


def check_records(doc: dict, data: dict, stage: str) -> None:
    require(doc["experiment_id"] == EXPERIMENT and doc["stage"] == stage, "stage provenance")
    require(doc["release"] == "2026b", "incorrect MATLAB release")
    require(len(doc["records"]) == 48, "missing cases")
    require(doc["input_sha256"] == sha(DIR / "input.json"), "result/input SHA mismatch")
    for case, record in zip(data["cases"], doc["records"]):
        require(record["id"] == case["id"] and record["n"] == case["n"], "record order/ID/n")
        require(set(record["fields"]) == set(GATES), "exact 12-field gate set")
        for field in GATES:
            n = case["n"] if field in ("h", "w") else 4 if field == "R" else 1
            hex_list(record["fields"][field], n, case["id"] + "/" + field)


def check_profile(p: dict) -> None:
    require(p["release"] == "2026b" and "R2026b" in p["matlab_version"],
            "incompatible original MATLAB environment")
    require(p["max_num_comp_threads"] == 1, "MATLAB threads unpinned")
    # GitHub runner must set MKL_NUM_THREADS=1 before MATLAB launches.
    # MATLAB R2026b itself may clear it from getenv() after startup; record
    # and compare the observed value across both independent source runs.
    # maxNumCompThreads(1) remains mandatory, no bitwise gate is relaxed.
    require(p["mkl_cbwr"] == "COMPATIBLE" and
            p["mkl_num_threads"] in ("", "1") and p["omp_num_threads"] == "1",
            "BLAS/CPU environment unpinned")
    require(p["architecture"] and p["cpu_model"] and p["github_sha"] and p["github_run_id"],
            "missing runtime provenance")


def pre_clone() -> None:
    initial()
    require(not (DIR / "forecast.json").exists(), "clone forecast already frozen")
    require(not (DIR / "forecast_seal.json").exists(), "forecast seal already exists")
    require(not (DIR / "source_result.json").exists(), "ORIGINAL_ALREADY_EXPOSED")
    print("STAGE_A_INPUTS_AND_12_EXACT_GATES_FROZEN_NO_ORIGINAL_RESULTS")


def seal_forecast() -> None:
    m, d = initial()
    require(not (DIR / "source_result.json").exists(), "ORIGINAL_ALREADY_EXPOSED")
    forecast = read(DIR / "forecast.json")
    check_records(forecast, d, "A_independent_clone_only")
    require(forecast["source_never_invoked"] is True, "source invisibility")
    require(forecast["predictor"] == "cpm_independent_bisquare_fit_raw_v2", "method changed")
    check_profile(forecast["profile"])
    actual_head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    require(forecast["profile"]["github_sha"] == actual_head, "not executed at current frozen public HEAD")
    seal = {
        "experiment_id": EXPERIMENT,
        "status": "STAGE_A_PREDICTIONS_FROZEN_BEFORE_FIRST_ORIGINAL_SOURCE_CALL",
        "prospective_unseen_original_not_yet_run": True,
        "input_sha256": sha(DIR / "input.json"),
        "manifest_sha256": sha(DIR / "manifest.json"),
        "forecast_sha256": sha(DIR / "forecast.json"),
        "original_source_name": "unchanged MathWorks MATLAB R2026b robustfit",
        "independent_source_method": "cpm_independent_bisquare_fit_raw_v2",
        "field_names": list(GATES),
        "exactness": "all full-array IEEE-754 binary64 hex; no tolerance",
        "prediction_run_id": forecast["profile"]["github_run_id"],
        "prediction_run_attempt": forecast["profile"]["github_run_attempt"],
        "prediction_git_sha": actual_head,
        "runtime_profile": forecast["profile"],
        "code_sha256": code_hashes(),
        "native_compiled_Rust_parity_claimed": False,
    }
    write(DIR / "forecast_seal.json", seal)
    print("STAGE_A_PREDICTION_SHA256", seal["forecast_sha256"])
    print("STAGE_A_FORECAST_SEALED_BEFORE_ORIGINAL_SOURCE")


def frozen() -> tuple[dict, dict, dict]:
    m, d = initial()
    s = read(DIR / "forecast_seal.json")
    require(s["experiment_id"] == EXPERIMENT and
            s["status"] == "STAGE_A_PREDICTIONS_FROZEN_BEFORE_FIRST_ORIGINAL_SOURCE_CALL",
            "missing immutable prediction seal")
    require(s["prospective_unseen_original_not_yet_run"] and
            s["input_sha256"] == sha(DIR / "input.json") and
            s["manifest_sha256"] == sha(DIR / "manifest.json") and
            s["forecast_sha256"] == sha(DIR / "forecast.json"), "seal SHA mismatch")
    require(s["code_sha256"] == code_hashes(), "frozen source/workflow code SHA mismatch")
    require(s["field_names"] == list(GATES) and
            s["exactness"] == "all full-array IEEE-754 binary64 hex; no tolerance", "gate changed")
    f = read(DIR / "forecast.json")
    check_records(f, d, "A_independent_clone_only")
    require(f["source_never_invoked"] and f["profile"] == s["runtime_profile"],
            "forecast/profile altered")
    check_profile(f["profile"])
    subprocess.run(["git", "merge-base", "--is-ancestor", s["prediction_git_sha"], "HEAD"],
                   cwd=ROOT, check=True)
    return d, f, s


def pre_source() -> None:
    frozen()
    require(not (DIR / "source_result.json").exists(), "STALE_SOURCE_RESULT_PRESENT")
    print("STAGE_B_AUTHORIZED_PRIOR_PREDICTIONS_AND_CODE_SHA_SEALED")


def exact_comparison(f: dict, source: dict, d: dict) -> dict:
    matches = {k: 0 for k in GATES}
    mismatches = []
    for case, predicted, original in zip(d["cases"], f["records"], source["records"]):
        for field in GATES:
            n = case["n"] if field in ("h", "w") else 4 if field == "R" else 1
            a = hex_list(predicted["fields"][field], n, "forecast/" + field)
            b = hex_list(original["fields"][field], n, "source/" + field)
            if a == b:
                matches[field] += 1
            else:
                mismatches.append({"case_id": case["id"], "field": field,
                                   "unequal_elements": sum(x != y for x, y in zip(a, b))})
    return {"exact_counts": matches, "mismatches": mismatches,
            "all_12_fields_exact_48_of_48": all(v == 48 for v in matches.values())}


def compare() -> None:
    d, f, s = frozen()
    source_path = DIR / "source_result.json"
    require(source_path.exists(), "NO_GENUINE_ORIGINAL_SOURCE_RESULT")
    source = read(source_path)
    check_records(source, d, "B_original_unchanged_robustfit_only")
    require(source["genuine_original_robustfit"] is True, "not original source")
    check_profile(source["profile"])
    require(source["profile"]["github_sha"] != s["prediction_git_sha"], "source not from later commit")
    require(source["profile"]["github_run_id"] != s["prediction_run_id"], "source run reused clone run")
    require(not os.environ.get("GITHUB_RUN_ID") or
            source["profile"]["github_run_id"] == os.environ["GITHUB_RUN_ID"],
            "source is stale or reused from another GitHub run")
    require(not os.environ.get("GITHUB_SHA") or
            source["profile"]["github_sha"] == os.environ["GITHUB_SHA"],
            "source git revision mismatch")
    profile_fields = ("matlab_version", "release", "architecture", "cpu_model",
                      "max_num_comp_threads", "mkl_cbwr", "mkl_num_threads", "omp_num_threads")
    profile_equal = all(f["profile"][k] == source["profile"][k] for k in profile_fields)
    results = exact_comparison(f, source, d)
    result = {
        "experiment_id": EXPERIMENT,
        "prediction_sha256": s["forecast_sha256"],
        "original_source_sha256": sha(source_path),
        "prediction_git_sha": s["prediction_git_sha"],
        "source_git_sha": source["profile"]["github_sha"],
        "prediction_run_id": s["prediction_run_id"],
        "source_run_id": source["profile"]["github_run_id"],
        "cases": 48, "fields": list(GATES),
        "profile_identical": profile_equal,
        "profile_differences": {k: [f["profile"][k], source["profile"][k]]
                                for k in profile_fields if f["profile"][k] != source["profile"][k]},
        "strict_no_tolerance_binary64": True,
        "matlab_language_raw_full_algorithm_prospectively_certified":
            profile_equal and results["all_12_fields_exact_48_of_48"],
        "compiled_Rust_original_raw_parity_certified": False,
        **results,
    }
    verdict_path = DIR / "strict_external_verdict.json"
    write(verdict_path, result)
    print(json.dumps(result, indent=2))
    require(profile_equal, "MATLAB_EXECUTION_PROFILE_DIFFERENT_UNCERTIFIABLE")
    require(results["all_12_fields_exact_48_of_48"], "BINARY64_PROSPECTIVE_EXACT_GATE_FAILED")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=("pre-clone", "seal-forecast", "pre-source", "compare"))
    args = ap.parse_args()
    try:
        {"pre-clone": pre_clone, "seal-forecast": seal_forecast,
         "pre-source": pre_source, "compare": compare}[args.mode]()
    except (AssertionError, KeyError, ValueError, subprocess.CalledProcessError) as exc:
        print("FATAL_FAIL_CLOSED:", exc, file=sys.stderr)
        raise SystemExit(1) from exc


if __name__ == "__main__":
    main()
